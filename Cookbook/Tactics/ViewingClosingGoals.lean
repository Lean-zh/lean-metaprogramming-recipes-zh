import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "查看与关闭目标" =>

%%%
tag := "viewing-closing-goals"
number := false
htmlSplit := .never
file := "viewing-closing-goals"
%%%

::: contributors
:::


{index}[查看与关闭目标]

策略可以用多种方式处理目标。它们可以检查目标、修改目标，甚至关闭目标。本节我们探讨如何用精译器编写查看和关闭目标的策略。

在上一个 {ref "tactics-as-shortcuts"}[配方] 中，我们看到了如何用宏把一段语法展开成另一段语法来构建策略。本配方中，我们用精译器编写策略，它让我们能够构造表达式，还让我们能访问大量信息，包括目标状态。

# 打印主目标的策略

%%%
tag := "tactic-to-print-the-main-goal"
number := false
htmlSplit := .never
file := "tactic-to-print-the-main-goal"
%%%
{index}[打印主目标的策略]

我们先编写一个基础的精译器，它取出并显示表示主目标类型的表达式。

```lean
elab "goalExpr" : tactic => do
  let goalExpr ← getMainTarget
  logInfo m!"Main Target Expression: {goalExpr}"

example: 2 + 3 = 5 := by
  goalExpr
  simp
```
关于如何在信息视图（Infoview）中使用字符串格式化，参见 {ref "displaying-in-the-infoview"}[在信息视图中显示内容]。

# 关闭目标：自定义的 `sorry` 策略

%%%
file := "tactics-viewing-closing-goals-section-03"
%%%

接下来说明如何用精译器关闭目标。我们将实现一个定制版的 `sorry` 策略，它不仅关闭目标，还会向信息视图记录一条自定义消息。

如果你用 Lean 形式化数学，你很可能熟悉 `sorry` 策略。我们经常把它当作尚未写出的证明的占位符。`sorry` 策略关闭当前主目标，但会在信息视图中留下一条警告。

```lean
example : 847 + 153 = 1000 := by sorry
```

在底层，`sorry` 策略的工作方式是用 [`sorryAx`](https://lean-lang.org/doc/reference/latest/Axioms/?terms=sorryAx#standard-axioms) 公理创建一个主目标类型的项。我们可以直接查看这个内部组件：

```lean
#check sorryAx
-- sorryAx.{u} (α : Sort u) (synthetic :  Bool) : α
```

现在，我们用 `elab` 和 `sorryAx` 编写一个名为 `toDo` 的自定义策略。`toDo` 策略会像 `sorry` 一样关闭主目标，但它还接受一个字符串参数，用来向信息视图记录一条自定义提醒。

```lean
elab "toDo" s: str : tactic => do
  withMainContext do
    logInfo m!"Message:{s}"
    let targetExpr ← getMainTarget
    let sorryExpr ←
      mkAppM ``sorryAx #[targetExpr, mkConst ``false]
    closeMainGoal `toDo sorryExpr

example : 34 ≤ 47 := by
  toDo "This should be easy to do"
```

我们逐一分析实现这一功能所用到的具体元编程函数：

- {lean}`getMainTarget` 取出当前主目标类型的表达式。
- {lean}`mkAppM` 构造函数应用表达式。它接受函数的 `Name`（这里是 `sorryAx`），以及一个由待传入参数的表达式组成的数组。
- {lean}`closeMainGoal` 用我们构造的表达式关闭当前主目标。

这个例子展示了基于精译器的策略的基本模式：检查当前目标，构造一个正确类型的表达式，并用它更新证明状态。
