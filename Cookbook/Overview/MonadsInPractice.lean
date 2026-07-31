import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "实践中的单子" =>

%%%
tag := "monads-in-practice"
number := false
htmlSplit := .never
%%%

{index}[实践中的单子]

::: contributors
:::

# 实践中的单子：`MacroM`、`CoreM`、`MetaM`、`TermElabM` 与 `TacticM`

在 Lean 中做元编程，通常都要和所谓的_单子_（monad）打交道。这里不打算解释单子，而是给出相关单子 `MacroM`、`CoreM`、`MetaM`、`TermElabM` 和 `TacticM` 的一个简化的、卡通式的说明。

## 状态单子

这些单子本质上都是_状态_单子的实例。如果 `MyMonadM` 是状态为 `MyMonad.State` 的状态单子，那么大致来说，一个类型为 `MyMonadM α` 的值就是一个函数，它接受一个类型为 `MyMonad.State` 的输入，产生一个类型为 `α` 的输出以及一个类型为 `MyMonad.State` 的新状态。换句话说，我们可以把类型为 `MyMonadM α` 的值看作形如 `MyMonad.State → (α × MyMonad.State)` 的函数。所以在实践中使用这些单子意味着我们可以访问状态（例如策略状态），也可以修改它。通常我们不直接处理状态，而是使用 Lean 提供的各种 API 函数来访问和修改状态。

## 单子层级结构

进一步细化来看，这些单子构成一个层级：_较高_的单子在较低的单子之上，附加了*额外的*状态。于是 `MetaM α` 在 `Core.State` 之外还有状态 `Meta.State`，`TermElabM α` 在 `Meta.State` 和 `Core.State` 之外还有状态 `TermElab.State`。它们之上是 `TacticM α`，它在 `TermElab.State`、`Meta.State` 和 `Core.State` 之外还有状态 `Tactic.State`。所以当我们使用 `TacticM α` 时，可以访问策略状态、项精译状态、meta 状态和 core 状态。当我们使用 `MetaM α` 时，可以访问 meta 状态和 core 状态，但不能访问项精译状态或策略状态。使用较高的单子时，我们可以使用所有较低单子的函数。

当我们只处理 Syntax 时，使用单子 `MacroM α`，它的状态是 `Macro.State`。它不属于上述层级。

在 `CoreM` 单子之下是单子 `IO α`，即输入/输出操作的单子。它不能用于元编程，而是处理副作用，例如读写文件、向控制台打印等等。

## 错误处理、日志及其他功能

除了状态之外，元编程单子还支持错误处理、日志及其他各种操作。

## 读取器单子

单子的部分状态是只读的。技术上这是通过用一个读取器单子扩展状态单子来实现的。
