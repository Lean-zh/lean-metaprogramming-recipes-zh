import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "读取与写入 JSON 文件" =>

%%%
file := "data-structures-json-read-write-json-file"
%%%

::: contributors
:::

{index}[处理 JSON 文件]

本节讲述如何与文件系统交互来读写 JSON 数据。关于如何构造或操作 JSON 对象本身的细节，参见 {ref "creating-json-objects"}[创建 JSON 对象]。

# 如何读取 JSON 文件

%%%
tag := "reading-json-file"
number := false
file := "reading-json-file"
%%%

{index}[读取 JSON 文件]

要读取一个 JSON 文件，你可以使用 Lean 中的 {lean}`Lean.Json` 模块。用 {lean}`IO.FS.readFile` 把文件作为字符串读取，然后用 {lean}`Lean.Json.parse` 解析它：

```lean
def readJsonFile (path : System.FilePath) : IO Json := do
  let content ← IO.FS.readFile path
  match Json.parse content with
  | Except.ok json => return json
  | Except.error err =>
    throw <| IO.userError
      s!"Failed to parse JSON from {path}: {err}"
```
 
# 如何写入 JSON 文件

%%%
tag := "writing-json-file"
number := false
file := "writing-json-file"
%%%

{index}[写入 JSON 文件]

要把 JSON 数据写入文件，你首先要把 `Json` 对象转换为字符串。你可以用 `toString` 得到紧凑表示，或用 `.pretty` 得到格式化的版本。

```lean
def writeJsonToFile (path : System.FilePath) (data : Json)
  : IO Unit := do IO.FS.writeFile path (data.pretty)
```

如果你需要更多控制，比如设置缩进级别，可以给 `.pretty` 方法传一个参数：

```lean
def writeJsonIndented (path : System.FilePath) (data : Json)
  : IO Unit := do  IO.FS.writeFile path (data.pretty 2)
  -- .pretty(2) formats the JSON with an indent of 2 spaces
```
