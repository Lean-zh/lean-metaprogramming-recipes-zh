import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "从文件读取" =>

%%%
tag := "reading-from-file"
number := false
%%%

::: contributors
:::

{index}[从文件读取]

从文件读取需要在 {lean}`IO` 单子中完成。要把整个文件作为字符串读取，可以使用 {lean}`IO.FS.readFile`：

```lean
def readWholeFile (path : System.FilePath) : IO String :=
  IO.FS.readFile path
```

如果你想把文件文本放到一个变量里使用，可以取得 {lean}`IO.FS.readFile` 的结果并把它当作字符串来操作：

```lean
def readAndUse (path : System.FilePath) : IO String := do
  let content ← IO.FS.readFile path
  -- Do something with content, like convert it to uppercase
  return content.toUpper
```

如果你想逐行读取文件，可以使用 {lean}`IO.FS.withFile` 获取文件的句柄，然后从中读取行。{lean}`IO.FS.Handle.getLine` 方法从文件读取一行：

```lean
def readFirstLine (path : System.FilePath) : IO String :=
  IO.FS.withFile path .read fun handle => do
    handle.getLine
```

如果你想把所有行读入一个数组，可以使用 {lean}`IO.FS.lines`：

```lean
def readAllLines (path : System.FilePath) :
    IO (Array String) :=
  IO.FS.lines path
```

现在假设你想通过去掉读到的行两端的空白来修剪它。你可以用 {lean}`String.trimAscii` 方法来做，这也会去掉行末的 `\n` 字符：

```lean
def readTrimmedLines (path : System.FilePath) :
    IO String := do
  let line ← readFirstLine path
  return line.trimAscii.toString 
```
