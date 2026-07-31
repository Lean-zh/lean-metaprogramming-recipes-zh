import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "处理 JSONL 文件" =>

%%%
htmlSplit := .never
%%%

::: contributors
:::

{index}[处理 JSONL 文件]

JSONL（JSON Lines）是一种每行都是一个有效 JSON 对象的格式。它对大型数据集尤其有用，因为它支持流式处理，并且比单个大型 JSON 数组对文件损坏更不敏感。
处理常规 JSON 文件的方法参见 {ref "json"}[JSON] 一节。

# 如何读取 JSONL 文件

%%%
tag := "reading-jsonl-file"
number := false
%%%

{index}[读取 JSONL 文件]

要读取一个 JSONL 文件，我们用 {lean}`IO.FS.lines` 获取一个字符串数组，然后解析每个非空行。

```lean
def readJsonlFile (path : System.FilePath) :
    IO (Array Json) := do
  let lines ← IO.FS.lines path
  let mut result := #[]
  for line in lines do
    let line := line.trim
    if line.isEmpty then continue
    match Json.parse line with
    | .ok j => result := result.push j
    | .error err =>
      throw <| IO.userError s!"Failed to parse line: {err}"
  return result
```

# 如何写入 JSONL 文件

%%%
tag := "writing-jsonl-file"
number := false
%%%

{index}[写入 JSONL 文件]

写入 JSONL 时，每个对象都必须渲染为单独一行，内部不含换行。你可以用 {lean}`Lean.Json.compress` 确保输出是紧凑的。

1. 写入一个 JSON 对象数组

```lean
def writeJsonlFile (path : System.FilePath)
  (data : Array Json) : IO Unit := do
  let lines := data.map (·.compress)
  IO.FS.writeFile path (String.intercalate "\n"
    lines.toList ++ "\n")
```

2. 把自定义结构体写入 JSONL

对于大型日志或数据集，最好使用句柄逐行写入。

```lean
structure LogEntry where
  timestamp : String
  level     : String
  message   : String
deriving ToJson

def writeLogs (path : System.FilePath)
    (logs : Array LogEntry) : IO Unit := do
  IO.FS.withFile path .write fun handle => do
    for log in logs do
      handle.putStrLn (toJson log).compress
```
