import os
from PIL import Image, ImageDraw, ImageFont

OUT = r"D:\dsh\work\leave-ios\LeaveSim\Assets.xcassets\AppIcon.appiconset\icon-1024.png"
os.makedirs(os.path.dirname(OUT), exist_ok=True)

S = 1024
BLUE = (31, 97, 235)
WHITE = (255, 255, 255)

img = Image.new("RGB", (S, S), BLUE)
d = ImageDraw.Draw(img)

# 顶部一层更亮的蓝做点渐变感
for y in range(S):
    t = y / (S - 1)
    r = int(31 + (46 - 31) * (1 - t))
    g = int(97 + (128 - 97) * (1 - t))
    b = int(235 + (247 - 235) * (1 - t))
    d.line([(0, y), (S, y)], fill=(r, g, b))

# 白色圆角卡片
pad = 170
d.rounded_rectangle([pad, pad, S - pad, S - pad], radius=110, fill=WHITE)

font_path = r"C:\Windows\Fonts\msyhbd.ttc"
font = ImageFont.truetype(font_path, 300)

text = "假"
bbox = d.textbbox((0, 0), text, font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
d.text(((S - tw) / 2 - bbox[0], (S - th) / 2 - bbox[1] - 10), text, font=font, fill=BLUE)

# 底部一条蓝色短横，像请假单的下划线
d.rounded_rectangle([S / 2 - 90, S - pad - 120, S / 2 + 90, S - pad - 96], radius=12, fill=BLUE)

img.save(OUT, "PNG")
print(OUT, img.size)
