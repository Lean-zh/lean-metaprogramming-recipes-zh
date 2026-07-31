import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean


set_option pp.rawOnError true

#doc (Manual) "表达式的种类" =>

%%%
tag := "kinds-of-expressions"
number := false
htmlSplit := .never
file := "kinds-of-expressions"
%%%

::: contributors
:::


{index}[表达式的种类]

# `Expr` 类型

%%%
file := "expressions-types-of-expressions-section-02"
%%%

Lean 中的表达式由 `Expr` 类型表示。这是一种递归数据结构，能够表示各种各样的表达式，包括变量、常量、函数应用、λ 抽象等等。`Expr` 类型定义在 Lean 核心库中，在元编程中被广泛使用。

我们勾勒 `Expr` 类型能表示的各种表达式及其构造子。首先，我们看看 `Expr` 类型的各个构造子。
```lean
#print Lean.Expr
```


通过 `#print Lean.Expr` 我们可以看到 Lean 为 `Expr` 类型提供了如下构造子：

- `Lean.Expr.bvar : Nat → Lean.Expr`
- `Lean.Expr.fvar : Lean.FVarId → Lean.Expr`
- `Lean.Expr.mvar : Lean.MVarId → Lean.Expr`
- `Lean.Expr.sort : Lean.Level → Lean.Expr`
- `Lean.Expr.const : Lean.Name → List Lean.Level → Lean.Expr`
- `Lean.Expr.app : Lean.Expr → Lean.Expr → Lean.Expr`
- `Lean.Expr.lam : Lean.Name → Lean.Expr → Lean.Expr → Lean.BinderInfo → Lean.Expr`
- `Lean.Expr.forallE : Lean.Name → Lean.Expr → Lean.Expr → Lean.BinderInfo → Lean.Expr`
- `Lean.Expr.letE : Lean.Name → Lean.Expr → Lean.Expr → Lean.Expr → Bool → Lean.Expr`
- `Lean.Expr.lit : Lean.Literal → Lean.Expr`
- `Lean.Expr.mdata : Lean.MData → Lean.Expr → Lean.Expr`
- `Lean.Expr.proj : Lean.Name → Nat → Lean.Expr → Lean.Expr`

对我们来说最重要的构造子是 `const`、`app`、`lam` 和 `forallE`，因为它们是我们在 Lean 中操作表达式时最常遇到的。我们先看这些构造子，然后简要提及其他构造子。

## 名字

%%%
file := "expressions-types-of-expressions-section-03"
%%%

