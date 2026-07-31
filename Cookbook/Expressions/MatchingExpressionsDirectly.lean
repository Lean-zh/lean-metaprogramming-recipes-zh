import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "直接对表达式进行模式匹配" =>

%%%
tag := "pattern-matching-expressions-directly"
number := false
%%%

::: contributors
:::


{index}[直接对表达式进行模式匹配]

在元编程中，例如编写策略时，常常需要判断一个表达式是否匹配某个模式。Lean 提供了若干[识别器（Recognizers）](https://leanprover-community.github.io/mathlib4_docs/Lean/Util/Recognizers.html)，可用来检查一个表达式是否匹配某个模式并提取相关的子表达式。例如，函数 {lean}`Expr.isAppOf` 检查一个表达式是否是某个函数的应用，并提取该应用的参数。

# 例子：拆分 `∧` 中的目标

作为一个例子，我们可能想把形如 `P ∧ Q` 的目标迭代地分解为独立的目标 `P` 和 `Q`。为此，我们可以用 {lean}`Expr.app2?` 函数检查主目标是否为 `P ∧ Q` 的形式，该函数检查一个表达式是否是给定常量带两个参数的应用，如果是，就返回该应用的参数。递归地这样做，就能把形如 `P1 ∧ P2 ∧ P3` 的目标拆分成三个独立的目标 `P1`、`P2` 和 `P3`。我们在下面的函数中这样做。

```lean
partial def splitAnds (e: Expr) : List Expr :=
  match e.app2? ``And with
  | some (P, Q) => splitAnds P ++ splitAnds Q
  | none => [e]
```

为了看到这个函数的实际效果，我们写一个精译器，它在证明过程中获取主目标并把它传给 `matchNatLe`（关于如何用精译器编写策略见 {ref "viewing-closing-goals"}[查看与关闭目标]，关于如何在信息视图中显示信息见 {ref "displaying-in-the-infoview"}[在信息视图中显示]）。

```lean
elab "splitAnds" : tactic => do
  withMainContext do
  let goal ← getMainTarget
  let subgoals := splitAnds goal
  if subgoals.length = 1 then
    logInfo m!"The goal is not a conjunction: {goal}"
  else
    logInfo m!"The goal is a conjunction"
    logInfo m!" Subgoals ({subgoals.length} subgoals) are:"
    for subgoal in subgoals do
      logInfo m!"Subgoal: {subgoal}"

example: 123 ≤ 234 := by
  splitAnds
  simp

example: (123 ≤ 234) ∧ (234 ≤ 345) ∧
    (345 ≤ 456 ∧ 2 ≤ 3) := by
  splitAnds
  simp
```

## 其他识别器

如上所述，还有若干其他识别器，可用来检查一个表达式是否匹配某个模式并提取相关的子表达式。也有相关的布尔函数，它们检查一个表达式是否匹配某个模式，但不提取子表达式。

例如，函数 {lean}`Expr.isLambda` 检查一个表达式是否是 lambda 抽象并提取该 lambda 的主体。函数 {lean}`Expr.isForall` 检查一个表达式是否是全称量化并提取该量化的主体。函数 {lean}`Expr.isAppOfArity` 检查一个表达式是否是某个函数带一定数量参数的应用并提取该应用的参数。我们还有匹配器 {lean}`Expr.eq?`、{lean}`Expr.const?`、{lean}`Expr.prod?` 等，它们检查一个表达式是否为某种形式并提取相关的子表达式。

你可以在 [Lean 4 文档](https://leanprover-community.github.io/mathlib4_docs/Lean/Util/Recognizers.html)中找到识别器的完整列表。
