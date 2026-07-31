import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "并行运行任务" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

在了解 {lean}`Task` 是什么、以及如何派生和处理它们之前，请先查看 {ref "spawning-tasks-and-worker-threads"}[派生任务与工作线程] 这篇配方。

# 并行运行任务

%%%
tag := "running-tasks-in-parallel"
number := false
%%%

{index}[并行运行任务]

任务最强大的用途之一是同时运行多个 {lean}`IO` 操作。由于 {lean}`Task` `α` 是异步计算的一个原语，你可以派生多个任务在后台执行 {lean}`IO`，稍后再等待它们的结果。这让你能够交错不同任务的输出，从而展示并发性。

```lean
def heavyWork (name : String) (iters : Nat) : IO Unit := do
  for i in [0:iters] do
    -- We use a small loop to simulate work
    let mut _x := 0
    for _ in [0:1000] do
      _x := _x + 1
    
    -- Printing acts as a synchronization/yield point
    IO.println s!"{name}: step {i}"

def runParallel : IO Unit := do
  IO.println "Starting heavy work..."

  -- Spawn Task A
  let taskA ← IO.asTask (heavyWork "Task A" 5)
  -- Spawn Task B
  let taskB ← IO.asTask (heavyWork "Task B" 2)

  -- Wait for both to finish
  let _ ← IO.wait taskA
  let _ ← IO.wait taskB
  IO.println "Both tasks finished!"

/-
Task A: step 0
Task B: step 0
Task A: step 1
Task B: step 1
Task A: step 2
Task A: step 3
Task A: step 4
Starting heavy work...
Both tasks finished!
-/
-- #eval runParallel
```

在本例中，A 和 B 的输出交错在一起，说明它们在并发运行。注意即便执行了刷新，“Starting heavy work...” 也是稍后才出现。打印输出时并不是直接写到终端，而是写到一个缓冲区，其他工作线程的输出也是如此。因此，受中断频率和线程调度行为影响，主线程与工作线程的输出顺序可能不同 {margin}[如果你有更好的解释，请分享]。

然而在许多情况下，由于派生了过多线程，你可能会造成死锁。关于派生过多线程时如何避免死锁的更多信息，请查看 {ref "deadlocking-the-task-system"}[任务系统死锁] 一节。
