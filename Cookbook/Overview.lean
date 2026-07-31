import VersoManual
import Cookbook.Lean
import Cookbook.Overview.CodeSyntaxExpressions
import Cookbook.Overview.MonadsInPractice

open Verso.Genre Manual Cookbook

#doc (Manual) "什么是元编程？" =>
%%%
tag := "overview"
number := false
%%%

::: contributors
:::

Lean 中的元编程指编写能够操作其他代码的程序。由于代码用字符串表示，最朴素的元编程方式就是直接操作字符串。但这样做非常容易出错，也不够强大和高效。

因此，元编程操作的是代码的_内部表示_。在 Lean 中，代码的内部表示有两个层次：*语法*（Syntax）与*表达式*（Expressions）（在多数其他语言中操作的是*抽象语法树*）。较简单的元编程形式是操作语法（即所谓的*宏*），更强大的形式是操作表达式。本手册中的配方会覆盖这两个层次的元编程，但大多数配方都在表达式这一层。

*配方：*

{include 1 Cookbook.Overview.CodeSyntaxExpressions}
{include 1 Cookbook.Overview.MonadsInPractice}
