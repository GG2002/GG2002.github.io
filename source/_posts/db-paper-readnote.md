---
title: Reading Notes for Papers in Databases
date: 2023-12-17 19:04:47
tags: database
---

近些年兴起的 NewSQL，Google 在 2012 年发表的 Spanner[8]和 2013 年发表的 F1[9]两篇论文，提出将关系模型和 NoSQL
的扩展性相结合，使之既支持关系模型，又具备高可扩展性。Spanner 和 F1 的出现标志着 NewSQL 的兴起，PingCAP 的 TiDB[10]、CockroachLabs 的 CockroachDB[11]和已经闭源的 OceanBase 都是 NewSQL 的典型产品。TiDB 和 CockroachDB 底层都是基于 RocksDB[12]实现，而 RocksDB 又是在 LevelDB[13]基础上发展的单机 KV 存储引擎。

KV 数据库种类繁多，以 DBEngine 上面列出的为例，就包含 60 多种，虽然种类繁多，但按照其底层的存储模型基本分为四大类，LSM-Tree[14]模型、B/B+Tree 模型、哈希模型和一致性哈希模型。

以 LSM-Tree 为存储模型的 KV 数据库主要有 LevelDB[14]、RocksDB[12]、Badger[15]，以 Btree 为存储模型主要有 LMDB[16]、BoltDB[17]和 kyoto Cabinet[18]，以哈希为存储模型主要有 Redis[19]和 Memcached[20]，以一致性哈希作为存储模型主要有 Dynamo[3]，Cassandra[6]底层存储模型虽然也基于一致性哈希，但其数据模型却参照 BigTable[3]，一般被认为属于列族数据库。
