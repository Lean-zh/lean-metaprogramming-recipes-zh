import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.HandlingNestedToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "读写 TOML 文件" =>

%%%
tag := "reading-writing-toml"
number := false
file := "reading-writing-toml"
%%%

{index}[读取 TOML 文件]
{index}[写入 TOML 文件]

::: contributors
:::

处理文件包括从磁盘读取字符串并传给我们的解析器，或者把一个 {name}`Table` 格式化输出到文件。我们将使用上一节中定义的 {name}`ServiceConfig` 结构。

# 从 TOML 文件读取

%%%
file := "data-structures-toml-read-write-toml-file-section-02"
%%%

要读取一个 TOML 文件，我们把文件内容读为字符串，解析成一个 {name}`Table`，然后把该表解码成一个 Lean 结构。

```lean
def loadTomlConfig (path : System.FilePath) : 
    CoreM ServiceConfig := do
  let content ← IO.FS.readFile path
  let table ← parseToml content

  let val := Value.table' .missing table
  let result : EStateM.Result Unit (Array DecodeError)
    ServiceConfig := decodeToml val #[]

  match result with
  | .ok cfg _ => return cfg
  | .error _ errs => 
    let msgs := errs.toList.map 
      (fun (e : DecodeError) => e.msg)
    throwError s!"Failed to decode {path}: {msgs}"
```

# 写入 TOML 文件

%%%
file := "data-structures-toml-read-write-toml-file-section-03"
%%%

要写入 TOML，我们用 `toToml` 把 Lean 结构转换成一个 {name}`Value`，提取其底层的 {name}`Table`，然后用 `ppTable` 把它格式化为标准的多行 TOML 字符串。

```lean
def saveTomlConfig (path : System.FilePath) 
  (cfg : ServiceConfig) : IO Unit := do
  let val := toToml cfg
  
  let content := match val with
    | .table' _ tbl => ppTable tbl
    | _ => toString val -- Fallback to inline format

  IO.FS.writeFile path content
```

## 示例：嵌套的往返转换

%%%
file := "data-structures-toml-read-write-toml-file-section-04"
%%%

```lean
def egRoundTrip : CoreM String := do
  let path : System.FilePath := "service_config.toml"
  let config : ServiceConfig := {
    name := "Production",
    addresses := #[{ host := "127.0.0.1", port := 80 }]
  }
  
  -- Save it
  saveTomlConfig path config
  
  -- Load it back, just for demonstration
  let loaded ← loadTomlConfig path
  return s!"Loaded config for: {loaded.name}"

-- #eval egRoundTrip
```
