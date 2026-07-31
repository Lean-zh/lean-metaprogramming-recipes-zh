import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "列出目录" =>

%%%
tag := "listing-a-directory"
htmlSplit := .never
file := "listing-a-directory"
%%%

::: contributors
:::

# 列出目录的内容

%%%
tag := "list-directory"
number := false
file := "list-directory"
%%%

{index}[列出目录的内容]

要列出一个目录的内容，我们对一个 {lean}`System.FilePath` 使用 {lean}`System.FilePath.readDir` 方法。
它返回一个 {lean}`Array IO.FS.DirEntry`，其中包含
关于每个文件和子目录的信息。

```lean
def listDirectory (path : System.FilePath) : IO Unit := do
  let entries ← path.readDir
  for entry in entries do
    IO.println entry.fileName
```

每个 {lean}`IO.FS.DirEntry` 都包含 `fileName`（文件或
目录本身的名称）及其完整的 `path`。

# 递归遍历目录

%%%
tag := "recursive-directory-traversal"
number := false
file := "recursive-directory-traversal"
%%%

{index}[递归遍历目录]
{index}[遍历目录树]

如果你想递归地列出一个目录树中的所有文件，可以使用
{lean}`System.FilePath.walkDir` 方法。

*注*：你可以用 {lean}`System.FilePath.isDir` 方法检查一个条目是否是目录。

```lean
def listAllFiles (path : System.FilePath) : IO Unit := do
  let allFiles ← path.walkDir
  for file in allFiles do
    IO.println file
```

## 遍历时进行过滤

%%%
file := "file-system-list-directory-section-04"
%%%

{lean}`System.FilePath.walkDir` 接受一个可选的 `enter` 参数——一个函数，
用来决定是否递归进入某个给定的子目录。这对于
跳过像 `.git` 或 `.lake` 这样庞大或无关的文件夹很有用。

```lean
def listSourceFiles (path : System.FilePath) : IO Unit := do
  /- Only enter directories that aren't
    hidden or build artifacts -/
  let filter (p : System.FilePath) : IO Bool := do
    let name := p.fileName.getD ""
    return name != ".git" && name != ".lake"

  let files ← path.walkDir (enter := filter)
  for f in files do
    -- Only print files with the .lean extension
    if f.extension == some "lean" then
      IO.println f
```
