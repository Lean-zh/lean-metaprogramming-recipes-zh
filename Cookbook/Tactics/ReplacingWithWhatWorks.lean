import VersoManual
import Cookbook.Lean
import Cookbook.Tactics.CheckingTactics

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "替换为可行的策略" =>

%%%
tag := "replacing-with-what-works"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[替换为可行的策略]

有一种常见模式：策略涉及一次搜索，但如果搜索成功，我们希望把搜索范围缩小到一个已知可行的具体策略。例如，我们可能想检查某个策略序列能否应用于主目标类型，如果能，就应用一个我们已知可行的具体策略。我们可以用 {lean}`TryThis.addSuggestion` 函数来做到这一点，它在给定的语法节点处添加一条“尝试某个具体策略”的建议。

这里我们使用配方 {ref "checking-tactics"}[检查策略] 中定义的函数，构建一个策略，它检查给定的策略序列能否应用于主目标类型，如果能，就运行该策略，并添加一条建议，提示尝试该序列中第一个成功的策略。

```lean
syntax (name:= check_tactic) "check_tactic?"
  "[" tacticSeq,* "]" : tactic

@[tactic check_tactic] def checkTacticImpl : Tactic :=
  fun stx => withMainContext do
  match stx with
  | `(tactic| check_tactic? [$tacs,*]) =>
    for tac in tacs.getElems do
      let n? ← checkTactic (← getMainTarget) tac
      match n? with
      | some n =>
        if n = 0 then
          TryThis.addSuggestion stx tac
          evalTactic tac
          return
      | none =>
        logWarning m!"Tactic failed"
  | _ => throwUnsupportedSyntax

example : 2 ≤ 20 := by
  check_tactic? [rfl, decide, grind]
```
