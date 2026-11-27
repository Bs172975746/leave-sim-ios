//
//  Theme.swift
//  LeaveSim
//
//  配色、尺寸、字体与基础零件。数值与 Android 版 res/values/colors.xml、
//  activity_main.xml 里的 dp/sp 一一对应，1dp → 1pt。
//

import SwiftUI
import UIKit

// MARK: - 配色

enum Palette {
    static let pageBg       = Color(hex: 0xF3F7FF)
    static let white        = Color(hex: 0xFFFFFF)
    static let textPrimary  = Color(hex: 0x101114)
    static let textValue    = Color(hex: 0x2C2F36)
    static let textLabel    = Color(hex: 0x94969B)
    static let textTabIdle  = Color(hex: 0x82868C)
    static let blue         = Color(hex: 0x1F61EB)
    static let green        = Color(hex: 0x17BF8D)
    static let divider      = Color(hex: 0xECEEF2)
    static let ruleBg       = Color(hex: 0xE7EEFF)
    static let ghostBorder  = Color(hex: 0xDFE3EA)
    static let moreText     = Color(hex: 0x4A4F57)
    static let fieldBg      = Color(hex: 0xF5F7FA)
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
    static let cardRadius: CGFloat = 12
    static let cardMargin: CGFloat = 22
    static let cardPadding: CGFloat = 22
    static let cardSpacing: CGFloat = 13
    static let rowHeight: CGFloat = 35
    static let labelWidth: CGFloat = 103
    static let navHeight: CGFloat = 48
    static let tabHeight: CGFloat = 46
    static let underlineWidth: CGFloat = 44
    static let underlineHeight: CGFloat = 3
    static let captureWidth: CGFloat = 393
}

// MARK: - 字体

enum Typo {
    static let navTitle     = Font.system(size: 17, weight: .semibold)
    static let sectionTitle = Font.system(size: 17, weight: .semibold)
    static let label        = Font.system(size: 13)
    static let value        = Font.system(size: 13)
    static let tab          = Font.system(size: 15)
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
/// 这样父视图可以先 `.frame(...)` 再挂手势，热区覆盖整个列宽。
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
            Circle().fill(Palette.ruleBg)
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

// MARK: - 蓝色圆形小图标

struct CircleBadge: View {
    var systemName: String
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(Palette.blue)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.52, weight: .semibold))
                    .foregroundStyle(Color.white)
            )
    }
}

// MARK: - 「请假规则」竖排条

struct VerticalRuleText: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { item in
                Text(String(item.element))
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.blue)
                    .frame(width: 16)
            }
        }
        .padding(.vertical, 11)
        .frame(width: 16)
        .background(Palette.ruleBg)
    }
}

// MARK: - 导航条（自绘，保证能进截图）

struct NavHeader: View {
    let titleKey: String
    let title: String
    var showsBack: Bool = false
    var onBack: () -> Void = {}
    var trailingIcons: [String] = []
    var onTrailingTap: (Int) -> Void = { _ in }

    @Environment(\.editorCenter) private var editor

    init(titleKey: String,
         title: String,
         showsBack: Bool = false,
         onBack: @escaping () -> Void = {},
         trailingIcons: [String] = [],
         onTrailingTap: @escaping (Int) -> Void = { _ in }) {
        self.titleKey = titleKey
        self.title = title
        self.showsBack = showsBack
        self.onBack = onBack
        self.trailingIcons = trailingIcons
        self.onTrailingTap = onTrailingTap
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                if showsBack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture { onBack() }
                        .padding(.leading, 6)
                }
                Spacer(minLength: 0)

                ForEach(Array(trailingIcons.enumerated()), id: \.offset) { entry in
                    Image(systemName: entry.element)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture { onTrailingTap(entry.offset) }
                }
                .padding(.trailing, 6)
            }

            Text(title.isEmpty ? " " : title)
                .font(Typo.navTitle)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 44)
                .contentShape(Rectangle())
                .onTapGesture { editor.begin(key: titleKey, value: title) }
        }
        .frame(height: Metrics.navHeight)
        .frame(maxWidth: .infinity)
        .background(Palette.white)
    }
}
