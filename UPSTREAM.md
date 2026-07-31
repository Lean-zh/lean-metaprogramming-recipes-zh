# 上游同步

- 上游仓库：<https://github.com/leanprover-cookbook/lean-metaprogramming-recipes>
- 中文仓库：<https://github.com/Lean-zh/lean-metaprogramming-recipes-zh>
- 初始翻译基线：`18c12de7a681c856a96e4a594fec6d39d952f7f3`
- 初始基线日期：2026-04-22
- 上游默认分支：`main`

本地 clone 应保留两个 remote：

```bash
git remote add upstream https://github.com/leanprover-cookbook/lean-metaprogramming-recipes.git
git fetch upstream
git fetch origin
```

同步时单独创建 `sync/upstream-YYYY-MM-DD` 分支。先合并上游，再处理冲突并更新译文。不要在同一个提交中顺手润色无关章节。

同步完成后更新本文件中的“当前同步到”一项，并运行完整构建与渲染。

- 当前同步到：`18c12de7a681c856a96e4a594fec6d39d952f7f3`
