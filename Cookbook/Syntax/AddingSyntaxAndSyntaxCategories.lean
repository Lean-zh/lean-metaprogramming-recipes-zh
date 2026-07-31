import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "添加语法（类别）" =>

%%%
tag := "adding-syntax-and-syntax-categories"
number := false
htmlSplit := .never
file := "adding-syntax-and-syntax-categories"
%%%

::: contributors
:::


{index}[添加语法（类别）]

我们关心的 Lean 对象通常是项、策略和命令，但语法必须表示构造它们时涉及的各种中间对象，例如函数的参数、match 语句中的模式等等。为了表示这些各式各样的对象，Lean 的语法系统有_语法类别_（syntax category）的概念。一个语法类别是一组解析规则，描述如何解析某种语法。例如，`term` 语法类别包含解析像 `1 + 2` 这样的表达式的规则，而 `tactic` 语法类别包含解析像 `simp` 这样的策略的规则。

Lean 已经内置了像 `term`（用于像 1+2 这样的表达式）、`tactic`（用于策略）和 `command`（用于命令）这样的语法类别。语法类别完美地融入了 Lean 的可扩展性框架。它们在实现领域特定语言（DSL）时尤其有用。

# 声明一个语法类别

%%%
tag := "declaring-a-syntax-category"
number := false

file := "declaring-a-syntax-category"
%%%

{index}[声明一个语法类别]

我们可以用 Lean 内置的命令 `declare_syntax_cat` 声明一个语法类别。新的语法类别按如下方式声明：
```lean
declare_syntax_cat mySyntax
```
该类别的新自定义规则通过 `syntax <my-syntax-rule> : mySyntax` 添加。当 Lean 的解析器遇到 `<my-syntax-rule>` 时，会按照 `mySyntax` 规则来解析它。例如，你可以在 `mySyntax` 中定义一个像 `<p> … </p>`（内部含一个字符串）的 HTML 段落块，它会被解析为 `mySyntax`。

```lean
syntax "<p>" str "</p>" : mySyntax
```

# HTML 无序列表的 DSL

%%%
tag := "dsl-for-html-unordered-lists"
number := false
file := "dsl-for-html-unordered-lists"
%%%

{index}[HTML 无序列表的 DSL]

在本配方中，我们将通过创建一个名为 `listItem` 的自定义语法类别来解析无序列表的 HTML 语法。我们还会写一个宏，把这个自定义语法转换成标准的 Lean {name}`List`。由于我们想把列表定义为列表项的集合，方便的做法是先为列表项定义一个语法类别，然后用这个类别来定义列表的语法。这样我们以后就能轻松地扩展 DSL，加入更复杂的列表项，例如带属性的列表项。

我们先声明语法类别 `listItem`。

```lean
declare_syntax_cat listItem
```
接下来，我们要把新的解析规则加入 `listItem` 语法类别。添加新规则的标准格式是 `syntax <new_rule> : <syntax_category>`。

```lean
syntax "<li>" term "</li>" : listItem
syntax "<ul>" listItem* "</ul>" : term
```
这两条规则一起构成一个递归定义，让我们的 DSL 能够处理嵌套列表。第一条规则把 HTML 列表中的一项定义为一个 `<li> … </li>` 块，内部含有任意 Lean 项。第二条规则规定一个 `<ul> … </ul>` 包含零个或多个 `listItem` 块。`(<syntax_block>)*` 记法告诉解析器 `syntax_block` 模式可以出现零次或多次。

最后，我们要把这个解析出来的 HTML 风格无序列表转换成 Lean 中的 {name}`List`。为此我们定义一个辅助函数 `liTerm`，从 `listItem` 类别的语法中提取内部的项。

```lean

def liTerm : TSyntax `listItem → MacroM Syntax.Term
| `(listItem| <li> $t </li>) => return t
| _ => Macro.throwUnsupported
```
我们来拆解 `liTerm` 函数的类型签名：
- {lean}`` TSyntax `listItem `` 确保该函数的输入严格属于我们刚刚定义的 `listItem` 类别。
- `liTerm` 的输出是一个表示 Lean 项的语法（{name}`Syntax.Term`），包裹在 {name}`MacroM` 单子里。宏展开需要由 {name}`MacroM` 提供的上下文。
- 如果输入语法不匹配预期的 `<li>` 模式，函数会抛出 {name}`Macro.throwUnsupported` 错误并安全退出。

```lean
macro_rules
| `(<ul> $ls:listItem* </ul>) => do
  let ts ←  ls.mapM liTerm
  `([$ts,*])

#eval <ul>
         <li> "Drongo" </li>
         <li> "Sparrow" </li>
      </ul> -- ["Drongo", "Sparrow"]

#eval <ul>
         <li>
            <ul>
                  <li> 42 </li>
            </ul>
         </li>
         <li>
            <ul>
                  <li> 13 </li>
                  <li> 57 </li>
            </ul>
         </li>
      </ul>  -- [[42], [13, 57]]

```

`macro_rules` 命令用来对我们的自定义语法进行模式匹配，并精确定义它应如何被翻译（或“展开”）成标准 Lean 代码。在宏展开块中，`ts` 是一个 {name}`Syntax.Term` 数组，我们想输出一个包含这些项的 Lean {name}`List`。这由记法 `[$ts, *]` 实现。方括号 `[]` 是 Lean 的 {name}`List` 字面量，`$ts,*` 把 `ts` 这个 {name}`Array` 解包，放入一个逗号分隔的项序列中。
