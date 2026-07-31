import VersoManual
import Cookbook.Lean
import Lean

import Cookbook.DataStructures.Trees.BinaryTree
import Cookbook.DataStructures.Trees.RBTree


open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command
open Std (HashMap)

set_option pp.rawOnError true

#doc (Manual) "树" =>

%%%
tag := "trees-intro"
number := false
%%%

::: contributors
:::

树是编程中非常重要的数据结构。本章从树的基本定义讲到红黑树、二叉搜索树等专门化的树结构。

*配方：*

{include 1 Cookbook.DataStructures.Trees.BinaryTree}
{include 1 Cookbook.DataStructures.Trees.RBTree}
