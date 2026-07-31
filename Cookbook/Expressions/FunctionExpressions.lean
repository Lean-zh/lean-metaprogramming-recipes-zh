import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

set_option pp.rawOnError true

#doc (Manual) "函数、依值函数与函数类型的表达式" =>

%%%
tag := "expressions-for-functions"
number := false
-- Optional: If you don't want the recipe to be split into multiple subpages, because of depth.
htmlSplit := .never
%%%

::: contributors
:::

{index}[函数、依值函数与函数类型的表达式]

# 用 λ 抽象定义函数

假设我们想为一个函数定义表达式，该函数接受一个自然数 `n` 并返回 `n + n`。不建议直接用 λ 抽象的构造子 `Expr.lam` 来构建表达式，因为 Lean 的卫生（hygiene）机制会修改该表达式。不过，Lean 提供了引入局部变量并构建 λ 抽象的便捷方式，即 `withLocalDeclD`（或 `withLocalDecl`）和 `mkLambdaFVars`。下面是我们定义倍增函数表达式的方法：

```lean
open Lean Meta Elab

def doubleExpr : MetaM Expr :=
  withLocalDeclD `n (mkConst ``Nat) fun n => do
    let double ← mkAppM ``Add.add #[n, n]
    mkLambdaFVars #[n] double
```

函数 `withLocalDeclD` 有三个参数：局部变量的名字、它的类型（此处为 `Nat`），以及一个把新创建的局部变量作为参数的续延函数。在续延内部，我们可以用 `mkAppM` 把加法函数应用到 `n` 和 `n` 上，从而构建 λ 抽象的主体。最后，我们用 `mkLambdaFVars` 创建一个对局部变量 `n` 进行抽象的 λ 抽象。

为了说明如何使用这个表达式，我们可以写一个精译器（见 {ref "elaboration-extending-syntax"}[精译]），让我们能在项位置使用它：

```lean
elab "double%" : term =>
  doubleExpr

#eval double% 7 -- 14
```

# 用 Π 类型定义依值函数

我们可以用类似的技术为依值函数以及 `∀` 量化的命题定义表达式，它们在 Lean 中由 Π 类型表示。例如，我们可以按如下方式为命题 `forall n : Nat, n = n` 定义一个表达式：

```lean
def rflNatExpr : MetaM Expr :=
  withLocalDeclD `n (mkConst ``Nat) fun n => do
    let eqn ← mkEq n n
    mkForallFVars #[n] eqn

elab "rflnat%" : term => do
  rflNatExpr

example : rflnat% := by -- goal `∀ (n : Nat), n = n`
  simp
```

# 例子：证明结论 `∀ (n : Nat), n = n`

把上面两个构造放在一起，来证明结论 `∀ (n : Nat), n = n`。我们将构造一个给出该结论证明的表达式，然后检查该表达式的类型确实是 `∀ (n : Nat), n = n`。这会用到函数 `inferType`（推断表达式的类型）和 `isDefEq`（检查两个表达式是否在定义上相等）。

我们定义一个函数 `rflNatExprProof`，它构造结论 `∀ (n : Nat), n = n` 的一个证明表达式，并检查其类型正确：

```lean
def rflNatExprProof : MetaM Bool := do
  let pf ← withLocalDeclD `n (mkConst ``Nat) fun n => do
    let pfN ← mkAppM ``Eq.refl #[n]
    mkLambdaFVars #[n] pfN
  let pfType ← inferType pf
  isDefEq pfType (← rflNatExpr)

#eval rflNatExprProof -- true
```


# 用 `mkArrow` 定义函数类型

对于非依值的函数类型，我们可以用 `mkArrow` 函数来构建函数类型的表达式。例如，我们可以按如下方式为从 `Nat` 到 `Nat` 的函数类型定义一个表达式：

```lean
def natToNatExpr : MetaM Expr :=
  mkArrow (mkConst ``Nat) (mkConst ``Nat)
```
