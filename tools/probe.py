"""按 dp 坐标扫参考图的颜色分带（用来定卡片边界 / 分割线 / 底栏高度）。

用法：
  python tools/probe.py <图> row <y_dp> [--x0 0 --x1 392.7]
  python tools/probe.py <图> col <x_dp> [--y0 0 --y1 872]
输出：每段起止 dp + 主色（hex），相邻同色合并；容差 tol。
"""
import sys
import numpy as np
from PIL import Image


def runs(vals, coords, tol=6):
    out = []
    cur = vals[0]
    start = coords[0]
    prev = coords[0]
    for v, c in zip(vals[1:], coords[1:]):
        if np.abs(v.astype(int) - cur.astype(int)).max() > tol:
            out.append((start, prev, cur))
            cur = v
            start = c
        prev = c
    out.append((start, prev, cur))
    return out


def main():
    path = sys.argv[1]
    mode = sys.argv[2]
    pos = float(sys.argv[3])
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    W, H = im.width, im.height
    k = 392.7 / W  # px -> dp
    if mode == "row":
        y = int(round(pos / k))
        y = min(max(y, 0), H - 1)
        vals = a[y]
        coords = np.arange(W) * k
        print(f"== {path} row y={pos}dp (px {y})")
    else:
        x = int(round(pos / k))
        x = min(max(x, 0), W - 1)
        vals = a[:, x]
        coords = np.arange(H) * k
        print(f"== {path} col x={pos}dp (px {x})")
    for s, e, c in runs(vals, coords):
        if e - s < 0.3:
            continue
        print(f"  {s:7.1f} - {e:7.1f}  ({e - s:6.1f})  #{c[0]:02X}{c[1]:02X}{c[2]:02X}")


if __name__ == "__main__":
    main()
