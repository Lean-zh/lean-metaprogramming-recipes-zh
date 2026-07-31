import VersoManual
import Cookbook.Lean
import Std

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "读取与设置文件权限" =>

%%%
tag := "file-permissions"
number := false
%%%

::: contributors
:::

{index}[读取与设置文件权限]

# 设置文件权限

%%%
tag := "setting-file-permissions"
number := false
%%%

{index}[设置文件权限]

由于相关 API 不够直观，设置文件权限较为复杂。下面是一个示例，展示如何用 Lean4 参考手册[这里](https://lean-lang.org/doc/reference/latest/IO/Files___-File-Handles___-and-Streams/#IO___AccessRight___mk)提供的 {lean}`IO.AccessRight`、{lean}`IO.FileRight` 和 {lean}`IO.setAccessRights` API 为一个文件路径设置文件权限。

```lean
def setFilePermissions (path : System.FilePath) : 
    IO Unit := do
  -- Define specific access rights
  let rw : IO.AccessRight := 
    { read := true, write := true, execution := false } 
  let rOnly : IO.AccessRight := 
    { read := true, write := false, execution := false }

  -- Construct the FileRight structure
  -- Setting User to RW, Group to R, and Other to R
  let myRights : IO.FileRight := {
    user  := rw,
    group := rOnly,
    other := rOnly
  }

  -- Apply the rights to the file
  IO.setAccessRights path myRights
  IO.println s!"Access rights for {path} have been updated."
```

# 读取文件权限

要读取一个文件的权限，Lean 没有提供内置 API（如果你知道有，请告诉我们！我在文档里没有找到）。不过，我们可以用 Linux 的 `stat` 命令以八进制格式获取权限，然后把它转换为一个 {lean}`IO.FileRight` 结构体。

```lean
/-- Convert an octal digit to an IO.AccessRight structure. -/
def octalToAccessRight (c : Char) : IO.AccessRight :=
  let val := c.toString.toNat!
  { 
    read      := val / 4 % 2 == 1,
    write     := val / 2 % 2 == 1,
    execution := val % 2 == 1 
  }

/-- Reads the permissions of a file with `stat` command. -/
def getFilePermissions (path : System.FilePath) :
    IO IO.FileRight := do
  let out ← IO.Process.output {
    cmd  := "stat",
    args := #["-c", "%a", path.toString]
  }

  if out.exitCode != 0 
    then throw <| 
      IO.userError s!"Failed to run stat: {out.stderr}"

  -- The output is usually 3 digits
  let s := out.stdout.trimAscii.toString
  let chars := s.toList

  -- Handle cases with 3 digits (User, Group, Other)
  match chars with
  | [u, g, o] =>
      return {
        user  := octalToAccessRight u,
        group := octalToAccessRight g,
        other := octalToAccessRight o
      }
  | _ => throw <| 
      IO.userError s!"Unexpected permission format: {s}"

def demoPermissions (path : System.FilePath) : IO Unit := do
  -- Get current permissions
  let current ← getFilePermissions path
  IO.println s!"User can read: {current.user.read}"

  -- Modify permissions: Add execution for the user
  let updated := { current with 
    user := { current.user with execution := true },
    group := { current.group with write := true },
    other := { current.other with execution := true },
  }
  
  -- Apply updated permissions
  IO.setAccessRights path updated
  IO.println "Updated user to allow execution."
```

这在 Unix 系统上运行良好，你可以相应地修改命令。注意，当你设置权限时，只会改变 {lean}`IO.FileRight` 结构体中提到的那些权限，之前设置的、未被提到的权限将保持不变。
