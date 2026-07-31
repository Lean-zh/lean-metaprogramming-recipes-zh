import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "准引用：创建与匹配语法" =>

%%%
tag := "quasi-quotes"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[准引用：创建与匹配语法]

# 准引用

处理语法时，我们几乎总是使用_准引用_（quasi-quotation），它是创建和匹配语法的便捷方式。准引用是形如 `` `(<syntax>) `` 或更一般的 `` `(<category>| <syntax>) `` 的语法表示。这里的 `category` 可以是例如 `command` 或 `tactic`。如果省略类别，则默认为 `term`。我们也可以用一个解析器代替类别。

使用准引用构造表达式只能在具备 `Lean.MonadQuotation` 的单子中进行，元编程单子都属于此类。它们既可以表示语法，也可以表示_有类型语法_（typed syntax）。因此，下面这些表达式都定义了命令的语法：

```lean
def egCommand : Lean.CoreM Lean.Syntax.Command := do
  `(command| example := "Hello World")

def egCommand' : Lean.CoreM Lean.Syntax:= do
  `(command| example := "Hello World")

def egCommand'' : Lean.CoreM (Lean.TSyntax `command) := do
  `(command| example := "Hello World")
```

## 带插值的准引用

在上面的例子中，我们精确指定了想要创建的语法。不过，我们也可以用_插值_（interpolation）来创建依赖于变量的语法。以 `$` 开头的表达式是一个插值，可以用来把某个变量的值插入到语法中。例如，我们可以按如下方式定义一个表示两个自然数之和的项：

```lean
open Lean
def sumTerm (a b : Nat) : CoreM Syntax.Term := do
  let aLit := Syntax.mkNatLit a
  let bLit := Syntax.mkNatLit b
  `($aLit + $bLit)
```

这里我们用了函数 `Syntax.mkNatLit`，它从一个自然数构造出一个表示自然数字面量的语法。

## 用准引用匹配语法

我们也可以用准引用来匹配语法。例如，我们可以定义一个函数，检查给定的语法是否为某个 `a` 和 `b` 的 `a + b` 形式，如果是，就交换 `a` 和 `b` 的顺序：

```lean
def flipSum : Lean.Syntax.Term → CoreM Lean.Syntax.Term
| `($a +  $b) => `($b + $a)
| stx => return stx

def checkFlipSum (a b : Nat) : CoreM Format := do
  let stx ← flipSum (← (sumTerm a b))
  PrettyPrinter.ppTerm stx

#eval checkFlipSum 1 3 -- 3 + 1
```
