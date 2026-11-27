"""粗略检查 Swift 源码的括号/引号平衡，用于在没有 macOS 时提前发现语法级错误。"""
import glob
import sys


def strip(src):
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if src.startswith('"""', i):
            j = src.find('"""', i + 3)
            i = n if j < 0 else j + 3
            out.append(' ')
            continue
        if c == '"':
            i += 1
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                i += 1
            out.append(' ')
            continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


bad = 0
files = sorted(glob.glob('LeaveSim/*.swift'))
for f in files:
    code = strip(open(f, encoding='utf-8').read())
    for a, b in (('{', '}'), ('(', ')'), ('[', ']')):
        if code.count(a) != code.count(b):
            print('%-28s %s%s 不平衡 %d/%d' % (f, a, b, code.count(a), code.count(b)))
            bad += 1
print('文件 %d 个，括号问题 %d 处' % (len(files), bad))

main_files = [f for f in files if '@main' in open(f, encoding='utf-8').read()]
print('@main 所在文件：', main_files)
sys.exit(1 if bad else 0)
