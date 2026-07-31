# Lean 4（元）编程 Cookbook 配方指南

本指南说明如何为 Lean 4（元）编程 Cookbook 编写配方。仓库同时收录普通编程和元编程内容；名称中的 `metaprogramming-recipes` 是为了便于识别，并不排除普通编程配方。下文把解决一个具体问题的独立条目称为“配方”，把一组相关配方称为“章节”。

翻译或校对现有内容时，还必须遵守 [STANDARDS.md](STANDARDS.md) 和 [GLOSSARY.md](GLOSSARY.md)。

## 仓库结构

本书按章节和配方组织：

- **总入口**：`Cookbook.lean` 是首页。
- **章节父文件**：位于 `Cookbook/`，例如 `Syntax.lean`、`Expressions.lean`。这些文件定义章节标题并引入各个配方。
- **配方文件**：位于对应子目录中的独立 Lean 文件，例如 `Cookbook/FileSystem/ReadingFromFile.lean`。

## 编写新配方

请按以下步骤添加配方，使新内容与现有结构保持一致。

1. **先讨论**：确认相同内容尚未覆盖，而且确有收录价值。本书通常不重复其他资料已经充分解释的内容。动笔前请在 Discussions 中沟通。

2. **创建文件**：在合适的子目录中添加 `Cookbook/{CHAPTER_NAME}/{RecipeName}.lean`。如果没有合适章节，可以新建章节。命名之前先阅读下文的命名约定。

3. **使用模板**：复制 [TemplateRecipe.lean](./TemplateRecipe.lean)，再按配方内容修改。

   其中几项元数据需要特别注意：

   - `tag` 用于索引和交叉引用，不能省略。它应采用 `kebab-case`，并与不含 `.lean` 后缀的文件名对应。例如，`ReadingFromFile.lean` 使用 `tag := "reading-from-file"`。
   - `number := false` 关闭自动编号。独立配方通常使用这一设置。
   - `htmlSplit := .never` 让配方留在章节的同一个 HTML 页面中。本书使用 `htmlDepth := 3`，深度不超过 3 的 `#` 标题默认会拆出子页面。Verso 又不允许在某些位置直接从 `##` 开始，因此如果必须使用 `#` 标题但不想分页，可以设置 `htmlSplit := .never`。

4. **编写正文**：遵守本文件后面的最佳实践。不同配方区块的写法可参考 [BuildingRecipe.lean](./Cookbook/BuildingRecipe.lean)。

5. **接入章节**：在章节父文件中导入并包含新配方，否则它不会出现在书中，也无法正确建立索引。

   - 打开父文件，例如 `Cookbook/{ChapterName}.lean`。
   - 在顶部加入 `import Cookbook.{CHAPTER_NAME}.{RecipeName}`。
   - 在合适位置加入 `{include 1 Cookbook.{CHAPTER_NAME}.{RecipeName}}`。若配方在阅读顺序上应排在现有配方之前，就插入相应位置；否则放在末尾。

配方的完整示例见 [BuildingRecipe.lean](./Cookbook/BuildingRecipe.lean)，起始模板见 [TemplateRecipe.lean](./TemplateRecipe.lean)。

## 章节、文件与标题的命名

1. **章节名**：使用简短而范围足够宽的总括词，例如 `Syntax`、`Widgets`、`Tactics`。不要用只能容纳一个配方的过窄名称。确有必要时，可以在章节内增加子模块来组织相关配方。

2. **文件名**：名称应当简短、技术含义明确，并能反映配方解决的问题。可参考已有文件。

   - 不要与章节同名，以免混淆。
   - 使用 PascalCase（UpperCamelCase），例如 `ReadingFromFile.lean`，不要写成 `reading_from_file.lean` 或 `Reading-from-File.lean`。
   - 不要在文件名中使用符号或数字。用单词表达，例如用 `And` 代替 `&`，用 `Zero` 代替 `0`。
   - 避免 `AnEasyMacro.lean`、`AUsefulTactic.lean` 一类泛泛名称。若配方确实简单或实用，可以在索引或说明中写明，Verso 搜索会据此找到内容。

   `HelloWorldTactic.lean` 和 `Miscellaneous.lean` 是有意保留的例外。新章节可以用一个 Hello World 配方帮助读者入门，也可以在同一文件中包含多个很短的基础配方。`Miscellaneous.lean` 适合收纳过小、不值得单独成文件但仍应进入章节的配方。

3. **标题**：标题应当具体、易懂，让读者不必打开正文就能判断配方内容。英文标题只要求第一个单词首字母大写；中文标题按正常中文句式书写。

## 最佳实践

- **保持原子性**：一个配方只解决一个明确问题。
- **建立索引**：为重要概念添加 `{index}[配方标题]`。配方标题与索引名称应尽量对应。
- **解释原因**：不要只给代码。说明做法、关键选择和真正有用的技巧，但避免在已有权威资料覆盖的地方重复大段概念教学。优先链接官方文档或教材；若没有可用资料，再给出简短而足够的背景说明。
- **交叉引用**：用 `{ref "tag"}[可见文字]` 链接相关配方。需要概念背景时，可以引用 TPIL、FPIL 和 Lean 官方文档。
- **本地运行**：每次修改都执行完整构建和渲染：

  ```bash
  lake build lean-cookbook
  lake exe lean-cookbook
  ```

  输出位于 `_out/html-multi`。可以打开 `_out/html-multi/index.html`，也可以启动静态文件服务器：

  ```bash
  python3 -m http.server -d _out/html-multi
  ```

  除首页外，还应检查受影响章节和配方的 HTML。

- **不要提交 AI 流水账**：内容必须经过作者逐段核对。复杂术语堆砌、含糊解释和看似完整却无法运行的代码会直接降低配方的价值。若不确定，请先在 Discussions 或 Lean Zulip 中提问。

## 构建与预览

渲染结果在 `_out/html-multi`。任何静态文件服务器都能用于本地预览，例如：

```bash
python3 -m http.server -d _out/html-multi
```

## 排查 `INTERNAL PANIC`

如果 `lake exe` 因 `executed 'sorry'` 发生 panic：

1. 检查 `+error` 区块，确认其中的错误信息与 Lean 实际输出完全一致。
2. 确认每个 `+error` 区块都有 `(name := ...)` 参数。
3. 若仍无法匹配，先删除相应 `+error` 或 `leanOutput`，改用普通代码块，再单独排查差异。

## 贡献者署名

我们感谢每一位参与者。配方页会在顶部显示对该文件有实质贡献的作者，并链接到相应 commit。只做导入修复、索引改名、空行调整或很小的错字修正，通常不会进入该配方的作者列表；编写代码、解释或参考资料等内容贡献会被记录。

这与 Mathlib 的作者列表原则相近：

> 对于作者列表，我们没有严格规定什么贡献才有资格列入。一般来说，列出的人应当是：如果我们对 Lean 代码的设计或开发有疑问，会去询问的人。

本书采用同样的思路。

系统以一次 commit 中超过 `15` 个有意义字符作为文件级署名的启发式阈值。这个数字并非数学界线，只是为了减少纯错字修正进入配方作者列表的情况。该机制在 [#15](https://github.com/leanprover-cookbook/lean-metaprogramming-recipes/pull/15) 中加入，因此阈值也取了 15。

**需要手工填写姓名吗？**

不需要。构建程序通过 `git` 历史自动读取贡献者姓名。它会尽量排除前述管理性修改，同时把所有拥有 commit 的人列入首页链接的 `Cookbook Contributors` 页面。不要在配方正文中手工维护作者名单。
