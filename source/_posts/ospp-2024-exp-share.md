---
title: OSPP 2024 经验分享
date: 2024-09-12 02:09:25
tags: OSPP2024
---
## 简单版简历
- Github: [feathercyc](https://github.com/GG2002)
- 邮箱：feathercyc@163.com
- 教育经历：
    - 2023-现今：硕士，计算机科学与技术，华中科技大学

## 项目基本信息
- 项目名称：图数据库 NebulaGraph 对接数据访问层 OpenDAL
- 项目导师：Suyan
- 项目描述：OpenDAL 是一个数据访问层，允许用户以统一的方式轻松有效地从各种存储服务中检索数据。目前 OpenDAL 尚未对接图数据库 NebulaGraph，希望通过这个项目完成 NebulaGraph 和 OpenDAL 的对接，让 OpenDAL 能直接访问 NebulaGraph 存储的数据。
- 项目链接：https://summer-ospp.ac.cn/org/prodetail/241190422

## 关于 OpenDAL 社区
> OpenDAL 是一个数据访问层，其支持以相同的方式访问多种存储后端，旨在减轻开发人员要为每个服务重新实现访问各种存储后端的工作量。

## 关于 NebulaGraph 社区
> NebulaGraph 是图数据库，其以 vertex，edge 和 tag 的形式存储数据。其中 vertex 为点，在一般项目中可以是一个人、一篇帖子、一个组织等任意实体；edge 则是点之间的关系，如引用、属于、包含等各种关系；而 tag 则是用来修饰 vertex 的东西，如个人信息，帖子发布信息，组织信息等。从 tag 的角度看，vertex 可以视作为一堆 tag 的集合。
> 
> 图数据库这样做的优点在于灵活性高，支持复杂的图形算法，可用于构建复杂的关系图谱。它可以看作是特化了传统关系型数据库的 JOIN 操作，简化了用户查询实体之间的关系的操作，换言之，图数据库是比关系型数据库更注重关系的数据库。

## 项目实现思路
要给 OpenDAL 新增 Service，最低要求是为新增的 Service 实现位于 core/src/raw 下的 Access trait 和 Builder trait。OpenDAL 主要支持的云存储后端都实现了这两个 trait。

而要新增 DB Service 则简单不少，因为 OpenDAL 定义了 Adapter trait，实现这个 trait 就可以让 OpenDAL 使用任何 KV 工作。因此，只要将各类 DB 的操作映射为 KV DB 的操作——set, get, delete, scan，OpenDAL 就可以使用这个 DB 了。

实际上，直接为 DB 实现 Access trait 也是可行的，OpenDAL 能访问实现了 Adapter trait 的 DB 是因为 OpenDAL 自己为 Adapter trait 实现了 Access trait。这在简化了添加 DB 服务难度的同时，也减弱了 DB 能提供的功能。

以上皆摘自笔者的 [Proposal](https://docs.google.com/document/d/1yF370GX8lrVUbmeZk4wiY8kBpnKbML6pUuqqtV7cXxI)，也是笔者最开始设想的工作量最大的地方。那么看到这句话，大家也都知道了实际上笔者在做这个项目时付出最大精力的点并不在这。

OpenDAL 适配各类 DB 的前提是各类 DB 有着可以直接比较好操作 DB 的客户端。尽管数据库客户端这种东西在开发的绝大部分时候已经被各类 ORM 框架集成好了，因此它的存在感较低，但只要它实现的不好，那么它的存在感就会飙升了。笔者正是花了大量的时间在修缮 NebulaGraph 的 Rust 客户端上。

关于 NebulaGraph 的 Rust 客户端现状笔者也在 Proposal 里提到了，下面摘录一段：
> 官方提供了各种语言版本的 Client，不同语言 Client 的功能完善度都不同。其中 nebula-python 与 nebula-go 是官方支持最好的，毕竟官方的 nebula-console 是用 Golang 写的，而 python 主要用于数据科学方面，所以也得到了较好的支持。这两个项目都能独立连接 metad、graphd、storaged。
> 
> 而 nebula-rust 客户端仓库目前目录与包含的项目就比较杂乱了，梳理介绍如下：
> ... ...

> 该仓库基本处于放养状态，上次 commit 是在 7 个月前。我初步尝试了使用 nebula-client 连接 graphd 来执行自定义的 nGQL 并获取查询结果，过程还算顺利，至少按其 README 所言的方法连接并没有出什么问题。

虽然当时笔者已经料想到了这一步的工作量，但也只是想到也许要对这个客户端做一些修修补补的工作。而结果是笔者经过沟通交流后直接舍弃了修修补补这个客户端，选择了借鉴它的代码，然后重写一个新的客户端。

原因在于 nebula-rust 并不支持动态获取查询结果，在笔者重写之前，它只能接受一个定义好的结构体，然后将结果挨个赋值到结构体字段上。这是不可能拿去直接给 OpenDAL 使用的，因为 OpenDAL 需要用户自定义字段名，然后根据名字去查询结果里找数据，而结构体定义是在编译期就确定下来的，假如用户给了新字段，新的结构体定义不可能凭空生成。

同时 nebula-rust 由于年久失修，前前主人想给它可替换异步运行时、可兼容 NebulaGraph v1/v2/v3的强大的能力，但实际上除了tokio与v3，其他的支持都是新建文件夹状态，这就在代码结构上留出了不少让人乍一看看不明白的冗余设计。而前主人又给它加上了连接storaged与metad的功能，但支持的也不是很好，代码结构显得更加凌乱了。

总之由于这样那样的原因，笔者感受到再往 nebula-rust 上面堆代码是一件很难受的事情，于是与 NebulaGraph 负责人沟通了一阵子，决定重写这个客户端。由于 nebula-rs 与 nebula-rust 这两个名字都被前前主人用了，现在又联系不上，笔者只好新开一个仓库，命名为 `rust-nebula`（要是笔者也停止维护了，NebulaGraph 就没有符合直觉的 rust 客户端命名可用了）。

决定重写之后，单就项目本身待添加的新功能而言，其原理并不复杂。NebulaGraph 返回的结果都是统一的 DataSet 结构体，只需给 DataSet 包装一层好用的接口即可。
### 为 rust-nebula 添加 DataSetWrapper
说是 wrapper，但 rust 里对所有权的限制让真正的 wrapper 几乎无法实现，即使实现了，可能也要手动在所有函数上加上生命周期声明，并且每次使用的时候都要显式地获取一个 wrapper。因此，笔者实现的 DataSetWrapper 实际上直接获取了 DataSet 的所有权。结构体如下：
```rust
#[derive(Debug)]
pub struct DataSetWrapper {
    dataset: DataSet,
    col_name_index_map: HashMap<Vec<u8>, usize>,
    timezone_info: TimezoneInfo,
}
```
而对于 NebulaGraph 的 graphd 与 storaged 返回的不同查询结构，笔者使用了两个结构体 `GraphQueryOutput` 和 `StorageQueryOutput` 来处理。只需在 new 函数分别里转移 `ExecutionResponse` 和 `ScanResponse` 的 DataSet 所有权即可：
```rust
impl GraphQueryOutput {
    pub(super) fn new(mut resp: ExecutionResponse, timezone_info: TimezoneInfo) -> Self {
        let data_set = resp.data.take();
        let data_set = data_set.map(|v| DataSetWrapper::new(v, timezone_info));
        Self { resp, data_set }
    }
}


impl StorageQueryOutput {
    pub fn new(mut resp: ScanResponse, timezone_info: TimezoneInfo) -> Self {
        let data_set = resp.props.take();
        let data_set = data_set.map(|v| DataSetWrapper::new(v, timezone_info));
        Self { resp, data_set }
    }
}
```
DataSet 的结构也相当简单，是非常常规的表格形式，这一点也是 NebulaGraph 与 Neo4j 的不同，两者同为图数据库，NebulaGraph 对数据的约束会更大一些，和 SQL 一样都是处理结构性数据，而 Neo4j 接受的则是非结构性数据。因此只需提供下列的函数，rust-nebula 就可以很好地支持动态获取 DataSet 里不同字段名的数据这一功能了：
```rust
impl DataSetWrapper {
    pub fn as_string_table(&self) -> Vec<Vec<String>> {
        let mut res_table = vec![];
        let col_names = self
            .get_col_names()
            .iter()
            .map(|v| String::from_utf8(v.to_vec()).unwrap())
            .collect();
        res_table.push(col_names);
        let rows = self.get_rows();
        let mut rows_table = rows
            .iter()
            .map(|row| {
                let temp_row = row
                    .values
                    .iter()
                    .map(|v| ValueWrapper::new(v, &self.timezone_info).to_string())
                    .collect();
                temp_row
            })
            .collect();
        res_table.append(&mut rows_table);
        res_table
    }

    // Returns all values in the given column
    pub fn get_values_by_col_name(
        &self,
        col_name: &str,
    ) -> Result<Vec<ValueWrapper>, DataSetError> {
        if !self.has_col_name(col_name) {
            return Err(DataSetError::UnexistedColumnError(col_name.to_string()));
        }
        let col_name = col_name.as_bytes().to_vec();
        let index = self.col_name_index_map[&col_name];
        let rows = self.get_rows();
        let val_list = rows
            .iter()
            .map(|row| ValueWrapper::new(&row.values[index], &self.timezone_info))
            .collect();
        Ok(val_list)
    }

    pub fn get_row_values_by_index<'a>(&'a self, index: usize) -> Result<Record<'a>, DataSetError> {
        if index >= self.get_row_size() {
            return Err(DataSetError::InvalidIndexError(index, self.get_row_size()));
        }
        let rows = self.get_rows();
        let val_wrap = gen_val_wraps(&rows[index], &self.timezone_info);
        Ok(Record {
            column_names: &self.get_col_names(),
            records: val_wrap,
            col_name_index_map: &self.col_name_index_map,
            timezone_info: &self.timezone_info,
        })
    }

    pub fn scan<D>(&self) -> Result<Vec<D>, DataSetError>
    where
        D: DeserializeOwned,
    {
        let mut data_set = vec![];
        if self.is_empty() {
            return Ok(data_set);
        }
        let names = self.get_col_names();
        let rows = self.get_rows();
        for row in rows.iter() {
            let mut data_deserializer = DataDeserializer::new(names, &row.values);
            let data = D::deserialize(&mut data_deserializer)
                .map_err(DataSetError::DataDeserializeError)?;
            data_set.push(data);
        }
        Ok(data_set)
    }
}
```
而此前 nebula-rust 接收定义好的结构体并解析的功能 rust-nebula 也完好地继承了下来，就在上方的 `scan` 函数中得到了实现。值得一提的是，rust-nebula 大量借鉴了 nebula-go 现有的设计以使得用户可以对比理解，而大家都知道的是 go 的泛型一塌糊涂。因此 rust 里几行代码就实现好的`scan`，在 nebula-go 里写了相当多的对泛型的处理才能实现，不仅难写而且不好懂（）。这算是 rust 给我带来的小小的惊喜:)

尽管 rust-nebula 还在其他地方做了相当多的工作，但是受限于篇幅就不一一列举了，而且还有更多的待建设区域留待笔者以及未来的同学们完善（笔者也希望未来的同学看到笔者现在这份代码时不至于嫌弃笔者太菜）。

### 为 OpenDAL 添加 NebulaGraph 支持
实现了对 DataSet 的动态解析功能后，为 OpenDAL 添加 NebulaGraph 支持就显得水到渠成了。核心要点就在于将 NebulaGraph 映射成一个 KV DB，图数据库映射 KV DB 是语义的缩小，自然完全可行。这里选择了在 NebulaGraph 指定 space 的指定 tag 上存取数据：
```rust
impl kv::Adapter for Adapter {
    ...
 
    async fn get(&self, path: &str) -> Result<Option<Buffer>> {
        let path = path.replace("'", "\\'").replace('"', "\\\"");
        let query = format!(
            "LOOKUP ON {} WHERE {}.{} == '{}' YIELD properties(vertex).{} AS {};",
            self.tag, self.tag, self.key_field, path, self.value_field, self.value_field
        );
        let mut sess = self.get_session().await?;
        let result = sess
            .query(&query)
            .await
            .map_err(parse_nebulagraph_session_error)?;
        if result.is_empty() {
            Ok(None)
        } else {
            let row = result
                .get_row_values_by_index(0)
                .map_err(parse_nebulagraph_dataset_error)?;
            let value = row
                .get_value_by_col_name(&self.value_field)
                .map_err(parse_nebulagraph_dataset_error)?;
            let base64_str = value.as_string().map_err(parse_nebulagraph_dataset_error)?;
            let value_str = BASE64.decode(base64_str).map_err(|err| {
                Error::new(ErrorKind::Unexpected, "unhandled error from nebulagraph")
                    .set_source(err)
            })?;
            let buf = Buffer::from(value_str);
            Ok(Some(buf))
        }
    }

    async fn set(&self, path: &str, value: Buffer) -> Result<()> {
        #[cfg(feature = "tests")]
        let path_copy = path;

        self.delete(path).await?;
        let path = path.replace("'", "\\'").replace('"', "\\\"");
        let file = value.to_vec();
        let file = BASE64.encode(&file);
        let snowflake_id: u64 = GENERATOR.generate();
        let query = format!(
            "INSERT VERTEX {} VALUES {}:('{}', '{}');",
            self.tag, snowflake_id, path, file
        );
        let mut sess = self.get_session().await?;
        sess.execute(&query)
            .await
            .map_err(parse_nebulagraph_session_error)?;

        // To pass tests, we should confirm NebulaGraph has inserted data successfully
        #[cfg(feature = "tests")]
        loop {
            let v = self.get(path_copy).await.unwrap();
            if v.is_none() {
                std::thread::sleep(Duration::from_millis(1000));
            } else {
                break;
            }
        }
        Ok(())
    }

    async fn delete(&self, path: &str) -> Result<()> {
        let path = path.replace("'", "\\'").replace('"', "\\\"");
        let query = format!(
            "LOOKUP ON {} WHERE {}.{} == '{}' YIELD id(vertex) AS id | DELETE VERTEX $-.id;",
            self.tag, self.tag, self.key_field, path
        );
        let mut sess = self.get_session().await?;
        sess.execute(&query)
            .await
            .map_err(parse_nebulagraph_session_error)?;
        Ok(())
    }

    async fn scan(&self, path: &str) -> Result<Vec<String>> {
        let path = path.replace("'", "\\'").replace('"', "\\\"");
        let query = format!(
            "LOOKUP ON {} WHERE {}.{} STARTS WITH '{}' YIELD properties(vertex).{} AS {};",
            self.tag, self.tag, self.key_field, path, self.key_field, self.key_field
        );

        let mut sess = self.get_session().await?;
        let result = sess
            .query(&query)
            .await
            .map_err(parse_nebulagraph_session_error)?;
        let mut res_vec = vec![];
        for row_i in 0..result.get_row_size() {
            let row = result
                .get_row_values_by_index(row_i)
                .map_err(parse_nebulagraph_dataset_error)?;
            let value = row
                .get_value_by_col_name(&self.key_field)
                .map_err(parse_nebulagraph_dataset_error)?;
            let sub_path = value.as_string().map_err(parse_nebulagraph_dataset_error)?;

            res_vec.push(sub_path);
        }
        Ok(res_vec)
    }
}
```
由于 NebulaGraph 目前还不支持插入 `Blob` 数据类型，因此这里不得不使用`字符串`类型+`Base64 编码` 做权宜之计。当然，负责人也表示 `Blob` 数据类型会在 NebulaGraph 之后的版本进行支持，到时候只需在 rust-nebula 里支持好这个数据类型，然后直接移除上方的 Base64 部分即可正常使用 OpenDAL 了。

这里也有一个小插曲，笔者在两个月前就 fork 了 OpenDAL 的主仓库并在上面测试好了 NebulaGraph 的相关功能，结果同步主分支后，合并的时候一堆配置代码结构直接大改，甚至测试逻辑也改了，在此不得不感慨 OpenDAL 的更新速度之快。笔者也不得不直接放弃 merge，选择在同步完成后的主分支上进行功能添加。

这一情况在 GSoC 上亦有体现，笔者需要吸取教训，以后要对某个自己很早之前就 fork 的项目提 PR 时，一定要先同步一下再改:(