---
title: OSPP2024 Proposal OpenDAL 对接 NebulaGraph
date: 2024-05-10 22:11:51
tags: OSPP2024
---
# 图数据库 NebulaGraph 对接数据访问层 OpenDAL

## 项目介绍
- Repo: [apache/opendal](https://github.com/apache/opendal)
- 相关 issue: [Add support for NebulaGraph](https://github.com/apache/opendal/issues/4553)

## 申请人介绍
- Github: [feathercyc](https://github.com/GG2002)
- 邮箱：feathercyc@163.com
- 教育经历：
    - 2023-Present: Huazhong University of Science and Technology, Computer Science(master)
- Rust 相关经历：
  - [重构 Xline append entries](https://github.com/xline-kv/Xline/pull/663)
  - [Rust 重写 net-tools 的 arp 命令](https://gitee.com/chenyuchen2024/easybox)

我对 Rust 非常非常感兴趣（我一定是 RP 吧），同时我也对数据库领域相关技术很有兴趣。

## 提案
### 相关项目简介
#### Nebula Graph 
![Nebula Graph 架构图](../img/ospp-2024-proposal/nebula-graph-architecture.png)
上图是官方的架构图，细节略去不谈，易知 Nebula Graph 由三部分——graphd, metad, storaged 组成。其中 graphd 算是查询引擎，metad 存有服务地址和 Schema 等各类元信息，而 storaged 存储具体的数据。

使用 [nebula-rust](https://github.com/vesoft-inc/nebula-rust/tree/master)  Client 连接 Nebula Graph 有两种方式可选：
- 使用 nGQL 操作 Nebula Graph。这是最简单的方法，这种方式先请求 graphd 解析 nGQL，然后由 graphd 去请求 metad 和 storaged 获取数据，再返回给用户
- 直连 storaged。考虑到一些简单的、大批量的操作并没有必要经过 graphd 这个中转站再传给 storaged 去做，用户也可以直连 storaged 获取 vertex 与 edge

这两种方法各有优劣：
- 使用 nGQL 操作固然方便，但要是 graphd 和 metad、storaged 不在一个服务器上，再简单的操作也要多出一段时延。
- 直连 storaged 固然能减少时延，但对于 Nebula Graph 用户而言，metad 与 storaged 很多时候都是不对外暴露服务的，参考 [Should I use graphd-client or storaged-client?](https://github.com/vesoft-inc/nebula-rust/issues/20)，而且 nGQL 能实现的各种基于图的算法肯定是用不了了

#### OpenDAL
要给 OpenDAL 新增 Service，最低要求是为新增的 Service 实现位于 `core/src/raw` 下的 `Access trait` 和 `Builder trait` 。

而要新增 DB Service 则简单不少，因为 OpenDAL 定义了 `Adapter trait`，实现这个 `trait` 就可以让 OpenDAL 使用任何 KV 工作。因此，只要将各类 DB 的操作映射为 KV DB 的操作——`set`, `get`, `delete`, `scan`，OpenDAL 就可以使用这个 DB 了。

### 方案设计
要将图数据库映射为 KV DB 还是比较简单的，只需按下列命令操作就够了：

```nGQL
// create test space, its vid type should be str
CREATE SPACE test_kv(PARTITION_NUM = 20, VID_TYPE = FIXED_STRING(21));

// create kv tag
CREATE TAG kv(value string);

// insert key-value pair
INSERT VERTEX kv VALUES "test":("23");

// get value by key
FETCH PROP ON kv "test" YIELD kv.value as value;
+-------+
| value |
+-------+
| "23"  |
+-------+

// delete key-value pair
DELETE VERTEX "test";
```
同时参考 Nebula Graph 源码解读系列文章，可以知道 vertex 和 tag 属性在底层都是存在 RocksDB 中：
> 数据分片 Partition 或者有些系统叫 Shard，它的 ID 是怎么得到？非常简单，根据点的 ID 做 Hash，然后取模 partition 数量，就得到了 PartitionID。
> 
> Vertex 的 Key 是由 PartID + VID + TagID 三元组构成的，Value 里面存放的是属性（Property），这些属性是一系列 KV 对的序列化。
> 
> https://www.nebula-graph.com.cn/posts/nebula-graph-design-in-practice
> 
虽然 Nebula Graph 会将 vertex 和 tag 存在两个地方，而不是像真正的 KV DB 一样存真正的 key-value 对，而且在存入之前还要经过 Raft 共识算法达成共识，性能相对于 RocksDB 一定有很多损失，但这是无法避免的事。

值得注意的是，由于使用了 vertex 的 VID 作为 key，nGQL 并没有提供 **搜索 以 xxxx 为前缀 的 VID 的 vertex** 的功能，这也意味着只模拟 KV DB 的话，Nebula Graph 实现不了 `list` 操作。

#### 实现 `list` 操作

OpenDAL 将 DB 作为 Backend 这一行为其本质上是使用这个 DB 在模拟一个文件系统树。众所周知树结构是图的子集，对于 Nebula Graph，其可以直接把文件树结构存进去而不需要任何额外的抽象。

因此只需在上述 nGQL 操作中加入文件与文件目录的 edge 即可：
```nGQL
// create test space, its vid type should be str
CREATE SPACE test_kv(PARTITION_NUM = 20, VID_TYPE = FIXED_STRING(21));

// create file and dir TAG
CREATE TAG file(value string);
CREATE TAG dir(); 

// create edge
CREATE EDGE IF NOT EXISTS fstree();

// create / dir
INSERT VERTEX dir VALUES "/":();

// create dir
INSERT VERTEX dir VALUES "/test/":();
INSERT EDGE fstree () VALUES "/"->"/test/":();

// write file
FETCH PROP ON * "/test/";                                   // Fetch whether "/" exists
INSERT VERTEX file VALUES "/test/init":("23");              // write file
INSERT EDGE fstree () VALUES "/test/"->"/test/init":();     // insert edge between "/test/" and "/test/init"

// copy

// rename, delete and insert

// list file, 那些在比 10 层更深目录里的文件和文件夹就不会展示了
GO 1 TO 10 STEPS FROM "/test/" OVER fstree YIELD dst(edge);

// delete file
DELETE VERTEX "/test/init" WITH EDGE;

// delete dir, 同样的，那些在比 10 层更深目录里的文件和文件夹就删不掉了
GO 1 TO 10 STEPS FROM "/test/" OVER fstree YIELD dst(edge) AS id | DELETE VERTEX $-.id;
```

同时，由于 Nebula Graph 只能设置 VID 为固定长度字符串，要满足文件系统的需求则需要将这个固定长度设置为一个很大的数字，这将大幅度降低 Nebula Graph 的性能。

或者将文件绝对路径设置为 tag 里的 String，VID 就随意设置了，每次查询都靠匹配 tag，但这样写入性能不会慢多少，查询性能应该会大大下降，考虑到即使是 `write` 操作也需要先查一下父目录在不在，这对整体性能的影响应该还挺大的。

由于上述操作过于简单，因此在 storaged 可访问且被 Client 知晓的情况下，完全可以通过 Client 直连 storaged 获取相应 key-value 对，这样可以省去 graphd 解析 nGQL 相关的开销提升性能。