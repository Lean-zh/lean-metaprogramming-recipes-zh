#!/usr/bin/env python3
"""本地化 Verso 生成但不由书稿控制的可见文案。"""

from pathlib import Path


REPLACEMENTS = {
    "Cross-Reference Redirection": "交叉引用跳转",
}


def main() -> None:
    root = Path("_out/html-multi")
    target = root / "find" / "index.html"
    if not target.exists():
        raise SystemExit(f"缺少生成文件：{target}")
    text = target.read_text()
    counts = {old: text.count(old) for old in REPLACEMENTS}
    for old, new in REPLACEMENTS.items():
        if counts[old] == 0:
            raise SystemExit(f"未找到待本地化文案：{old!r}")
        text = text.replace(old, new)
    target.write_text(text)
    print("localized", target)
    for old, count in counts.items():
        print(f"{old!r}: {count} occurrence(s)")


if __name__ == "__main__":
    main()
