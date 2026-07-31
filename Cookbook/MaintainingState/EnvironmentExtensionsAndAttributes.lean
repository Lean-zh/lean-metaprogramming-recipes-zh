import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean
open Std Lean Meta Elab Tactic

set_option pp.rawOnError true

#doc (Manual) "环境扩展与属性" =>

%%%
tag := "environment-extensions-and-attributes"
number := false
htmlSplit := .never
%%%

::: contributors
:::

{index}[环境扩展与属性]

# 环境扩展与属性

Lean 允许状态跨文件、跨会话持久化，甚至在导入的已编译代码中也是如此，方法是使用 _环境扩展（Environment extensions）_。环境扩展的一个常见应用是实现像 `@[simp]` 和 `@[grind]` 这样的属性。本章我们给出定义环境扩展和属性的配方，并以该属性为例。

具体来说，我们实现一个策略 `distribute`，它尝试应用所有带 `@[distribute]` 属性标记的引理。我们首先制作一个环境扩展来存储带 `@[distribute]` 标记的引理，然后定义 `@[distribute]` 属性，把引理添加到这个环境扩展中。最后，我们实现 `distribute` 策略，它从环境扩展中取出这些引理并应用它们。

## 环境扩展

环境扩展有若干不同类型，其中我们将使用 {lean}`SimpleScopedEnvExtension`。`SimpleScopedEnvExtension` 接受两个类型参数：存储在环境扩展中的条目的类型，以及由环境扩展维护的状态的类型。“Scoped” 意味着我们可以作用于某个命名空间或某个 section 的局部作用域。

在我们的情形中，我们想存储带 `@[distribute]` 标记的引理，所以条目的类型是 `Name`（引理的名字），并且我们想把这些引理的一个数组作为状态维护，所以状态的类型是 `Array Name`。

```lean
initialize distributeExt :
    SimpleScopedEnvExtension Name (Array Name) ←
  registerSimpleScopedEnvExtension {
    addEntry := fun m n =>
        m.push n
    initial := #[]
  }
```

一旦定义了环境扩展，我们就可以用 `add` 函数向环境扩展添加条目，并用 `getState` 函数在给定环境下取出环境扩展的状态。

```lean
#check distributeExt.add
#check distributeExt.getState

def distributeLemmas : MetaM (Array Name) := do
  let env ← getEnv
  return distributeExt.getState env
```


## 属性

和环境扩展一样，属性也有若干不同类型。我们将用 `registerBuiltinAttribute` 来定义 `@[distribute]` 属性。下面的代码定义 `@[distribute]` 属性，并指定当一个引理被标记 `@[distribute]` 时，应把它添加到 `distributeExt` 环境扩展中。

```lean
namespace Distribute
initialize registerBuiltinAttribute {
  name := `distribute
  descr := "Lemmas to be used in the distribute tactic"
  add := fun decl _stx kind =>
    distributeExt.add decl kind
}
end Distribute
open Distribute
```

## 策略

%%%
tag := "distribute-tactic-implementation"
number := false
%%%

最后，我们实现 `distribute` 策略，它从环境扩展中取出这些引理并应用它们。我们用 `apply` 策略把每个引理应用到目标上。

```lean
elab "distribute" : tactic => do
  let lemmas ← distributeLemmas
  for lemma in lemmas do
    let lemmaIdent := mkIdent lemma
    try
      let tac ← `(tactic|rw [$lemmaIdent:ident])
      evalTactic tac
      return
    catch _ =>
      continue
```

我们无法在初始化属性的同一个文件中标记或使用属性，因此不得不把代码拆成两个文件。在下一个配方 {ref "environment-extensions-and-attributes-example"}[环境扩展与属性：示例] 中，我们展示如何使用 `@[distribute]` 属性和 `distribute` 策略。
