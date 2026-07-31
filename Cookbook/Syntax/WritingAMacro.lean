import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term Parser Category

set_option pp.rawOnError true

#doc (Manual) "编写一个宏" =>

%%%
tag := "writing-a-macro"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[编写一个宏]
在 Lean 中可以很容易地为 {name}`term`、`tactic`、{lean}`command` 添加新语法。最简单的方式是写一个宏，把新语法变换成现有语法。在本配方中，我们演示如何为项和命令的新语法编写宏。

我们将从一个解析 Python 幂运算语法的简单例子开始，然后转到解析 Python `for` 循环语法这个更复杂的例子。

# Python 幂运算的语法
%%%
tag := "syntax-for-python-exponentiation"
number := false
%%%
{index}[Python 幂运算 DSL]

我们先从一个解析 Lean 中 Python 幂运算语法的简单例子开始。下面的 `macro` 声明告诉 Lean 如何解析形如 `2**4` 的东西，并把它展开成 Lean 的幂运算语法。

```lean
macro n:num "**" m:num : term => `($n^$m)

#eval 2**3 --8
```

这里，`num` 是一个解析器，它只接受纯数字字面量，拒绝其他一切。

# Python `for` 循环的语法
%%%
tag := "syntax-for-python-for-loop"
number := false
%%%
{index}[Python `for` 循环 DSL]

在 Python 中，列表推导式提供了一种创建列表的简洁方式。例如，表达式 `[x^2 for x in [1,2,3,4,5]]` 生成前五个自然数的平方组成的列表。我们将在 Lean 中定义类似的语法，然后实现求值它的逻辑。

在 Lean 中，这可以用 {name}`List.map` 函数来完成。

```lean
#eval List.map (fun x => x * x) [1, 2, 3, 4]
```

## 一个解析 Python 风格 `for` 循环的 `macro`
%%%
tag := "macro-for-python-for-loop"
number := false
%%%

接下来，我们定义一个 `macro`，让我们能在 Lean 中写出类似 Python 的语法。它解析形如 `[<term> pyfor <ident> in <term>]` 的表达式，并用 {name}`List.map` 把它们变换成标准的 Lean 表达式。{name}`ident` 是推导式中所用变量名的占位符，两个 {name}`term` 占位符分别表示要生成的表达式和要遍历的集合。为了避免与 Lean 中的 `for` 关键字冲突，我们改用 `pyfor`。

```lean
macro "[" t:term "pyfor" x:ident "in" l:term "]": term => do
  let fn ← `(fun $x => $t)
  `(List.map $fn $l)

#eval [x * 2 pyfor x in [1, 2, 3, 4]] --> [2, 4, 6, 8]
```
如果你更愿意把语法声明和宏展开分开，Lean 也允许你先用 `syntax` 定义语法，再单独添加宏规则。

```lean
syntax "[" term "pyfor'" ident "in" term "]" : term

macro_rules
| `([ $t:term pyfor' $x:ident in $l:term ]) => do
    let fn ← `(fun $x => $t)
    `(List.map $fn $l)
```

`macro_rules` 命令用来对我们的自定义语法进行模式匹配，并精确定义它应如何被翻译（或“展开”）成标准 Lean 代码。在本例中，我们从自定义语法中取出项 `t`、标识符 `x` 和列表 `l`，构造一个新表达式，把 `List.map` 应用到一个 lambda 函数 `fn`（由 `t` 和 `x` 构造）和列表 `l` 上。

宏只充当语法糖，只会展开成另一段“已经存在的”语法。在后面的配方 {ref "elaborator-for-python-for-loop"}[一个解析 Python 风格 `for` 循环的精译器]中，我们会看到如何编写一个精译器，它解析同样的语法，并在精译过程中执行额外的检查。