Lean 中的名字字面量可以用单反引号写，如 {lean}`` `f ``，也可以用双反引号写，如 {lean}``` ``Nat ```。单反引号表示按原样取该名字，而双反引号表示取该名字并把它解析为当前环境中的一个常量。如果引用的是全局常量，用双反引号更安全：既能避免拼写错误，也能在悬停时看到该名字解析到的实际常量。

## `const` 表达式

%%%
file := "expressions-types-of-expressions-section-04"
%%%

这些由 `const` 构造子给出，表示 Lean 中的常量。它们由一个名字（可以是限定名）和一个宇宙层级列表组成。例如，表达式 `Nat` 会被表示为 {lean}```Lean.Expr.const ``Nat []```，而表达式 `List Nat` 会被表示为 {lean}```Lean.Expr.app (Lean.Expr.const ``List []) (Lean.Expr.const ``Nat [])```。

## `app` 表达式

%%%
file := "expressions-types-of-expressions-section-05"
%%%

这些由 `app` 构造子给出，表示函数应用。它们由一个函数表达式和一个参数表达式组成。例如，表达式 `f x` 会被表示为 {lean}``Lean.Expr.app (Lean.Expr.const `f []) (Lean.Expr.const `x [])``。

## `lam` 表达式

%%%
file := "expressions-types-of-expressions-section-06"
%%%

这些由 `lam` 构造子给出，表示 λ 抽象，即形如 `fun x ↦ y` 的函数定义。它们由一个名字（约束变量的名字）、一个类型表达式、一个主体表达式和一个绑定子信息（binder info，用来指示该变量是隐式还是显式）组成。主体表达式不能含有自由变量，但可以用德布鲁因索引（de Bruijn index）引用约束变量，该索引是一个自然数，表示该变量距离其绑定位置有多少个绑定子。例如，表达式 `fun x : Nat ↦ Nat.succ x` 会被表示为 {lean}```Lean.Expr.lam `x (Lean.Expr.const `Nat []) (Lean.Expr.app (Lean.Expr.const ``Nat.succ []) (Lean.Expr.bvar 0))  Lean.BinderInfo.default```。

由于需要正确管理德布鲁因索引和宇宙，直接构造 `lam` 表达式可能会很棘手。最好使用 Lean 的单子式辅助函数来做这件事，正如我们在配方 {ref "expressions-for-functions"}[函数的表达式]中所见。

## `forallE` 表达式

%%%
file := "expressions-types-of-expressions-section-07"
%%%

这些由 `forallE` 构造子给出，表示依值函数类型，即形如 `(x : A) → B` 或 `∀ x : A, B` 的类型。它们由一个名字（约束变量的名字）、一个类型表达式、一个主体表达式和一个绑定子信息组成。与 `lam` 表达式的情形一样，主体表达式不能含有自由变量，但可以用德布鲁因索引引用约束变量。同样，直接构造 `forallE` 表达式可能会很棘手，最好使用 Lean 的单子式辅助函数来做这件事，正如我们在配方 {ref "expressions-for-functions"}[函数的表达式]中所见。


## `sort` 表达式

%%%
file := "expressions-types-of-expressions-section-08"
%%%

这些由 `sort` 构造子给出，表示 Lean 中的宇宙层级。它们由一个宇宙层级表达式组成。例如，表达式 `Type` 会被表示为 {lean}`Lean.Expr.sort (Lean.Level.succ (Lean.Level.zero))`，而表达式 `Prop` 会被表示为 {lean}`Lean.Expr.sort (Lean.Level.zero)`。

## `letE` 表达式

%%%
file := "expressions-types-of-expressions-section-09"
%%%

这些由 `letE` 构造子给出，表示 let 表达式，即形如 `let x := a; b` 的表达式。它们由一个名字（约束变量的名字）、一个类型表达式、一个值表达式、一个主体表达式，以及一个指示该 let 绑定是否递归的布尔值组成。

## `lit` 表达式

%%%
file := "expressions-types-of-expressions-section-10"
%%%

这些由 `lit` 构造子给出，表示自然数或字符串字面量。出于效率考虑，Lean 用这些字面量节点代替例如由归纳类型 `Nat` 的构造子组成的表达式。它们由一个字面值组成。例如，表达式 `123` 会被表示为 {lean}`Lean.Expr.lit (Lean.Literal.natVal 123)`。

## `fvar` 和 `mvar` 表达式

%%%
file := "expressions-types-of-expressions-section-11"
%%%

这些分别由 `fvar` 和 `mvar` 构造子给出，分别表示自由变量和元变量。它们由一个变量的标识符组成。自由变量用来表示不被任何量词或 λ 抽象绑定的变量，而元变量用作尚未确定的表达式的占位符。

## `bvar` 表达式

%%%
file := "expressions-types-of-expressions-section-12"
%%%

这些由 `bvar` 构造子给出，表示约束变量，即被量词或 λ 抽象绑定的变量。它们由一个德布鲁因索引组成，该索引是一个自然数，表示该变量距离其绑定位置有多少个绑定子。

## `proj` 表达式

%%%
file := "expressions-types-of-expressions-section-13"
%%%

这些由 `proj` 构造子给出，表示结构体投影。它们由结构体的名字、字段索引和被投影的结构体表达式组成。例如，若局部变量 `p : Point` 在元编程代码中由自由变量表达式 `pExpr` 表示，并令 `pointName` 为结构体 `Point` 的完整 `Name`，那么 `p.x` 对应 `Expr.proj pointName 0 pExpr`，`p.y` 对应 `Expr.proj pointName 1 pExpr`。这里不能把局部变量 `p` 写成常量表达式。

## `mdata` 表达式

%%%
file := "expressions-types-of-expressions-section-14"
%%%

这些由 `mdata` 构造子给出，表示带元数据的表达式。它们由一个元数据对象和一个表达式组成。元数据可用来给表达式附加额外信息，例如源代码位置信息或注解。
