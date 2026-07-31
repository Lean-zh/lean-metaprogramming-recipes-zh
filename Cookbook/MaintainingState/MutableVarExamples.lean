import VersoManual
import Cookbook.Lean
import Cookbook.MaintainingState.MutableVariables

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std

set_option pp.rawOnError true

#doc (Manual) "可变变量：示例" =>

%%%
tag := "mutable-variables-example"
number := false
htmlSplit := .never
file := "mutable-variables-example"
%%%

::: contributors
:::

{index}[可变变量：示例]

# 可变变量：示例

%%%
tag := "mutable-variables-example-overview"
number := false
file := "mutable-variables-example-overview"
%%%

由 `IO.Ref` 和 `Std.Mutex` 定义的可变变量无法在定义它们的同一个文件中求值。这里，我们延续上一个配方 {ref "mutable-variables"}[跨命令的可变变量] 中计算卡塔兰数的例子，展示如何用可变变量跨不同命令保留已计算的值。

当我们最初查找 `C(32)` 的缓存值时，得到的是 `none`，因为它还没有被计算。
```lean
#eval getCatalanCache? 32
```

在我们用 `catalanCached` 函数计算出 `C(32)` 之后，该值就被存入缓存。当我们查找 `C(31)` 的缓存值时，得到 `some 14544636039226909`，这正是 `C(31)` 的正确值。

```lean
#eval catalanCached 32

#eval getCatalanCache? 31

#eval catalanCached 31
```
