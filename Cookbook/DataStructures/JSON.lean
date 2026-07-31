import VersoManual
import Cookbook.Lean
import Lean.Data.Json
import Cookbook.DataStructures.JSON.JsonObject
import Cookbook.DataStructures.JSON.ReadWriteJsonFile
import Cookbook.DataStructures.JSON.AccessingModifyingJson
import Cookbook.DataStructures.JSON.Miscellaneous

open Verso.Genre Manual Cookbook Lean
open Verso.Genre.Manual.InlineLean

#doc (Manual) "JSON" =>

%%%
tag := "json"
number := false
file := "json"
%%%

::: contributors
:::

{lean}`Json` 是表示结构化数据时使用最广泛的数据格式之一。Lean 4 提供了一个健壮的模块来处理 {lean}`Json`，你可以通过 `import Lean.Data.Json` 找到它。本章讲述如何在 Lean 中创建、操作并持久化 {lean}`Json` 数据。

*配方：*

{include 1 Cookbook.DataStructures.JSON.JsonObject}
{include 1 Cookbook.DataStructures.JSON.AccessingModifyingJson}
{include 1 Cookbook.DataStructures.JSON.ReadWriteJsonFile}
{include 1 Cookbook.DataStructures.JSON.Miscellaneous}
