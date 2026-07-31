import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "通过求解对表达式进行模式匹配" =>

%%%
tag := "matching-expressions-by-solving"
number := false
%%%

::: contributors
:::


{index}[通过求解对表达式进行模式匹配]

在配方 {ref "pattern-matching-expressions-directly"}[直接对表达式进行模式匹配]中，我们看到了如何通过检查表达式的结构来匹配表达式。然而，这种方法很脆弱，因为 Lean 可能会（例如）化简表达式或展开定义，导致结构改变、匹配失败。

一种更稳健的匹配表达式的方式是使用 Lean 的*合一*（unification）。做法是构建一个带_元变量_的表达式，再用 {lean}`isDefEq` 合一两个表达式，从而求解这些元变量。这里你可以把元变量想象成数学方程中的变量（例如方程 `2x+5=9` 中的变量 `x`）。



# 例子：自然数之间的不等式

假设我们想检查一个目标，看它是否为 `a ≤ b` 形式的不等式，其中 `a` 和 `b` 是自然数。如果是，我们想提取这些值（为了说明，我们把它们打印到信息视图）。由于这涉及创建和赋值元变量（临时占位符），我们需要在 {lean}`MetaM` 单子内部工作。

我们先写一个以表达式（`Expr`）为输入的函数。它的输出是一个包裹在 `MetaM` 单子里的 {lean}`Option (Expr × Expr)`，如果找到匹配就返回不等式的两侧，否则返回 `none`。

因此，我们函数的类型签名将是 {lean}`Expr → MetaM (Option (Expr × Expr))`。

```lean
def matchNatLe? (e: Expr) :
    MetaM <| Option (Expr × Expr) := do
  let nat := mkConst ``Nat
  let a ← mkFreshExprMVar nat
  let b ← mkFreshExprMVar nat
  let ineq ← mkAppM ``Nat.le #[a, b]
  if (← isDefEq ineq e) then
    return some (a, b)
  else
    return none
```

{lean}`mkFreshExprMVar` 构造一个给定类型的元变量，这里是 `nat`，其中 `nat` 是一个表达式。这会创建一个 Lean 之后可以填入的空洞。表达式 `isDefEq ineq e` 检查所构造的表达式 `ineq` 与目标表达式 `e` 是否在定义上相等。关键在于，在检查相等的同时，它会尝试合一二者，把 `e` 中的具体值赋给我们的空元变量 `a` 和 `b`。

现在，为了看到这个函数的实际效果，我们写一个精译器，它在证明过程中获取主目标并把它传给 `matchNatLe`（关于如何用精译器编写策略见 {ref "viewing-closing-goals"}[查看与关闭目标]，关于如何在信息视图中显示信息见 {ref "displaying-in-the-infoview"}[在信息视图中显示]）。

```lean
elab "matchNatLe?" : tactic => do
  withMainContext do
  let goal ← getMainTarget
  match (← matchNatLe? (goal)) with
  | some (a, b) => logInfo m!"The goal is an inequality
    `a ≤ b` between natural numbers where a = {a}, b = {b}"
  | _ => logInfo m!"The goal is not an inequality"

example: 123 ≤ 234 := by
  matchNatLe?
  simp

```
