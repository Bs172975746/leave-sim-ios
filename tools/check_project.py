#!/usr/bin/env python3
"""静态自检（本机无 macOS / Xcode，只能做这些）：

1. 11 个 Swift 文件的括号配对（{} () []，跳过字符串字面量与注释）；
2. 代码里出现的所有 store["key"] / editTap("key") / labelKey/valueKey 字面量
   是否都在 Models.swift 的 TextStore.fields 里登记；
3. Art.* 里用到的图标名在 Assets.xcassets 里都有对应 imageset；
4. project.pbxproj 的括号 / 分号配对，以及它引用的每个 Swift 文件与
   Assets.xcassets 是否真的存在于磁盘。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "LeaveSim"
ASSETS = SRC / "Assets.xcassets"
PBX = ROOT / "LeaveSim.xcodeproj" / "project.pbxproj"

errors: list[str] = []
warnings: list[str] = []


# ── 1. 括号配对 ────────────────────────────────────────────────────────────
def strip_code(text: str) -> str:
    """去掉注释与字符串字面量（保留换行，方便报行号）。"""
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                if text[i] == "\n":
                    out.append("\n")
                i += 1
            i += 2
        elif ch == '"':
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                if text[i] == "\n":
                    out.append("\n")
                i += 1
            out.append('""')
        else:
            out.append(ch)
            i += 1
    return "".join(out)


PAIRS = {"}": "{", ")": "(", "]": "["}


def check_balance(path: Path) -> None:
    raw = path.read_text(encoding="utf-8")
    code = strip_code(raw)
    stack: list[tuple[str, int]] = []
    line = 1
    for ch in code:
        if ch == "\n":
            line += 1
        elif ch in "{( [" .replace(" ", ""):
            stack.append((ch, line))
        elif ch in PAIRS:
            if not stack:
                errors.append(f"{path.name}:{line} 多余的 '{ch}'")
                return
            top, tline = stack.pop()
            if top != PAIRS[ch]:
                errors.append(f"{path.name}:{line} '{ch}' 与 {tline} 行的 '{top}' 不匹配")
                return
    for top, tline in stack:
        errors.append(f"{path.name}:{tline} 未闭合的 '{top}'")


# ── 2. key 覆盖率 ──────────────────────────────────────────────────────────
KEY_PATTERNS = [
    r'store\["([^"\\]+)"\]',
    r'\.editTap\("([^"\\]+)"',
    r'labelKey:\s*"([^"\\]+)"',
    r'valueKey:\s*"([^"\\]+)"',
    r'begin\(key:\s*"([^"\\]+)"',
    r'requiredHint\("([^"\\]+)"\)',
    r'"(rec[123]\.[a-z]+)"',
]

DYNAMIC_OK = re.compile(r"^(请|续)")


def declared_keys(models_text: str) -> set[str]:
    return set(re.findall(r'\("([^"]+)",\s*"', models_text))


def check_keys() -> None:
    models = (SRC / "Models.swift").read_text(encoding="utf-8")
    declared = declared_keys(models)
    used: dict[str, set[str]] = {}
    for swift in sorted(SRC.glob("*.swift")):
        text = swift.read_text(encoding="utf-8")
        for pat in KEY_PATTERNS:
            for key in re.findall(pat, text):
                used.setdefault(key, set()).add(swift.name)

    for key, files in sorted(used.items()):
        if key in declared:
            continue
        if DYNAMIC_OK.match(key):
            continue
        errors.append(f"未登记的 key: {key}  (出现在 {', '.join(sorted(files))})")

    # 反向：登记了但没用到（只警告）
    unused = sorted(k for k in declared if k not in used)
    if unused:
        warnings.append(f"{len(unused)} 个 key 当前没被引用: " + ", ".join(unused[:12]) + (" …" if len(unused) > 12 else ""))
    print(f"  key: 声明 {len(declared)} 个，引用 {len(used)} 个")


# ── 3. 图标 ────────────────────────────────────────────────────────────────
def check_icons() -> None:
    theme = (SRC / "Theme.swift").read_text(encoding="utf-8")
    names = re.findall(r'static let \w+\s*=\s*"([^"]+)"', theme.split("enum Art {")[1].split("}")[0])
    for name in names:
        folder = ASSETS / f"{name}.imageset"
        if not folder.is_dir():
            errors.append(f"缺少 imageset: {folder.relative_to(ROOT)}")
            continue
        contents = folder / "Contents.json"
        if not contents.is_file():
            errors.append(f"{folder.name} 缺少 Contents.json")
            continue
        try:
            json.loads(contents.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{folder.name}/Contents.json 不是合法 JSON: {exc}")
        if not any(folder.glob("*.png")):
            errors.append(f"{folder.name} 里没有 PNG")
    print(f"  图标: {len(names)} 个 imageset 全部存在且 Contents.json 合法")


# ── 4. pbxproj ─────────────────────────────────────────────────────────────
def check_pbxproj() -> None:
    if not PBX.is_file():
        errors.append("找不到 project.pbxproj")
        return
    text = PBX.read_text(encoding="utf-8")
    for ch, other in (("{", "}"), ("(", ")")):
        if text.count(ch) != text.count(other):
            errors.append(f"pbxproj 里 '{ch}' {text.count(ch)} 个 / '{other}' {text.count(other)} 个，不配对")
    # isa 段落的 ; 结尾检查：每条语句应以 ; 结束（粗略）
    for lineno, line in enumerate(text.splitlines(), 1):
        s = line.strip()
        if not s or s.startswith("//"):
            continue
        if s in ("{", "}", "(", ")", "};", ");", ""):
            continue
        if s.endswith(("{", "(", ";")):
            continue
        if s.endswith(("}", ")")):
            continue
        if "=" in s:
            warnings.append(f"pbxproj:{lineno} 这行没有以 ; 结尾: {s[:60]}")

    # 引用的源文件必须存在
    for name in sorted(set(re.findall(r"path = (\w+\.swift);", text))):
        if not (SRC / name).is_file():
            errors.append(f"pbxproj 引用了不存在的文件: LeaveSim/{name}")
    if "Assets.xcassets" not in text:
        errors.append("pbxproj 的 Resources 里没有 Assets.xcassets")
    # 每个 Swift 文件都应该同时出现在 PBXBuildFile 段与 Sources phase 里
    swift_files = sorted(p.name for p in SRC.glob("*.swift"))
    for name in swift_files:
        if f"{name} in Sources" not in text:
            errors.append(f"pbxproj 里 {name} 没有挂进 Sources build phase")
    print(f"  pbxproj: 引用 {len(swift_files)} 个 Swift 文件 + Assets.xcassets")

    # Sources phase 里列出的文件数要和磁盘一致
    listed = set(re.findall(r"(?<![\w.])[\w]+\.swift in Sources", text))
    on_disk = set(f"{n} in Sources" for n in swift_files)
    if listed != on_disk:
        errors.append(f"Sources phase 与磁盘不一致: 多 {sorted(listed - on_disk)} / 少 {sorted(on_disk - listed)}")
    print(f"  磁盘: {len(swift_files)} 个 Swift 文件")


# ── 5. 类型引用 ────────────────────────────────────────────────────────────
def check_types() -> None:
    decls: set[str] = set()
    refs: dict[str, set[str]] = {}
    for swift in sorted(SRC.glob("*.swift")):
        text = swift.read_text(encoding="utf-8")
        decls |= set(re.findall(r"\b(?:struct|class|enum|final class)\s+(\w+)", text))
        for name in re.findall(r"^\s*(?:let|var)\s+\w+\s*:\s*(?:\[)?(\w+)", text, re.M):
            refs.setdefault(name, set()).add(swift.name)
    known_swiftui = {
        "View", "String", "Int", "Double", "CGFloat", "Bool", "Color", "Font", "Image",
        "Text", "Data", "Date", "URL", "UUID", "Set", "Array", "Dictionary", "Binding",
        "State", "Published", "Environment", "StateObject", "ObservedObject", "Binding",
        "UIImage", "UIViewController", "UIActivityViewController", "CGSize", "CGRect",
        "TextAlignment", "Font", "Content", "Self", "Any", "Void", "Error",
    }
    for name, files in sorted(refs.items()):
        if name in decls or name in known_swiftui or name[0].islower():
            continue
        if name.endswith(("View", "Payload", "Store", "Center", "Monitor", "Writer",
                          "Panel", "Bar", "Row", "Strip", "Target", "Shape", "Field",
                          "State", "Tab", "Route", "Glyph", "Data", "Fmt", "Tone", "Slot")):
            errors.append(f"类型 {name} 被 {', '.join(sorted(files))} 使用但没有定义")
    print(f"  类型: 定义 {len(decls)} 个")


def main() -> int:
    print("检查 Swift 括号配对…")
    for swift in sorted(SRC.glob("*.swift")):
        check_balance(swift)

    print("检查文案 key 覆盖…")
    check_keys()

    print("检查图标资源…")
    check_icons()

    print("检查项目文件…")
    check_pbxproj()

    print("检查类型引用…")
    check_types()

    if warnings:
        print("\n警告：")
        for item in warnings:
            print("  !", item)
    if errors:
        print("\n错误：")
        for item in errors:
            print("  x", item)
        return 1
    print("\n全部检查通过（注意：不代表能编译，本机无 macOS 工具链）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
