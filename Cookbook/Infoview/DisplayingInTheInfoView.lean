import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "在信息视图中显示" =>

%%%
tag := "displaying-in-the-infoview"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[在信息视图中显示]

本配方演示如何在 Lean 信息视图中显示消息，这是元编程时进行调试和向用户提供反馈的一项基本技术。

这里介绍的函数依赖于 {name}`MessageData`，它让你能够记录富文本和表达式。为了方便地构造 {name}`MessageData` 对象，Lean 提供了 `m!` 插值字符串宏，它能把纯文本和 Lean 项无缝组合成信息视图可以渲染的格式。

这些日志函数并不直接接受任意项。要在信息视图中打印某个东西，Lean 必须知道如何把它转换成 {name}`MessageData`，通常是通过 {name}`ToMessageData` 的一个实例。很多情况下这些实例是现成的。例如，一个 {name}`ToFormat` 实例会自然导出一个 {name}`ToMessageData` 实例，而一个 {name}`ToString` 实例又可以用来构造一个 {name}`ToFormat` 实例。

像 {name}`Nat` 这样的内置类型已经有了 {name}`ToMessageData` 实例，所以 ` m!"The number is {42}" ` 开箱即用。对于自定义类型，你需要告诉 Lean 它应该如何在信息视图中显示：

```lean
structure Point where
  x : Nat
  y : Nat

instance : ToMessageData Point where
  toMessageData p :=
    m!"Point({p.x}, {p.y})"

def showPoint : MetaM Unit := do
  let p : Point := { x := 3, y := 5 }
  logInfo m!"Current point: {p}"
```

这里，插值 `{p}` 之所以有效，是因为 {lean}`ToMessageData Point` 实例告诉了 Lean 如何把一个 `Point` 转换成可打印的东西。

# `logInfo`、`logWarning` 与 `logError`

三个主要的日志函数都是单子式的，最常用在 {name}`CoreM`、{name}`MetaM`、{name}`TermElabM` 和 {name}`TacticM` 单子中。

与 {name}`Lean.throwError` 不同，这些日志函数都不会中断或终止执行。它们只是向信息视图发送一条消息，并让程序继续运行。

## {name}`Lean.logInfo`

{index}[`logInfo`]

{name}`logInfo` 在信息视图中显示标准的信息类消息。由于它是单子式的，可以用在策略、命令以及其他精译上下文中。

```lean
def message (msg: String) : MetaM Unit :=
  logInfo m!"Here is the message: {msg}"

#eval message "logInfo worked"
```

下面是一个名为 `readGoal` 的策略示例，它用 {name}`getMainTarget` 获取当前目标的期望类型，然后配合 `m!` 宏使用 `logInfo`，直接在信息视图中漂亮地打印该目标。

```lean
elab "readGoal" : tactic => do
  let goal ← getMainTarget
  logInfo m!"Current goal: {goal}"

example : 2 + 3 = 5 := by
  readGoal
  rfl
```

注意 `m!` 宏如何处理插值表达式：`m!"Current goal: {goal}"` 展开成一个 {name}`MessageData` 对象，其中既包含一个文本部分（`"Current goal: "`），又包含一个表达式部分（漂亮打印后的 `goal`）。{name}`logInfo` 接受这个对象并把它推送到信息视图。

## {name}`Lean.logWarning`

{index}[`logWarning`]

{name}`logWarning` 在信息视图中以黄色显示警告消息。它非常适合用来标记非关键性的问题或边界情况。

```lean
def warningMessage (msg : String) : CoreM Unit := do
  logWarning m!"Warning: {msg}"

#eval warningMessage "something might be wrong"
```

在下面这个策略示例中，如果某个策略把状态拆分成多个目标，我们就用 {name}`logWarning` 提醒用户：

```lean
elab "warnIfMultipleGoals" : tactic => do
  let goals ← getUnsolvedGoals
  if goals.length > 1 then
    logWarning m!"More than one goal left!"

example : ∀ x : Nat, (x = x ↔ x - x = 0) := by
  intro x
  apply Iff.intro
  warnIfMultipleGoals
  · simp
  · simp
```


## {name}`Lean.logError`

{index}[`logError`]

`Lean.logError` 在信息视图中以红色显示错误消息。虽然它会给相关代码标上表示错误的红色波浪线，但并不会中断执行。

```lean
def errorMessage (msg : String) : CoreM Unit := do
  logError m!"Error: {msg}"

/-- error: Error: something went wrong -/
#guard_msgs in
#eval errorMessage "something went wrong"
```

当你想报告一个错误但仍继续处理文件或命令的其余部分时，这尤其有用。例如，`#requireProp` 是一个命令，用来检查给定的项是否具有类型 {lean}`Prop`。如果不是，它会记录一个错误，但仍继续执行并记录该项的表达式：

```lean
elab "#requireProp" t:term : command => do
  Command.liftTermElabM do
    let tExpr ← Term.elabTerm t none
    unless ← isProp tExpr do
      logError m!"Goal must be a proposition: {tExpr}"
    logInfo m!"The expression of the term: {tExpr} "

/--
error: Goal must be a proposition: Nat
---
info: The expression of the term: Nat
-/
#guard_msgs in
#requireProp Nat

/--
error: Goal must be a proposition: Nat → Nat
---
info: The expression of the term: Nat → Nat
-/
#guard_msgs in
#requireProp (Nat → Nat)

#requireProp 2 = 0
```

如果把 {name}`Lean.logError` 换成 {name}`Lean.throwError`，注意其中的差别。由于 {name}`Lean.throwError` 会立即中止执行，当项不是命题时，后面的 {name}`logInfo` 永远不会运行：

```lean
elab "#requireProp" t:term : command => do
  Command.liftTermElabM do
    let tExpr ← Term.elabTerm t none
    unless ← isProp tExpr do
      throwError m!"Goal must be a proposition: {tExpr}"
    logInfo m!"The expression of the term: {tExpr}"

/-- error: Goal must be a proposition: Nat -/
#guard_msgs in
#requireProp Nat

/-- error: Goal must be a proposition: Nat → Nat -/
#guard_msgs in
#requireProp (Nat → Nat)

#requireProp 2 = 0
```
