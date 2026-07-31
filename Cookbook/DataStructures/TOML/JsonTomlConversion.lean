import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "JSON 与 TOML 互转" =>

%%%
tag := "json-toml-conversion"
number := false
file := "json-toml-conversion"
%%%

::: contributors
:::

# 把 TOML 转换成 JSON

%%%
tag := "toml-to-json"
number := false
file := "toml-to-json"
%%%

{index}[把 TOML 转换成 JSON]

为了与其他系统互操作，把 TOML 数据转换成 JSON 格式常常很有用。下面的示例展示如何通过递归地把 TOML 结构映射到 {lean}`Json`，把你自己的 TOML {lean}`Value` 转换成一个 {lean}`Json` 对象。

```lean
open Lake Toml Lean

/-- Recursive conversion from TOML Value to Json -/
partial def tomlToJson : Value → Json
  | .string _ s    => toJson s
  | .integer _ i   => toJson i
  | .float _ f     => toJson f
  | .boolean _ b   => toJson b
  | .dateTime _ d  => toJson (toString d)
  | .array _ arr   => toJson (arr.map tomlToJson)
  | .table' _ tbl  =>
      let pairs := tbl.items.toList.map fun (k, v) =>
        (k.toString, tomlToJson v)
      Json.mkObj pairs

def egTomlToJson : CoreM Json := do
  let input := "
[database]
server = \"192.168.1.1\"
ports = [ 8000, 8001, 8002 ]
"
  let table ← parseToml input
  return tomlToJson (Value.table .missing table)

#eval egTomlToJson
```

# 把 JSON 转换成 TOML

%%%
tag := "json-to-toml"
number := false
file := "json-to-toml"
%%%

{index}[把 JSON 转换成 TOML]

把 JSON 转换回 TOML 需要把 JSON 类型映射到对应的 TOML 构造子。由于 JSON 数字用 {lean}`JsonNumber` 表示，我们会尝试把它们转换成整数或浮点数。

```lean
open Lake Toml Lean

/-- Recursive conversion from Json to TOML Value -/
partial def jsonToToml : Json → Value
  | .null       => .string .missing "null"
  | .bool b     => .boolean .missing b
  | .num n      => 
      -- Check if it is a simple integer (exponent 0)
      if n.exponent == 0 then 
        .integer .missing n.mantissa
      else 
        .float .missing n.toFloat
  | .str s      => .string .missing s
  | .arr a      => .array .missing (a.map jsonToToml)
  | .obj o      => 
      let tbl := o.toList.foldl (fun t (k, v) => 
        Table.insert k.toName (jsonToToml v) t) Table.empty
      .table .missing tbl

def egJsonToToml : CoreM String := do
  let j := json% {
    "project": "Lean4",
    "meta": { "active": true, "version": 4 }
  }
  let val := jsonToToml j
  if let .table _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egJsonToToml
```
