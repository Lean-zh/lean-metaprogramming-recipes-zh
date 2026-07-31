import VersoManual
import Cookbook.Lean
import Cookbook.FileSystem.ReadingFromFile
import Cookbook.FileSystem.WritingToFile
import Cookbook.FileSystem.CreatingDirectories
import Cookbook.FileSystem.ListDirectory
import Cookbook.FileSystem.DeletingFileOrDirectory
import Cookbook.FileSystem.ReadWriteJsonl
import Cookbook.FileSystem.FilePermissions
import Cookbook.FileSystem.Miscellaneous

open Verso.Genre Manual Cookbook
open Verso.Genre.Manual.InlineLean

#doc (Manual) "文件系统" =>

%%%
tag := "file-system"
number := false
%%%

::: contributors
:::

本章覆盖大多数文件系统操作，例如读写文件、创建目录、列出目录内容等。我们主要使用 {name}`System.FilePath` 类型以及 Lean 标准库中的 `IO.FS` 模块。
本章还为其他重要但不属于数据结构的文件格式补充了配方，例如常用的 JSONL。

对于像 JSON、TOML 等本身是数据结构的文件格式，可以参阅 {ref "data-structures"}[数据结构]。
本章用到多个 {lean}`IO` 配方，你可以事先在 {ref "io"}[I/O] 一章中了解它们。

*配方：*

{include 1 Cookbook.FileSystem.ReadingFromFile}
{include 1 Cookbook.FileSystem.WritingToFile}
{include 1 Cookbook.FileSystem.CreatingDirectories}
{include 1 Cookbook.FileSystem.ListDirectory}
{include 1 Cookbook.FileSystem.DeletingFileOrDirectory}
{include 1 Cookbook.FileSystem.FilePermissions}
{include 1 Cookbook.FileSystem.ReadWriteJsonl}
{include 1 Cookbook.FileSystem.Miscellaneous}
