import VersoManual
import Cookbook.Lean
import Cookbook.IO.SpawningChildProcess
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "其他 I/O 操作" =>

%%%
file := "io-miscellaneous"
%%%

::: contributors
:::

以下是一些可能有用的 I/O 函数。

# 获取一个随机数

%%%
tag := "get-a-random-number"
number := false
file := "get-a-random-number"
%%%


{index}[获取一个随机数]

你可以使用 {lean}`IO.rand` 函数获取一个下界为 `low`、上界为 `high` 的随机数。

```lean
def getRandomNumber (low high : Nat) : IO Unit := do
  let random ← IO.rand low high
  IO.println s!"Random number between 
    {low} and {high}: {random}"
```

# 终止一个进程

%%%
tag := "terminating-a-process"
number := false
file := "terminating-a-process"
%%%

{index}[终止一个进程]

你可以使用 {lean}`IO.Process.exit` 以某个特定的退出码终止当前进程。按照惯例，退出码 `0` 表示成功，任何非零码都表示错误。

```lean
def terminateProcess (someCondition : Bool) : IO Unit := do
  if someCondition then
    IO.Process.exit 0 -- Success
  else
    IO.println s!"Condition not met. Terminating process..."
    IO.Process.exit 1
```

也可以使用 {lean}`IO.Process.forceExit` 强制立即终止当前进程。

此外，你还可以通过派生一个子进程，用 Linux 的 `kill` 命令（或你机器上对应的版本）并给出目标进程的 PID，来杀掉任何其他进程。

# 文件压缩与解压

%%%
tag := "file-compression-decompression"
number := false
file := "file-compression-decompression"
%%%

{index}[文件压缩与解压]

Lean 没有内置的文件压缩支持，但我们可以轻松调用像 `gzip` 或 `zip` 这样的外部程序来完成这些任务。关于如何从 Lean 运行外部命令的更多信息，参见 {ref "spawning-child-process"}[派生子进程] 配方。

*警告*：由于我们使用的是外部程序，这些都依赖于系统，请确保你的系统上装有所需工具。对于不同的操作系统或压缩格式，请相应地更改命令。

利用上面定义的函数，我们可以轻松执行像压缩文件或创建归档这样的常见系统任务。

1. 使用 `gzip`

`gzip` 命令是单文件压缩的标准工具。

```lean
def compressFile (path : System.FilePath) : IO Unit := do
  let _ ← runExternalProgram "gzip" #["-k", path.toString]
  IO.println s!"Compressed {path}"
```

2. 创建 `.zip` 归档

要归档多个文件或目录，我们可以使用 `zip` 工具。

```lean
def createArchive (archiveName : String) 
    (files : Array String) : IO Unit := do
  let _ ← runExternalProgram "zip" (#[archiveName] ++ files)
  IO.println s!"Created archive {archiveName}"
```

要解压一个 `.zip` 文件，我们可以使用 `unzip` 命令：

```lean
def decompressArchive (archiveName : String) : IO Unit := do
  let _ ← runExternalProgram "unzip" #["-o", archiveName]
  IO.println s!"Decompressed archive {archiveName}"
```

对于任何其他压缩格式，你都可以类似地用 {name}`runExternalProgram` 函数调用相应的命令行工具。

# 读取环境变量

%%%
tag := "reading-environment-variables"
number := false
file := "reading-environment-variables"
%%%


{index}[读取环境变量]

你可以使用 {lean}`IO.getEnv` 获取一个环境变量的值。由于变量可能未被设置，它返回一个 {lean}`Option String`。

```lean
def checkUser : IO Unit := do
  let user? ← IO.getEnv "USER"
  match user? with
  | some name => IO.println s!"Hello, {name}!"
  | none      => IO.println "Could not find USER variable."
```

# 任务系统中的阻塞与资源耗尽

%%%
tag := "deadlocking-the-task-system"
number := false
file := "deadlocking-the-task-system"
%%%

{index}[任务系统中的阻塞与资源耗尽]

::: contributors
:::

这里区分两类容易混淆的并发故障。第一类是任务在有限的工作线程池中互相等待，导致没有线程能够继续执行，这属于死锁或线程饥饿。第二类是一次创建过多任务或底层线程，耗尽操作系统资源。下面的程序可能因运行时和系统限制表现为其中任一种，因此诊断时必须查看实际错误，不能只凭“程序卡住”判断原因。

