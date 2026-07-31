import VersoManual
import Cookbook.Lean
import Cookbook.Elaboration.SyntaxForCommands
import Cookbook.Elaboration.SyntaxForTerms

open Verso.Genre Manual Cookbook

#doc (Manual) "精译（elaboration）：扩展语法" =>

%%%
tag := "elaboration-extending-syntax"
number := false
file := "elaboration-extending-syntax"
%%%

::: contributors
:::

扩展 Lean 语法最简单的方式是编写宏，把新语法转换为已有语法（见 {ref "syntax"}[语法与宏]）。不过，还有一种更强大的扩展方式：编写新的*精译器（elaborator）*，把新语法转换成表达式。本章给出为项和命令的新语法编写精译器的配方。

*配方：*

{include 1 Cookbook.Elaboration.SyntaxForTerms}
{include 1 Cookbook.Elaboration.SyntaxForCommands}
