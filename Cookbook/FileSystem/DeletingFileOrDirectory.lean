import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "删除文件或目录" =>

%%%
htmlSplit := .never
file := "file-system-deleting-file-or-directory"
%%%

::: contributors
:::

# 如何删除文件

%%%
tag := "deleting-a-file"
number := false
file := "deleting-a-file"
%%%

{index}[删除文件]

你可以使用 {lean}`IO.FS.removeFile` 函数删除一个文件。它返回
一个 {lean}`IO Unit`，也就是说它执行删除文件的动作，但
不返回任何值。

```lean
def deleteFile (path : String) : IO Unit := do
  try
    IO.FS.removeFile path
    IO.println s!"File {path} deleted successfully."
  catch e =>
    IO.println s!"Failed to delete file {path}: {e}"
```
# 如何删除目录

%%%
tag := "delete-a-directory"
number := false
file := "delete-a-directory"
%%%

{index}[删除目录]

你可以使用 {lean}`IO.FS.removeDir` 函数删除一个空目录。
如果你想删除目录内的所有内容，
请使用 {lean}`IO.FS.removeDirAll`。

```lean
def deleteEmptyDir (path : String) : IO Unit := do
  IO.FS.removeDir path

def deleteDir (path: String) : IO Unit := do
  IO.FS.removeDirAll path
```

关于这里为什么 {lean}`String` 能当作文件路径使用，请参阅 {ref "creating-directories"}[创建目录] 一节的末尾了解更多。
