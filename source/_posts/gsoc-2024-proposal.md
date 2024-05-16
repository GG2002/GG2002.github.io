---
title: GSOC2024 Proposal
date: 2024-03-02 00:24:31
tags: GSOC2024
katex: true
---
# Improve Transaction Validation

## Project Info
- Repo: [xline-kv/Xline](https://github.com/xline-kv/Xline)
- Idea: Improve Transaction Validation

## Applicant Info
- Name: Yuchen Chen
- Github: [feathercyc](https://github.com/GG2002)
- Email: feathercyc@163.com
- Tel: +86 15616326211
- Related PR: 
    - [refactor: improve append entries](https://github.com/xline-kv/Xline/pull/663)
- Education: 
    - 2023-Present: Huazhong University of Science and Technology, Computer Science(master)

I really like Rust and Golang, especially Rust has a certain geek flavor. I have just done PingCAP's [tinykv project](https://github.com/talent-plan/tinykv) and am familiar with Raft and Etcd. I want to enter the field of distributed db for work after graduation and now I'm trying to solve some issues in [Xline](https://github.com/xline-kv/Xline).

There are several questions on this project homepage, my answers are as follows:
- What do you find most attractive about our program and the reason you choose us?
    - A distributed database written in Rust, particularly in its early stages, is extremely appealing to me. I have a strong desire to continue contributing even after the conclusion of GSOC. Additionally, I am also interested in participating in OSPP this year.
- How does your current skills match with the requirements of our program?
    - I believe I am well-equipped for the task at hand. I am proficient in Golang and modern C++, and I have no difficulty comprehending Rust code. While it may require some time for me to learn how to write Rust code in accordance with the Rust programming philosophy, the learning curve should not be excessively long.
- What do you expect to gain from this program and how can we get the best out of you?
    - Although I am new to Rust, I have extensive experience in writing Golang code within the domain of distributed databases. Nonetheless, I am eager to expand my knowledge of Rust's code styles and engineering practices. Furthermore, I am enthusiastic about acquiring a deeper understanding of distributed systems.
    - If community could provide appropriate guidance while reading the source code and polish my code style, that would be helpful.
- Have you ever participated in GSoC (or a similar program) before?
    - No. This is my first time to participate in this program.

## Proposal

### Motivation
In Xline project, it exists the concept of Transaction(hereinafter abbreviated as txn). To keep the atomicity of txn, it need to detect whether all keys within a TxnRequest have overlapping parts.

Now, there's several problems with the Txn Validation function that need to be solved. Ref to [[Bug]: check_intervals will not validate correctly in certain nested txn scenarios](https://github.com/xline-kv/Xline/issues/410) and [[Perf] Improve Performance of check_intervals](https://github.com/xline-kv/Xline/issues/409). These issue could be summarized as: 
- the order of sub-Txns will affect the result of the entire Txn
- it's time to improve Txn Validation's poor peformance

Among these two issues, the more important thing is to ensure the correctness of check_intervals fn. But ensuring the correctness will lead to an increase in time complexity in my proposal, a interval tree is also neccessary.

### Design
Describing the rules for detecting overlapping keys in language seem too cumbersome. So I drew a pricture to explain it：
![Overlapping rules](https://gg2002.github.io/img/gsoc-2024-proposal/Overlapping-rules.png)
Given the `put` op of `STxn-0` (Notice,the `put` mentioned here doesn't contain `STxn-0`'s sub-Txns, e.g., `GsTxn-*`'s `put`), it should not intersect with these `del` and `put` marked in red, meanwhile, it could intersect with these `del` and `put` marked in blue in this diagram (it means that these green area should be excluded in the search tree). This is because the semantics of `Then` and `Else` dictate that only one of them will be executed, so even if they overlap, it doesn't matter. 

#### Plan A
Firstly, consider the intersection problem between `put` and `del`:

The best way is to build a interval tree containing the entire set of `del`, and then traverse `put` to detect intersection. But as mentioned above, some `del` should be exclued, a interval tree that only contains range is not enough to achieve it, more information needs to be contained.

Actually, the above picture is a little complicated, and the relation between `del` and `put` could be simplified as follows:
![Overlapping Rules Simplified](https://gg2002.github.io/img/gsoc-2024-proposal/Overlapping-rules-simple.png)

Given the `put` in `Then` branch of `STxn-0`, it still cannot intersect with these red area, but can intersect with these blue area.

Here I need to explain why it could be simplified:
- Only `del` are considered now, so other `put` can be hidden, and `*Txn List` can be omitted
- There exist `del` belong to `Then` and `Else`, so they have colors
- For Txn node like `GsTxn-*`, since both their `Then` and `Else` branches either can intersect or cannot intersect with `put`, they can be directly painted red/blue
- The purple node is painted just for visual harmony, as $red+blue=purple$. They alse represent that their `Then` and `Else` should be handled separately

Obviously, it's a multi-branch tree. Let's consider encoding it. For example, the node can be numbered in the order of their appearace in `*Txn List` of their parent node, starting from `0,1,2` and so on. Then, the `Then`/`Else` branch can be represented as 0/1. For instance, the encoding for the `put` in `Then` branch of `STxn-0` should be `00 00`, and the encoding for a `del` belonging to `FatherTxn-Then-(STxn-0)-Else-(GsTxn-1)-Then` should be `00 01 10`.

The excluded node list of each Txn is different. Follows are some examples:
- For `put` with the encoding `00 00`, the set of encodings to be excluded would be [`01 *`, `00 01 *`], where * represents any encoding
- For `put` with the encoding `01 20 11`, the set of encodings to be excluded would be [`00 *`, `01 21 *`, `01 20 10 *`]

So a rule could be summarized: find the LCA(Lowest Common Ancestor) node between `put` and `del`, if the node is `*Txn*`, these `del` should be exclued; if the node is `Then` or `Else`, return `DuplicatedKeyError`.

Futhermore, consider $depth$ of this multi-branch tree. Let `FatherTxn` be `root`, $depth=0$. It's easy to know: if LCA node's $depth\%2==0$, these `del` should be exclued; else, return `DuplicatedKeyError`.

Now the steps of detecting intersection between `put` and `del` can be determined as follows:
1. Build a interval tree map. This data structure has two properties:
    - it should be allowed to insert (Range, Value) tuple, Value can be either a path encoding or a reference to a node in the multi-branch tree.
    - After the interval tree inserts two tuples (RangeA, Value1) and (RangeA, Value2), the query should return two values [Value1, Value2]. It's because there may be identical intervals between two sub-Txns.
2. Traverse `put` belong to each branch of each sub Txn recursively. For each `put`, query the `del` interval tree, and detect intersection based on the LCA or path encoding mentioned above.

Finally, consider the intersection problem between `put`:

Compare to overlapping detection between `del` and `put`, it's more easy to solve this problem. For `put`, building overlapping detection with HashSet would be faster because they are just collections of points. And there's no need to consider their order, so the detection can be done together with the 2nd step of detecting intersection between `del` and `put` completely.

#### Plan B
If the goal is to reduce spatial complexity, there should be some methods. For example, during the collection of `del`, consider detecting intersection at the same time, my brief idea is as follows:

1. When recursively traversing to the bottom level of `* Txn *`. It should be ensured that its `Then` and `Else` branches can pass overlap detection, and then combine the `del` and `put` of these two branches into one `del` and `put`
2. Then compare the `del` and `put` of other `* Txn *` at the same level as this `* Txn *` being processed. Note that these `* Txn *` are also in the `Then` or `Else` branch of their parent transaction. After the comparison, these `* Txn *`'s `del` and `put` should also be combined into one `del` and `put` and jump back to 1

The details are not further elaborated here. By handling the `Then` and `Else` branches separately, there is no longer a need to record the parent-child sibling relationship of these Txns.

In fact, this PR [etcdserver: fix checkIntervals will not validate correctly](https://github.com/etcd-io/etcd/pull/16395) uses above method.

#### Comparison between Plan A and B
I have to say, to correct the behavior of check_intervals, an increase in either time complexity or spatial complexity cannot be avoided.
- Plan A brings an increase in spatial complexity, approximately $8*Num_{del}$ more Bytes，$Num_{del}$ is the total numbers of all intervals in `del`, and $8$ is the size of a reference. And Building another multi-branch tree that includes a child node pointing to the parent node and records the $depth$ information would be faster.
- Plan B doesn't aim to record these relationships, and as a result, it increases the time complexity. For each `*Txn*`, it should build a interval tree for its own `del`, and then merge the interval trees created by its child Txns. Moreover, when comparing its own `put` with other Txn's `del` at the same level, it essentially involves searching on $n$ small interval trees, which lead to higher time complexity compared to searching on a single large interval tree containing all `del` ops.

I personally lean towards using the plan A. As Xline is a metadata db, it should not have very complex transaction structures. The spatial complexity is determined by the total number of `del` and Txns(containing all sub-Txns), and the total number of `del` can be reduced by interval merging. Thus, its spatial complexity is within a manageable range. 

Consider the extreme case of plan A (which is also the extreme case of interval tree), where traversing `put` querys a large number of `del` range, regardless of whether there is a overlap, it should iterate these ranges one by one. Even though interval tree queries have a $O(logN)$ time complexity, in this case, the overall time complexity would tend to be infinite as it approaches $O(N)$.

Plan B, on the other hand, does not encounter this issue. By handling `Then` and `Else` branches seperately, in this scenario, finding any overlapping range would indicate occurance of overlapping.

However, Xline is still a metadata db and these cases rarely occur. And if such extreme cases do arise, I believe it should be considered as a problem with the transaction creator rather than something Xline should handle efficiently.

### Related Issues
- [[Bug]: check_intervals will not validate correctly in certain nested txn scenarios](https://github.com/xline-kv/Xline/issues/410)
- [[Perf] Improve Performance of check_intervals](https://github.com/xline-kv/Xline/issues/409)

## Schedule
If I am accepted to GSoC in this project, I should start work at this from May.1st.
May 1st - August 26th:
| Week  | Dates | Work |
| ----- | ------------------- | -------------------------- |
|  1-3  | May 1st  - May 26th | Implement interval tree map|
|  4-7  | May 27th - Jun 23rd | Refactor check_intervals fn|
|  8-9  | Jun 24th - Jul 7th  | Write unit tests|
| 10-19 | Jul 8th  - Aug 26th | Final Wrap-ups|