import VersoManual
import Cookbook.Lean

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

open Lean Elab Meta Tactic Command

set_option pp.rawOnError true

#doc (Manual) "解析命令行参数" =>

%%%
tag := "parsing-command-line-arguments"
htmlSplit := .never
file := "parsing-command-line-arguments"
%%%

::: contributors
:::

{index}[解析命令行参数]

# 解析命令行参数

%%%
tag := "parsing-cli-args"
number := false
file := "parsing-cli-args"
%%%

在 Lean 4 中，访问命令行参数最常见、最地道的方式是把 `main` 函数定义为接受一个 {lean}`List String`。当你运行可执行文件时，Lean 会自动用所提供的参数填充这个列表。

```lean
def getCliArgs (args : List String) : IO Unit := do
  IO.println s!"Received {args.length} arguments."
  for arg in args do
    IO.println s!"- {arg}"
```

如果你用 `lean --run test.lean arg1 arg2` 运行脚本，那么 `args` 将是 `["arg1", "arg2"]`。

# 简单的参数解析

%%%
file := "io-cli-args-section-03"
%%%

对许多工具来说，你只需检查特定的标志或单个输入文件。对字符串列表进行模式匹配是做这件事最地道的方式。

```lean
def parseArgs (args : List String) : IO Unit := do
  match args with
  | [] | ["--help"] | ["-h"] =>
    IO.println "Usage: mytool [OPTIONS] [FILE]\n"
    IO.println "Options:"
    IO.println "  -h, --help     Show this help"
    IO.println "  -v, --version  Show version"

  | ["--version"] | ["-v"] =>
    IO.println "mytool version 1.0.0"
  | [filename] =>
    IO.println s!"Processing file: {filename}"
  | _ =>
    IO.eprintln "Error: Unknown or too many arguments.
      Use --help for usage."
    IO.Process.exit 1
```

# 递归解析选项

%%%
file := "io-cli-args-section-04"
%%%

如果你的工具以任意顺序接受多个选项，推荐使用一个递归函数来逐步构建一个配置结构体。

```lean
structure CliConfig where
  verbose : Bool := false
  outputFile : Option String := none
  inputFiles : List String := []
deriving Repr

/-- Recursively parses arguments
  into a CliConfig structure. -/
partial def parseConfig (args : List String)
  (cfg : CliConfig := {}) : CliConfig :=
  match args with
  | [] => cfg
  | "-v" :: rest | "--verbose" :: rest =>
    parseConfig rest { cfg with verbose := true }
  | "-o" :: file :: rest | "--output" :: file :: rest =>
    parseConfig rest { cfg with outputFile := some file }
  | file :: rest =>
    parseConfig rest { cfg with inputFiles :=
      cfg.inputFiles ++ [file] }

def runParser (args : List String) : IO Unit := do
  let cfg := parseConfig args
  IO.println s!"Configuration: {repr cfg}"
```

若想要更好、更健壮的工具，可以参考 [Lean4-cli](https://github.com/leanprover/lean4-cli)，这是一个更全面的命令行解析库。
