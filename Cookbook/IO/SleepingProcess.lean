import VersoManual
import Cookbook.Lean
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command Std.Internal.IO.Async Std.Time

set_option pp.rawOnError true

#doc (Manual) "让进程休眠" =>

%%%
tag := "sleeping-process"
htmlSplit := .never
%%%

::: contributors
:::

# 让进程休眠

%%%
tag := "sleep-process"
number := false
%%%


{index}[让进程休眠]

你可以使用 {lean}`IO.sleep` 暂停当前线程。它以*毫秒*为单位接受休眠时长。

```lean
def sleepProcessHello : IO Unit := do
  IO.println "Wait for it..."
  IO.sleep 2000 -- Wait for 2 seconds
  IO.println "Hello Lean!"
```

注意 {lean}`IO.sleep` 对其他 Lean 任务是非阻塞的；它只暂停当前的执行流。

# 异步休眠

%%%
tag := "async-sleep"
number := false
%%%

{index}[异步休眠]

异步休眠基于让出（Yielding）的原理运作。程序不是告诉操作系统“停止这个线程”，而是告诉 Lean 运行时“接下来 N 毫秒我没有事可做。把我当前的执行状态取走保存起来，把这段 CPU 时间给另一个任务。”底层的操作系统线程仍然保持活跃并运行。它会立即查看其他待处理 Lean 任务的队列并开始执行它们。当计时器到期时，原来的任务会被移回“就绪”队列以便恢复。

虽然 {lean}`IO.sleep` 是在任务中暂停的标准方式，但 Lean 的内部库在 `Std.Internal.IO.Async` 中提供了一个更专门化的事件驱动异步 I/O 框架。在这个框架内，{lean}`Std.Internal.IO.Async.sleep` 用于暂停执行而不阻塞任务管理器的线程池。
这个框架是事件循环（Event Loop）的一个实现。它被设计为使用少量固定数目的操作系统线程（通常等于 CPU 核心数）来处理成千上万个并发操作（如网络请求或计时器）。

```lean
/-- 
  Computes the sum of first n numbers.
  This represents the "Work" the agent does after waking up.
--/
def sumFirstN (n : Nat) (acc : Nat := 0) : Nat :=
  match n with
  | 0 => acc
  | n + 1 => sumFirstN n (acc + (n + 1))

/--
  A helper to print the current Process ID. 
  This confirms we are in the same OS process.
--/
def printSystemIdentity (label : String) : IO Unit := do
  let pid ← IO.Process.getPID
  -- If you want to check thread ID,
  -- let tid ← IO.getTID
  IO.println s!"[{label}] PID: {pid}"

/--
  The Enhanced Async Sleeper.
  It performs: 1. Identity Check -> 2. Async Sleep 
  -> 3. Computation -> 4. Identity Check
--/
def persistentAsyncSleeper (n : Nat) : IO Unit := do
  IO.println "[Sleeper] --- Phase 1: Pre-Sleep ---"
  printSystemIdentity "Sleeper-Start"
  
  let duration := Millisecond.Offset.ofInt 2000
  let computation : Async Unit := do
    -- This block runs inside the Async context
    Std.Internal.IO.Async.sleep duration
    -- After waking up, perform the computation
    let total := sumFirstN n
    IO.println s!"[Sleeper] Computation Complete: 
      Sum of 1 to {n} = {total}"

  -- Execute the async block
  computation.block
  
  IO.println "[Sleeper] --- Phase 2: Post-Sleep ---"
  printSystemIdentity "Sleeper-End"
  -- now returns to taskPulse task

/--
  A Concurrent Worker (taskPulse) to prove 
  the thread pool is active.
--/
def taskPulse (iterations : Nat) : IO Unit := do
  for i in [0:iterations] do
    IO.println s!"[taskPulse] Pulse {i+1}..."
    printSystemIdentity s!"taskPulse-Loop-{i+1}"
    IO.sleep 500 -- Sleep for 500ms

def asyncSleepEg : IO Unit := do
  IO.println "Starting Async Workflow..."

  -- Spawn the taskPulse as a background Task
  let hTask ← IO.asTask (taskPulse 6)

  -- Run our sleeper/computer on the main execution path
  persistentAsyncSleeper 10000
  
  -- Synchronize
  let _ ← IO.wait hTask
  IO.println "Workflow Finished."

/-
Starting Async Workflow...
[Sleeper] --- Phase 1: Pre-Sleep ---
[Sleeper-Start] PID: 59432
[taskPulse] Pulse 1...
[taskPulse-Loop-1] PID: 59432
[taskPulse] Pulse 2...
[taskPulse-Loop-2] PID: 59432
[taskPulse] Pulse 3...
[taskPulse-Loop-3] PID: 59432
[taskPulse] Pulse 4...
[taskPulse-Loop-4] PID: 59432
[Sleeper] Computation Complete: Sum of 1 to 10000 = 50005000
[Sleeper] --- Phase 2: Post-Sleep ---
[Sleeper-End] PID: 59432
[taskPulse] Pulse 5...
[taskPulse-Loop-5] PID: 59432
[taskPulse] Pulse 6...
[taskPulse-Loop-6] PID: 59432
Workflow Finished.
-/
-- #eval asyncSleepEg
```

你可能注意到例子中使用了 `.block`。它有什么作用？

- *局部阻塞与全局阻塞：* `computation.block` 会执行当前的任务，但它不会阻塞底层的操作系统线程。

- *事件循环：* 当你对一个 {lean}`Async` 对象调用 `.block` 时，本质上是在告诉 Lean 运行时：“我要坐在这里等待这个特定的结果。与此同时，用我的线程去运行队列中任何其他任务。”由于这个异步线程进入了休眠，在它休眠结束并让出控制权（通过一次中断）之后，原来的任务会继续，计算前 N 个数的和；完成后返回到 {lean}`taskPulse` 任务并把它完成。

*如果线程没有被阻塞，那是谁在唤醒休眠中的任务？*

一个任务无法进入操作系统的等待队列。运行时改用 `epoll` 把计时器委托给操作系统内核，由内核充当全局计时器。当 {lean}`Task` 被移入运行时内存中的一个逻辑等待队列时，操作系统线程仍未被阻塞，可以自由地轮转去处理其他待办工作。注意 *tid* 可能不同，但 *pid* 一定保持不变。
