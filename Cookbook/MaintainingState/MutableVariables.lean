import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "跨命令的可变变量" =>

%%%
tag := "mutable-variables"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[跨命令的可变变量]

# 跨命令的可变变量

在配方 {ref "state-monad"}[状态单子] 中，我们看到了如何在一个函数内保留状态。然而，有时我们想跨不同的命令保留状态。如果我们在 Infoview 中求值 `catalanMemo 32`，在这个过程中我们也已经计算出了从 `C(0)` 到 `C(32)` 的所有卡塔兰数。然而，如果接下来我们求值 `catalanMemo 31`，就不得不重新计算从 `C(0)` 到 `C(31)` 的所有卡塔兰数，这很低效。本节我们展示如何用可变变量跨不同命令保留状态。

我们可以用 {lean}`IO.Ref` 或 {lean}`Std.Mutex` 在 Lean 中创建可变变量。`IO.Ref` 是一个可以在 `IO` 单子中使用的可变引用，而 `Std.Mutex` 是一个互斥量，可用于在并发环境下保护对可变变量的访问。在本配方中，我们用 `Std.Mutex` 创建一个存储已计算卡塔兰数的可变变量。我们用互斥量确保以线程安全的方式访问该可变变量。

我们初始化一个类型为 `Mutex (HashMap Nat Nat)` 的可变变量 `catalanCache`，用来存储已计算的卡塔兰数。`HashMap` 用来存储卡塔兰数的已计算值，其中键是自然数 `n`，值是对应的卡塔兰数 `C(n)`。然后我们实现辅助函数来从缓存读取和向缓存保存。

```lean
initialize catalanCache : Mutex (HashMap Nat Nat) ←
  Mutex.new (HashMap.emptyWithCapacity)

def getCatalanCache? (n : Nat) : IO (Option Nat) :=
  catalanCache.atomically do
    let m ← get
    return m.get? n

def setCatalanCache (n : Nat) (value : Nat) : IO Unit :=
  catalanCache.atomically do
    modify (fun m => m.insert n value)
```


```lean
partial def catalanCached (n : Nat) : IO Nat := do
  let cache ← getCatalanCache? n
  match cache with
  | some value => return value
  | none =>
    match n with
    | 0 =>
      setCatalanCache 0 1
      return 1
    | n + 1 =>
      let mut sum := 0
      for i in [0:n + 1] do
        let ci ← catalanCached i
        let cni ← catalanCached (n - i)
        sum := sum + (ci * cni)
      setCatalanCache (n + 1) sum
      return sum
```
