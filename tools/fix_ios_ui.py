"""按真机截图把 iOS 侧三处差异改回：首页导航返回箭头、撤销按钮尺寸、tab 图标着色。"""
import io
import os

ROOT = r'D:\dsh\work\leave-ios\LeaveSim'


def rw(name, fn):
    p = os.path.join(ROOT, name)
    s = io.open(p, encoding='utf-8').read()
    out = fn(s)
    if out == s:
        print('未变:', name)
    else:
        io.open(p, 'w', encoding='utf-8', newline='\n').write(out)
        print('已改:', name)


# 1) ArtImage 支持 tint（模板图才有颜色，原图不受影响）
def theme(s):
    old = """struct ArtImage: View {
    let name: String
    var width: CGFloat
    var height: CGFloat
"""
    new = """struct ArtImage: View {
    let name: String
    var width: CGFloat
    var height: CGFloat
    /// 模板渲染的图标靠这个上色；原色位图（IconJoin）传不传都一样
    var tint: Color? = nil
"""
    assert old in s
    s = s.replace(old, new, 1)

    old2 = """        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)"""
    if old2 not in s:
        # 兜底：找 ArtImage body 里的 Image 调用
        import re
        m = re.search(r'struct ArtImage: View \{(?:.|\n)*?\n\}', s)
        body = m.group(0)
        assert 'Image(name)' in body, '没找到 ArtImage 的 Image 调用'
        body2 = body.replace('.frame(width: width, height: height)',
                             '.frame(width: width, height: height)\n            .foregroundStyle(tint ?? Color.primary)', 1)
        s = s.replace(body, body2, 1)
    else:
        s = s.replace(old2, old2 + '\n            .foregroundStyle(tint ?? Color.primary)', 1)

    # 撤销按钮：40/15 -> 32/13（真机是 13sp 高约 30）
    s = s.replace('static let revokeButton  = Font.system(size: 15)',
                  'static let revokeButton  = Font.system(size: 13)', 1)
    s = s.replace('static let revokeHeight: CGFloat     = 40',
                  'static let revokeHeight: CGFloat     = 32', 1)
    s = s.replace('static let revokeMinWidth: CGFloat   = 132',
                  'static let revokeMinWidth: CGFloat   = 118', 1)
    return s


rw('Theme.swift', theme)


# 2) 首页导航补返回箭头 + tab 图标上色
def home(s):
    old = 'NavHeader(store: store, titleKey: "nav.home")'
    new = 'NavHeader(store: store, titleKey: "nav.home", showsBack: true)'
    n = s.count(old)
    s = s.replace(old, new)
    print('首页导航补箭头处数:', n)

    old_item = """            ArtImage(name: on ? iconOn : iconOff, width: iconSize, height: iconSize)"""
    new_item = """            ArtImage(name: on ? iconOn : iconOff,
                     width: iconSize, height: iconSize,
                     tint: on ? Palette.blue : Palette.textTabIdle)"""
    assert old_item in s
    s = s.replace(old_item, new_item, 1)
    return s


rw('HomeView.swift', home)


# 3) 记录页筛选漏斗同样上色
def records(s):
    import re
    m = re.search(r'ArtImage\(name: selection\.isActive \? Art\.filterActive : Art\.filterInactive,(?:.|\n)*?\)', s)
    if not m:
        print('记录页漏斗：没找到调用')
        return s
    call = m.group(0)
    if 'tint:' in call:
        print('记录页漏斗：已有 tint')
        return s
    fixed = call.replace('height: 20', 'height: 20,\n                                tint: selection.isActive ? Palette.blue : Palette.textTabIdle', 1)
    if fixed == call:
        fixed = call[:-1] + ',\n                                tint: selection.isActive ? Palette.blue : Palette.textTabIdle)'
    return s.replace(call, fixed, 1)


rw('RecordsView.swift', records)
