---
title: OSPP2024 Proposal OpenDAL对接NebulaGraph
date: 2024-05-10 22:11:51
tags: OSPP2024
---

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

> 数据分片 Partition 或者有些系统叫 Shard，它的 ID 是怎么得到？非常简单，根据点的 ID 做 Hash，然后取模 partition 数量，就得到了 PartitionID。
> 
> Vertex 的 Key 是由 PartID + VID + TagID 三元组构成的，Value 里面存放的是属性（Property），这些属性是一系列 KV 对的序列化。
> 
> https://www.nebula-graph.com.cn/posts/nebula-graph-design-in-practice


> Nebula 架构剖析系列（一）图数据库的存储设计
> 
> https://www.nebula-graph.com.cn/posts/nebula-graph-storage-engine-overview