import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term

set_option pp.rawOnError true

#doc (Manual) "检查策略" =>

%%%
tag := "checking-tactics"
number := false
htmlSplit := .never
file := "checking-tactics"
%%%

::: contributors
:::


{index}[检查策略]

# 检查策略

%%%
tag := "checking-tactics-overview"
number := false
file := "checking-tactics-overview"
%%%

在编写策略以及实现其他形式的自动化时，常常需要检查某个策略能否应用于一个目标，如果能，应用之后还剩下多少个目标（尤其是它是否关闭了目标）。重要的是，这种检查不能修改策略状态。我们可以用 {lean}`@withoutModifyingState` 函数来做到这一点，它执行给定的计算而不修改策略状态。我们用 {lean}`Elab.runTactic` 函数运行策略（更确切地说是策略序列），它接受一个目标和一个策略序列，返回在给定目标上执行该策略序列之后的新目标列表和新策略状态。下面的函数检查某个策略能否应用于一个目标，如果能，返回应用该策略之后剩下的目标数。

```lean
def checkTactic (target: Expr)(tac: Syntax):
  TermElabM (Option Nat) :=
    withoutModifyingState do
    try
      let goal ← mkFreshExprMVar target
      let (goals, _) ←
        withoutErrToSorry do
        Elab.runTactic goal.mvarId! tac
          (← read) (← get)
      return some goals.length
    catch _ =>
      return none
```

为了说明这个函数，我们定义一个策略，它接受一个策略序列作为参数，检查它能否应用于主目标类型，如果能，记录应用该策略之后剩下的目标数。如果该策略无法应用，就记录一条警告。

```lean
elab "check_tactic" tac:tacticSeq : tactic =>
  withMainContext do
  let n? ← checkTactic (← getMainTarget) tac
  match n? with
  | some n =>
    logInfo m!"Tactic succeeded; {n} goals remain"
  | none =>
    logWarning m!"Tactic failed"

example : 1 ≤ 5 := by
  check_tactic rfl
  check_tactic decide
  decide
```
