import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "修改目标" =>

%%%
tag := "modifying-goals"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[修改目标]

策略可以用多种方式处理目标。它们可以检查目标、修改目标，甚至关闭目标。本节我们探讨如何用精译器编写修改目标的策略。

# 修改目标

策略状态中的目标，特别是主目标，用元变量表示。主目标的类型称为主目标类型（main target）。主目标和主目标类型分别通过 {lean}`getMainGoal` 和 {lean}`getMainTarget` 函数获得。

策略通常给主目标赋一个作为该目标证明的表达式，即类型为主目标类型的表达式。然而，赋给主目标的表达式也可以涉及新的元变量，这些元变量进而成为待求解的新目标。这样，策略就能在不完全关闭主目标的情况下修改目标状态。

注意，如果主目标被赋值，我们必须改变目标列表。最方便的做法是使用 {lean}`replaceMainGoal` 函数，它用新的目标列表替换主目标。这个新目标列表通常包含在赋给主目标的表达式中引入的新元变量。

我们用一个化简主目标类型的策略来说明这一点。

```lean
elab "reduce" : tactic => do
  let target ← getMainTarget
  let reducedTarget ← reduce (skipTypes := false) target
  let mvar ←  mkFreshExprMVar reducedTarget
  let goal ← getMainGoal
  goal.assign mvar
  replaceMainGoal [mvar.mvarId!]

example : 1 + 1 = 2 := by -- goal `1 + 1 = 2`
  reduce -- goal `2 = 2`
  rfl
```

我们要强调，确保以下这点是策略作者的责任：如果给一个元变量（例如一个目标）赋了某个表达式，那么该表达式的类型必须与目标的类型在定义等价意义下相同。作者还必须正确地修改目标列表，以反映引入的任何新元变量，并移除那些已被赋值的元变量。否则，使用该策略时我们会得到一个底层错误。

## 拆分 `∧` 目标

作为一个稍微复杂一点的例子，我们可以编写一个策略，把形如 `P ∧ Q` 的目标拆成两个独立的目标 `P` 和 `Q`。做法是给主目标赋一个形如 `And.intro p q` 的表达式，其中 `p` 和 `q` 是分别表示 `P` 和 `Q` 的证明的新元变量。然后我们用对应这些元变量的新目标替换主目标。为了识别主目标类型是否为 `P ∧ Q` 的形式，我们可以使用 {lean}`Expr.app2?` 函数，它检查一个表达式是否是某个给定常量带两个参数的应用，如果是，则返回该应用的参数。

```lean
elab "and" : tactic => do
  let target ← getMainTarget
  match target.app2? ``And with
  | some (P, Q) => do
    let p ← mkFreshExprMVar P
    let q ← mkFreshExprMVar Q
    let andIntroExpr ← mkAppM ``And.intro #[p, q]
    let goal ← getMainGoal
    goal.assign andIntroExpr
    replaceMainGoal [p.mvarId!, q.mvarId!]
  | none =>
    logWarning m!"The goal is not of the form `P ∧ Q`"

example : (1 + 1 = 2) ∧ (2 + 2 = 4) := by
  -- goal `(1 + 1 = 2) ∧ (2 + 2 = 4)`
  and -- two goals `1 + 1 = 2` and `2 + 2 = 4`
  · -- goal `1 + 1 = 2`
    rfl
  · -- goal `2 + 2 = 4`
    rfl
```
