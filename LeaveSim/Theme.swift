//
//  Theme.swift
//  LeaveSim
//
//  配色、尺寸、字号与基础零件。数值对齐 Android 版：
//  page #F3F7FF / 主色 #2561EF / 标签灰 #999999 / 错误红 #EE0A24 / 输入框底 #F7F8FA；
//  导航 48pt、标题 19pt 纯黑居中、返回 chevron 20pt 细线；
//  详情行高 35pt、标签列 103pt、卡片左右 22pt、卡片间隙 13pt、标题 17pt 加粗、正文 13pt；
//  表单行距 46pt、标签列 108pt、必填星号红、缺项提示红字在值下方。
//

import SwiftUI
import UIKit

// MARK: - 配色

enum Palette {
    static let pageBg       = Color(hex: 0xF3F7FF)
    static let white        = Color(hex: 0xFFFFFF)
    static let textPrimary  = Color(hex: 0x000000)
    static let textValue    = Color(hex: 0x2C2F36)
    static let textLabel    = Color(hex: 0x999999)
    static let textTabIdle  = Color(hex: 0x999999)
    static let blue         = Color(hex: 0x2561EF)
    static let blueSoft     = Color(hex: 0xE7EEFF)
    static let green        = Color(hex: 0x40C59C)
    static let disabled     = Color(hex: 0xC9CEDA)
    static let error        = Color(hex: 0xEE0A24)
    static let divider      = Color(hex: 0xECEEF2)
    static let ruleBg       = Color(hex: 0xE7EEFF)
    static let ghostBorder  = Color(hex: 0xDFE3EA)
    static let moreText     = Color(hex: 0x4A4F57)
    static let fieldBg      = Color(hex: 0xF7F8FA)
    static let shade        = Color.black.opacity(0.35)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - 尺寸

enum Metrics {
    static let cardRadius: CGFloat     = 12
    static let fieldRadius: CGFloat    = 8
    static let cardMargin: CGFloat     = 22
    static let cardPadding: CGFloat    = 22
    static let cardSpacing: CGFloat    = 13
    static let rowHeight: CGFloat      = 35
    static let labelWidth: CGFloat     = 103
    static let formLabelWidth: CGFloat = 108
    static let formRowPitch: CGFloat   = 46
    static let navHeight: CGFloat      = 48
    static let tabHeight: CGFloat      = 46
    static let bottomTabHeight: CGFloat = 56
    static let underlineWidth: CGFloat = 44
    static let underlineHeight: CGFloat = 3
    static let captureWidth: CGFloat   = 393
}

// MARK: - 字体

enum Typo {
    static let navTitle     = Font.system(size: 19, weight: .bold)
    static let sectionTitle = Font.system(size: 17, weight: .bold)
    static let cardTitle    = Font.system(size: 17, weight: .bold)
    static let label        = Font.system(size: 13)
    static let value        = Font.system(size: 13)
    static let tab          = Font.system(size: 15)
    static let tabLabel     = Font.system(size: 12)
    static let tiny         = Font.system(size: 11)
}

// MARK: - 图标资源名（Assets.xcassets 里的 imageset）

enum Art {
    static let tabLeaveActive    = "TabLeaveActive"
    static let tabLeaveInactive  = "TabLeaveInactive"
    static let tabRecordActive   = "TabRecordActive"
    static let tabRecordInactive = "TabRecordInactive"
    static let filterActive      = "IconFilterActive"
    static let filterInactive    = "IconFilterInactive"
    static let more              = "IconMore"
    static let join              = "IconJoin"
}

/// 模板渲染的位图图标：图形来自 SVG 转出来的 PNG，颜色由 foregroundStyle 控制。
struct ArtIcon: View {
    let name: String
    var width: CGFloat = 18
    var height: CGFloat = 18
    var tint: Color = Palette.textPrimary

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .foregroundStyle(tint)
    }
}

/// 原色位图（ic_join 那种自带蓝底的圆图），不做模板渲染。
struct ArtImage: View {
    let name: String
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
    }
}

// MARK: - 状态配色（已通过/已完成/即将休假=绿，审批中/待审批=蓝，其余=灰）

