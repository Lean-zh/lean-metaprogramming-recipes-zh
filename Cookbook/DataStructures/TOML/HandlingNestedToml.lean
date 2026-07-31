import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.AccessingModifyingToml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lake Toml Lean Parser

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "嵌套 TOML 与表数组" =>

%%%
tag := "handling-nested-toml"
number := false
%%%

{index}[处理嵌套 TOML]

::: contributors
:::

TOML 通过表（如 `[server]` 这样的小节）和表数组（用 `[[endpoints]]` 表示）支持嵌套结构。这些是通过嵌套 {name}`DecodeToml` 和 {name}`ToToml` 实例来处理的。

在 `Lake.Toml` 中，你可能同时见到 {name}`Value.table` 和 {name}`Value.table'`。它们几乎完全相同：
*   *`Value.table'`*：{name}`Lake.Toml.Value` 归纳类型的原始构造子。
*   *`Value.table`*：`table'` 的简写，常为清晰起见而使用。

两者都接受两个参数：一个 {name}`Lean.Syntax`（手动创建时通常为 `.missing`）和一个 {name}`Lake.Toml.Table`。

# 定义嵌套结构

%%%
tag := "defining-nested-toml"
number := false
%%%

首先，我们定义 Lean 结构，并提供把它们与 TOML 相互转换的逻辑。

```lean
structure Address where
  host : String
  port : Nat
deriving Inhabited, Repr

instance : DecodeToml Address where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      host := ← tbl.decode `host, 
      port := ← tbl.decode `port 
    }

instance : ToToml Address where
  toToml e := Value.table' .missing <| Table.empty
    |> Table.insert `host e.host
    |> Table.insert `port e.port

structure ServiceConfig where
  name      : String
  addresses : Array Address
deriving Inhabited, Repr

instance : DecodeToml ServiceConfig where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      addresses := ← tbl.decode `addresses 
    }

instance : ToToml ServiceConfig where
  toToml c := Value.table' .missing <| Table.empty
    |> Table.insert `name c.name
    |> Table.insert `addresses c.addresses
```

# 编码（表示为 TOML）

%%%
tag := "encoding-nested-toml"
number := false
%%%

要查看嵌套结构在 TOML 格式下的样子，我们使用 {name}`Lake.Toml.ppTable`。

```lean
def egEncodeNested : CoreM String := do
  let config : ServiceConfig := {
    name := "Production",
    addresses := #[
      { host := "api1.io", port := 80 },
      { host := "api2.io", port := 8080 }
    ]
  }
  let val := toToml config
  if let .table' _ tbl := val then
    return ppTable tbl
  else
    return toString val

#eval egEncodeNested
```

# 解码（读取与访问）

%%%
tag := "decoding-nested-toml"
number := false
%%%

{index}[读取嵌套 TOML]

读取时，你既可以一次性解码整个文件，也可以针对某个特定的嵌套小节。

```lean
def egDecodeNested : CoreM String := do
  let input := "
name = \"Staging\"

[[addresses]]
host = \"localhost\"
port = 3000
"
  let table ← parseToml input
  let val := Value.table' .missing table
  
  let result : EStateM.Result Unit (Array DecodeError) 
    ServiceConfig := decodeToml val #[]
  match result with
  | .ok cfg _ => return s!"Config '{cfg.name}' 
      has {cfg.addresses.size} addresses."
  | .error _ e => 
      throwError s!"Error: {e.toList.map (·.msg)}"

#eval egDecodeNested
```

如果你只想要一个复杂 TOML 文件中的某一部分，可以先提取原始的 {name}`Value`，然后只解码那一部分。

```lean
def egDecodeSection : CoreM String := do
  let input := "
[server]
name = \"Backend\"
[[addresses]]
host = \"127.0.0.1\"
port = 80
"
  let table ← parseToml input
  
  -- Extract the [server] section as a raw Value
  let serverVal : Value := getTomlValue table "server"
  
  -- Decode that Value into a specific structure
  let result : EStateM.Result Unit (Array DecodeError) 
    Address := decodeToml serverVal #[]
    
  match result with
  | .ok addr _ => return s!"Server host is {addr.host}"
  | .error _ e => 
      throwError s!"Error: {e.toList.map (·.msg)}"
```

# 修改嵌套 TOML

%%%
tag := "modifying-nested-toml"
number := false
%%%

要修改嵌套结构，你既可以更新 Lean 对象再重新编码，也可以使用 {name}`decodeTomlValue` 和 {name}`updateValue` 之类的辅助函数直接操作 {name}`Table`。

```lean
def egModifyNested : CoreM String := do
  let input := "name = \"Dev\"\naddresses = []"
  let table ← parseToml input

  -- Retrieve the existing array of addresses
  let addresses : Array Address ← 
    match (decodeTomlValue table "addresses" : 
    Except String (Array Address)) with
    | .ok v => pure v
    | .error _ => pure #[]

  -- Add a new address to the array
  let newAddress : Address := 
    { host := "127.0.0.1", port := 5000 }
  let updatedAddresses := addresses.push newAddress
    
  -- Update the table and pretty-print
  let finalTable := updateValue 
    (updateValue table "addresses" updatedAddresses) 
    "name" "Dev-Local"
  
  return ppTable finalTable

#eval egModifyNested
```
