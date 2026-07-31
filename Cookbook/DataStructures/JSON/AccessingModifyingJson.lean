import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "访问与修改 JSON" =>

%%%
file := "data-structures-json-accessing-modifying-json"
%%%

::: contributors
:::

# 从 JSON 读取值

%%%
tag := "accessing-json"
number := false
file := "accessing-json"
%%%

{index}[从 JSON 读取值]

要从 {lean}`Json` 对象读取值，你可以使用像 {lean}`Json.getObjValAs?` 这样的专用辅助函数，它会尝试取出一个值并把它转换为特定的 Lean 类型。

```lean
def getAge (j : Json) : Except String Nat :=
  j.getObjValAs? Nat "age"

#eval getAge (json% { "name": "Alice", "age": 30 })

def getJsonValue (j : Json) (key : String) : Json :=
  let val := j.getObjVal? key
  match val with
  | .ok v => v
  | .error err => panic! s!"Key '{key}' not found: {err}"

#eval getJsonValue (json% { "name": "Bob", "age": 7 }) "age"
```

要获取一个 {lean}`Json` 对象中的所有键，你只需对 {lean}`Json.obj` 构造子进行匹配：

```lean
def getSortedKeys (j : Json) : List String :=
  match j with
  | .obj m => m.toList.map (·.1) |>.mergeSort
  | _ => []

#eval getSortedKeys (json% { apple: 1, "b": 2, cats: 3 })
```

对于更复杂的结构，你可以使用 {name}`fromJson?` 类一次性解码整个对象：

```lean
structure JsonUser where
  name : String
  age  : Nat
  isAdmin : Bool
deriving FromJson, ToJson, Inhabited

def getUserName (j : Json) : String :=
  match (fromJson? j : Except String JsonUser) with
  | .ok user => user.name
  | .error err => panic! s!"Failed to decode User: {err}"

#eval getUserName (json% { "name": "Charlie", 
  "age": 25, "isAdmin": false })
```

# 修改 JSON 对象

%%%
tag := "modifying-json"
number := false
file := "modifying-json"
%%%

{index}[修改 JSON 对象]

由于 {lean}`Json` 是一个不可变的归纳类型，“修改”它其实是在旧值的基础上创建一个新的 {lean}`Json` 值。

## 1. 直接操作对象

%%%
file := "data-structures-json-accessing-modifying-json-section-04"
%%%

如果你确知某个 {lean}`Json` 值是一个对象，可以对 {lean}`Json.obj` 进行模式匹配来访问底层的 `RBMap`。然后你可以使用像 `insert` 或 `erase` 这样的方法，并把结果重新包回 {lean}`Json.obj`。

```lean
/-- Update or add the 'isAdmin' field -/
def setAdminStatus (j : Json) (status : Bool) : Json :=
  match j with
  | Json.obj kv => Json.obj 
      (kv.insert "isAdmin" (toJson status))
  | _ => j

#eval setAdminStatus (json% { "name": "Bob", 
    "isAdmin": false }) true
#eval setAdminStatus (json% { "name": "Charlie"}) true

/-- Remove the 'age' field if it exists -/
def stripAge (j : Json) : Json :=
  match j with
  | Json.obj kv => Json.obj (kv.erase "age")
  | _ => j

#eval stripAge (json% { "name": "Bob", "age": 42 })
```

## 2. 解码—修改—编码模式

%%%
file := "data-structures-json-accessing-modifying-json-section-05"
%%%

对于复杂的修改，尤其是涉及嵌套数据或集合的修改，最健壮的做法是把 JSON 解码为一个 Lean 结构体，用 Lean 强大的函数式工具执行更新，然后再重新编码它。

```lean
structure Endpoint where
  host : String
  port : Nat
deriving FromJson, ToJson

structure ServerConfig where
  name      : String
  endpoints : List Endpoint
  active    : Bool
  location  : Option String
deriving FromJson, ToJson

/-- Update the port for a specific host 
  and toggle the active status -/
def updateConfig (config : ServerConfig) 
    (targetHost : String) (newPort : Nat) : ServerConfig :=
  let updatedEndpoints := config.endpoints.map fun e =>
    if e.host == targetHost then 
      { e with port := newPort } else e
  { config with endpoints := updatedEndpoints, active 
    := !config.active }

def serverUpdate (j : Json) (target : String)
    (port : Nat) : Except String Json := do
  let config : ServerConfig ← fromJson? j
  return toJson (updateConfig config target port)

/- Example: Updating 'localhost' to port 8080 
  and toggling active to false -/
#eval serverUpdate (json% {
  "name": "DevServer",
  "active": true,
  "endpoints": [
    { "host": "localhost", "port": 3000 },
    { "host": "api.example.com", "port": 443 }
  ]
}) "localhost" 8080
```
