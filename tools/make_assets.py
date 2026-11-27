#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把 Android / cpdaily 那批现成图标塞进 Assets.xcassets。

来源：
  D:\\dsh\\work\\cpdaily\\svg\\leave_active-92ef320c.svg       → TabLeaveActive
  D:\\dsh\\work\\cpdaily\\svg\\leave_inactive-a14e1191.svg     → TabLeaveInactive
  D:\\dsh\\work\\cpdaily\\svg\\record_active-ff844c1b.svg      → TabRecordActive
  D:\\dsh\\work\\cpdaily\\svg\\record_inactive-205647b2.svg    → TabRecordInactive
  D:\\dsh\\work\\cpdaily\\svg\\filter_active-527c3776.svg      → IconFilterActive
  D:\\dsh\\work\\cpdaily\\svg\\filter_inactive-f559ac61.svg    → IconFilterInactive
  D:\\dsh\\work\\cpdaily\\svg\\more-965e5b62.svg               → IconMore
  D:\\dsh\\work\\leave-app\\res\\drawable-nodpi\\ic_join.png   → IconJoin（原图直接拷）
  D:\\dsh\\work\\cpdaily\\asset_icon640.png                    → AppIcon 1024

做法：
  1. 给没有 viewBox 的 SVG 补 viewBox（否则放大渲染会裁掉），写好目标像素尺寸；
  2. 用一个极简 HTML 包住 SVG，调 Edge 无头模式截图，
     --default-background-color=00000000 出透明底，所以 PNG 只有图形 alpha；
  3. Pillow 按 alpha 包围盒裁掉空白，存成单尺寸 PNG（single scale）；
  4. 生成 Contents.json，写进 LeaveSim/Assets.xcassets/<Name>.imageset/。

为什么不用 SVG 直接进 asset catalog：SVG 需要 "preserves-vector-representation"，
Xcode 12+ 支持，但本机没有 Xcode 无法验证；PNG 是 100% 稳的路子，且图形本身是 18pt 级小图标，
4 倍图足够。SwiftUI 侧用 .renderingMode(.template) 上色，颜色仍然由代码控制。

