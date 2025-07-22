---
title: 数据库适配迁移方案设计
date: 2025-07-16 15:03:37
tags:
---

## Gorm
gorm 身为 orm 框架，本身提供相当多的数据库操作函数，并会在底层自动将它们转成符合相应数据库 SQL 格式的 SQL。

gorm 重写（或者说转译）SQL 的类称为 Dialector。在具体执行方面可以复用 mysql 和 postgresql 的 Dialector，但是 mysql 语法转成 postgresql 语法这部分工作需要自行完成。

### clause.OnConflict
mysql 与 pg 的 UPSERT 操作语法不一致：
```sql
-- MySQL
INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); 
-- PostgreSQL
INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age";
```

其中 pg 需要给出具体的 unique key 组合，而 mysql 会自动判断使用什么 key。这部分兼容需要从两方面考虑：
- 一方面需要确保修改后要同时能在 mysql 和 pg 上运行，只是让开发人员改成 pg 语法无济于事；
- 另一方面老项目肯定全都是 mysql 语法，天然缺失 unique key 的信息，因此 unique key 的信息需要补全。

再从用法分析，gorm 要实现 UPSERT 操作有两种方式：
1. `clause.OnConflict`，这个结构体本来就接受 unique key 参数，orm 也会在连接 mysql 的时候自动忽略掉这部分参数。因此这个操作没什么太多要改的，只是因为这个参数不重要，所以老项目的这个参数要么没有要么漏填几个列，交给开发人员自行查漏补缺。
2. 裸 SQL 执行，这个是比较麻烦的，因为老项目中很多大段大段的手动拼接 sql 的用法，把某个 sql 字符串改成 pg 语法指不定在哪个地方就报错了，而且即使这样在底层也要手动将 pg 转成 mysql。最后选用在 sql 字符串里增加注释：
    ```SQL
    [MIDDLE-KEY{}MIDDLE-KEY]
        MIDDLE-KEY：注入类型 KEY
        {}：注入具体内容

    -- 例如：[MIDDLE-KEY{UNIQUE: ["user_id", "is_deleted"]}MIDDLE-KEY]
    ```
   注释插在哪都 OK，反正都是直接正则匹配。当然，注释也只能让开发人员自己加。

### QuoteTo
- mysql 使用 \` 号表示表名、列名等等，`"` 和 `'` 表示字符串；
- pg 使用 `"` 号表示表名、列名，`'` 号表示字符串。

Dialector 通过 QuoteTo 函数来给 sql 加引号，仍然要处理两种用法：
1. gorm 函数，所有的 gorm 函数当然会走 QuoteTo 函数，因此这种方式生成的 sql 都会有正确的 sql 引号格式；
2. 裸 SQL 执行，还是老项目，开发人员手写的 sql 不加引号自然是家常便饭，裸 SQL 也不走 QuoteTo 函数，只能在更底层的 driver 层处理。

因此可以在 Dialector 层将能转的表名、列名都转成 mysql 语法一致，然后再在 driver 层统一处理。

### 自动加/解密 plugin
既然已经有 gorm 中间层了，不妨再给中间层加点好用的功能，减少开发人员一点工作量。

## database/sql/driver
### parser 重写
上面的 Gorm 函数转 sql 都是低垂的果实，适配了就能搞定大部分场景了，但是老项目的裸 SQL 保底还得是直接上 parser 做语法分析然后挨个重写。

这部分主要有：
1. SQL 函数名转换（DATE_ADD 函数转 INTERVAL 函数等等）
2. 语法结构的细微差异
3. 引号

繁琐细微的工作，只能靠大量的测试 SQL 语句来检查效果，麻烦但又必要（换言之，纯 dirty work）。

### 旁路执行
转换好的 sql 当然不能放心地直接丢到生产环境上跑，而且一些不兼容处也没办法通过全局搜索发现，只能看实际跑起来的报错来定位。

所以要在开发环境上同时执行原来的 mysql sql 和转换好的 pg sql，这个工作也交给了 driver 层。mysql sql 当然立刻执行，pg sql 就不着急了（转换也要时间的嘛），写个队列开几个协程慢慢消费就好，报错了就上报日志。

## 性能调优
### sync.Pool
sql 转换会有大量的字符串拼接操作，常规手段就是自己维护一小块字符串对象池，减少 GC 压力。

### Query Cache
虽然 Query Cache 已经被 mysql8 抛弃了，但在这里并不是存 sql 转 statement 的缓存，而是存 mysql sql 转 pg sql 的缓存。

不过也同样的，优化效果聊胜于无，反正 CPU 消耗少了 2-3 个点（很难想象 gorm 能成为性能瓶颈的场景，这 2-3 个点省不省都不影响加机器罢）。