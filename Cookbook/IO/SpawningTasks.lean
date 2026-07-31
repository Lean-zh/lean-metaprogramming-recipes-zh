import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "派生任务与工作线程" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

# 派生任务与工作线程

%%%
tag := "spawning-tasks-and-worker-threads"
number := false
%%%


{index}[派生任务与工作线程]

Lean 4 通过 {lean}`Task` 支持轻量级并发。你可以派生任务在后台执行 {lean}`IO`，稍后再等待它们的结果。{lean}`Task` `α` 是异步计算的一个原语。它表示一个最终会归结为 `type α` 类型值的计算，这个计算可能在另一个线程上进行。

关于 {lean}`Task` API 的信息，请查阅 Lean 4 参考手册的 [任务与线程](https://lean-lang.org/doc/reference/latest/IO/Tasks-and-Threads) 一节。


## 派生一个任务

如果你有一个非常繁重的纯计算，可以使用 {lean}`Task.spawn` 在不借助 {lean}`IO` 单子的情况下并行运行它。如前所述，当派生一个 {lean}`Task` `α` 时，它会给你一个 `α` 类型的输出。每个 {lean}`Task` `α` 由 Lean 派生的一个工作线程完成。

```lean
def computeSomething : Nat :=
  let t := Task.spawn (fun _ => 2 + 2)
  t.get
```

## 派生后台任务

%%%
tag := "spawning-background-task"
number := false
%%%


对于除计算之外还有副作用的任务，你应当使用 {lean}`IO.asTask` 在后台线程中运行一个 {lean}`IO` 动作。它返回一个 {lean}`Task`，最终会包含结果（包裹在 {lean}`Except` 中）。这些任务是异步的，会自动在后台运行。

```lean
def backgroundWork : IO Unit := do
  let task ← IO.asTask do
    for i in [1:5] do
      IO.println s!"Working... {i}"
      for _ in [1:10000] do
        -- Simulate heavy computation
        continue
    IO.println "Background task finished!"
    return "Result Data"
  
  IO.println "Doing other things in the main thread..."

  -- Wait for the task to complete and get the result
  match (← IO.wait task) with
  | .ok val => IO.println s!"Task returned: {val}"
  | .error e => IO.eprintln s!"Task failed with error: {e}"

/-
Working... 1
Working... 2
Working... 3
Working... 4
Background task finished!
Doing other things in the main thread...
Task returned: Result Data
-/
-- #eval backgroundWork
```

## 任务状态

你可以使用 {lean}`IO.TaskState` 检查一个任务是否仍在运行。它会告诉你任务是仍在运行、等待运行还是已经完成。注意 {lean}`Task` 不是进程也不是线程，因此你不能用 {lean}`IO.TaskState` 检查子进程的状态。

```lean
def monitorTask (task : Task α) : IO String := do
  let state ← IO.getTaskState task
  return match state with
    | .waiting  => "Task is still waiting."
    | .running  => "Task is currently running."
    | .finished => "Task has finished."

def checkTaskStatus : IO Unit := do
  -- Create a task that runs asynchronously
  let task ← IO.asTask (do
    IO.sleep 2000
    pure "Success"
  )
  
  let s1 ← monitorTask task
  IO.println s1 
  -- Wait for the task's internal timer to expire
  IO.sleep 2500
  -- Check again after completion
  let s2 ← monitorTask task
  IO.println s2

/-
Task is still waiting.
Task has finished.
-/
-- #eval checkTaskStatus
```

你可以使用 {lean}`IO.getTID` 获取当前线程的线程 ID，关于如何获取一个进程的线程 ID 的更多信息，请查看 {ref "get-thread-ids"}[获取线程 ID]。

## *IO.asTask* 与 *BaseIO.Task*

%%%
tag := "io-baseio-astask"
number := false
%%%

{index}[IO.asTask 与 BaseIO.asTask]

{lean}`IO.asTask` 为可能失败的操作创建任务，把结果包裹在一个 {lean}`Except IO.Error` 盒子中；而 {lean}`BaseIO.asTask` 用于保证不会出错的逻辑，直接返回原始值。

基本上，如果你想使用 {name}`throw`、{lean}`IO.userError` 等，{lean}`IO.asTask` 能帮你更好地处理，而 {lean}`BaseIO.asTask` 不能。因此你必须做适当的错误处理来提取值或显示错误。但如果你确信你的 {lean}`Task` 一定会成功、只需要直接拿到原始值，那么可以使用 {lean}`BaseIO.asTask`。

```lean
/-- A division which fails in IO monad if d is 0 -/
def realDiv (n d : Int) : IO Int := do
  if d == 0 then 
    throw (IO.userError "Error: Division by zero detected!")
  else 
    pure (n / d)

-- Using IO.asTask
-- This is designed to catch the error.
def computeWithIO : IO Unit := do
  let task ← IO.asTask (realDiv 10 0)
  -- wait returns Except IO.Error Int
  -- because realDiv is IO
  let result ← IO.wait task 
  IO.println s!"IO.asTask result: {result}"

-- Using BaseIO.asTask
-- This cannot run realDiv directly because
-- realDiv is not BaseIO. Hence we use pure
def computeWithBaseIO : IO Unit := do
  let task ← BaseIO.asTask (pure (10 / 0))
  -- wait returns Int directly
  let result ← IO.wait task
  IO.println s!"BaseIO.asTask result: {result}"

#eval computeWithIO
#eval computeWithBaseIO
```


# 获取线程 ID

%%%
tag := "get-thread-ids"
number := false
%%%

{index}[获取线程 ID]

为了执行任何 {lean}`Task`，Lean 会为同一进程派生工作线程来并行执行任务。因此同一进程可以有多个线程在运行。由于这些都是异步任务，输出也可能以任意顺序出现。{lean}`Task` 的执行被调度在一个有界的工作线程池上，因此它不一定总是由一个独立的工作线程完成。

本例说明每个 {lean}`Task` 都由各自独立的工作线程运行，因此有不同的 TID 但相同的 PID。你可以用 {lean}`IO.getTID` 获取线程 ID。


```lean
/- 
All will share the same PID but likely report distinct TIDs.
-/
def showWorkerThreadInfo : IO Unit := do
  let pid ← IO.Process.getPID
  IO.println s!"Main Process PID: {pid}"

  -- Create a list of 4 asynchronous tasks
  let tasks ← (List.range 4).mapM fun i => 
    IO.asTask do
      let tid ← IO.getTID
      IO.println s!"Task {i} has TID: {tid} (PID: {pid})"

  -- Wait for all tasks to complete
  for t in tasks do
    let _ ← IO.wait t

  IO.println s!"For the main thread, 
    TID: {← IO.getTID} (PID: {pid})"

/-
Task 1 has TID: 348178 (PID: 23379)
Task 0 has TID: 348148 (PID: 23379)
Task 2 has TID: 348177 (PID: 23379)
Task 3 has TID: 348179 (PID: 23379)
Main Process PID: 23379
For the main thread, TID: 348175 (PID: 23379)
-/
-- #eval showWorkerThreadInfo
```


