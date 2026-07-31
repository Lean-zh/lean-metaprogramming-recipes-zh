import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "RBMap 与 RBTree" =>

%%%
tag := "rbmap-rbtree"
number := false
%%%

::: contributors
:::

{lean}`RBMap` 和 {lean}`RBTree` 是红黑树，在整个 Lean 4 编译器中被广泛使用。与需要 {lean}`Hashable` 实例的 {lean}`HashMap` 不同，这些结构只需要一个排序实例（{lean}`Ord`）。

# RBMap（红黑映射）

{index}[RBMap 操作]

{lean}`RBMap` 是一个持久化的有序映射。在纯函数式代码中它常常更受青睐，因为它的性能不依赖 {lean}`IO` 或 {lean}`ST` 单子。

```lean
-- Defining an RBMap with Name keys and Nat values
#print RBMap
def myRBMap : RBMap Name Nat Name.quickCmp := {}

-- Inserting values
def rb1 := myRBMap.insert `apple 1
def rb2 := rb1.insert `banana 2

-- Accessing values (returns Option)
#eval rb2.find? `apple
#eval rb2.find? `cherry 

-- Checking for existence
#eval rb2.contains "apple".toName
#eval rb2.contains `cherry

-- Converting to list
#eval rb2.toList
#eval rb2.toList.map (λ (k, v) => (k.toString, v * 10))
```

# RBTree（红黑树）

{index}[RBTree 基本操作]

{lean}`RBTree` 是用红黑树实现的集合。在元编程中，Lean 提供了若干 {lean}`RBTree` 的“别名”（预定义版本），这样你就不必手动提供比较函数，例如 {lean}`NameSet` 就是 {lean}`RBTree Name Name.quickCmp` 的别名。

```lean
def s1 : NameSet := {}

def s2 := s1.insert `x
def s3 := s2.insert `y

#eval s3.contains `x
#eval s3.toList
```

# 应用：用 RBMap 调度进程

%%%
tag := "rbmap-scheduling"
number := false
%%%

{index}[用 RBMap 调度进程]

在 CFS（完全公平调度器）中，Linux 使用红黑树，依据进程的虚拟运行时间来管理进程。每个进程都表示为树中的一个节点，调度器可以高效地找到虚拟运行时间最小的进程。

```lean
structure Proc where
  pid : Nat
  vruntime : Nat := 0
  workLeft : Nat
  weight : Nat := 1 -- priority weight
deriving Repr, Inhabited

/-- 
  Order processes primarily by virtual runtime.
  Use PID as a tie-breaker.
-/
instance : Ord Proc where
  compare p1 p2 := 
    match compare p1.vruntime p2.vruntime with
    | .eq => compare p1.pid p2.pid
    | ord => ord

/- A scheduler state: a set of processes
  ordered by vruntime -/
abbrev Scheduler := RBMap Proc Unit compare

namespace Scheduler

def empty : Scheduler := RBMap.empty

/-- Create a new process with a unique PID based
on current scheduler state -/
def createProc (s : Scheduler) (workLeft : Nat)
  (weight : Nat := 1) : Proc :=
  if s.isEmpty then
    { pid := 1, vruntime := 0, workLeft, weight }
  else
    let maxPid := (s.toList.map (λ (p, _) =>
      p.pid)).foldl max 0
    { pid := maxPid + 1, vruntime := 0, workLeft, weight }

/-- Add a process to the scheduler -/
def add (s : Scheduler) (p : Proc) : Scheduler :=
  s.insert p ()

/-- Measure for termination: total remaining
work across all processes -/
def totalWork (s : Scheduler) : Nat :=
  s.toList.foldl (init := 0) 
    (fun acc (p, _) => acc + p.workLeft)

/-- Simulate the actual work of a process -/
def doWork (pid : Nat) : IO Unit := do
  IO.println s!"  [executing PID {pid} ...]"
  IO.sleep 10 -- Simulate a brief period of execution

/-- Run the next process for a time quantum (pure logic) -/
def step (s : Scheduler) (quantum : Nat := 10) 
    : Option (Proc × Scheduler) := do
  -- Pick the process with the smallest vruntime
  let (p, _) ← s.min
  let s' : Scheduler := s.erase p

  let runTime := min p.workLeft quantum
  let vruntimeDelta := (runTime * 10) / p.weight
  let newProc := { p with 
    workLeft := p.workLeft - runTime,
    vruntime := p.vruntime + vruntimeDelta
  }

  -- If it still has work, put it back in the tree
  if newProc.workLeft > 0 then
    some (p, Scheduler.add s' newProc)
  else
    some (p, s')

-- Dynamic simulation loop
partial def simulate (s : Scheduler) : IO Unit := do
  if s.isEmpty then 
    IO.println "\nAll processes finished."
  else
    match _h_step : s.step 10 with
    | some (p, s') => 
        doWork p.pid
        let log := s!"Finished quantum for PID {p.pid} " ++
                   s!"(vruntime: {p.vruntime}, " ++
                   s!"remaining: {p.workLeft})"
        IO.println log
        s'.simulate
    | none => return ()
-- termination_by s.totalWork
-- decreasing_by sorry

end Scheduler

def egRunSchedule : IO Unit := do
  let mut s := Scheduler.empty
  s := s.add (s.createProc 30 1)
  s := s.add (s.createProc 40 2)
  s := s.add (s.createProc 20 1)

  IO.println "Starting CFS Simulation..."
  s.simulate

#eval! egRunSchedule
```

# 应用：用 RBTree 追踪未定义的标识符

%%%
tag := "rbtree-tracking-undefined"
number := false
%%%

{index}[用 RBTree 追踪未定义的标识符]

下面的示例实现了一个简单的“linter”，用于找出一段语法中所有未定义的标识符。由于 {lean}`RBTree` 是持久化的，我们可以直接把这个集合向下传递给嵌套的表达式。当我们为某个 `let` 主体把一个新变量“插入”集合时，原来的集合对于语法树的其他分支保持不变。

```lean
/-- A simple linter that finds undefined variables 
    in a piece of syntax. -/
partial def findUndefined (stx : Syntax) 
    (defined : NameSet := {}) : List Name :=
  match stx with
  | `($id:ident) => 
    let n := id.getId.eraseMacroScopes
    if defined.contains n then [] else [n]
  | `(let $id:ident := $v; $body) =>
    let errs1 := findUndefined v defined
    -- Shadowing is handled automatically by the tree.
    let errs2 := findUndefined body 
      (defined.insert id.getId.eraseMacroScopes)
    errs1 ++ errs2
  | `($e1 + $e2) => 
    findUndefined e1 defined ++ findUndefined e2 defined
  | _ => 
    -- Recursively check all other syntax components
    stx.getArgs.toList.flatMap (findUndefined · defined)

def runLinterExample : CoreM Unit := do
  let expr ← `(let y := 2; let z := x + 3; z * y)
  let undef := findUndefined expr
  IO.println s!"Undefined: {undef}"

#eval show CoreM Unit from runLinterExample
```
