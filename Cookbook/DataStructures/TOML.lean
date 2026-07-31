import VersoManual
import Cookbook.Lean
import Lake.Toml
import Cookbook.DataStructures.TOML.ParsingToml
import Cookbook.DataStructures.TOML.AccessingModifyingToml
import Cookbook.DataStructures.TOML.HandlingNestedToml
import Cookbook.DataStructures.TOML.ReadWriteTomlFile
import Cookbook.DataStructures.TOML.JsonTomlConversion
import Cookbook.DataStructures.TOML.LakefileToml

open Verso.Genre Manual Cookbook Lean
open Verso.Genre.Manual.InlineLean
open Lean Lake Toml

#doc (Manual) "TOML" =>

%%%
tag := "toml"
number := false
%%%

::: contributors
:::

`Lake.Toml` 常用于配置文件。Lean 4 提供了一个用于处理 `Lake.Toml` 的模块。本章介绍如何在 Lean 中创建、操作和持久化 `Lake.Toml` 数据。

在 Lean 中处理 TOML 需要理解两个主要类型：

*   *Table*：本质上是一个从键到值的映射（字典）。当你解析一个 TOML 字符串时，得到的是一个 {name}`Table`。
*   *Value*：这是一个归纳类型，可以是字符串、整数、布尔值、数组或另一个表。
    *   *为什么 Value 很重要*：{lean}`Table` 把键映射到值，但这些值可以是任意类型（先是字符串，再是数字，然后是嵌套表）。在 Lean 中，一个映射的所有值必须是同一种类型。{name}`Value` 充当统一的封装类型，让我们能在同一个 {lean}`Table` 中存放不同类型的数据。
*   *Syntax* 与 *.missing*：Lean 中大多数 TOML 类型都携带一个 {name}`Lean.Syntax` 对象。它用于追踪值在源文件中的确切位置，以便提供更好的错误报告。
    *   *为什么 .missing 很重要*：当我们以编程方式（而非从文件）创建 TOML 值时，没有可指向的“源代码行”。我们使用 {name}`Lean.Syntax.missing`（或简写 *.missing*）来满足类型系统的要求，而不必提供一个虚构的源位置。

处理 `Lake.Toml` 不像处理 {lean}`Json` 那样直接，但接下来的各节会提供有效处理 TOML 数据所需的工具。

*配方：*

{include 1 Cookbook.DataStructures.TOML.ParsingToml}
{include 1 Cookbook.DataStructures.TOML.AccessingModifyingToml}
{include 1 Cookbook.DataStructures.TOML.HandlingNestedToml}
{include 1 Cookbook.DataStructures.TOML.ReadWriteTomlFile}
{include 1 Cookbook.DataStructures.TOML.JsonTomlConversion}
{include 1 Cookbook.DataStructures.TOML.LakefileToml}
