import VersoManual
import Cookbook.Lean
import Cookbook.Syntax.QuasiQuotes
import Cookbook.Syntax.AddingSyntaxAndSyntaxCategories
import Cookbook.Syntax.WritingAMacro

open Verso.Genre Manual Cookbook

#doc (Manual) "语法与宏" =>

%%%
tag := "syntax"
number := false
file := "syntax"
%%%

::: contributors
:::

在 Lean 中，代码首先被_解析_成语法，然后被_精译_成表达式。创建新的策略、命令和项，最简单的方式是在语法层面工作，把新语法映射到现有语法。变换语法的函数称为_宏_。

本章给出匹配、创建和变换语法的配方。

*配方：*

{include 1 Cookbook.Syntax.QuasiQuotes}
{include 1 Cookbook.Syntax.WritingAMacro}
{include 1 Cookbook.Syntax.AddingSyntaxAndSyntaxCategories}
