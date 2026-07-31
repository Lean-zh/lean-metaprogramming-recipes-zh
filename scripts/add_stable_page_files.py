#!/usr/bin/env python3
"""为 Verso 中文标题补充稳定、无碰撞的页面文件名。

Verso 4.28 的默认文件名来自 `titleString.sluggify`。中文字符会被转成下划线，
同级且长度相同的标题可能静默写入同一目录，导致页面丢失。此脚本为每个文档
part 写入显式 `file := "..."` 元数据；已有 tag 优先用作文件名，否则按源文件
路径和标题序号生成稳定名称。
"""

from __future__ import annotations

import re
from pathlib import Path


def kebab(text: str) -> str:
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1-\2", text)
    text = re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-").lower()
    return text or "page"


def sources() -> list[Path]:
    out = [Path("Cookbook.lean")]
    out.extend(
        p for p in sorted(Path("Cookbook").rglob("*.lean"))
        if p.as_posix() != "Cookbook/Lean.lean"
    )
    return out


def base_name(path: Path) -> str:
    if path.as_posix() == "Cookbook.lean":
        return "index"
    rel = path.relative_to("Cookbook").with_suffix("")
    return kebab("-".join(rel.parts))


def transform(path: Path) -> bool:
    lines = path.read_text().splitlines()
    in_fence = False
    headings: list[tuple[int, int | None, int | None, str | None, bool]] = []
    section_no = 0

    for i, line in enumerate(lines):
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        is_doc = bool(re.match(r'^#doc \(Manual\) ".*" =>$', line))
        is_heading = bool(re.match(r"^#{1,6} .+", line))
        if not (is_doc or is_heading):
            continue
        if not is_doc:
            section_no += 1

        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        meta_start = meta_end = None
        tag = None
        if j < len(lines) and lines[j].strip() == "%%%":
            meta_start = j
            k = j + 1
            while k < len(lines) and lines[k].strip() != "%%%":
                m = re.match(r'^\s*tag\s*:=\s*"([^"]+)"', lines[k])
                if m:
                    tag = m.group(1)
                k += 1
            if k >= len(lines):
                raise RuntimeError(f"未闭合的元数据块：{path}:{j + 1}")
            meta_end = k
        headings.append((i, meta_start, meta_end, tag, is_doc))

    base = base_name(path)
    changed = False
    for ordinal, (i, meta_start, meta_end, tag, is_doc) in reversed(list(enumerate(headings, 1))):
        # 根文档本身固定输出为 index.html，不需要 file 元数据。
        if path.as_posix() == "Cookbook.lean" and is_doc:
            continue
        desired = kebab(tag) if tag else (base if is_doc else f"{base}-section-{ordinal:02d}")
        if meta_start is not None and meta_end is not None:
            if any(re.match(r"^\s*file\s*:=", lines[k]) for k in range(meta_start + 1, meta_end)):
                continue
            lines.insert(meta_end, f'file := "{desired}"')
            changed = True
        else:
            lines[i + 1:i + 1] = ["", "%%%", f'file := "{desired}"', "%%%"]
            changed = True

    if changed:
        path.write_text("\n".join(lines) + "\n")
    return changed


def main() -> None:
    changed = [str(p) for p in sources() if transform(p)]
    print(f"updated {len(changed)} files")
    for p in changed:
        print(p)


if __name__ == "__main__":
    main()
