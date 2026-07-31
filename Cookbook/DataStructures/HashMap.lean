import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "HashMap" =>

%%%
tag := "hashmap"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{lean}`HashMap` 是一个键值对的集合，提供高效的查找、插入和删除。在 Lean 4 中，最常用的实现是 {name}`Std.HashMap`。

# 基本操作

{index}[HashMap 基本操作]

要使用 {name}`HashMap`，你通常需要提供键和值的类型。键类型必须具有 {name}`Hashable` 和 {name}`BEq` 实例。

```lean
-- Creating an empty HashMap
def myMap : HashMap String Nat := {}

-- Inserting values
def updatedMap := myMap.insert "apple" 1
def updatedMap2 := updatedMap.insert "banana" 2

-- Accessing values (returns Option)
#eval updatedMap2.get? "apple" 
#eval updatedMap2.get? "cherry"

-- Checking for existence
#eval updatedMap2.contains "apple"

-- Removing values
def erasedMap := updatedMap2.erase "apple"
#eval erasedMap.contains "apple"

-- Updating values using 'alter'
/-- Increment the value for a key, or initialize it to 1 -/
def increment (map : HashMap String Nat) (key : String)
  : HashMap String Nat :=
  map.alter key fun
    | some n => some (n + 1)
    | none   => some 1

#eval (increment updatedMap2 "apple").get? "apple"
```

# 用 StateM 做记忆化

%%%
tag := "memoization-hashmap"
number := false
%%%

{index}[使用 HashMap 做记忆化]

记忆化（memoization）是一种加速计算机程序的技术，它存储昂贵函数调用的结果，并在相同输入再次出现时返回缓存的结果。在 Lean 中，把 {name}`HashMap` 与 {name}`StateM` 单子结合是实现它的一种强大方式。{name}`StateM` 让我们能在计算过程中携带缓存（这里是 {name}`HashMap`）的状态。

下面是用记忆化实现斐波那契数列的一个例子。

```lean
/--
  Recursive Fibonacci with memoization.
  We use StateM Memo to carry the cache.
-/
abbrev FibState := HashMap Nat Nat
abbrev FibM := StateM FibState

def fib (n: Nat) : FibM Nat := do
  match n with
  | 0 => return 1
  | 1 => return 1
  | k + 2 => do
    let m ← get
    match m.get? n with -- check if we calculated it before
    | some v => return v
    | none => do
      let v1 ← fib k -- calculate at k and update the state
      let v2 ← fib (k + 1)
      let v := v1 + v2
      modify (fun m => m.insert n v)
      return v

/-
- `run` -> calculates given an initial state and 
  returns the result and the final state
- `run'` -> given an initial state returns the result
-/
#eval fib 350 |>.run' {}
#eval fib 50 |>.run {}
```

使用记忆化让我们几乎瞬间就能算出 `fib 350`，而朴素的递归实现则需要很长时间。

# 应用：高级表达式分析

%%%
tag := "frequency-hashmap-advanced"
number := false
%%%

{index}[高级 HashMap 操作]

在元编程中，你可能想对一个表达式做多层次的分析。下面的例子：
1.  统计每个*常量*出现了多少次。
2.  记录每个常量首次出现时的最小*深度*。
3.  演示如何*合并*两个频次映射。
4.  展示如何*过滤*一个映射，只保留特定的条目。

```lean
structure ConstInfo where
  count : Nat
  firstDepth : Nat
deriving Repr, Inhabited

instance : ToString ConstInfo where
  toString info := s!"Count: {info.count}, 
    First Depth: {info.firstDepth}"

/-- 
  An analyzer that tracks both count 
  and the depth of the first occurrence.
  Using MetaM allows us to use 'logInfo' for debugging.
-/
def analyzeExpr (e : Expr) (depth : Nat := 0) 
    (emap : HashMap Name ConstInfo := {}) :
    MetaM (HashMap Name ConstInfo) := do
  match e with
  -- for constants
  | .const name _ =>
      -- Simple debug print to the Infoview
      logInfo m!"Found constant: {name} at depth {depth}"
      return emap.alter name fun
        | some info => 
            some { info with count := info.count + 1 }
        | none      => 
            some { count := 1, firstDepth := depth }
  -- for applications like `f a`
  | .app f a => 
      let emap' ← analyzeExpr f depth emap
      analyzeExpr a depth emap'
  -- for lambda and forall
  | .lam _ _ b _ | .forallE _ _ b _ => 
      analyzeExpr b (depth + 1) emap
  | _ => return emap

/-- 
  We merge two HashMaps.
  If a constant exists in both, we sum the counts 
  and take the minimum depth.
-/
def mergeAnalysis (m1 m2 : HashMap Name ConstInfo) 
    : HashMap Name ConstInfo :=
  m2.fold (init := m1) fun acc name info2 =>
    acc.alter name fun
    | some info1 => some { 
        count := info1.count + info2.count, 
        firstDepth := min info1.firstDepth info2.firstDepth 
      }
    | none => some info2

def egExprCounter : MetaM Unit := do
  -- Using 'toExpr' elaborates numbers
  -- into 'OfNat.ofNat' calls
  let e1 ← mkEq (toExpr 1) (toExpr 1)
  let e2 ← mkEq (toExpr 2) (toExpr 3)

  let analysis1 ← analyzeExpr e1
  logInfo s!"Analysis of e1: 
    {analysis1.toList.map (fun (k, v) => (k, s!"{v}"))}"
  let analysis2 ← analyzeExpr e2
  logInfo s!"Analysis of e2: 
    {analysis2.toList.map (fun (k, v) => (k, s!"{v}"))}"

  -- Merge the results of two different expressions
  let combined := mergeAnalysis analysis1 analysis2
  logInfo s!"Analysis of combined: 
    {combined.toList.map (fun (k, v) => (k, s!"{v}"))}"

  -- filter the map to only include constants that 
  -- appeared more than once
  let frequent := combined.toList.filter (·.2.count > 1) 
    |> HashMap.ofList

  -- Map the values to just the counts for final display
  let finalCounts := frequent.toList.map 
    fun (k, v) => (k, v.count)

  IO.println s!"Frequent constants: {finalCounts}"

#eval egExprCounter
```


