---
title: GSOC2024 Completion Record with Reflections
date: 2024-08-25 00:10:21
tags: GSOC2024
katex: true
---
## What I have done
- [add some doc](https://github.com/xline-kv/interval_map/pull/2)
- [feat: add ci](https://github.com/xline-kv/interval_map/pull/5)
- [[chore] change some fn's and variable's name](https://github.com/xline-kv/interval_map/pull/6)
- [add some iter type](https://github.com/xline-kv/interval_map/pull/7)
- [chore: add example and correct README](https://github.com/xline-kv/interval_map/pull/8)
- [feat: add tests.rs](https://github.com/xline-kv/interval_map/pull/9)
- [feat: add intervalmap tests](https://github.com/xline-kv/interval_map/pull/10)
- [chore: change crate name to prepare for cargo publish](https://github.com/xline-kv/interval_map/pull/11)

I have extracted the interval map impl from Xline, refined this part into a crate, added detailed documentation and testing, and published it as `rb-interval-map` on crates.io.

- [fix: correct request validation](https://github.com/xline-kv/Xline/pull/963)
- [chore: transfer utils's interval map impl into dependency](https://github.com/xline-kv/Xline/pull/960)

Modifications to the Xline project are outlined in the first PR cited above, representing the fundamental tasks of the project I'm applying for. There's little to discuss regarding the specific implementation, as I've provided ample details in the PR. Please refer to this [proposal](https://gg2002.github.io/2024/03/02/gsoc-2024-proposal/) for the general idea. The specific code behavior is slightly different from what is stated in the proposal, but the idea of finding out LCA is the same.
