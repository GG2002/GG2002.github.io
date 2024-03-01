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
In Xline project, it exists the concept of Transaction(hereinafter abbreviated as txn). To keep the atomicity of txn, we need to detect whether all keys within a TxnRequest have overlapping parts.

More specifically, the rules for determining whether keys overlap could be described as follows:
