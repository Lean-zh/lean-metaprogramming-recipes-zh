import VersoManual
import Cookbook.Lean
import Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true
set_option linter.unusedVariables false

#doc (Manual) "二叉树" =>

%%%
tag := "binary-tree"
number := false
htmlSplit := .never
%%%

::: contributors
:::

二叉树是一种基础的数据结构，广泛用于各类应用。它由节点组成，每个节点最多有两个子节点，分别称为左子节点和右子节点。二叉树常用于实现二叉搜索树、堆和表达式树。

# 定义二叉树

%%%
tag := "binary-tree-definition"
number := false
%%%

{index}[定义二叉树]

由于二叉树是一种归纳数据结构，其子节点本身又是另一棵二叉树，我们用归纳类型来定义它。我们用 `Option` 来表示某个子节点可能不存在（即叶子节点）。为适应各种应用，节点可以携带一个值和一个权重，因此我们也把它们纳入定义中。

```lean
inductive BinaryTree (α : Type) where
  | Leaf (val : α) (weight : Nat)
  | Node (val : α) (weight : Nat) 
          (left : Option (BinaryTree α)) 
          (right : Option (BinaryTree α))
deriving Inhabited, Repr
```

- 对于递归数据结构，如果我们想检查两棵树是否相等，往往需要定义一个自定义的 {lean}`BEq` 实例。关于如何为递归数据结构定义 `instance BEq`，参见 [Lean 参考手册的递归实例](https://lean-lang.org/doc/reference/latest/Type-Classes/Instance-Declarations/#recursive-instances)。

# 二叉树上的操作

%%%
tag := "binary-tree-operations"
number := false
%%%

{index}[二叉树上的操作]

通常，你需要定义递归函数来在二叉树上执行操作，例如查找一个值、插入一个新值、计算树的深度等等。下面我们将实现其中一些操作。

## 查找与插入

{index}[二叉搜索树]

要把一棵二叉树变成二叉搜索树（BST），我们需要实现能维持 BST 性质的查找和插入操作。查找操作检查一个值是否存在于树中，而插入操作在确保树满足 BST 性质（左子节点 < 父节点 < 右子节点）的前提下添加一个带权重的新值。我们使用 {lean}`Ord` 类型类来比较值并维护顺序。

```lean
/-- Checks if a value exists in the tree. -/
def contains [Ord α] (v : α) : Option (BinaryTree α) → Bool
  | none => false
  | some (.Leaf val _) => compare v val == .eq
  | some (.Node val _ l r) =>
      match compare v val with
      | .lt => contains v l
      | .gt => contains v r
      | .eq => true

/-- Inserts a value with a weight into the BST. -/
def insert [Ord α] (v : α) (w : Nat) : 
    Option (BinaryTree α) → Option (BinaryTree α)
  | none => some (.Leaf v w)
  | some (.Leaf val weight) =>
      match compare v val with
      | .lt => some 
          (.Node val weight (some (.Leaf v w)) none)
      | .gt => some 
          (.Node val weight none (some (.Leaf v w)))
      | .eq => some (.Leaf v w)
  | some (.Node val weight l r) =>
      match compare v val with
      | .lt => some (.Node val weight (insert v w l) r)
      | .gt => some (.Node val weight l (insert v w r))
      | .eq => some (.Node v w l r)
```

要找出树的最大深度，或计算所有节点的总权重，我们可以定义遍历树并计算所需值的递归函数。

```lean
/-- Computes the maximum depth of the tree. -/
def depth {α} : Option (BinaryTree α) → Nat
  | none => 0
  | some (.Leaf ..) => 1
  | some (.Node _ _ l r) => 1 + max (depth l) (depth r)

/-- Calculates the total weight of all nodes in the tree. -/
def totalWeight {α} : Option (BinaryTree α) → Nat
  | none => 0
  | some (.Leaf _ w) => w
  | some (.Node _ w l r) => 
      w + totalWeight l + totalWeight r
```

# 列表转二叉树

%%%
tag := "list-to-binary-tree"
number := false
%%%

{index}[列表转二叉树]

我们常常以 {lean}`List` 的形式拿到树的数据，需要把它转换成二叉树结构。我们知道第 `i` 个元素的左子节点在 `2*i + 1`、右子节点在 `2*i + 2`。我们通过选取中位数把一个有序列表转换成一棵平衡树。

```lean
def listToBinaryTree {α} (xs : List (α × Nat)) : 
    Option (BinaryTree α) :=
  match p:xs with
  | [] => none
  | [(v, w)] => some (.Leaf v w)
  | v₁ :: v₂ :: rest =>
      let midIdx := xs.length / 2
      match h_head: (xs.drop midIdx).head? with
      | some (val, w) =>
          -- needed by Lean to show termination
          have hl: min (xs.length / 2) xs.length < 
            rest.length + 2 := by grind
          let left  := listToBinaryTree (xs.take midIdx)
          let right := 
            listToBinaryTree (xs.drop (midIdx + 1))
          some (.Node val w left right)
      | none => none
termination_by xs.length
```

# 示例用法

我们将用上面的函数，在一个示例中从一组值和权重构建一棵二叉树，并执行前面定义的各种操作。

```lean
/-- Pretty prints the binary tree for visualization. -/
def pprintBST {α} [Repr α] : Option (BinaryTree α) → String
  | none => "Empty"
  | some (.Leaf v w) => s!"(Leaf: {repr v} {w})"
  | some (.Node v w l r) => 
      let left := pprintBST l
      let right := pprintBST r
      s!"(Node: {repr v} {w} {left} {right})"

def egBinaryTree : Option (BinaryTree String) :=
  let data := [("A", 1), ("B", 2), ("C", 3), ("D", 4)]
  listToBinaryTree data

#eval pprintBST egBinaryTree
#eval contains "B" egBinaryTree

def updatedTree := insert "E" 5 egBinaryTree
#eval pprintBST updatedTree

#eval depth updatedTree
#eval totalWeight updatedTree
```
