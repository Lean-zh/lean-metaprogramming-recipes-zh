import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.RememberingComputations
import Cookbook.MaintainingState.MutableVariables
import Cookbook.MaintainingState.MutableVarExamples
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes
import Cookbook.MaintainingState.EnvironmentExtensionsAndAttributesExample

open Verso.Genre Manual Cookbook

#doc (Manual) "维护状态" =>

%%%
tag := "state"
number := false
file := "state"
%%%

::: contributors
:::


由于 Lean 是纯函数式编程语言，它没有传统意义上的可变状态。不过，我们可以在不同层面用多种方式维护状态。_状态单子（State Monad）_ 在程序执行期间维护状态，状态可以在函数调用之间传递。_可变变量（Mutable variables）_ 让我们在同一会话的多条命令之间维护状态。最后，通过 _环境扩展（Environment extensions）_，状态还能跨文件、跨会话持久保存。本章给出用这些不同技术维护状态的配方。

*配方：*

{include 1 Cookbook.MaintainingState.RememberingComputations}
{include 1 Cookbook.MaintainingState.MutableVariables}
{include 1 Cookbook.MaintainingState.MutableVarExamples}
{include 1 Cookbook.MaintainingState.EnvironmentExtensionsAndAttributes}
{include 1 Cookbook.MaintainingState.EnvironmentExtensionsAndAttributesExample}
