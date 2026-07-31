import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "派生子进程" =>

%%%
tag := "spawning-a-child-process"
htmlSplit := .never
file := "spawning-a-child-process"
%%%

::: contributors
:::


# 派生子进程

%%%
tag := "spawning-child-process"
number := false
file := "spawning-child-process"
%%%

{index}[派生子进程]

要从 Lean 文件内部运行一个外部程序，我们可以使用 {lean}`IO.Process.run`，它接受一个 {lean}`IO.Process.SpawnArgs` 结构体，并以 {lean}`String` 的形式返回该命令的 stdout。关于可用选项的更多细节，你可以在 Lean4 参考手册中查阅 [IO.Process.SpawnArgs](https://lean-lang.org/doc/reference/latest/IO/Processes/#IO___Process___SpawnArgs___mk)。

```lean
def runExternalProgram (cmd : String) (args : Array String)
    : IO String :=
  IO.Process.run {
    cmd := cmd
    args := args
  }

-- #eval runExternalProgram "curl" #["https://www.test.com"]
```

如果程序失败（返回非零退出码），{lean}`IO.Process.run` 会抛出异常。要更优雅地处理输出并查看退出码和 stderr，可以使用 {lean}`IO.Process.output`。

```lean
def runExternalWithOutput (cmd : String)
    (args : Array String) : IO Unit := do
  let out ← IO.Process.output {
    cmd := cmd
    args := args
  }
  if out.exitCode == 0 then
    IO.println s!"Command succeeded: {out.stdout}"
  else
    IO.println s!"Command failed. Exit Code: {out.exitCode},
      Error: {out.stderr}"
```

如果你想了解进程的更多信息，例如它的 PID，可以使用 {lean}`IO.Process.spawn` 启动进程并获得一个 `IO.Process` 对象。

```lean
def spawnExternalProgram (cmd : String) 
    (args : Array String) : IO Unit := do
  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
  }
  IO.println s!"Spawned process with PID: {proc.pid}"
  let exitCode ← proc.wait
  IO.println s!"Process exited with code: {exitCode}"

-- #eval spawnExternalProgram "touch" #["test.txt"]
```

## 获取进程的 PID

%%%
tag := "get-pid-process"
number := false
file := "get-pid-process"
%%%

{index}[获取进程的 PID]

要获取你派生的进程的 PID，可以使用 {lean}`IO.Process.Child.pid` 方法。

```lean
def getProcessInfo (cmd : String) (args : Array String) 
  : IO Unit := do
  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
  }
  -- for current process
  let cpid ← IO.Process.getPID
  IO.println s!"Current Process PID: {cpid}"
  IO.println s!"Child Process PID: {proc.pid}"
```

要检查一个子进程是否仍在运行，可以使用 {lean}`IO.Process.Child.tryWait` 方法。


# 为子进程设置环境变量

%%%
tag := "setting-environment-variables-child-process"
number := false
file := "setting-environment-variables-child-process"
%%%

{index}[为子进程设置环境变量]

你可以在派生新子进程时设置环境变量来配置它的环境。记住，无法改变当前进程的环境，因为它已经在运行。

使用 [{lean}`IO.Process.SpawnArgs`](https://lean-lang.org/doc/reference/latest/IO/Processes/#IO___Process___SpawnArgs___mk) 时，可以传入一个 `env` 数组来为新进程指定变量。

```lean
def runWithCustomEnv : IO Unit := do
  let child ← IO.Process.spawn {
    cmd := "printenv",
    args := #["MY_VAR"],
    env := #[("MY_VAR", "1234")]
  }
  let exitCode ← child.wait
  IO.println s!"Process exited with code: {exitCode}"
```

这样就能确保 `MY_VAR` 对子进程可用，同时不影响父进程的环境。
