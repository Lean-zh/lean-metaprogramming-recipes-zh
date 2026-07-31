import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "处理 Stdin/Stdout/Stderr 流" =>

%%%
tag := "handling-std-streams"
number := false
htmlSplit := .never
file := "handling-std-streams"
%%%

::: contributors
:::

# 如何从 Stdin 读取

%%%
tag := "read-stdin"
number := false
file := "read-stdin"
%%%

{index}[从 Stdin 读取]

要从 `stdin` 读取，可以使用 {lean}`IO.FS.Stream.getLine` 函数，它从标准输入流读取一行输入，并以 {lean}`IO String` 的形式返回。

```lean
def readFromStdin : IO Unit := do
  IO.print "Please enter some input: "
  (← IO.getStdout).flush
  let input ← (← IO.getStdin).getLine
  IO.println s!"You entered: {input.trimAscii}"
```

对于更复杂的输入处理，可以直接使用 {lean}`IO.getStdin` 来逐字符读取，或读取直到 EOF 的全部内容。

```lean
def readAllFromStdin : IO String := do
  let stdin ← IO.getStdin
  stdin.readToEnd
```

## 有趣的例子：交互式的玩家输入

%%%
file := "io-handling-std-streams-section-03"
%%%

CLI 工具中的一个常见模式是请求特定类型的数据（如数字），并在输入无效时重新提示用户。

```lean

/-- Repeatedly prompts the user until a valid natural number
within range is provided. -/
partial def getBoundedNat (prompt : String)
    (low high : Nat) : IO Nat := do
  IO.print s!"{prompt} ({low}-{high}): "
  (← IO.getStdout).flush
  let input ← (← IO.getStdin).getLine
  match input.trimAscii.toNat? with
  | some n =>
    if n >= low && n <= high then return n
    else
      IO.println s!"Error: {n} is out of range."
      getBoundedNat prompt low high
  | none =>
    IO.println "Error: Please enter a valid number."
    getBoundedNat prompt low high

def playerInput : IO Unit := do
  IO.print "Enter character name: "
  (← IO.getStdout).flush
  let name ← (← IO.getStdin).getLine
  
  let age ← getBoundedNat "Enter age" 1 150
  let level ← getBoundedNat "Enter starting level" 1 99
  
  IO.println s!"\nWelcome, {name.trimAscii}!"
  IO.println s!"Stats: Age {age}, Level {level}"
```

本例中，我们对 {lean}`getBoundedNat` 使用 `partial`，因为它是一个递归函数，理论上如果用户始终不提供有效输入，它可能永远运行下去。

# 如何打印到 Stdout 和 Stderr

%%%
file := "io-handling-std-streams-section-04"
%%%

{index}[打印到 Stdout 和 Stderr]

你可以分别用 {name}`IO.println` 和 {name}`IO.eprintln` 函数打印到 `stdout` 和 `stderr`。和其他语言一样，`ln` 用于在输出末尾添加一个换行符。

```lean
def printToStdout : IO Unit := do
  IO.print "This is printed to stdout without a newline."
  IO.println "This is printed to stdout with a newline."

def printToStderr : IO Unit := do
  IO.eprint "This is printed to stderr without a newline."
  IO.eprintln "This is printed to stderr with a newline."
```

## 有趣的例子：覆盖输出与刷新缓冲

%%%
file := "io-handling-std-streams-section-05"
%%%

{index}[进度条与旋转指示符]
{index}[覆盖 CLI 行]

默认情况下，标准输出通常是“行缓冲”的，也就是说，在遇到换行符（`\n`）或缓冲区被填满之前，Lean 并不会真正把文本显示在你的终端上。如果你想显示一个提示或进度消息而*不*换行，就应当手动*刷新*（flush）缓冲区。

配合使用回车符（`\r`）和 `flush`，我们可以创造出进度条或旋转指示符这类在同一行上不断更新的效果。

```lean
def showProgressBar (n: Nat) : IO Unit := do
  for i in [1:n] do
    let progress := i * 10
    let filled := String.ofList (List.replicate i '#')
    let empty := String.ofList (List.replicate (10-i) '-')
    -- \r moves the cursor back to the
    -- start of the current line
    IO.print s!"\rProgress: [{filled}{empty}] {progress}%"
    (← IO.getStdout).flush
    IO.sleep 200 -- Sleep for 200ms
  IO.println "\nTask Complete!"

def showSpinner (n: Nat) : IO Unit := do
  let spinChars := ["|", "/", "-", "\\"]
  for i in [1:n] do
    let spinChar := spinChars[i % spinChars.length]!
    IO.print s!"\rProcessing... {spinChar}"
    (← IO.getStdout).flush
    IO.sleep 100 -- 100ms is a better speed for a spinner
  IO.print "\rDone!          "
  IO.println ""


-- run `main` to see the progress bar in action like 
-- `lean --run test.lean` in your terminal.
-- def main : IO Unit := do 
--   showProgressBar 10
--   showSpinner 20
```

## 有趣的例子：使用 ANSI 颜色与辅助函数

%%%
file := "io-handling-std-streams-section-06"
%%%

{index}[ANSI 颜色]

如果你想给文本加粗、斜体或添加颜色，可以使用 ANSI 转义码来实现。与其每次都手动敲这些码，不如定义一个辅助函数更好。

```lean
/-- Wraps a string in ANSI escape codes for coloring. -/
def colorize (msg : String) (colorCode : String) : String :=
  s!"\x1b[{colorCode}m{msg}\x1b[0m"

def printStatus : IO Unit := do
  IO.println s!"Status: {colorize "SUCCESS" "32"}" -- Green
  IO.println s!"Status: {colorize "WARNING" "33"}" -- Yellow
  IO.println s!"Status: {colorize "FAILURE" "31"}" -- Red
  IO.println s!"Status: {colorize "BOLD" "1"}"    -- Bold
```

这些都是标准的 ANSI 序列；完整参考可查看[这里](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)。
