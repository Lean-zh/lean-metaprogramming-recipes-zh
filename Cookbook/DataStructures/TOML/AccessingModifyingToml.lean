import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "访问与修改 TOML" =>

%%%
tag := "accessing-modifying-toml"
number := false
%%%

::: contributors
:::

{name}`Lake.DecodeToml` 与 {name}`Lake.ToToml` 类让你能够自动
把 TOML 表转换成 Lean 结构，反之亦然。

# 从 TOML 读取值

{index}[从 TOML 读取值]

要把 TOML 转换成 Lean 类型，我们主要用两种方法：通过 {name}`Lake.DecodeToml` 类进行高层的类型安全解码，以及使用 {name}`Lake.Toml.Table` 的方法进行低层的提取。

1. *decodeTable*：把一个通用的 {name}`Lake.Toml.Value` 转换成一个 {lean}`Table`。这就是你“打开盒子”以访问嵌套小节内部键的方式。
2. *decode*：{lean}`Table` 上的一个高层方法，它取出一个键并立即把它转换成一个 Lean 类型（如 {lean}`String`）。
3. *decodeValue*：一个低层方法，仅仅取出某个键对应的原始 {name}`Lake.Toml.Value`。

```lean
structure ToolConfig where
  name    : String
  version : String
  active  : Bool := true
deriving Inhabited, Repr

instance : DecodeToml ToolConfig where
  decode v := do
    -- Cast the generic Value to a Table
    let tbl ← v.decodeTable
    -- Decode specific keys into Lean types
    let name ← tbl.decode `name
    let version ← tbl.decode `version
    let active ← tbl.decode? `active
    return { name, version, active := active.getD true }

/-- 
  A general helper to get any type from a Table.
  If the key is missing or the type is wrong, it panics.
-/
def getTomlValue [DecodeToml α] [Inhabited α] 
    (table : Table) (key : String) : α :=
  match (table.decode key.toName).run #[] with
  | .ok v _ => v
  | .error _ errs => panic! 
      s!"Failed to get '{key}': {errs.toList.map (·.msg)}"

/-- Another safe helper to decode a
  specific key into a Lean type. -/
def decodeTomlValue [DecodeToml α] (table : Table) 
    (key : String) : Except String α :=
  match (table.decode key.toName).run #[] with
  | .ok v _ => .ok v
  | .error _ errs => .error 
    s!"Decode error for '{key}': {errs.toList.map (·.msg)}"

def egGetValue : CoreM String := do
  let input := "
name = \"Dragonbot\"
version = 4
is_active = true
"
  let table ← parseToml input
  
  let name : String := getTomlValue table "name"
  let ver  : Int    := getTomlValue table "version"
  let act  : Bool   := getTomlValue table "is_active"
  
  -- You can even get the raw 'Value' box if you want
  let _raw : Value := getTomlValue table "name"
  return s!"{name} v{ver} (Active: {act})"

#eval egGetValue
```

# 编码与修改 TOML

{index}[编码 TOML]
{index}[修改 TOML 对象]

要把 Lean 结构转换回 TOML，需实现 {name}`Lake.ToToml` 类。创建表时，我们用 `Value.table .missing tbl` 把字典包装成一个 TOML 值。

```lean
instance : ToToml ToolConfig where
  toToml c :=
    let tbl := Table.empty
      |> Table.insert `name c.name
      |> Table.insert `version c.version
      |> Table.insert `active c.active
    -- We use .missing because this Value 
    -- is being generated programmatically
    Value.table .missing tbl

def egTomlEncode (cfg : ToolConfig) : CoreM String := do
  let val := toToml cfg
  -- If it's a table, we can pretty-print it for a file
  if let .table _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egTomlEncode
  { name := "my-tool", version := "0.1.0", active := true }
```

对于给定的 {lean}`Table`，如果你想修改它（例如添加或更新键），可以用 {name}`Table.insert` 创建一个带有所需改动的新表。对于默认值，可以改用 {name}`Table.insertD` 方法。

```lean
def updateValue [ToToml α] (table : Table) (key : String) 
    (newValue : α) : Table :=
  -- If the key exists, this replaces it; else, it adds it
  Table.insert key.toName newValue table

def safeUpdateValue [ToToml α] (table : Table)
  (key : String) (newValue : α) : Table :=
  -- Check if the key exists before updating
  match (table.decodeValue key.toName).run #[] with
  | .ok .. => updateValue table key newValue
  | .error .. => 
    panic! s!"Key '{key}' does not exist in the table."

def egUpdate : CoreM String := do
  let input := "name = \"Lean4\"\nversion = \"4.15.0\""
  let table ← parseToml input
  -- Update existing key
  let table := updateValue table "version" "4.16.0"
  -- Add new key
  let table := updateValue table "active" true
  return ppTable table

#eval egUpdate
```
