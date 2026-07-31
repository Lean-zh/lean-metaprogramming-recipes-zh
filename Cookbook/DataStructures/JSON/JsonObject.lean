import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "创建 JSON 对象" =>

%%%
tag := "creating-json-objects"
number := false
file := "creating-json-objects"
%%%

::: contributors
:::

{index}[处理 Json 对象]


在 Lean 中，{name}`Lean.Json` 类型是一个归纳类型，表示 JSON 结构中可能出现的各种值类型。你可以在 `import Lean.Data.Json` 中找到它的定义：

# 创建 JSON 对象

%%%
file := "data-structures-json-json-object-section-02"
%%%

在 Lean 中创建 JSON 对象主要有三种方式。

## 1. 使用 `json%` 宏

%%%
file := "data-structures-json-json-object-section-03"
%%%

创建字面量 JSON 值最方便的方式是使用 `json%` 宏。它让你可以直接在 Lean 代码中书写 JSON 语法。

```lean
def myJson : Json := json% {
  "name": "Bob",
  "age": 42,
  "isActive": true,
  "scores": [1, 2, 3]
}
```

## 2. 使用 `Json.mkObj`

%%%
file := "data-structures-json-json-object-section-04"
%%%

你可以用 `Json.mkObj` 手动构建一个 JSON 对象，它接受一个键值对列表（形式为 `String × Json`）。

```lean
def manualJson : Json := Json.mkObj [
  ("name", "Bob"),
  ("age", 9)
]
```

## 3. 使用带 `Deriving ToJson` 的自定义结构体

%%%
file := "data-structures-json-json-object-section-05"
%%%

在 Lean 中处理 JSON 最地道的方式是定义一个结构体并派生一个 {lean}`Lean.ToJson` 实例。这让你可以用 `toJson` 函数直接把 Lean 对象转换为 JSON。

```lean
structure User where
  name : String
  age  : Nat
  isAdmin : Bool
deriving ToJson, FromJson

def userJson (user : User) : Json := toJson user

#eval userJson { name := "Bob", age := 7, isAdmin := false }
```
