import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


open Lean Elab Meta Tactic Command Term Parser Category

set_option pp.rawOnError true

#doc (Manual) "为项添加语法" =>

%%%
tag := "adding-syntax-for-terms"
number := false
htmlSplit := .never
file := "adding-syntax-for-terms"
%%%

::: contributors
:::

{index}[为项添加语法]

# Python `for` 循环的语法

%%%
file := "elaboration-syntax-for-terms-section-02"
%%%

我们将改进配方 {ref "macro-for-python-for-loop"}[解析类 Python `for` 循环的 `macro`] 中定义的、用于解析 Python `for` 循环语法的 `macro`。这里我们用精译器（`elab`）而非 `macro` 来解析相同的语法。这样一来，我们不再只做简单的语法变换，而是从语法生成一个表达式。这让我们能够在精译过程中执行更复杂的变换和检查。

这个版本会检查被遍历的集合是 {name}`List` 还是 {name}`Array`，并分别处理各种情况。当集合是意料之外的类型时，它还会给出更明确的错误消息。

## 解析类 Python `for` 循环的精译器

%%%
tag := "elaborator-for-python-for-loop"
number := false
file := "elaborator-for-python-for-loop"
%%%

下面是用精译器（`elab`）实现的一个更健壮、更完整的版本。这个版本会检查被遍历的集合是 {name}`List` 还是 {name}`Array`，并分别处理各种情况：

```lean
elab "[" t:term "py_for" x:ident "in" l:term  "]" :
    term => do
  let fnStx ← `(fun $x => $t)
  let lExpr ← elabTerm l none
  let fn ← elabTerm fnStx none
  let ltype ← inferType lExpr
  Term.synthesizeSyntheticMVarsNoPostponing
  if ltype.isAppOf ``List then
    mkAppM ``List.map #[fn, lExpr]
  else
    if ltype.isAppOf ``Array then
      mkAppM ``Array.map #[fn, lExpr]
    else
      throwError "Expected a List or Array in py_for
      comprehension, got {ltype}"

#eval [x * 2 py_for x in [1, 2, 3, 4]] --> [2, 4, 6, 8]
#eval [x * 2 py_for x in #[1, 2, 3, 4]] --> #[2, 4, 6, 8]

/--
error: Expected a List or Array in py_for
      comprehension, got String
-/
#guard_msgs in
#eval [x * 2 py_for x in "List"]
```
我们逐一分析上面精译器中用到的具体元编程函数：

- {name}`Term.elabTerm` 用来把集合 `l` 和函数 `fnStx` 的语法精译成真正的 Lean 表达式，而 {name}`Meta.inferType` 用来确定集合的类型。
- 调用 {name}`Term.synthesizeSyntheticMVarsNoPostponing` 是为了确保在我们尝试检查类型之前，精译过程中产生的任何元变量都已完全解析。如果项 `l` 是一个 {name}`List`，`ltype` 会具有 `List ?m` 的形式，其中 `?m` 是表示元素类型的元变量。调用 {name}`Term.synthesizeSyntheticMVarsNoPostponing` 确保 `?m` 被解析为具体类型，使我们能够继续调用 `mkAppM`，而不会遇到未解析元变量导致的问题。
- {name}`Expr.isAppOf` 用来检查 `l` 的类型是 {name}`List` 还是 {name}`Array`。根据结果，我们用 {name}`mkAppM` 构造相应的 {name}`List.map` 或 {name}`Array.map` 表达式。如果两者都不是，就抛出一个自定义错误。
