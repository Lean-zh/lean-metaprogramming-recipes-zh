import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "写入文件" =>

%%%
tag := "writing-to-a-file"
htmlSplit := .never
file := "writing-to-a-file"
%%%

::: contributors
:::

# 如何写入文件

%%%
tag := "writing-to-file"
number := false
file := "writing-to-file"
%%%

{index}[写入文件]

在 Lean 中写入文件可以简单地使用 {lean}`IO.FS.writeFile` 函数完成。不过，另一种创建新文件并向其写入字符串的方式是：使用 {lean}`IO.FS.Handle.mk`，以一个字符串路径和 {lean}`IO.FS.Mode.write` 模式创建一个文件句柄，其中该模式表示你想写入文件。`file` 的类型是 {lean}`IO.FS.Handle`，也就是说你拿到的是文件的句柄，可以对它执行各种操作。

要向文件写入字符串，可以对文件句柄使用 {lean}`IO.FS.Handle.putStr` 方法。这会用你提供的字符串覆盖文件的内容。如果文件不存在，则会被创建。

```lean
def writeToFile (path : System.FilePath) (s : String)
    : IO Unit := do
  IO.FS.writeFile path s

-- Another way where you use file handle directly
def writeToFile' (path s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.write
  file.putStr s
```

# 如何向文件追加文本

%%%
tag := "appending-to-file"
number := false
file := "appending-to-file"
%%%

{index}[向文件追加]

要向文件追加文本而不是覆盖它，可以在创建文件句柄时使用 {lean}`IO.FS.Mode.append` 模式。这让你能在文件末尾添加新内容，而不删除已有内容。注意它不会自动添加换行符，你需要自己包含它。

*重要：* `flush` 是必要的，用来确保文件句柄立即把内容写入文件。否则内容可能被缓冲，直到稍后才写入。

```lean
def appendToFile (path s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.append
  file.putStr s
  file.flush

-- Another way
def appendToFile' (path : System.FilePath) (s : String)
    : IO Unit := do
  IO.FS.withFile path IO.FS.Mode.append fun handle =>
    handle.putStr s

```
注意，推荐使用 {lean}`IO.FS.withFile`，因为即便抛出异常，它也能确保句柄被关闭、缓冲区被刷新。


现在如果你想把字符串写在文件开头并保留已有内容，可以先读取已有内容，再写入新字符串，后面接上旧内容。

```lean
def prependToFile (path s : String) : IO Unit := do
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.read
  let oldContent ← file.readToEnd
  let file := ← IO.FS.Handle.mk path IO.FS.Mode.write
  file.putStr (s ++ oldContent)
  file.flush

-- Another way
def prependToFile' (path : System.FilePath) (s : String)
    : IO Unit := do
  let oldContent ← IO.FS.readFile path
  IO.FS.writeFile path (s ++ oldContent)
```

# 重命名文件路径

%%%
tag := "renaming-file-path"
number := false
file := "renaming-file-path"
%%%

{index}[重命名文件路径]

要重命名一个文件路径，可以使用 {lean}`IO.FS.rename` 函数，它接受旧路径和新路径作为参数。

```lean
def renameFile (oldPath newPath : System.FilePath) :
  IO Unit := do
  try 
    IO.FS.rename oldPath newPath
    IO.println s!"Renamed {oldPath} to {newPath}"
  catch e =>
    IO.eprintln s!"Failed to rename {oldPath} to {newPath}:
      Error Found: {e}"
```

