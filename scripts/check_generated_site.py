#!/usr/bin/env python3
"""验证 Verso 中文站点的页面数量、标题、本地链接与代码块。"""

from __future__ import annotations

import html
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path("_out/html-multi").resolve()
EXPECTED_PAGES = 90


def plain_title(text: str) -> str:
    m = re.search(r"<title>(.*?)</title>", text, re.S)
    return html.unescape(re.sub(r"<[^>]+>", "", m.group(1) if m else "")).strip()


def resolve_local(page: Path, text: str, href: str) -> Path | None:
    parts = urlsplit(html.unescape(href))
    if parts.scheme or parts.netloc or href.startswith(("mailto:", "javascript:", "data:")):
        return None
    if not parts.path:
        return None
    path = unquote(parts.path)
    if path.startswith("/"):
        target = ROOT / path.lstrip("/")
    else:
        base_match = re.search(r'<base\s+href="([^"]+)"', text)
        base = html.unescape(base_match.group(1)) if base_match else ""
        target = (page.parent / base / path).resolve()
    if target.is_dir() or path.endswith("/"):
        target = target / "index.html"
    return target


def main() -> None:
    pages = sorted(ROOT.rglob("index.html"))
    failures: list[str] = []
    if len(pages) != EXPECTED_PAGES:
        failures.append(f"页面数错误：期望 {EXPECTED_PAGES}，实际 {len(pages)}")

    code_blocks = 0
    for page in pages:
        text = page.read_text(errors="replace")
        title = plain_title(text)
        rel = page.relative_to(ROOT)
        if rel == Path("find/index.html"):
            if title != "交叉引用跳转":
                failures.append(f"find 页面未本地化：{title!r}")
        elif rel != Path("index.html") and not re.search(r"[\u3400-\u9fff]", title):
            # API/格式名本身可以是完整标题。
            if title not in {"JSON", "TOML", "HashMap"}:
                failures.append(f"页面标题仍是英文：{rel}: {title!r}")

        code_blocks += text.count('class="hl lean block"')
        link_text = re.sub(r'<base\s+href="[^"]+"[^>]*>', "", text)
        for href in re.findall(r'href="([^"]+)"', link_text):
            if "${" in href:
                continue
            target = resolve_local(page, text, href)
            if target is None:
                continue
            try:
                target.relative_to(ROOT)
            except ValueError:
                # 指向仓库外的相对链接应改成绝对 URL；越界即失败。
                failures.append(f"站内链接越出发布目录：{rel}: {href}")
                continue
            if not target.exists():
                failures.append(f"站内链接目标不存在：{rel}: {href} -> {target.relative_to(ROOT)}")

    if code_blocks < 100:
        failures.append(f"Lean 高亮代码块过少：{code_blocks}")

    if failures:
        print("\n".join(failures))
        raise SystemExit(1)
    print(f"站点检查通过：{len(pages)} 个页面，{code_blocks} 个 Lean 高亮代码块，全部本地链接目标存在。")


if __name__ == "__main__":
    main()
