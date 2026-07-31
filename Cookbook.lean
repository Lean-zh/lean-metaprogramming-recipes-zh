import VersoManual
import Cookbook.Lean

import Cookbook.Overview
import Cookbook.Expressions
import Cookbook.Syntax
import Cookbook.FileSystem
import Cookbook.DataStructures
import Cookbook.IO
import Cookbook.Tactics
import Cookbook.MaintainingState
import Cookbook.Index
import Cookbook.BuildingRecipe
import Cookbook.Elaboration
import Cookbook.Infoview
import Cookbook.CookbookContributors

open Verso.Genre Manual
open Verso.Genre.Manual.InlineLean


open Cookbook

set_option pp.rawOnError true

#doc (Manual) "Lean 4（元）编程 Cookbook" =>

%%%
tag := "lean-metaprogramming-cookbook"
number := false
%%%

欢迎阅读 *Lean 4（元）编程 Cookbook*。本书收集 Lean 4 编程与元编程的代码配方和示例，从基础操作到较复杂的用法都有覆盖。每个配方都尽量保持独立，便于理解后放进自己的代码。

各章按主题组织。你需要编写 Lean 4 元编程代码时，可以直接找到对应章节，再从中查找配方。

如果你刚接触 Lean 4，请先学习 Lean 的基础语法和证明方法。Lean 4 官方网站提供语言文档与教程，本书则适合在掌握基础后按需查阅。

*重要说明*

本书不代替 *Theorem Proving in Lean*、*Mathematics in Lean* 等系统资料。它主要补充这些资料较少涉及的编程内容，并在需要背景知识时链接到相应来源，以免重复讲解。建议先用系统教材打好 Lean 4 基础，再把本书作为具体配方和示例的参考手册。无论是刚开始写元编程代码，还是已经有经验、想进一步理解 Lean 4 的程序员，都可以按问题查阅本书。

*更多信息*

如果你想分享自己的配方或示例，请阅读[如何编写配方](building-recipe/)。

感谢所有帮助本书成长的[贡献者（查看完整名单）](cookbook-contributors/)。

*其他参考资料*
- [Lean 4 语言参考手册](https://lean-lang.org/doc/reference/latest/)
- [Theorem Proving in Lean](https://leanprover.github.io/theorem_proving_in_lean4/)
- [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/)
- [Mathlib 文档](https://leanprover-community.github.io/mathlib4_docs/)



{include 1 Cookbook.Overview}

{include 1 Cookbook.Infoview}

{include 1 Cookbook.Syntax}

{include 1 Cookbook.Expressions}

{include 1 Cookbook.Elaboration}

{include 1 Cookbook.Tactics}

{include 1 Cookbook.MaintainingState}

{include 1 Cookbook.IO}

{include 1 Cookbook.FileSystem}

{include 1 Cookbook.DataStructures}

{include 0 Cookbook.Index}

{include 0 Cookbook.BuildingRecipe}

{include 0 Cookbook.CookbookContributors}
