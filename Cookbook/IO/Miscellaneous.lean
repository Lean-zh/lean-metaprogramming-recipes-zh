import VersoManual
import Cookbook.Lean
import Cookbook.IO.SpawningChildProcess
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "杂项 IO" =>

::: contributors
:::

以下是一些你可能在 Lean 代码中觉得有用的杂项 IO 函数。

# 获取一个随机数

%%%
tag := "get-a-random-number"
number := false
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

你也可以使用 {lean}`IO.Process.forceExit` 派生一个新进程来强制、突然地终止当前进程。

此外，你还可以通过派生一个子进程，用 Linux 的 `kill` 命令（或你机器上对应的版本）并给出目标进程的 PID，来杀掉任何其他进程。

# 文件压缩与解压

%%%
tag := "file-compression-decompression"
number := false
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

# 让任务系统死锁

%%%
tag := "deadlocking-the-task-system"
number := false
%%%

{index}[让任务系统死锁]

::: contributors
:::

这里我们介绍死锁，以及如何避免自己掉进这个陷阱。与其说这是一篇配方，不如说是对盲目派生过多任务的概念性理解。

在此之前，若想了解 {lean}`Task` 的基础，请先查看 {ref "spawning-tasks-and-worker-threads"}[派生任务与工作线程]。

## 什么是死锁？（卡住的比萨店）

想象一家只有 4 位厨师的比萨店。这些厨师就是工作线程，只有他们才能真正做菜。

当所有厨师都因为在互相等待而停止工作时，就发生了*死锁*。设想 4 位顾客点了一份“神秘比萨”。
1. 每位厨师都开始和面。
2. 然后，每位厨师都意识到自己需要另一位厨师做的一种秘制酱料。
3. *错误所在：* 每位厨师不去做其他工作，而是伸着手一动不动地站着，说：“拿不到我的酱料我就不动！”

由于 4 位厨师都站着不动地等着，就没人去真正做酱料了。这家店就永远卡住了。在编程中，我们称之为*线程饿死*（Thread Starvation）。


## 会死锁的代码

在本例中，我们尝试运行 100000 个任务，这会抛出下面所示的错误。由于如今的机器现代化程度更高，具备更强的多线程和多核处理能力，在线程创建停止之前这个数字会更大。

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
当你在一个任务内部调用 {lean}`IO.wait` 时，你是在让工作线程坐下来等待。由于线程数是*有限的*，一旦它们全都“坐着等待”，就没有谁去运行 subTask 了。

## 使用 {lean}`IO.bindTask` 的解决方案（“便利贴”方式）

安全的解决方案是使用*异步组合*。我们不让厨师去等，而是给他一张“便利贴”。

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

- *无需等待：* {lean}`IO.bindTask` 不会让厨师站着不动。它让店经理稍后处理这次交接。
- *线程回收：* 一旦任务的第一部分完成，*工作线程*就会被释放。它可以立即回到线程池去处理下一个任务或子任务。
- *高效：* 这让你即便只有少数几个 CPU 核心，也能处理成千上万个任务，因为没有任何线程会因单纯“坐着等待”而被浪费。