enum StatusTone {
    static func color(_ text: String) -> Color {
        let t = text
        if t.contains("驳回") || t.contains("撤销") || t.contains("逾期")
            || t.contains("未通过") || t.contains("作废") {
            return Palette.textLabel
        }
        if t.contains("即将休假") || t.contains("已通过") || t.contains("已完成")
            || t.contains("通过") || t.contains("完成") {
            return Palette.green
        }
        if t.contains("审批中") || t.contains("待审批") || t.contains("待审核") {
            return Palette.blue
        }
        return Palette.textLabel
    }
}

// MARK: - 白卡片

struct Card<Content: View>: View {
    var padding: CGFloat
    private let content: Content

    init(padding: CGFloat = Metrics.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

// MARK: - 可编辑文本

/// 纯展示的文字。点击改字由 `.editTap(key, text)` 叠在外面，
/// 这样父视图可以先 `.frame(...)` 再挂手势，热区覆盖整列。
struct EditableText: View {
    let text: String
    var font: Font = Typo.value
    var color: Color = Palette.textValue
    var lineSpacing: CGFloat = 0
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 头像

struct AvatarView: View {
    var image: UIImage?
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(Palette.blueSoft)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(Palette.blue.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - 「请假规则」竖排条

struct RuleStrip: View {
    let text: String

    var body: some View {
        ZStack {
            Palette.ruleBg
            VStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { item in
                    Text(String(item.element))
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.blue)
                }
            }
            .padding(.vertical, 11)
        }
        .frame(width: 16)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - 导航条（自绘，48pt 高）

enum NavGlyph {
    case symbol(String)
    case asset(String, Color)
}

struct NavHeader: View {
    let titleKey: String
    let title: String
    var showsBack: Bool = false
    var onBack: () -> Void = {}
    var trailing: [NavGlyph] = []
    var onTrailingTap: (Int) -> Void = { _ in }

    @Environment(\.editorCenter) private var editor

    init(titleKey: String,
         title: String,
         showsBack: Bool = false,
         onBack: @escaping () -> Void = {},
         trailing: [NavGlyph] = [],
         onTrailingTap: @escaping (Int) -> Void = { _ in }) {
        self.titleKey = titleKey
        self.title = title
        self.showsBack = showsBack
        self.onBack = onBack
        self.trailing = trailing
        self.onTrailingTap = onTrailingTap
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                if showsBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(Palette.textPrimary)
                            .frame(width: 26, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 10)
                }

                Spacer(minLength: 0)

                ForEach(Array(trailing.enumerated()), id: \.offset) { entry in
                    Button {
                        onTrailingTap(entry.offset)
                    } label: {
                        glyph(entry.element)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 10)
            }

            Text(title.isEmpty ? " " : title)
                .font(Typo.navTitle)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 58)
                .contentShape(Rectangle())
                .onTapGesture { editor.begin(key: titleKey, value: title) }
        }
        .frame(height: Metrics.navHeight)
        .frame(maxWidth: .infinity)
        .background(Palette.white)
    }

    @ViewBuilder
    private func glyph(_ item: NavGlyph) -> some View {
        switch item {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 38, height: 40)
                .contentShape(Rectangle())
        case .asset(let name, let tint):
            ArtIcon(name: name, width: 22, height: 22, tint: tint)
                .frame(width: 38, height: 40)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - 通用信息行（详情 / 列表 / 记录共用）

/// 左标签 + 右值，都可点即改；行高 35pt，标签列 103pt。
struct InfoRow: View {
    @ObservedObject var store: TextStore
    let labelKey: String
    let valueKey: String
    var interactive: Bool = true
    var valueColor: Color? = nil
    /// 给了就用它当「点值」的动作（例如「是否离校」点一下切换），改字改成值上长按。
    var valueAction: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            EditableText(text: store[labelKey], font: Typo.label, color: Palette.textLabel)
                .frame(width: Metrics.labelWidth, alignment: .leading)
                .editTap(labelKey, store[labelKey], enabled: interactive)

            if let valueAction {
                EditableText(text: store[valueKey],
                             font: Typo.value,
                             color: valueColor ?? Palette.textValue,
                             lineSpacing: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        valueAction()
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: valueKey, value: store[valueKey])
                    }
            } else {
                EditableText(text: store[valueKey],
                             font: Typo.value,
                             color: valueColor ?? Palette.textValue,
                             lineSpacing: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap(valueKey, store[valueKey], enabled: interactive)
            }
        }
        .frame(minHeight: Metrics.rowHeight)
    }
}

// MARK: - 透明点按层（ZStack 底层，避免和文字点击抢手势）

struct TapLayer: View {
    let action: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}
