import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "杂项 JSON" =>

::: contributors
:::

# 杂项 JSON 操作

%%%
tag := "misc-json-operations"
number := false
%%%

派生实例虽然方便，但现实中的 JSON 常常
需要手动控制序列化、默认值
以及各种变换。

## 1. 字段重命名（手写实例）

%%%
tag := "json-field-renaming"
number := false
%%%

{index}[Json 字段重命名]

如果你的 JSON 使用 `snake_case` 而你的 Lean 代码使用 `camelCase`，
你可以手动实现 {name}`ToJson` 和 {name}`FromJson` 实例。

Lean 中的 `instance` 关键字用于为一个*类型类*（type class）提供实现。这里，{name}`ToJson` 和 {name}`FromJson` 是类型类，定义了一个类型应如何与 {lean}`Json` 相互转换。通过手动定义这些实例，你可以完全控制映射过程，从而弥合不同命名约定或数据结构之间的差异。

```lean
structure Person where
  firstName : String
  lastName  : String
deriving Repr

instance : ToJson Person where
  toJson p := json% {
    "first_name": $(p.firstName),
    "last_name": $(p.lastName)
  }

instance : FromJson Person where
  fromJson? j := do
    let first ← j.getObjValAs? String "first_name"
    let last  ← j.getObjValAs? String "last_name"
    return { firstName := first, lastName := last }

#eval toJson 
  ({ firstName := "Ada", lastName := "Lovelace" : Person })
#eval (fromJson? (json% { "first_name": "Ada", 
    "last_name": "Lovelace" }) : Except String Person)
```

## 2. 处理默认值

%%%
tag := "json-default-values"
number := false
%%%

{index}[Json 处理默认值]

你可以使用 {name}`Json.getObjValAs?`，在某个键缺失或不是期望类型时提供一个回退值。

```lean
def getPort (j : Json) (defaultPort : Nat := 8080) : Nat :=
  match j.getObjValAs? Nat "port" with
  | .ok n => n
  | .error _ => defaultPort

#eval getPort (json% { "host": "localhost", "port": 3000 })
#eval getPort (json% { "host": "localhost" })
```

