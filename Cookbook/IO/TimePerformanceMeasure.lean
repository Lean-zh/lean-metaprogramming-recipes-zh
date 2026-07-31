import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "进程的时间测量" =>

%%%
tag := "process-time-measurement"
htmlSplit := .never
file := "process-time-measurement"
%%%

::: contributors
:::

# 为性能测量对进程计时

%%%
tag := "time-measurement"
number := false
file := "time-measurement"
%%%

{index}[性能计时]

Lean 4 提供了高精度的单调时钟用于测量性能，也提供了用于暂停执行的函数。

对于基准测试或性能监控，你应当使用单调时钟，它保证永远不会倒退（不像系统时钟那样）。

```lean
def timeTask : IO Unit := do
  let start ← IO.monoMsNow
  -- Simulate some work
  for _ in [1:1000000] do
    let _ := 1 + 1
  let stop ← IO.monoMsNow
  IO.println s!"The task took {stop - start}ms"
```

## 高精度计时（纳秒）

%%%
file := "io-time-performance-measure-section-03"
%%%

如果你需要更高的精度，可以使用 {lean}`IO.monoNanosNow`。

```lean
def preciseTiming : IO Unit := do
  let start ← IO.monoNanosNow

  for _ in [1:1000000] do
    let _ := 1 + 1

  let stop ← IO.monoNanosNow
  IO.println s!"Operation took {stop - start} nanoseconds."
```

