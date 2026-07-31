#!/usr/bin/env python3
"""检查中文翻译是否误改了 Cookbook 的结构与代码示例。"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

BASE_DEFAULT = "18c12de7a681c856a96e4a594fec6d39d952f7f3"


def git_text(ref: str, path: str) -> str:
    proc = subprocess.run(
        ["git", "show", f"{ref}:{path}"], text=True, capture_output=True
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"无法读取 {ref}:{path}")
    return proc.stdout


def fenced_blocks(text: str) -> list[str]:
    return re.findall(r"^(```[^\n]*\n.*?^```)\s*$", text, flags=re.M | re.S)


def captures(text: str, pattern: str) -> list[str]:
    return re.findall(pattern, text, flags=re.M)


def is_subsequence(xs: list[str], ys: list[str]) -> bool:
    it = iter(ys)
    return all(any(x == y for y in it) for x in xs)


def candidate_english_lines(text: str) -> list[tuple[int, str]]:
    """启发式列出可能尚未翻译的块外英文；不把它作为结构失败。"""
    out: list[tuple[int, str]] = []
    in_fence = False
    in_metadata = False
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if line == "%%%":
            in_metadata = not in_metadata
            continue
        if in_fence or in_metadata or not line:
            continue
        if line.startswith(("import ", "open ", "set_option ", "--", "/-", "-/")):
            continue
        if line.startswith(("{include ", "::: ", ":::", "#guard_msgs")):
            continue
        if line.startswith((
            "- [Theorem Proving in Lean]",
            "- [Mathematics in Lean]",
        )):
            continue
        # 四个以上连续英文词通常是正文；行内 API 名和短标题不会触发。
        words = re.findall(r"\b[A-Za-z][A-Za-z'-]*\b", re.sub(r"`[^`]*`", "", line))
        if len(words) >= 4 and not re.search(r"[\u3400-\u9fff]", line):
            out.append((n, raw))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=BASE_DEFAULT)
    ap.add_argument("--strict-prose", action="store_true")
    args = ap.parse_args()

    paths = sorted(
        str(p)
        for p in Path("Cookbook").rglob("*.lean")
        if p.as_posix() != "Cookbook/Lean.lean"
    )
    paths += ["Cookbook.lean", "TemplateRecipe.lean"]
    failures: list[str] = []
    prose: list[str] = []

    for path in paths:
        current_path = Path(path)
        if not current_path.exists():
            failures.append(f"缺少文件：{path}")
            continue
        base = git_text(args.base, path)
        current = current_path.read_text()

        base_fences = fenced_blocks(base)
        current_fences = fenced_blocks(current)
        if base_fences != current_fences:
            failures.append(
                f"代码块改变：{path}（基线 {len(base_fences)} 块，当前 {len(current_fences)} 块）"
            )

        for label, pattern in [
            ("tag", r'^\s*tag\s*:=\s*"([^"]+)"'),
            ("ref", r'\{ref\s+"([^"]+)"\}'),
            ("include", r'^\s*\{include\s+([^}]+)\}'),
        ]:
            old = captures(base, pattern)
            new = captures(current, pattern)
            if label == "tag":
                ok = is_subsequence(old, new)  # 中文标题可补显式稳定 tag
            else:
                ok = old == new
            if not ok:
                failures.append(f"{label} 结构改变：{path}\n  基线={old}\n  当前={new}")

        for n, line in candidate_english_lines(current):
            prose.append(f"{path}:{n}: {line}")

    if prose:
        print("可能的块外英文残留：")
        print("\n".join(prose))
    else:
        print("未发现明显的块外英文正文残留。")

    if failures:
        print("\n结构守恒检查失败：", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    if args.strict_prose and prose:
        return 2
    print(f"结构守恒检查通过：{len(paths)} 个 Lean 文档源。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
