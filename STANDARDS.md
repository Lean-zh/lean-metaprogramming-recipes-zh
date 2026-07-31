# 翻译与写作规范

本仓库是 [Lean 4 (Meta)programming Cookbook](https://github.com/leanprover-cookbook/lean-metaprogramming-recipes) 的简体中文译本。中文正文直接替换英文正文，Git 历史和 `upstream` remote 用于逐段对照原文，不在每一段旁重复保留英文。

## 翻译边界

应翻译：

- 页面标题、章节标题、正文、列表、提示、边注；
- 链接的可见文字、索引词和前端可见文案；
- README、贡献指南、Cookbook 指南与模板中的说明文字。

默认不翻译：

- Lean 代码、标识符、命名空间、模块路径和文件名；
- fenced code block 的内容；
- Verso 指令、`tag`、`ref`、URL、版本号和依赖 revision；
- `#guard_msgs` 的预期诊断文本；
- 示例里的字符串常量、路径、JSON/TOML 键和命令输出；
- `LICENSE` 原文。

代码注释只有在确定不参与测试、不改变导出示例含义时才翻译。每次修改后必须重新构建。

## 中文行文

- 直接说明要做什么、为什么这样做，不写“让我们来看看”“值得注意的是”一类开场白。
- 不删技术条件，不为追求简短跳过关键步骤。
- 首次出现的重要术语采用“中文（English）”，后文使用中文；API 名始终保留英文。
- 使用全角中文标点。中文与英文标识符、数字之间留一个半角空格。
- 标题采用中文句式，不使用英文标题式大小写。
- 译文应自然、准确，不逐词照搬英文句法，也不自行增加原文没有的事实。

## 术语

`GLOSSARY.md` 是全仓库的术语权威。新术语首次出现时若无既定译法，先补入术语表，再用于正文。

其中 `elaboration` 统一译为“精译”，首次出现写作“精译（elaboration）”；Lean API 中的 `Elab`、`elabTerm` 等名字不翻译。

## 结构与构建

- 不改变现有 `tag := "..."` 和 `{ref "..."}`，以免旧链接失效。
- 不随意调整章节层级、include 顺序或模块名。
- 每批翻译必须运行：

  ```bash
  LEAN_NUM_THREADS=6 lake build lean-cookbook
  LEAN_NUM_THREADS=6 lake exe lean-cookbook
  ```

- 构建成功只证明 Lean/Verso 接受源码。合并前还要检查生成页面中的标题、中文正文、链接和代码块。
- 翻译提交与上游同步提交分开，避免把语义更新和中文润色混在一个 diff 中。
