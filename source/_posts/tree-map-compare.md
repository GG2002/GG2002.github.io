---
title: The Difference Between B-Tree, B+Tree, Red-Black Tree, LSM Tree and SkipList
date: 2025-04-28 16:23:50
tags:
    - B-Tree
    - B+Tree
    - Red-Black Tree
    - LSM Tree
    - SkipList
---

人们总会争论 B-Tree 族、红黑树与跳表的互换性，已知 Java 与 C++ 的 Map 都使用了红黑树作为底层结构，围绕此问题，人们总会在一个缓存结构出现后问道：`那为什么不使用跳表/B树呢？`
- [rust 的 TreeMap 为什么采用 B-tree 而不是红黑树？](https://www.zhihu.com/question/516912481)
- [为啥 redis 使用跳表 (skiplist) 而不是使用 red-black？](https://www.zhihu.com/question/20202931)

抛开明明最有可能的个人作者喜好不谈（参与过开源的人都知道，项目最开始的走向极大概率取决于维护者个人喜好与品味，而后续的更改却需要拿出一个完善的 PR 与相当多的证据证明优越性才可能被维护者合入，简言之维护者乐意怎么写就怎么写，用哪个都有理，毕竟哪个都没有绝对优势），笔者在此总结一下这些 Tree 的特点。

| 名字               | 缓存友好性                                                              | 调参友好性                                                       | 并发友好性                                                           | 实现 scan 操作友好性                           | insert/delete 实现难度     |
| ------------------ | ----------------------------------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- | -------------------------- |
| **AVL Tree**       | 不太友好，每个节点都 new 一遍太伤了                                     | 无参可调                                                         | 不甚友好，旋转操作发生很频繁，要锁的节点太多                         | 中序遍历，没 B+Tree 和 SkipList 友好           | easy，谁都写过吧           |
| **Red-Black Tree** | 与 AVL Tree 无异                                                        | 无参可调                                                         | AVL Tree 的优化版，旋转操作少了，但总之还是要锁                      | 与 AVL Tree 无异                               | hard，超级难写，写完就玩   |
| **SkipList**       | 只能说不输于 AVL 和 R-B Tree，每个节点 new 一遍就不可能好于 B-Tree 族罢 | 节点在每层的留存概率是可调的，决定了整个 SkipList 的内存占用大小 | 独立的分层结构导致锁粒度比 AVL 和 R-B Tree 小，并发性能肯定是要好的  | 好用无需多言                                   | easy                       |
| **B-Tree**         | 缓存友好性拉满了，一个节点存一堆数据                                    | 节点存数据的数量是可调的，决定了修改时的分裂次数与树的深度       | 节点分裂/合并的时候还是要上锁的，但次数少，总比 AVL 和 R-B Tree 好点 | 中序遍历，多叉树中序遍历甚至比 R-B Tree 还复杂 | hard，跟 R-B Tree 半斤八两 |
| **B+Tree**         | 与 B-Tree 无异                                                          | 与 B-Tree 无异                                                   | 与 B-Tree 无异                                                       | 好用无需多言                                   | 与 B-Tree 无异             |

> 调参友好性：对于个人开发者而言作用不甚明显，但是对于工业场景，争对不同场景的可调参的数据结构还是各种意义上的很重要的

以上为不严谨总结，大致上只能分出几种数据结构明显优于/差于其他数据结构的方面，至于同级别的（比如同样缓存友好的 B-Tree 跟 B+Tree 则需要更进一步细化比较）。

那么标题里的 LSM Tree 呢？实际上 LSM Tree 应该看作一种数据存储组织形式，也就是与使用了 B+Tree 的聚集索引是一个 Level 的东西，这必然要牵扯到大到不可能全放在内存里的数据量，因此编程语言的 map 与 redis 这种纯内存使用场景是不可能使用 LSM Tree 和 B+Tree 的。

下面是一些对比的详细细节：

### B-tree、B+tree 对比红黑树
核心在于缓存友好，申请内存操作是耗时的，我们希望次数尽可能少，还希望想找的几条数据最好挨在一起，因此更大节点的 B-tree 会比红黑树更好。
- **缓存利用率**：由于 B+ 树节点较宽，单次磁盘读取可以加载较多的关键字到内存中，这样在进行查找时，每次磁盘 I/O 可以获得更高的关键字命中率，进而提高整体性能。
- **磁盘 I/O 效率**：B 树和 B+ 树设计时考虑到了减少磁盘 I/O 操作的需求，因为它们允许每个节点拥有多个子节点，从而降低了树的高度。相比之下，红黑树作为二叉树的一种，其高度相对较高，在处理大量数据时会导致更多的磁盘访问。

上述理由同样合适于 [rust 的 TreeMap 为什么采用 B-tree 而不是红黑树？](https://www.zhihu.com/question/516912481)。

范围查询其实是 B+tree 的特性，跟 B-tree 这个系列不太有关。
- **范围查询**：B+ 树中的所有叶子节点都通过指针相连，支持高效的范围查询。而在红黑树中进行范围查询则可能需要多次独立的查找，效率较低。

### B+tree 对比 B-tree
B+tree 主要优化了节点大小，同时有了范围查询，
- **缓存友好性**：B+ 树的内部节点仅用于索引，这使得它们能容纳更多键值对，有助于降低树的高度并减少 I/O 操作次数。同时，这种结构对于现代计算机系统的缓存机制更加友好。
- **范围查询优化**：B+ 树的叶子节点之间通过指针相连，极大地优化了范围查询的效率。而 B 树虽然也能进行范围查询，但效率不如 B+ 树高。

查询效率上不能说好了多少，只能说有些理由是扯出来的（比如查询效率一致性会更好，因为每次都稳定地查到叶子节点，而 B-tree 则会提前返回，这合适吗？）。

这里仍然可以参考 rust 的 TreeMap，为什么用 B-tree 而不是 B+tree 了，因为 B-tree：
1. 优势：省内存，不需要多做一层索引。
2. 劣势：Iter 略慢，next() 最差会出现 log n 的复杂度，B+Tree 可以稳定 O(1)。
3. 劣势：不能区分 index 和数据，也就不能把 index 做的很小，放进更快但是更小的存储中。

首先 Rust 的 BTreeMap 是全放在内存里的，第三条基本上就没啥用，第二条的性能提升微乎其微，但是第一条的省内存可是实实在在的，所以 B+Tree 在这个使用场景下 GG。

### SkipList 对比 Red-Black Tree
> There are a few reasons:
> 
> 1. They are not very memory intensive. It's up to you basically. Changing parameters about the probability of a node to have a given number of levels will make then less memory intensive than btrees.
> 2. A sorted set is often target of many ZRANGE or ZREVRANGE operations, that is, traversing the skip list as a linked list. With this operation the cache locality of skip lists is at least as good as with other kind of balanced trees.
> 3. They are simpler to implement, debug, and so forth. For instance thanks to the skip list simplicity I received a patch (already in Redis master) with augmented skip lists implementing ZRANK in O(log(N)). It required little changes to the code.
>
> [Redis 作者 antirez 回答](https://news.ycombinator.com/item?id=1171423)

再抄一下小林 coding。
- **从内存占用上来比较，跳表比平衡树更灵活一些**。平衡树每个节点包含 2 个指针（分别指向左右子树），而跳表每个节点包含的指针数目平均为 1/(1-p)，具体取决于参数 p 的大小。如果像 Redis 里的实现一样，取 p=1/4，那么平均每个节点包含 1.33 个指针，比平衡树更有优势。
- **在做范围查找的时候，跳表比平衡树操作要简单**。在平衡树上，我们找到指定范围的小值之后，还需要以中序遍历的顺序继续寻找其它不超过大值的节点。如果不对平衡树进行一定的改造，这里的中序遍历并不容易实现。而在跳表上进行范围查找就非常简单，只需要在找到小值之后，对第 1 层链表进行若干步的遍历就可以实现。
- **从算法实现难度上来比较，跳表比平衡树要简单得多**。平衡树的插入和删除操作可能引发子树的调整，逻辑复杂，而跳表的插入和删除只需要修改相邻节点的指针，操作简单又快速。


### B+tree 对比 LSM tree
- **写入性能**：LSM 树（Log-Structured Merge Tree）在写入密集型应用中通常表现更好，因为它将写操作批量处理后合并到较大的排序文件中，减少了随机写入的数量。而 B+ 树在写入时可能会涉及到节点分裂，导致更多的随机 I/O 操作。
- **读取性能**：B+ 树一般提供更稳定的读取性能，尤其是对于点查询而言，而 LSM 树为了达到较高的写入性能，可能需要在读取时检查多个文件或执行合并操作，增加了读取延迟。
- **空间开销**：LSM 树可能会有较高的空间开销，因为它需要维护多层的文件结构以及定期进行压缩以控制空间增长。而 B+ 树的空间利用率相对更高，特别是在更新操作较少的应用场景下。 
