import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "Hello World 策略" =>

%%%
tag := "hello-world-tactics"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[Hello World 策略]

# 一个基础策略

这是一个什么都不做的极其基础的策略，只是用来展示如何在 Lean 中定义一个策略。注意，我们应当以 {lean}`Lean.Elab.Tactic.withMainContext` 作为策略的开头，以确保该策略在主目标的上下文中执行。

```lean
open Lean Elab Tactic

elab "hello_tactic" : tactic =>
  withMainContext do
  return

example : 1 = 1 := by
  hello_tactic
  rfl
```
