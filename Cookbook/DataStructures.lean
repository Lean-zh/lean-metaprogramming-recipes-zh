import VersoManual
import Cookbook.Lean
import Cookbook.DataStructures.JSON
import Cookbook.DataStructures.TOML
import Cookbook.DataStructures.HashMap
import Cookbook.DataStructures.Trees

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "数据结构" =>

%%%
tag := "data-structures"
number := false
file := "data-structures"
%%%

::: contributors
:::

Lean 4 提供了若干内置数据结构以及管理它们的工具。本章讲述如何处理数据结构，配有一些自定义的数据结构示例并说明如何使用它们。本章还覆盖了一些常用于存储和管理数据的文件类型，例如 JSON、TOML 等，以及如何在 Lean 4 中使用它们。

*注：* 我们不会覆盖 `Array` 和 `List` 等数据结构上的基本操作，因为它们相当直接，网上也有大量相关资源。

*配方：*

{include 1 Cookbook.DataStructures.JSON}

{include 1 Cookbook.DataStructures.TOML}

{include 1 Cookbook.DataStructures.HashMap}

{include 1 Cookbook.DataStructures.Trees}
