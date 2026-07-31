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

#doc (Manual) "处理 lakefile.toml" =>

%%%
tag := "lakefile-toml"
number := false
%%%

::: contributors
:::

Lean 4 使用 *lakefile.toml* 进行包配置。虽然你通常手动编辑这个文件，但有时你可能想用 `Lake.Toml` 以编程方式读取或更新它。

# 解析 lakefile.toml

%%%
tag := "parsing-lakefile-toml"
number := false
%%%

{index}[解析 lakefile.toml]

*lakefile.toml* 本质上是一个 TOML 表。我们可以定义结构来匹配 `[[lean_lib]]` 或 `[[require]]` 这样的特定小节。

```lean
structure LibConfig where
  name : String
  moreLeanArgs : Array String
deriving Inhabited, Repr

instance : DecodeToml LibConfig where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      moreLeanArgs := ← tbl.decode `moreLeanArgs 
    }

/-- Reads the library name from the [[lean_lib]] section -/
def readLibName (path : System.FilePath) : 
    CoreM String := do
  let content ← IO.FS.readFile path
  let table ← parseToml content

  let libVal : Value := getTomlValue table "lean_lib"
  
  -- We decode to Array lean_lib 
  -- since it's an array of tables
  let result : EStateM.Result Unit (Array DecodeError) 
    (Array LibConfig) := decodeToml libVal #[]
  
  match result with
  | .ok libs _ => 
      match (libs[0]? : Option LibConfig) with
      | some { name := n, moreLeanArgs := args } =>
          return s!"Library name: {n} and Args: {args}"
      | none => return "No library found"
  | .error .. => return "Failed to decode lean_lib section."

#eval readLibName "lakefile.toml"
```

# 更新 lakefile.toml 中的依赖

%%%
tag := "updating-lakefile-toml"
number := false
%%%

{index}[更新 lakefile.toml]

要添加一个依赖，我们定义一个匹配 `[[require]]` 格式的结构，解码现有的列表，然后压入我们的新条目。

```lean
structure Dependency where
  name : String
  git  : String
  rev  : String
deriving Inhabited, Repr

instance : DecodeToml Dependency where
  decode v := do
    let tbl ← v.decodeTable
    return { 
      name := ← tbl.decode `name, 
      git  := ← tbl.decode `git,
      rev  := ← tbl.decode `rev 
    }

instance : ToToml Dependency where
  toToml d := Value.table .missing <| Table.empty
    |> Table.insert `name d.name
    |> Table.insert `git  d.git
    |> Table.insert `rev  d.rev

def addDependency (path : System.FilePath) 
  (dep : Dependency) : CoreM Unit := do
  let content ← IO.FS.readFile path
  let table ← parseToml content
  
  -- 1. Extract the existing array
  let reqVal : Value := getTomlValue table "require"
  let result : EStateM.Result Unit (Array DecodeError) 
    (Array Dependency) := decodeToml reqVal #[]
    
  let deps := match result with
    | .ok d _ => d
    | .error .. => #[]
    

  let updatedDeps := deps.push dep
  let updatedTable := 
    updateValue table "require" updatedDeps

  IO.FS.writeFile path (ppTable updatedTable)

/-
#eval addDependency "lakefile.toml" { 
  name := "mathlib", 
  git := "https://github.com/leanprover-community/mathlib4",
  rev := "v4.11.0" 
}
-/
```
