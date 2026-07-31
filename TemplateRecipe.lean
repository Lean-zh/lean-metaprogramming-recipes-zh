import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

set_option pp.rawOnError true

#doc (Manual) "配方标题" =>

%%%
tag := "similar-to-title"
number := false
-- 可选：若不想让配方因标题层级而拆成多个子页面，请保留这一项。
htmlSplit := .never
%%%

::: contributors
:::

{index}[与标签或标题对应的索引词]

# 配方的小标题

%%%
tag := "a-different-tag-if-needed"
number := false
%%%

{index}[需要时使用不同的索引词]

在这里说明配方要解决的问题……

```lean
def exampleRecipe (args : String) : IO Unit :=
  -- your recipe implementation here
  IO.println s!"This is a template recipe! {args}"
```

说明这段代码如何使用、为什么这里的 `Type` 重要，以及读者容易踩到哪些坑。解释应当足够理解配方，但不要展开成大段理论；需要更多背景时链接到相应资料。

配方写完后，请运行完整构建并检查生成页面。
