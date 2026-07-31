import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "进程中断与空闲休眠" =>

%%%
tag := "process-interrupt-idle-sleep"
number := false
htmlSplit := .never
file := "process-interrupt-idle-sleep"
%%%

::: contributors
:::

Lean 4 提供了若干机制来管理并发任务并处理中断。本节探讨如何实现可中断的休眠，以及等待外部信号的“空闲”状态。让进程休眠的方法参见 {ref "sleep-process"}[让进程休眠]。

# 可中断的休眠（“换班”模式）

%%%
tag := "interruptible-sleep-pattern"
number := false
file := "interruptible-sleep-pattern"
%%%

{index}[可中断的休眠]

一个常见需求是让线程休眠一段时间，但允许在时间到期之前被“唤醒”或中断。在 Lean 中，这可以用 {lean}`IO.Promise` 实现，见[参考文档](https://lean-lang.org/doc/reference/latest/IO/Tasks-and-Threads/#The-Lean-Language-Reference--IO--Tasks-and-Threads--Promises)。{lean}`IO.Promise` 是一种同步原语，允许一个线程等待由另一个线程稍后提供的值。在这里，它充当一个“信号”或“信箱”，休眠的线程在其中等待承诺（promise）被兑现，从而让外部触发能够中断这次等待。

## 使用额外的任务（超时任务）

%%%
file := "io-process-interrupt-section-03"
%%%

这种方法会派生一个独立的任务，在延迟后兑现一个承诺。主工作者等待同一个承诺。

```lean
def interruptibleWorker (p : IO.Promise Bool) 
    : IO Unit := do
  IO.println "Worker: starting sleep (10s timeout)..."

  let timeoutTask ← IO.asTask do
    IO.sleep 10000
    -- Resolve with 'false' to indicate timeout
    p.resolve false 

  -- Wait for the promise to be resolved 
  -- (either by timeout or interrupt)
  let interrupted ← IO.wait p.result!

  -- CRITICAL: Cancel the timeout task 
  -- so the process can exit immediately
  IO.cancel timeoutTask

  if interrupted then
    IO.println "Worker: interrupted early!"
  else
    IO.println "Worker: finished naturally (timeout)."
```

## 使用 `IO.waitAny`（逻辑上不需要额外的任务）

%%%
file := "io-process-interrupt-section-04"
%%%

如果你已经有多个任务在运行，并且想等待其中*第一个*完成的（或某个特定的“中断”任务），可以使用 {name}`IO.waitAny`。

```lean
def waitFirst (t1 t2 : Task α) : IO α := do
  IO.waitAny [t1, t2]
```

你也可以用 {name}`IO.waitAny` 实现一个超时机制，让一个计算任务与一个计时器任务竞速。

```lean
/-- Waits for a task to complete or 
  returns a default value after a delay. -/
def waitWithTimeout {α : Type} (action : Task α) 
    (timeoutMs : UInt32) (default : α) : IO α := do
  let timer ← BaseIO.asTask (do 
    IO.sleep timeoutMs
    pure default
  )
  let finished ← IO.waitAny [action, timer]
  return finished
```

# 应用：中断空闲休眠（类操作系统的休眠）

%%%
tag := "idle-sleep-application"
number := false
file := "idle-sleep-application"
%%%

{index}[进程空闲休眠]

“空闲休眠”是这样一种状态：进程什么都不做，消耗极少资源，直到被某个外部事件（如一个信号或一条消息）显式唤醒。

在 Lean 中，你可以通过等待一个没有关联超时任务的承诺来实现它。

```lean
def idleProcess (wakeUpSignal : IO.Promise Unit) 
    : IO Unit := do
  IO.println "Process entering idle state..."
  
  -- This will block indefinitely until 
  -- wakeUpSignal.resolve () is called
  let _ ← IO.wait wakeUpSignal.result!
  
  IO.println "Process woken up! Resuming execution..."

def runSystem : IO Unit := do
  let signal ← IO.Promise.new
  let procTask ← IO.asTask (idleProcess signal)
  
  IO.println "System running... doing other work."
  IO.sleep 3000
  
  IO.println "Main: Triggering wake-up signal."
  signal.resolve ()
  
  let _ ← IO.wait procTask
  IO.println "System shutdown."
```

在这种模式下，“休眠”是真正空闲的；没有计时器在运行。进程只是让出，直到承诺被系统的另一部分兑现。
