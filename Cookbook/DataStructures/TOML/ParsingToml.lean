import VersoManual
import Cookbook.Lean
import Lake.Toml

import Lean.Data.Json
import Lake.Toml

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lean Elab Meta Lake Toml Lean Parser Tactic Command

set_option pp.rawOnError true

#doc (Manual) "解析 TOML" =>

%%%
tag := "parsing-toml"
number := false
file := "parsing-toml"
%%%

::: contributors
:::

{index}[解析 TOML]

要解析一个 TOML 字符串，你首先用 TOML 解析器得到一个 {lean}`Syntax` 对象，然后把该语法精译（elaboration）为一个 {name}`Lake.Toml.Table`。下面给出一个通用的 TOML 解析器函数示例，你可以在自己的代码中使用。它以一个 TOML 字符串作为输入，返回一个 {name}`Table`，若解析失败则抛出错误。

```lean
def parseToml (input : String) : CoreM Table := do
  let env ← getEnv
  let ictx := mkInputContext input "<string>"
  let pctx := { env, options := {} }
  let s := toml.fn.run ictx pctx {} 
    (mkParserState ictx.inputString)
  if let some err := s.errorMsg then
    throwError s!"Parse error: {err}"
  else
    elabToml ⟨s.stxStack.back⟩

def egTomlParse : CoreM String := do
  let input := "name = \"Cookbook\"\nversion = \"1.0.0\""
  let table ← parseToml input
  return s!"Parsed table with {table.values} entries."

#eval egTomlParse
```

上面的 {name}`parseToml` 同样可以用于嵌套的 TOML 结构。你可以用 {name}`ppTable` 把解析得到的 {name}`Table` 格式化输出为一个 TOML 字符串，如下所示：

```lean
def egNestedParse : CoreM String := do
  let input := "
[database]
server = \"192.168.1.1\"
ports = [ 8000, 8001, 8002 ]

[[users]]
name = \"Alice\"
role = \"admin\"

[[users]]
name = \"Bob\"
role = \"user\"
"
  -- parseToml handles all the nesting for you
  let table ← parseToml input
  return ppTable table

#eval egNestedParse
```

关于嵌套 TOML 处理的更多内容，见 {ref "handling-nested-toml"}[处理嵌套 TOML] 一节。

