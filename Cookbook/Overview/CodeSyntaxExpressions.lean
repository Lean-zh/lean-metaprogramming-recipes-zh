import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "代码、语法与表达式" =>

%%%
htmlSplit := .never
file := "overview-code-syntax-expressions"
%%%

::: contributors
:::

{index}[代码、语法与表达式]

# 代码的内部表示

%%%
tag := "code-syntax-expressions"
number := false
file := "code-syntax-expressions"
%%%

`Syntax` 和 `Expr` 都是 Lean 核心库中定义的类型，在元编程中被广泛使用。Lean 为操作 `Syntax` 和 `Expr` 提供了丰富的 API。

## 语法

%%%
file := "overview-code-syntax-expressions-section-03"
%%%

Lean 中的语法是可扩展的，能够表示各种各样的语法结构，包括变量、常量、函数应用、λ 抽象等等。把字符串转换为语法由_解析器_（Parser）完成，解析器是接受字符串作为输入、产生语法作为输出的函数。

操作语法由_宏_（Macro）完成，宏是接受语法作为输入、产生语法作为输出的函数。宏用于定义新的语法结构，以及对现有语法进行变换。

## 表达式

%%%
file := "overview-code-syntax-expressions-section-04"
%%%

语法会进一步由_精译器_（elaborator）处理，精译器接受语法作为输入，产生表达式作为输出。精译（elaboration）过程进行类型推断、名字解析，以及其他变换，从而产生类型正确的表达式。

Lean 中的表达式由 `Expr` 类型表示，它是一种递归数据结构，能够表示各种各样的表达式，包括变量、常量、函数应用、λ 抽象等等。更复杂的元编程往往直接操作表达式，本书大多数配方都在这一层。
