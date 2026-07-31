import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "把策略当作快捷方式" =>

%%%
tag := "tactics-as-shortcuts"
number := false
htmlSplit := .never
file := "tactics-as-shortcuts"
%%%

::: contributors
:::


{index}[把策略当作快捷方式]

在配方 {ref "writing-a-macro"}[*编写宏*] 中，我们已经看到如何编写自定义语法以及解析该语法的 `macro`。本配方中，我们将看到如何用 `macro` 编写一个自定义策略。我们先从一个简单例子开始：一个反复应用同一定理直到无法再应用的策略；然后把它推广为一个接受两个定理作为参数、并按特定顺序应用它们的策略。

# 证明自然数不等式的策略

%%%
file := "tactics-tactics-as-shortcuts-section-02"
%%%
{index}[证明自然数不等式的策略]

我们从一个可能会写来证明 `2 ≤ 6` 的常规证明例子开始。

同样或相似的策略模式常常适用于一系列问题。为避免反复输入这段序列，我们可以用 _宏（macro）_ 为该模式创建一个策略。更重要的是，我们可以给这个策略起一个更易记、更易懂的描述性名字。

我们从一个常规证明的例子开始，即 `2 ≤ 6`。
```lean
example : 2 ≤ 6 := by
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_succ_of_le
  apply Nat.le_refl
```

这种做法高度重复。我们可以用 `repeat` 和 `first` 策略组合子来简化它。

```lean
example : 2 ≤ 6 := by
  repeat (first| apply Nat.le_refl |
  apply Nat.le_succ_of_le)
```

为了把它精简成单独一行、易读的形式，我们可以用 `macro` 定义一个自定义策略。

```lean
macro "nat_le" : tactic =>
  `(tactic| repeat(first| apply Nat.le_refl |
    apply Nat.le_succ_of_le))

example: 2 ≤ 6 := by nat_le
```

# 反复应用定理的策略

%%%
file := "tactics-tactics-as-shortcuts-section-03"
%%%
{index}[反复应用定理的策略]

虽然 `nat_le` 对我们的特定情形有效，但我们可以通过对定理进行抽象让它更有用。我们来构造一个带参数的 `macro`，它接受两个定理作为参数。它会反复尝试应用第二个定理（`t₂`）来关闭目标，而每当失败时，就通过应用第一个定理（`t₁`）取得进展。

下面是构造这样一个策略的方法：

```lean
macro "repeat_apply" t₁:term "then" t₂:term : tactic  =>
    `(tactic| repeat(first| apply $t₂| apply $t₁ ))

example : 10 ≤ 12 := by
  repeat_apply Nat.le_succ_of_le then Nat.le_refl
```