依赖：Python 3 + Pillow + Microsoft Edge（Chromium 无头截图）。
"""

import json
import os
import re
import subprocess
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "LeaveSim", "Assets.xcassets")
WORK = os.path.join(os.environ.get("TEMP", ROOT), "leave-ios-icons")

SVG_SRC = r"D:\dsh\work\cpdaily\svg"
PNG_SRC = r"D:\dsh\work\leave-app\res\drawable-nodpi"
ICON_SRC = r"D:\dsh\work\cpdaily\asset_icon640.png"

EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe"),
]

# (asset 名, 源文件, 渲染像素, 补的 viewBox)
SVG_ICONS = [
    ("TabLeaveActive",    "leave_active-92ef320c.svg",   72, "0 0 18 18"),
    ("TabLeaveInactive",  "leave_inactive-a14e1191.svg", 72, "0 0 18 18"),
    ("TabRecordActive",   "record_active-ff844c1b.svg",  56, "0 0 14 18"),
    ("TabRecordInactive", "record_inactive-205647b2.svg", 56, "0 0 14 18"),
    ("IconFilterActive",   "filter_active-527c3776.svg",   96, None),
    ("IconFilterInactive", "filter_inactive-f559ac61.svg", 96, None),
    ("IconMore",          "more-965e5b62.svg",            64, "0 0 16 11"),
]


def find_edge():
    for path in EDGE_CANDIDATES:
        if os.path.isfile(path):
            return path
    raise SystemExit("找不到 msedge.exe，无法无头渲染 SVG")


def normalize_svg(src_path, width_px, height_px, view_box):
    """读源 SVG，按目标像素尺寸重写成一份独立可渲染的 SVG。"""
    with open(src_path, "rb") as fh:
        raw = fh.read()
    text = raw.decode("utf-8-sig")

    if view_box and "viewBox" not in text:
        text = text.replace("<svg ", '<svg viewBox="%s" ' % view_box, 1)

    # 固定成目标像素（去掉 width="18px" height="18px" 这类写法）
    text = re.sub(r'\swidth="[^"]*"', ' width="%d"' % width_px, text, count=1)
    text = re.sub(r'\sheight="[^"]*"', ' height="%d"' % height_px, text, count=1)
    # 根节点若没有 fill，让图形默认纯黑（模板图只看 alpha，颜色无所谓）
    text = text.replace("<svg ", '<svg fill="#000000" ', 1)
    return text


def render_svg(edge, name, svg_text, width_px, height_px):
    os.makedirs(WORK, exist_ok=True)
    svg_path = os.path.join(WORK, name + ".svg")
    html_path = os.path.join(WORK, name + ".html")
    png_path = os.path.join(WORK, name + ".png")

    with open(svg_path, "w", encoding="utf-8") as fh:
        fh.write(svg_text)

    html = (
        '<!doctype html><html><head><meta charset="utf-8">'
        "<style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}"
        "img{display:block;width:%dpx;height:%dpx}</style></head>"
        '<body><img src="%s.svg"></body></html>' % (width_px, height_px, name)
    )
    with open(html_path, "w", encoding="utf-8") as fh:
        fh.write(html)

    cmd = [
        edge,
        "--headless=new",
        "--disable-gpu",
        "--no-sandbox",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        "--default-background-color=00000000",
        "--window-size=%d,%d" % (width_px, height_px),
        "--screenshot=" + png_path,
        "file:///" + html_path.replace("\\", "/"),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not os.path.isfile(png_path):
        raise SystemExit("Edge 没有产出 " + png_path)
    return png_path


def trim_alpha(png_path):
    img = Image.open(png_path).convert("RGBA")
    bbox = img.split()[-1].getbbox()
    if bbox:
        img = img.crop(bbox)
    # 周围留 1px 透明边，避免贴边像素在缩放时被吃掉
    canvas = Image.new("RGBA", (img.width + 2, img.height + 2), (0, 0, 0, 0))
    canvas.paste(img, (1, 1))
    return canvas


def write_imageset(name, image, scale_note):
    folder = os.path.join(ASSETS, name + ".imageset")
    os.makedirs(folder, exist_ok=True)
    filename = name + ".png"
    image.save(os.path.join(folder, filename), "PNG", optimize=True)

    contents = {
        "images": [
            {
                "filename": filename,
                "idiom": "universal",
                # single scale（不写 scale 字段）—— iOS 11+ 合法写法
            }
        ],
        "info": {"author": "xcode", "version": 1},
    }
    if scale_note:
        contents["properties"] = {"template-rendering-intent": scale_note}
    with open(os.path.join(folder, "Contents.json"), "w", encoding="utf-8") as fh:
        json.dump(contents, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print("  assets  %-22s %dx%d" % (name, image.width, image.height))


def main():
    edge = find_edge()

    for name, src, px, view_box in SVG_ICONS:
        src_path = os.path.join(SVG_SRC, src)
        if not os.path.isfile(src_path):
            raise SystemExit("缺源文件 " + src_path)
        # 按 SVG 自身宽高比算高度
        with open(src_path, "rb") as fh:
            head = fh.read(400).decode("utf-8-sig", "ignore")
        w = re.search(r'width="([\d.]+)px"', head)
        h = re.search(r'height="([\d.]+)px"', head)
        if w and h:
            ratio = float(h.group(1)) / float(w.group(1))
        else:
            ratio = 1.0
        height_px = max(1, int(round(px * ratio)))
        svg_text = normalize_svg(src_path, px, height_px, view_box)
        png = render_svg(edge, name, svg_text, px, height_px)
        write_imageset(name, trim_alpha(png), "template")

    # ic_join：原图直接用，不裁剪、不改色
    join = Image.open(os.path.join(PNG_SRC, "ic_join.png")).convert("RGBA")
    write_imageset("IconJoin", join, None)

    # AppIcon：192 → 1024
    icon = Image.open(ICON_SRC).convert("RGB")
    icon = icon.resize((1024, 1024), Image.LANCZOS)
    icon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    icon.save(os.path.join(icon_dir, "icon-1024.png"), "PNG", optimize=True)
    print("  appicon icon-1024.png 1024x1024")

    print("完成。")


if __name__ == "__main__":
    sys.exit(main())
