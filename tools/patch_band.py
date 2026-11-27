import io
BASE = 'D:/dsh/work/leave-ios/LeaveSim/'

def band(indent):
    pad = ' ' * indent
    return (f"{pad}// 真机最底部：先一条 0.5pt 分隔线，下面才是 #F9F9F9 色带\n"
            f"{pad}VStack(spacing: 0) {{\n"
            f"{pad}    Rectangle()\n"
            f"{pad}        .fill(Palette.hairlineColor)\n"
            f"{pad}        .frame(height: 0.5)\n"
            f"{pad}    Palette.systemBar\n"
            f"{pad}        .frame(height: Metrics.bottomBand)\n"
            f"{pad}}}")

# HomeView（12 空格缩进）
p = BASE + 'HomeView.swift'
s = io.open(p, encoding='utf-8').read()
old = ("            // 真机最底部那条 #F9F9F9 色带（高度 = 底部安全区）\n"
       "            Palette.systemBar\n"
       "                .frame(height: Metrics.bottomBand)")
if old in s:
    s = s.replace(old, band(12), 1)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('HomeView ok')
else:
    print('HomeView 未匹配')

# RecordsView（16 空格缩进）
p = BASE + 'RecordsView.swift'
s = io.open(p, encoding='utf-8').read()
old = ("                // 真机最底部那条 #F9F9F9 色带\n"
       "                Palette.systemBar\n"
       "                    .frame(height: Metrics.bottomBand)")
if old in s:
    s = s.replace(old, band(16), 1)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('RecordsView ok')
else:
    print('RecordsView 未匹配')

# Palette.hairlineColor + bottomBand 35
p = BASE + 'Theme.swift'
s = io.open(p, encoding='utf-8').read()
if 'hairlineColor' not in s:
    s = s.replace("    static let systemBar   = Color(hex: 0xF9F9F9)",
                  "    static let systemBar   = Color(hex: 0xF9F9F9)\n"
                  "    static let hairlineColor = Color(hex: 0xE7E7E7)   // 底部 tab 栏下沿那条细线", 1)
import re
s = re.sub(r'static let bottomBand: CGFloat\s*=\s*34[^\n]*', 'static let bottomBand: CGFloat       = 35    // 底部 #F9F9F9 色带（真机 34.8dp）', s, count=1)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('Theme ok:', 'hairlineColor' in s, '35' in s)
