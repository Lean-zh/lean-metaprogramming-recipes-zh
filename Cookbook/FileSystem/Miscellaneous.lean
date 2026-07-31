import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "其他文件系统操作" =>

::: contributors
:::

以下是一些处理文件路径时可能有用的文件系统操作。

# 如何拼接文件路径

%%%
tag := "concatenating-file-paths"
number := false
%%%

{index}[拼接文件路径]

要拼接文件路径，可以使用 {lean}`System.FilePath` 模块。你可以用 {lean}`System.mkFilePath` 创建一个文件路径，然后用 `/` 运算符把它与另一个路径拼接起来：

```lean
def concatPaths (base : System.FilePath) (sub : String)
  : System.FilePath := base / System.mkFilePath [sub]

#eval concatPaths (System.mkFilePath ["home", "user"]) "dir"
#eval System.mkFilePath ["home", "user"] 
  / System.mkFilePath ["dir"]
```

这个对象你可以像平常一样使用，因为新路径仍然是一个 {lean}`System.FilePath` 对象。

# 如何获取当前工作目录

%%%
tag := "getting-current-working-directory"
number := false
%%%


{index}[获取当前工作目录]

为了获取当前工作目录（cwd），我们可以使用 {lean}`IO.currentDir` API。

```lean
def getCurrentWorkingDirectory : IO Unit := do
  let mut cwd ← IO.currentDir
  IO.println s!"Current working directory: {cwd}"
```

# 检查路径的元数据

%%%
tag := "checking-metadata-for-path"
number := false
%%%

{index}[检查路径的元数据]
{index}[检查文件大小]

要检查一个路径的元数据，可以使用 {lean}`System.FilePath.metadata` 函数，它能告诉你诸如文件类型、大小、访问时间等元数据。

```lean
def checkFileSize (path : System.FilePath) : IO Unit := do
  let metadata ← System.FilePath.metadata path
  IO.println s!"Size of {path}: {metadata.byteSize} bytes"
```

# 检查路径是绝对路径还是相对路径

%%%
tag := "checking-if-path-is-absolute-or-relative"
number := false
%%%

{index}[检查路径是绝对路径还是相对路径]

```lean
def checkAbsolutePath (path₁ path₂: System.FilePath)
  : IO Unit := do
  if path₁.isAbsolute then
    IO.println s!"{path₁} is an absolute path"
  else
    IO.println s!"{path₁} is not an absolute path"

  if path₂.isRelative then
    IO.println s!"{path₂} is a relative path"
  else
    IO.println s!"{path₂} is not a relative path"
```

# 规范化文件路径

%%%
tag := "normalizing-file-path"
number := false
%%%

要规范化一个文件路径——也就是解析其中的任何 `.` 或 `..` 组成部分、去掉多余的分隔符并使其与操作系统兼容——你可以使用 {lean}`System.FilePath.normalize` 方法。

```lean
def normalizePath (path: System.FilePath) : IO Unit := do
  IO.println s!"Normalized path: {path.normalize}"
```

