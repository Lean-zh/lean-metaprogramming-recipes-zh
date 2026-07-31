import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Term Parser
open Category hiding grind


set_option pp.rawOnError true

#doc (Manual) "为命令添加语法" =>

%%%
tag := "adding-syntax-for-command"
number := false
htmlSplit := .never
%%%

::: contributors
:::


{index}[为命令添加语法]

Lean 允许你为 {name}`command` 定义自定义语法。和项一样，这既可以用 `macro` 以简单的方式完成，也可以用 `elab` 以更复杂的方式完成。`elab` 的方式更强大，因为它允许你从语法生成表达式，并在精译（elaboration）过程中执行检查。本配方展示如何用 `elab` 为命令定义自定义语法，它让你在同一处同时指定语法及其精译。

# “Hello World” 命令

%%%
tag := "hello-world-command"
number := false
%%%


{index}[“Hello World” 命令]

我们从一个简单的例子开始：一个打印 "Hello World" 的命令。下面的 `elab` 声明告诉 Lean 把 `#helloWorld` 解析为一个命令，并说明该命令应当做什么。

```lean
elab "#helloWorld" : command => do
    logInfo "Hello World!"

#helloWorld
```
这里，`logInfo s` 会在 InfoView 中打印字符串 `s`。

# 检查某个命题是否能被 grind 解决的命令

%%%
tag := "command-for-checking-whether-a-proposition-is-solved-by-grind"
number := false
%%%

{index}[检查某个命题是否能被 grind 解决的命令]
我们定义一个自定义命令，用来测试某个命题能否被 {name}`grind` 策略自动解决。目标是提供一个小巧的命令行风格工具，报告 {name}`grind` 能否关闭一个目标。

同样，我们可以直接用 `elab` 定义该命令。在下面的声明中，Lean 把形如 `#grindable? <term>` 的输入解析为一个命令，精译器则说明该命令应如何行为。

```lean
elab "#grindable?" t:term : command => do
    Command.liftTermElabM do
      try
        withoutErrToSorry do
          let tExpr ← elabTerm t none
          let goal ← mkFreshExprMVar tExpr
          Term.synthesizeSyntheticMVarsNoPostponing
          let (goals,_) ← Elab.runTactic goal.mvarId!
                                (← `(tactic|grind))
          if goals.isEmpty then
            logInfo m!"{t} is grindable"
          else
            logInfo m!"grind failed with goals: {goals}"
      catch _ =>
        logInfo m!"{t} is not grindable"

#grindable? ∀ n : Nat, n + 0 = n -- grindable
#grindable? ∃ x : Nat, x > 100 -- not grindable
```

我们逐一分析上面精译器中用到的具体元编程函数：
- 需要调用 {name}`Command.liftTermElabM`，因为命令精译发生在 {name}`CommandElabM` 单子中，而精译项和运行策略用的是 {name}`TermElabM` 单子里的项精译机制。
- Lean 的精译器有时会把精译错误转成 sorry。{name}`withoutErrToSorry` 阻止这种转换，从而让我们能捕获精译过程中抛出的异常。
- 我们写一个 `try … catch` 块，并把 {name}`withoutErrToSorry` 放在 `try` 块内部。
- {name}`Lean.Elab.Term.elabTerm` 把用户提供的命题（即 `t`）精译成一个表达式。
- 然后 {name}`mkFreshExprMVar` 创建一个新的元变量目标，其类型由一个表达式给出（即 `tExpr`）。
- {name}`Elab.runTactic` 在这个新目标上运行策略 {lean}`grind`，返回一个类型为 {lean}`List MVarId × Term.State` 的元组。在本例中，第一个分量恰好是 {name}`grind` 之后仍未关闭的目标列表，第二个分量是 {name}`TermElabM` 单子的更新后状态，我们用 `_` 忽略它。
- 最后，我们检查剩余的目标。如果列表为空，说明 `grind` 完整地证明了该命题。

如果你更愿意把语法声明与精译逻辑分开，Lean 也允许你先用 `syntax` 定义语法，再用 `elab_rules` 添加精译规则。

```lean
syntax "#grindable'?" term : command

elab_rules : command
|`(command| #grindable'? $t:term ) => do
    Command.liftTermElabM do
      try
        withoutErrToSorry do
          let tExpr ← elabTerm t none
          let goal ← mkFreshExprMVar tExpr
          Term.synthesizeSyntheticMVarsNoPostponing
          let (goals,_) ← Elab.runTactic goal.mvarId!
                                (← `(tactic|grind))
          if goals.isEmpty then
            logInfo m!"{t} is grindable"
          else
            logInfo m!"grind failed with goals: {goals}"
      catch _ =>
        logInfo m!"{t} is not grindable"

```

`elab_rules` 命令让我们通过对解析出的命令语法进行模式匹配来定义精译规则。两种风格都有用：直接的 `elab` 形式通常是紧凑的一次性命令的良好起点，而 `syntax` 加 `elab_rules` 则在你想更明确地把解析器和精译器分开时更有帮助。
