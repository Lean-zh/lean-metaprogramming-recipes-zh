import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "状态单子：记住计算结果" =>

%%%
tag := "state-monad"
number := false
htmlSplit := .never
file := "state-monad"
%%%

::: contributors
:::

{index}[状态单子：记住计算结果]

# 状态单子

%%%
file := "maintaining-state-remembering-computations-section-02"
%%%

由于 Lean 是函数式编程语言，它没有可变状态。然而，我们常常想编写操作状态的代码。例如，我们可能想在递归函数中记住某次计算的结果，以避免冗余计算。

_状态单子（State Monad）_ 是实现这一点的强大工具。它让我们能编写看起来像是在操作状态的代码，但在底层，它实际上是把状态作为参数传来传去。给定状态类型 `S` 和值类型 `A`，状态单子定义如下：
```lean
def State (S A : Type) : Type := S → (A × S)
```
这意味着，一个类型为 `State S A` 的值是一个函数，它接受一个类型为 `S` 的状态，返回一个由类型为 `A` 的值和类型为 `S` 的新状态构成的对。

利用 `do` 记法，我们可以在处理状态的同时编写简洁易读的代码。作为例子，我们用状态单子实现一个带记忆化的函数，用来计算所谓的 _卡塔兰数（Catalan numbers）_，它是一列自然数，出现在组合数学的各种计数问题中。

卡塔兰数满足如下递推关系：
* `C(0) = 1`
* `C(n+1) = Σ (C(i) * C(n-i)) for i = 0 to n`

我们可以在 Lean 中朴素地实现这个递推关系，但由于重复计算，它对较大的 `n` 会很低效。下面是卡塔兰数的一个朴素实现（我们不证明它会终止）：

```lean
partial def catalanNaive : Nat → Nat
  | 0 => 1
  | n + 1 =>
    let terms :=
      List.range (n + 1) |>.map
        (fun i => catalanNaive i * catalanNaive (n - i))
    terms.sum
```


我们展示如何用 `State` 单子通过记忆化来优化卡塔兰数的计算。我们把先前计算出的卡塔兰数值存储在一个 {lean}`HashMap` 中，并用它来避免冗余计算。我们为状态单子定义一个类型别名如下：

```lean
abbrev CatalanM := StateM (HashMap Nat Nat)
```

因此，一个类型为 `CatalanM α` 的项是一个函数，它接受一个类型为 `HashMap Nat Nat` 的状态，返回一个由类型为 `α` 的值和类型为 `HashMap Nat Nat` 的新状态构成的对。

要计算第 `n` 个卡塔兰数，我们先检查它是否已经计算并存储在状态中。如果是，就返回它。如果不是，就用递推关系计算它，把它存储到状态中，然后返回它。下面是实现：

```lean
partial def catalanMemo (n : Nat) : CatalanM Nat := do
  let cache ← get
  match cache.get? n with
  | some value => return value
  | none =>
    match n with
    | 0 =>
      modify (fun m => m.insert 0 1)
      return 1
    | n + 1 =>
      let mut sum := 0
      for i in [0:n + 1] do
        let ci ← catalanMemo i
        let cni ← catalanMemo (n - i)
        sum := sum + (ci * cni)
      modify (fun m => m.insert (n + 1) sum)
      return sum
```

当执行语句 `let ci ← catalanMemo i` 时，函数 `catalanMemo i` 以当前状态被调用。这会返回一个由计算出的值 `ci` 和新状态构成的对。自然数被赋给 `ci`，新状态则被传递给下一次计算。这样，我们就能高效地计算卡塔兰数而不做冗余计算。

有了记忆化版本，我们就能高效地计算大得多的卡塔兰数。例如，我们可以在几分之一秒内计算出第 32 个卡塔兰数，如下所示：

```lean
#eval catalanMemo 32 |>.run' {}
```
