# Lean 4（元）编程 Cookbook

这是 [Lean 4 (Meta)programming Cookbook](https://github.com/leanprover-cookbook/lean-metaprogramming-recipes) 的简体中文译本，收录 Lean 4 编程与元编程中可直接复用的代码配方。

在线阅读：<https://lean-zh.github.io/lean-metaprogramming-recipes-zh/>

> 本项目仍在翻译和校对。进度见 [PROGRESS.md](PROGRESS.md)。

这不是一本从基础概念讲起的线性教材。它更像一册按问题查阅的配方集：需要操作语法、表达式、策略、文件系统、JSON 或 TOML 时，可以找到一段能够运行的最小代码，再按自己的项目改造。如果你刚接触 Lean，建议先阅读《Theorem Proving in Lean》《Functional Programming in Lean》或《Mathematics in Lean》，再把本书当作参考资料使用。

本书只讨论 Lean 4 的编程与元编程，不收录数学定理证明配方。

## 本地构建

项目固定使用 `lean-toolchain` 与 `lake-manifest.json` 中记录的版本。首次构建会下载 Verso 等依赖。

```bash
lake build lean-cookbook
lake exe lean-cookbook
python3 -m http.server -d _out/html-multi
```

随后访问 <http://localhost:8000/>。

## 参与翻译

翻译前请阅读：

- [翻译与写作规范](STANDARDS.md)
- [术语表](GLOSSARY.md)
- [翻译进度](PROGRESS.md)
- [上游同步说明](UPSTREAM.md)
- [贡献指南](CONTRIBUTING.md)

新增或修改配方时，还要遵守 [Cookbook 配方指南](COOKBOOK_GUIDELINES.md)。

## 版权与致谢

原书由 Lean 社区贡献者共同维护，完整名单见上游仓库与本书贡献者页面。中文译本保留上游 Git 历史，并在此基础上记录译者贡献。

源码沿用上游的 MIT License。`LICENSE` 为具有法律效力的英文原文。
