import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Lean Meta

set_option pp.rawOnError true

#doc (Manual) "从函数应用构造表达式" =>

%%%
tag := "expressions-from-function-applications"
number := false
-- Optional: If you don't want the recipe to be split into multiple subpages, because of depth.
htmlSplit := .never
file := "expressions-from-function-applications"
%%%

::: contributors
:::

{index}[从函数应用构造表达式]

# 常量表达式

%%%
file := "expressions-function-application-expressions-section-02"
%%%

最简单的表达式是常量。它们可以用 {lean}`mkConst` 函数构建，该函数接受一个常量的名字，返回表示该常量的表达式。例如，```mkConst ``Nat``` 返回一个表示自然数类型的表达式。

# 直接应用

%%%
file := "expressions-function-application-expressions-section-03"
%%%

构建表示函数应用的表达式，最简单的方式是使用 {lean}`mkApp` 函数，它接受一个函数表达式和一个参数表达式，返回一个表示把该函数应用到该参数的表达式。例如，我们可以按如下方式为 `1` 构建一个表达式：

```lean
open Lean in
def oneExpr : Expr :=
  mkApp (mkConst ``Nat.succ) (mkConst ``Nat.zero)
```

对于有多个参数的函数，我们可以使用 {lean}`mkAppN`，它接受一个函数表达式和一个参数表达式列表。例如，我们可以按如下方式为 `2` 构建一个表达式：

```lean
open Lean in
def twoExpr : Expr :=
  mkAppN (mkConst ``Nat.add) #[oneExpr, oneExpr]
```

# 带隐式参数、类型类等的函数应用

%%%
file := "expressions-function-application-expressions-section-04"
%%%

虽然用 {lean}`mkApp` 和 {lean}`mkAppN` 可以构建简单的表达式，但这些函数不处理隐式参数、类型类实例、宇宙层级、合一（unification）或 Lean 精译过程的其他特性。要构建正确处理这些特性的表达式，我们可以使用 {lean}`mkAppM` 函数，它接受一个函数的名字和一个参数表达式列表，返回一个表示把该函数应用到这些参数的表达式，同时正确处理隐式参数和类型类实例。

例如，我们可以用 {lean}`mkAppM` 按如下方式为对应于 `Add.add 1 1` 的 `2` 构建一个表达式：

```lean
open Lean Meta in
def twoExprM : MetaM Expr := do
  mkAppM ``Add.add #[oneExpr, oneExpr]
```

还有一个相关的函数 {lean}`mkAppM'`，它的第一个参数是表达式而不是名字。如果需要更精细地控制哪些参数应被推断、哪些应被显式给出，则有一个函数 {lean}`mkAppOptM`，它接受一个 `Option Expr` 数组，其中 `none` 表示该参数应被推断，而 `some e` 表示该参数应被显式给出为 `e`。

## 例子：加法的交换律

%%%
file := "expressions-function-application-expressions-section-05"
%%%

作为使用 `mkAppM` 的一个例子，我们可以为自然数加法的交换律构建一个表达式，它断言对所有自然数 `a` 和 `b` 都有 `a + b = b + a`。我们先为自然数构建表达式，再为加法交换律这个命题构建表达式，最后用 `Nat.add_comm` 为该命题的一个证明构建表达式。

```lean
open Lean Meta in
def natExpr (n : Nat) : Expr :=
  match n with
  | 0 => mkConst ``Nat.zero
  | Nat.succ m => mkApp (mkConst ``Nat.succ) (natExpr m)
```

接下来我们为加法交换律这个命题构建一个表达式：

```lean
open Lean Meta in
def addCommPropExpr (a b : Nat) : MetaM Expr := do
  let aExpr := natExpr a
  let bExpr := natExpr b
  let addAB ←  mkAppM ``Add.add #[aExpr, bExpr]
  let addBA ←  mkAppM ``Add.add #[bExpr, aExpr]
  mkAppM ``Eq #[addAB, addBA]
```

最后，我们可以用 `Nat.add_comm` 为该命题的一个证明构建表达式：

```lean
open Lean Meta in
def addCommProofExpr (a b : Nat) : MetaM Expr := do
  let aExpr := natExpr a
  let bExpr := natExpr b
  mkAppM ``Nat.add_comm #[aExpr, bExpr]
```

我们可以检查这个证明表达式的类型确实是加法交换律这个命题。为此，我们用 `inferType` 函数推断证明表达式的类型，并用 `isDefEq` 检查它与命题表达式在定义上相等：

```lean
open Lean Meta in
def checkAddCommProof (a b : Nat) : MetaM Bool := do
  let proofExpr ← addCommProofExpr a b
  let proofType ← inferType proofExpr
  let propExpr ← addCommPropExpr a b
  isDefEq proofType propExpr

#eval checkAddCommProof 2 3 -- true
```
