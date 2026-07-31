import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std Lean Meta Elab Tactic

set_option pp.rawOnError true

#doc (Manual) "环境扩展与属性：示例" =>

%%%
tag := "environment-extensions-and-attributes-example"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[环境扩展与属性：示例]

在配方 {ref "environment-extensions-and-attributes"}[环境扩展与属性] 中，我们定义了一个环境扩展来存储带 `@[distribute]` 属性标记的引理，定义了 `@[distribute]` 属性把引理添加到这个环境扩展中，并实现了 `distribute` 策略，它从环境扩展中取出这些引理并应用它们。

在本配方中，我们展示如何使用 `@[distribute]` 属性和 `distribute` 策略。我们无法在初始化属性的同一个文件中标记或使用属性，因此不得不把代码拆成两个文件。在本文件中，我们给一些引理标记 `@[distribute]` 属性，然后用 `distribute` 策略应用这些引理。

```lean
open Distribute

@[distribute]
theorem distributeAnd (a b c : Prop) :
    (a ∧ (b ∨ c)) ↔ (a ∧ b) ∨ (a ∧ c) := by
  grind

example : (1 = 1) ∧ (2 = 3 ∨ 3 = 3) := by
  distribute
  grind
```

我们也可以给来自导入模块的定义或定理标记 `@[distribute]` 属性，它们会被添加到环境扩展中，并被 `distribute` 策略使用。

```lean
attribute [distribute] Nat.mul_add

example (a b c : Nat) : a * (b + c) = a * b + a * c := by
  distribute
```
