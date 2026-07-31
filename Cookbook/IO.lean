import VersoManual
import Cookbook.Lean
import Cookbook.IO.HandlingStdStreams
import Cookbook.IO.CliArgs
import Cookbook.IO.TimePerformanceMeasure
import Cookbook.IO.SleepingProcess
import Cookbook.IO.ProcessInterrupt
import Cookbook.IO.Miscellaneous
import Cookbook.IO.SpawningChildProcess
import Cookbook.IO.RunningTasksInParallel
import Cookbook.IO.SpawningTasks

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "I/O 与进程" =>

%%%
tag := "io"
number := false
%%%

::: contributors
:::


{index}[I/O 与进程]

本章覆盖 Lean 中与 I/O、进程、线程和并发相关的多个主题。Lean 对并发运行任务有很好的支持，并提供了强大的 API 来处理 I/O 操作。我们使用 {lean}`IO` 单子（monad）来执行这些操作。

在 Lean 中，理解进程、线程和任务之间的区别很重要。当你派生一个子进程时，Lean 给你一个指向该操作系统进程的句柄。当你派生一个内部计算时，Lean 给你一个 {lean}`Task`。因此 {lean}`Task` 不是操作系统层面可调度的实体。

*配方：*

{include 1 Cookbook.IO.HandlingStdStreams}
{include 1 Cookbook.IO.CliArgs}
{include 1 Cookbook.IO.SpawningChildProcess}
{include 1 Cookbook.IO.SpawningTasks}
{include 1 Cookbook.IO.RunningTasksInParallel}
{include 1 Cookbook.IO.SleepingProcess}
{include 1 Cookbook.IO.ProcessInterrupt}
{include 1 Cookbook.IO.TimePerformanceMeasure}
{include 1 Cookbook.IO.Miscellaneous}
