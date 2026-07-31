import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "创建目录" =>

%%%
tag := "creating-directories"
number := false
file := "creating-directories"
%%%

::: contributors
:::

{index}[创建目录]

要创建目录，我们使用 {name}`IO.FS.createDir`
模块中的函数。它会在指定路径创建单个目录。如果
父目录不存在，它会抛出错误。

```lean
def createDirectory (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDir path
    IO.println s!"Directory '{path}' created successfully."
  catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

/-- Another way is to check for existance
  before creating the directory. -/
def safeCreateDir (path : System.FilePath) : IO Unit := do
  if ← path.pathExists then
    if ! (← path.isDir) then
      throw <| IO.userError s!"Path '{path}' 
      already exists and is not a directory."
    else
      IO.println s!"Directory '{path}' already exists."
  else
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."

```

如果你想在创建目录的同时创建任何必要的父目录，
可以使用 {name}`IO.FS.createDirAll`。如果路径中指定的整个目录
结构尚不存在，它会创建出来。

```lean
def createSubDirAll (path : System.FilePath) : IO Unit := do
  try
    IO.FS.createDirAll path
    IO.println s!"Directory '{path}' created successfully."
catch e =>
    IO.println s!"Failed to create directory '{path}': {e}"

-- Useful Tip: String value also works here
-- #eval createSubDirAll "testDir/subDir"
```

注意，尽管这些函数期望的是 {name}`System.FilePath`，{lean}`String`（如 `"testdir/subdir"`）也能用。这是因为 Lean 有一个
*强制转换*（coercion，即一个 {lean}`Coe String System.FilePath` 实例），
它在需要时自动把字符串字面量转换为文件路径对象。更多信息参见[这里的 Coercions](https://lean-lang.org/doc/reference/latest/Coercions/#coercions)。
 
