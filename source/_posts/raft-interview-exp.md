---
title: raft 面经（？
date: 2023-12-04 22:56:34
tags: raft 协议
katex: true
---
按理说，做完了 6.824 理应对 Raft 了如指掌，可那是 11 个月前了，如今的笔者只能依稀记起来 lab 中印象较深的几个坑（其实也记不太清了。

所以可证明，做完 lab $\not=$ 面经全会。

为了让面试官不阴阳怪气\委婉\盛气凌人地跟笔者说——同学，你的项目是有借鉴 Github 吗？——记录一下笔者从各大网站搜罗而来的 Raft 协议面经。

## CAP 是什么？Raft 实现了 CAP 中的哪两个
CAP（Consistency, Availability, Partition tolerance）。CA 只有单机实现，毕竟分布式系统必须有 Partition tolerance。
![一致性细分类](/img/raft/consistency.jpg)

- 弱一致性——最终一致性（无法实时获取最新更新的数据，但是一段时间过后，数据是一致的）
  - Gossip(Cassandra，Redis 的通信协议)
  - 优先保证 AP 的 CouchDB，Cassandra，DynamoDB，Riak（一个都不了解）
- 强一致性
  -  Paxos
  -  Raft
  -  ZAB

据 PingCAP 所分享：
> 一些常见的误解：使用了 Raft 或者 paxos 的系统都是线性一致的（Linearizability，即强一致），其实不然，共识算法只能提供基础，要实现线性一致还需要在算法之上做出更多的努力。以 TiKV 为例，它的共识算法是 Raft，在 Raft 的保证下，TiKV 提供了满足线性一致性的服务。

所以，怪怪的问题。

## Raft 和其他共识协议相比的优缺点
不会

## Raft 过程

## 什么时候做日志压缩
这是 LSM-Tree 的内容，不会。

## 为什么 Raft 的 RPC 需要带上任期号，举例不带任期号导致的错误场景

## 如果 Raft 给一部分节点发送数据操作的过程中突然宕机了怎么办？
超时重选

## Raft 优化
prevote 阶段

no-op 解决 figure 8

## Raft 集群发生网络分区会怎么样

## Raft 成员变更
> https://zhuanlan.zhihu.com/p/359206808

- 要么一次性严格限制只变更一个节点。
- 如果实在想一次变更多个节点，那就不能直接变更，需要经过一个中间状态的过渡之后才能完成同时变更多个节点的操作。第一次从 C_Old 变成{C_Old,C_New}节点集合，第二次从{C_Old,C_New}变成 C_New。


## Raft 具体实现（比如 etcd）有哪些值得借鉴的

## 如果有多个节点竞选 Leader 怎么办？

## Raft leader 选举过程

## 分布式系统中如果有多个分区，每个分区都有一个 Leader，现在将分区合并有多个 Leader 如何处理？

## 怎么区分 Leader 分别属于第几轮选举的？（Leader 选取的轮次计数）

## Raft 算法中如果 Leader 宕机后怎么办？

## 如果 Raft 集群超过半数节点挂了会怎么样

## 上层业务如何使用 Raft？（面试官想的是和 etcd 那样单独作为一个存储服务

## Raft 如何高可用

## KV 存储如何容错

## multi-Raft 实现

## multi-Raft 怎么分片，分片怎么迁移

## multi-Raft 原理（用哈希分片好吗？）

## TiDB 的架构

## 项目的性能怎么样？最难的是什么？

## Percolator 原理

## 一致性 Hash 算法是什么？
环形 hash，负载均衡。

## 一致性 Hash 的缺点是什么？
数据不平衡——虚拟节点解决