在此之前，若想了解 {lean}`Task` 的基础，请先查看 {ref "spawning-tasks-and-worker-threads"}[派生任务与工作线程]。

## 什么是死锁？（卡住的比萨店）

%%%
file := "io-miscellaneous-section-07"
%%%

想象一家只有 4 位厨师的比萨店。这些厨师就是工作线程，只有他们才能真正做菜。

当所有厨师都因为在互相等待而停止工作时，就发生了*死锁*。设想 4 位顾客点了一份“神秘比萨”。
1. 每位厨师都开始和面。
2. 然后，每位厨师都意识到自己需要另一位厨师做的一种秘制酱料。
3. *错误所在：* 每位厨师不去做其他工作，而是伸着手一动不动地站着，说：“拿不到我的酱料我就不动！”

由于 4 位厨师都站着不动地等着，就没人去真正做酱料了。这家店就永远卡住了。在编程中，我们称之为*线程饥饿*（thread starvation）。


## 会阻塞或耗尽线程资源的代码

%%%
file := "io-miscellaneous-section-08"
%%%

本例尝试运行 100000 个任务，并在每个任务中等待另一个子任务。实际结果取决于运行时实现和系统资源：程序可能因工作线程全部阻塞而停滞，也可能在创建足够多的底层线程之前就因资源耗尽而失败。下方记录的 `failed to create thread` 属于后一种情况。

```lean
def potentialDeadlock (n : Nat := 100000) : IO Unit := do
  -- We try to start n tasks
  let tasks ← (List.range n).mapM fun i => 
    IO.asTask do
      let subTask ← IO.asTask (pure i)
      
      -- ERROR: IO.wait blocks the Chef (Thread).
      -- If all Chefs are waiting here,
      -- nobody can start the subTask!
      match (← IO.wait subTask) with
      | .ok val => pure (val+1)
      | .error e => throw e

  -- The program will likely hang here forever
  for t in tasks do
    match (← IO.wait t) with
    | .ok res => IO.println s!"Result: {res}"
    | .error e => IO.println s!"Error: {e}"
/-
libc++abi: terminating due to uncaught exception of type
lean::exception: failed to create thread
-/
-- #eval potentialDeadlock
```

*为什么会失败：*
在任务内部调用 {lean}`IO.wait` 会占住当前工作线程等待子任务。如果有限线程池中的线程都这样等待，子任务便得不到执行机会，形成线程饥饿。另一方面，大量创建任务也可能先触发操作系统线程或内存上限；示例中的错误正是资源耗尽。两种故障的修复方向相近：不要为等待而长期占住工作线程，也不要无界地创建并发工作。

## 使用 {lean}`IO.bindTask` 的解决方案（“便利贴”方式）

%%%
file := "io-miscellaneous-section-09"
%%%

针对嵌套等待，更安全的方案是使用*异步组合*。我们不让厨师去等，而是给他一张“便利贴”。

当一位厨师和好面后，写一张便条：“等酱料好了，谁有空谁来把这份比萨做完。”然后这位厨师离开厨房，好让另一位厨师用他的位置去做酱料！

```lean
def safeFromDeadlock (n : Nat := 1000000) : IO Unit := do
  let tasks ← (List.range n).mapM fun i => do
    let t1 ← IO.asTask (pure i)
    
    -- Use bindTask to "chain" the next part.
    -- does NOT block a thread but registers a callback.
    IO.bindTask t1 fun
      | .ok val => IO.asTask (pure (val + 1))
      | .error e => throw e

  -- Now it's safe to wait from the "Outside" (Main Thread)
  for t in tasks do
    match (← IO.wait t) with
    | .ok res => IO.println s!"Result: {res}"
    | .error e => IO.println s!"Error: {e}"

-- No error here, but it will take time since `n` is huge.
-- #eval safeFromDeadlock
```

## 为什么这样更好

%%%
file := "io-miscellaneous-section-10"
%%%

- *无需等待：* {lean}`IO.bindTask` 不会让厨师站着不动。它让店经理稍后处理这次交接。
- *线程回收：* 一旦任务的第一部分完成，*工作线程*就会被释放。它可以立即回到线程池去处理下一个任务或子任务。
- *高效：* 这避免把线程浪费在单纯等待上。不过并发任务本身仍会占用内存和调度资源，实际程序还应限制任务数量。

