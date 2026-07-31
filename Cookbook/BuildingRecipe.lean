import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "如何编写配方" =>

%%%
tag := "building-recipe"
number := false
%%%

::: contributors
:::

{index}[如何编写配方]

本章演示 Cookbook 配方的标准结构，以及配方中可以使用的文档功能。请同时查看网页中的渲染效果，这比只读源码更容易看清各部分的关系。仓库根目录的 `TemplateRecipe.lean` 可以直接作为起点。

本书使用 Verso 构建，因此编写配方前需要了解 Verso 的基本标记。以下内容概括本项目最常用的写法。需要完整说明时，请查阅 [Verso Manual](https://verso-user-manual.netlify.app/)，也可以参考已有配方的源码。

一个典型配方包含：

1. 简短、易读，并能清楚指出所解决问题的标题。
2. 简要介绍问题和解决办法的开头。
3. 展示解决办法的代码片段。
4. 理解代码所需的解释，以及供进一步阅读的资料链接。
5. 适合放在同一配方中的后续用法。例如介绍读取普通文件后，可以在小节中补充 JSON、CSV 等文件类型，而不必为每种类型另建配方。每个小标题都应设置 tag 和索引，方便引用。
6. 调试技巧、预期错误和进一步用法。

模板源码见[这里](https://github.com/Lean-zh/lean-metaprogramming-recipes-zh/blob/main/TemplateRecipe.lean)。

# 添加章节

%%%
tag := "adding-sections"
%%%

一级小节使用 `#`，如下所示。每个章节应从明确的问题陈述和解决办法概览开始，本节的写法就是一个例子。

内容内部可以用 `##` 组织二级小节。用 `*` 标记强调文字，例如 *这样*。

## 元数据与标签

%%%
tag := "metadata-and-tagging"
%%%

每个标题下面都可以定义元数据：

```
%%%
tag := "my-tag"
number := false
htmlSplit := .never
%%%
```

以后可以通过 tag 引用这一节。

*怎样取得 tag 对应的链接？* 在网页中点击标题并跳转到该节，浏览器 URL 中会出现这个 tag。

- *说明 1*：`htmlSplit := .never` 是可选项，只在不想把本节拆成多个页面时使用。本书的 Verso 配置为 `htmlDepth := 3`。在达到第三层深度之前，`#` 标题会生成子页面，而不是留在当前页面。如果确定不应分页，就在元数据中加入这一行。
- *说明 2*：本书不是按固定顺序阅读的线性教材，而是可以直接跳到任意条目的参考手册，因此用 `number := false` 关闭编号。

# 文本格式

%%%
tag := "formatting-text"
htmlSplit := .never
%%%

Verso 的完整格式说明见 [Verso Markup](https://verso-user-manual.netlify.app/Verso-Markup/?terms=--verso#verso-markup)。下面只列出本书最常用的功能。

## 插入行内 Lean 代码

%%%
tag := "adding-inline-lean-code"
%%%

文档可以包含由 Lean 直接精译的代码，适合短小片段。代码仍应遵守 Lean 的命名、大小写等语法约定。

```lean
def helloCookbook := "Welcome!"

#eval helloCookbook
```

## 可交互符号

%%%
tag := "interactive-symbols"
%%%

若希望正文中的 Lean 符号支持悬停信息和类型提示，请使用 `{name}` 与 `{lean}` role，而不是普通反引号。

- *`{lean}`* `` `term` ``：精译一个完整的 Lean 表达式，例如 `` {lean}`1 + 2` ``。表达式中的每个 token 都会带有交互信息。
- *`{name}`* `` `ConstName` ``：解析一个全局常量，例如 `` {name}`Nat` ``。悬停时显示其 docstring 和类型签名。

*写法：*

数字使用类型 `` {name}`Nat` ``。
示例项可以写成 `` {lean}`[1, 2].map (· + 1)` ``。

*效果：*

渲染后，把鼠标悬停在 {name}`Nat` 上会看到它的定义和 docstring。悬停在 {lean}`[1, 2].map (· + 1)` 的不同部分，则会看到列表、`map` 函数和 λ 抽象的类型。

## Docstring

%%%
tag := "docstrings"
%%%

Verso 可以通过 `{docstring}` role 把 Lean 定义的 docstring 直接嵌入文档。详细说明见[这里](https://verso.lean-lang.org/doc/latest/Manuals-and-Books/#docstrings)。

```
{docstring Nat.add}
```

渲染结果如下：

{docstring Nat.add}

## 错误与警告

%%%
tag := "errors-and-warnings"
%%%

若代码片段应当报错，可以像普通 Lean 文件一样在代码前使用 `#guard_msgs`。下面的例子来自 {ref "displaying-in-the-infoview"}[在信息视图中显示内容]配方。

```
def errorMessage' (msg : String) : CoreM Unit := do
  Lean.logError m!"Error: {msg}"

/-- error: Error: something went wrong -/
#guard_msgs in
#eval errorMessage' "something went wrong"
```

渲染结果如下：

```lean
def errorMessage' (msg : String) : CoreM Unit := do
  Lean.logError m!"Error: {msg}"

/-- error: Error: something went wrong -/
#guard_msgs in
#eval errorMessage' "something went wrong"
```

## 交叉引用

%%%
tag := "cross-references"
%%%

通过 tag 可以链接其他章节：`{ref "tag-name"}[链接文字]`。

例如，源码 `` {ref "building-recipe"}[返回开头] `` 的效果是 {ref "building-recipe"}[返回开头]。

## 边注

%%%
tag := "marginal-notes"
%%%

`{margin}[边注文字]` 会在页边显示补充内容，效果如下：{margin}[边注适合补充不应打断正文的背景。]

## 索引

%%%
tag := "indexing"
%%%

用 `{index}` role 把术语加入索引。它不会在正文中显示内容，只会在生成的索引中增加条目，例如 `{index}[要索引的术语]`。

# 贡献者区块

%%%
tag := "contributor-section"
%%%

每个页面顶部都应在 `#doc (Manual) "标题" =>` 和元数据之后放置贡献者区块。贡献者信息由 `git` 自动读取，不需要手工填写。哪些贡献会进入页面署名，见 [COOKBOOK\_GUIDELINES](../COOKBOOK_GUIDELINES.md)。

每页只添加一次：

```
::: contributors
:::
```

Verso 对 `:::` 区块的位置有严格要求：它不能放在 `%%%` 元数据之前。如果 `#doc` 后面紧接元数据，贡献者区块必须放在元数据之后。已有配方可以作为参考。
