import sys, re, xml.etree.ElementTree as ET

NS = '{http://schemas.android.com/apk/res/android}'
KEEP = ['layout_width','layout_height','orientation','orientation','textSize','textStyle','textColor','text','background','gravity','paddingStart','paddingEnd','paddingTop','paddingBottom','paddingLeft','paddingRight','layout_marginStart','layout_marginEnd','layout_marginTop','layout_marginBottom','layout_weight','minWidth','minHeight','scaleType','src','drawableStart','drawableEnd','drawablePadding','includeFontPadding','lineSpacingExtra','maxLines','ellipsize','visibility','hint','maxLength','layout_gravity','cornerRadius','layout_centerVertical','baselineAligned','weightSum','layout_marginLeft','layout_marginRight','padding','foreground']

def short(i):
    if not i: return ''
    return i.split('/')[-1]

def walk(e, depth, out):
    tag = e.tag.split('}')[-1]
    attrs = []
    for k,v in e.attrib.items():
        key = k.replace(NS,'')
        if key in KEEP:
            attrs.append(f'{key}={v}')
    txt = (e.text or '').strip()
    line = '  '*depth + f'<{tag} id={short(e.get(NS+"id"))} ' + ' '.join(attrs) + '>'
    if txt:
        line += f' TEXT="{txt[:40]}"'
    out.append(line.rstrip())
    for c in e:
        walk(c, depth+1, out)

for p in sys.argv[1:]:
    print('='*8, p)
    tree = ET.parse(p)
    out = []
    walk(tree.getroot(), 0, out)
    print('\n'.join(out))
