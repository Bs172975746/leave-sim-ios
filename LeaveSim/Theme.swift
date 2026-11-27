//
//  Theme.swift
//  LeaveSim
//
//  视觉层的唯一出口：颜色、尺寸、字号、矢量图标、通用部件。
//  所有数值都来自安卓克隆版的 res/values/colors.xml 与 res/layout/*.xml，
//  单位换算 1dp = 1pt，视图里不再出现裸数字。
//

import SwiftUI
import UIKit

// MARK: - 颜色（colors.xml / drawable 里的取色）

enum Palette {
    // 底色与卡片
    static let pageBg      = Color(hex: 0xF3F7FF)
    static let white       = Color.white
    static let systemBar   = Color(hex: 0xF9F9F9)
    static let hairlineColor = Color(hex: 0xE7E7E7)   // 底部 tab 栏下沿那条细线   // 底部系统条（真机最底下那条色差）
    static let cardBg      = Color.white

    // 文字
    static let navTitle    = Color(hex: 0x000000)   // 导航标题：纯黑
    static let textPrimary = Color(hex: 0x24262A)   // text_primary
    static let textValue   = Color(hex: 0x33363B)   // text_value
    static let textLabel   = Color(hex: 0x999999)   // text_label
    static let textTabIdle = Color(hex: 0x82868C)   // text_tab_idle
    static let textHint    = Color(hex: 0x9AA0A6)   // text_hint
    static let moreText    = Color(hex: 0x4A4F57)   // 详情底栏「更多」
    static let footerText  = Color(hex: 0x8A8F94)   // 列表尾部「没有更多数据了~」

    // 主色
    static let blue        = Color(hex: 0x2561EF)   // colors.xml blue
    static let avatarBlue  = Color(hex: 0x1F61EB)   // bg_avatar_blue
    static let chipOn      = Color(hex: 0x1F61EB)   // bg_chip_on
    static let green       = Color(hex: 0x40C59C)
    static let error       = Color(hex: 0xEE0A24)

    // 面
    static let blueSoft    = Color(hex: 0xE7EEFF)   // bg_rules
    static let banner      = Color(hex: 0xE8F0FE)   // bg_banner
    static let chipBg      = Color(hex: 0xF1F3F7)   // bg_chip
    static let fieldBg     = Color(hex: 0xF7F8FA)   // bg_field
    static let thumb       = Color(hex: 0xE9EDF2)   // bg_thumb
    static let avatarBg    = Color(hex: 0xE9EEF7)   // bg_avatar
    static let ghostFill   = Color(hex: 0xF1F2F5)   // bg_btn_ghost

    // 描边 / 分割
    static let divider     = Color(hex: 0xEEEEEE)
    static let outline     = Color(hex: 0xDCE0E8)   // bg_btn_outline 描边
    static let fwdBorder   = Color(hex: 0xDFE3EA)   // bg_fwd 描边
    static let dashed      = Color(hex: 0xC9CDD6)   // bg_dashed 虚线
    static let chevron     = Color(hex: 0xC2C6CE)   // ic_chevron_right
    static let chevronDown = Color(hex: 0x9AA0AA)   // ic_chevron
    static let back        = Color(hex: 0x333333)   // ic_back
    static let filterIcon  = Color(hex: 0x666666)   // ic_filter
    static let checkOff    = Color(hex: 0xC6CAD2)   // ic_check_off
    static let disabled    = Color(hex: 0xB9BDC5)   // bg_btn_gray

    static let shade       = Color.black.opacity(0.35)

    // 兼容旧命名（EditSheet / Wheels / Shot / App 仍在用）
    static let ruleBg      = blueSoft
    static let ghostBorder = fwdBorder
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

// MARK: - 字号

enum Typo {
    static let navTitle      = Font.system(size: 19, weight: .regular)   // 48dp 导航条标题
    static let formTitle     = Font.system(size: 20, weight: .bold)      // 申请表头部假别
    static let section       = Font.system(size: 17, weight: .bold)      // 分区标题
    static let detailName    = Font.system(size: 18, weight: .bold)      // 详情页姓名
    static let homeTitle     = Font.system(size: 15, weight: .bold)      // 列表卡标题
    static let recordTitle   = Font.system(size: 15, weight: .bold)      // 记录卡标题
    static let typeLabel     = Font.system(size: 15, weight: .bold)      // 发起卡标签
    static let avatarName    = Font.system(size: 15, weight: .bold)      // 卡内申请人
    static let recordName    = Font.system(size: 14)                     // 记录卡申请人
    static let detailStatus  = Font.system(size: 15)                     // 详情页状态
    static let status        = Font.system(size: 13)                     // 列表 / 记录卡状态
    static let row           = Font.system(size: 13)                     // 信息行
    static let formRow       = Font.system(size: 13)                     // 申请表行
    static let more          = Font.system(size: 14)                     // 列表卡「更多」
    static let moreSmall     = Font.system(size: 12)                     // 详情底栏「更多」
    static let footer        = Font.system(size: 14)                     // 列表尾部
    static let revokeButton  = Font.system(size: 13)                     // 撤销按钮
    static let tabBar        = Font.system(size: 12)                     // 底部 tab 文字
    static let tabBarActive  = Font.system(size: 12, weight: .bold)      // 选中的底部 tab
    static let tabStrip      = Font.system(size: 15)                     // 详情分段 tab
    static let tabStripBold  = Font.system(size: 15, weight: .bold)      // 选中的详情分段 tab
    static let rule          = Font.system(size: 10)                     // 竖排「请假规则」
    static let revokeSmall   = Font.system(size: 13)
    static let errHint       = Font.system(size: 12)                     // 校验红字
    static let counter       = Font.system(size: 12)                     // 0/1000
    static let agree         = Font.system(size: 14)                     // 承诺书勾选行
    static let body          = Font.system(size: 15)                     // 承诺书正文
    static let filterTitle   = Font.system(size: 17)
    static let filterSection = Font.system(size: 15)
    static let field         = Font.system(size: 14)
    static let sheetButton   = Font.system(size: 16)
    static let submit        = Font.system(size: 17)
    static let fwd           = Font.system(size: 17)
}

// MARK: - 尺寸

enum Metrics {
    static let navHeight: CGFloat        = 48    // 导航条
    static let backBox: CGFloat          = 58    // 返回热区（58×48，图标居中）
    static let pagePadding: CGFloat      = 22    // 页面左右留白 / 卡片内边距
    static let cardRadius: CGFloat       = 12    // bg_card
    static let cardGap: CGFloat          = 13    // 卡与卡之间的间隔
    static let fieldRadius: CGFloat      = 10    // bg_field / 提交按钮
    static let smallRadius: CGFloat      = 6     // 表格按钮 / 虚线框
    static let chipRadius: CGFloat       = 4     // bg_chip
    static let ruleRadius: CGFloat       = 4     // bg_rules 右侧圆角
    static let sheetRadius: CGFloat      = 18    // bg_sheet

    static let homeSectionTop: CGFloat   = 8.2    // 「进行中」
    static let homeCardTop: CGFloat      = 18.2    // 进行中卡
    static let homeSection2Top: CGFloat  = 23.8    // 「发起」
    static let homeTypeFirstTop: CGFloat = 25    // 第一张发起卡
    static let homeTypeGap: CGFloat      = 15    // 发起卡之间
    static let homeTypeHeight: CGFloat   = 64    // 发起卡高度
    static let homeTypeIcon: CGFloat     = 44    // ic_join
    static let homeInfoTop: CGFloat      = 11.1
    static let homeInfoPad: CGFloat      = 4.0     // 每行信息上下 padding
    static let homeFootTop: CGFloat      = 34
    static let homeCardPadTop: CGFloat   = 18.4
    static let homeCardPadBottom: CGFloat = 15.8
    static let homeWhoTop: CGFloat       = 16
    static let homeMoreTop: CGFloat      = 11
    static let avatarSmall: CGFloat      = 26    // 卡内头像
    static let avatarSmallIcon: CGFloat  = 16
    static let recordAvatarIcon: CGFloat = 14
    static let revokeHeight: CGFloat     = 32
    static let revokeMinWidth: CGFloat   = 118

    static let tabBarRow: CGFloat        = 52
    static let bottomBand: CGFloat       = 35    // 底部 #F9F9F9 色带（真机 34.8dp）
    static let tabIcon: CGFloat          = 24
    static let tabIconRecord: CGFloat    = 22
    static let tabTextTop: CGFloat       = 2
    static let hairline: CGFloat         = 0.5

    static let stripHeight: CGFloat      = 46    // 详情分段 tab
    static let stripUnderlineW: CGFloat  = 44
    static let stripUnderlineH: CGFloat  = 3
    static let stripUnderlineTop: CGFloat = 5
    static let underlineRadius: CGFloat  = 2

    static let ruleWidth: CGFloat        = 16    // 竖排「请假规则」条
    static let rulePadV: CGFloat         = 11
    static let headerPadStart: CGFloat   = 36    // 详情 / 表单头卡
    static let headerPadEnd: CGFloat     = 22
    static let headerPadV: CGFloat       = 21
    static let formHeaderPadV: CGFloat   = 20
    static let avatarDetail: CGFloat     = 56
    static let avatarGap: CGFloat        = 6     // 头像与姓名

    static let cardPadTop: CGFloat       = 16    // 信息卡
    static let cardPadBottom: CGFloat    = 10
    static let sectionPadTop: CGFloat    = 6     // 分区标题上方内边距
    static let sectionPadBottom: CGFloat = 8     // 分区标题与首行
    static let rowPadV: CGFloat          = 8     // 详情页行上下 padding
    static let labelWidth: CGFloat       = 103   // 详情页标签列
    static let formRowPadV: CGFloat      = 15    // 申请表行上下 padding
    static let formLabelWidth: CGFloat   = 108
    static let starWidth: CGFloat       = 15   // 星号 + 8pt 间距
    static let starGap: CGFloat          = 6     // 星号与标签
    static let hintIndent: CGFloat       = 138   // 红字左缩进
    static let chevronSmall: CGFloat     = 16    // ic_chevron_right
    static let chevronFold: CGFloat      = 18    // ic_chevron
    static let reasonMinHeight: CGFloat  = 52
    static let proofBox: CGFloat         = 54    // 上传框
    static let ccBox: CGFloat            = 66    // 抄送人上传框
    static let placeDividerW: CGFloat    = 14    // 发起位置竖线
    static let proofHintTop: CGFloat     = 8     // 上传框下提示间距
    static let fieldHeight: CGFloat      = 44    // 筛选字段
    static let bigButton: CGFloat        = 46    // 46dp 按钮
    static let submitHeight: CGFloat     = 48
    static let chipHeight: CGFloat       = 34

    static let bottomBarPadStart: CGFloat = 14
    static let bottomBarPadEnd: CGFloat   = 16
    static let bottomBarPadTop: CGFloat   = 8
    static let bottomBarPadBottom: CGFloat = 16
    static let moreBoxWidth: CGFloat      = 56
    static let moreIconW: CGFloat         = 20
    static let moreIconH: CGFloat         = 14
    static let moreIconTop: CGFloat       = 3
    static let fwdRadius: CGFloat        = 8
    static let fwdHeight: CGFloat         = 46
    static let fwdGap: CGFloat            = 12

    static let promisePad: CGFloat        = 40
    static let promiseTop: CGFloat        = 72
    static let promisePadBottom: CGFloat  = 24
    static let promiseParaGap: CGFloat    = 18
    static let checkSize: CGFloat         = 22
    static let checkGap: CGFloat          = 10

    static let filterRowH: CGFloat      = 40   // 记录页筛选行
    static let filterIconSize: CGFloat  = 20
    static let filterIconPad: CGFloat   = 10
    static let filterRowEnd: CGFloat    = 6
    static let formContentBottom: CGFloat = 14
    static let filterRowHeight: CGFloat   = 52
    static let filterBodyTop: CGFloat     = 14
    static let filterFieldTop: CGFloat    = 10
    static let filterSectionTop: CGFloat  = 16
    static let filterChipTop: CGFloat     = 10
    static let filterChipGap: CGFloat     = 8
    static let filterButtonTop: CGFloat   = 12
    static let filterPadBottom: CGFloat   = 14

    // 列表 / 记录 / 表单里剩下的零碎间距（全部对应 XML 里的具体 dp）
    static let pageBottom: CGFloat        = 24    // 内容底部留白
    static let typeTextGap: CGFloat       = 12    // 发起卡图标与文字
    static let whoGap: CGFloat            = 10    // 头像与姓名
    static let recordsTop: CGFloat        = 14    // 记录页内容上边距
    static let bannerTop: CGFloat         = 13    // 统计条上边距
    static let bannerPadV: CGFloat        = 10
    static let bannerPadH: CGFloat        = 12
    static let cardTopFirst: CGFloat      = 8     // 记录卡：首卡上边距
    static let cardTopGap: CGFloat        = 12    // 记录卡：卡间距
    static let recCardPadH: CGFloat       = 22
    static let recCardPadV: CGFloat       = 18
    static let recInfoTop1: CGFloat       = 10    // 记录卡三行的上边距
    static let recInfoTop2: CGFloat       = 6
    static let recFootTop: CGFloat        = 16
    static let proofPadTop: CGFloat       = 12    // 证明材料行上下
    static let proofPadBottom: CGFloat    = 4
    static let placePadTop: CGFloat       = 12    // 发起位置行上下
    static let placePadBottom: CGFloat    = 8
    static let inlineGap: CGFloat         = 10    // 行内竖线左右
    static let ccTop: CGFloat             = 14    // 抄送人加号 / 提示行上边距
    static let ccListTop: CGFloat         = 10
    static let ccPadBottom: CGFloat       = 16
    static let sheetBodyBottom: CGFloat   = 12    // 筛选面板内容底部
    static let sheetFieldPadH: CGFloat    = 12    // 字段左右内边距
    static let sheetCloseW: CGFloat       = 44
    static let promiseCheckTop: CGFloat   = 14    // 勾选行上下
    static let promiseCheckBottom: CGFloat = 6
    static let promiseButtonTop: CGFloat  = 6
    static let promiseButtonBottom: CGFloat = 14
    static let submitPadV: CGFloat        = 10    // 提交栏上下
    static let designWidth: CGFloat       = 411      // 原版逻辑宽（1206px / 2.931）
    static let designHeight: CGFloat      = 894.6    // 原版逻辑高（2622px / 2.931）
    static let captureWidth: CGFloat      = 411      // 与原版一致：1206px / 2.931
    static let captureHeight: CGFloat     = 894.6    // 原版 2622px / 2.931
    static let captureScale: CGFloat      = 2.931      // 与原版一致：1206px / 2.931
}

// MARK: - 资源名

enum Art {
    static let tabLeaveActive   = "TabLeaveActive"
    static let tabLeaveInactive = "TabLeaveInactive"
    static let tabRecordActive  = "TabRecordActive"
    static let tabRecordInactive = "TabRecordInactive"
    static let filterActive     = "IconFilterActive"
    static let filterInactive   = "IconFilterInactive"
    static let more             = "IconMore"
    static let join             = "IconJoin"
}

/// 位图图标：保持原色，按 frame 缩放。
struct ArtImage: View {
    let name: String
    var width: CGFloat = 24
    var height: CGFloat = 24
    /// 模板渲染的图标靠这个上色；原色位图（IconJoin）传了也不生效
    var tint: Color? = nil

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .foregroundStyle(tint ?? Color.primary)
            .accessibilityHidden(true)
    }
}

// MARK: - 自绘图标（对应 res/drawable 里的矢量）

/// ic_back：20×20，线宽 1.9，#333333
struct BackChevron: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 20.0
            var path = Path()
            path.move(to: CGPoint(x: 15.4 * s, y: 0.9 * s))
            path.addLine(to: CGPoint(x: 4.6 * s, y: 10.0 * s))
            path.addLine(to: CGPoint(x: 15.4 * s, y: 19.1 * s))
            context.stroke(path,
                           with: .color(Palette.back),
                           style: StrokeStyle(lineWidth: 1.9 * s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 20, height: 20)
    }
}

/// ic_chevron_right：16×16，viewport 24，线宽 2，#C2C6CE
struct ChevronRight: View {
    var color: Color = Palette.chevron

    var body: some View {
        Canvas { context, size in
            let s = size.width / 24.0
            var path = Path()
            path.move(to: CGPoint(x: 9 * s, y: 5.5 * s))
            path.addLine(to: CGPoint(x: 16 * s, y: 12 * s))
            path.addLine(to: CGPoint(x: 9 * s, y: 18.5 * s))
            context.stroke(path,
                           with: .color(color),
                           style: StrokeStyle(lineWidth: 2 * s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 16, height: 16)
    }
}

/// ic_chevron：18×18，viewport 24，线宽 2，#9AA0AA（可翻转表示展开态）
struct ChevronFold: View {
    var up: Bool = false

    var body: some View {
        Canvas { context, size in
            let s = size.width / 24.0
            var path = Path()
            path.move(to: CGPoint(x: 6 * s, y: 9.5 * s))
            path.addLine(to: CGPoint(x: 12 * s, y: 15.5 * s))
            path.addLine(to: CGPoint(x: 18 * s, y: 9.5 * s))
            context.stroke(path,
                           with: .color(Palette.chevronDown),
                           style: StrokeStyle(lineWidth: 2 * s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 18, height: 18)
        .rotationEffect(.degrees(up ? 180 : 0))
    }
}

/// ic_person：白色人形（放进蓝色圆里）
struct PersonGlyph: View {
    var color: Color = .white
    var size: CGFloat = 16

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24.0
            let head = CGRect(x: 8.4 * s, y: 4.6 * s, width: 7.2 * s, height: 7.2 * s)
            var headPath = Path()
            headPath.addEllipse(in: head)
            context.fill(headPath, with: .color(color))

            let body = CGRect(x: 4.6 * s, y: 14.2 * s, width: 14.8 * s, height: 6.3 * s)
            var bodyPath = Path()
            bodyPath.addRoundedRect(in: body,
                                    cornerSize: CGSize(width: 5.2 * s, height: 5.2 * s))
            context.fill(bodyPath, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

/// ic_more：20×13.75 的三横线
struct MoreGlyph: View {
    var color: Color = Palette.back
    var width: CGFloat = 20
    var height: CGFloat = 14

    var body: some View {
        Canvas { context, size in
            let unit = size.width / 20.0
            let bars: [(CGFloat, CGFloat)] = [(0, 1.6), (5.3, 1.6), (10.6, 1.6)]
            for (y, h) in bars {
                let rect = CGRect(x: 0, y: y * unit, width: 20 * unit, height: h * unit)
                var path = Path()
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: 0.8 * unit, height: 0.8 * unit))
                context.fill(path, with: .color(color))
            }
        }
        .frame(width: width, height: height)
    }
}

/// ic_check_off / ic_check_on：22×22
struct CheckMark: View {
    var on: Bool

    var body: some View {
        ZStack {
            if on {
                Circle().fill(Palette.avatarBlue)
            } else {
                Circle().strokeBorder(Palette.checkOff, lineWidth: 1.6 * (22.0 / 24.0))
            }
            if on {
                Canvas { context, size in
                    let s = size.width / 24.0
                    var path = Path()
                    path.move(to: CGPoint(x: 7.8 * s, y: 12.3 * s))
                    path.addLine(to: CGPoint(x: 10.7 * s, y: 15.2 * s))
                    path.addLine(to: CGPoint(x: 16.2 * s, y: 9.1 * s))
                    context.stroke(path,
                                   with: .color(.white),
                                   style: StrokeStyle(lineWidth: 2 * s, lineCap: .round, lineJoin: .round))
                }
                .padding(2)
            }
        }
        .frame(width: Metrics.checkSize, height: Metrics.checkSize)
    }
}

// MARK: - 状态色

enum StatusTone {
    static func color(_ status: String) -> Color {
        if status.contains("驳回") || status.contains("撤销")
            || status.contains("逾期") || status.contains("未通过")
            || status.contains("作废") {
            return Palette.textLabel
        }
        if status.contains("已完成") || status.contains("即将休假")
            || status.contains("已通过") || status.contains("通过")
            || status.contains("完成") {
            return Palette.green
        }
        if status.contains("审批中") || status.contains("待审批") || status.contains("待审核") {
            return Palette.blue
        }
        return Palette.textLabel
    }
}

// MARK: - 可编辑文字

/// 点一下就能改字的文本；空串时撑一个空格，避免整行塌掉。
struct EditableText: View {
    var text: String
    var font: Font
    var color: Color
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

// MARK: - 卡片容器

struct Card<Content: View>: View {
    var padding: CGFloat = Metrics.pagePadding
    var paddingTop: CGFloat? = nil
    var paddingBottom: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, padding)
            .padding(.top, paddingTop ?? padding)
            .padding(.bottom, paddingBottom ?? padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

// MARK: - 头像

/// 卡内小头像：26pt 蓝圆 + 白人形；有照片就换成照片。
struct AvatarBadge: View {
    var image: UIImage? = nil
    var size: CGFloat = Metrics.avatarSmall
    var glyphSize: CGFloat = Metrics.avatarSmallIcon

    var body: some View {
        ZStack {
            Circle().fill(Palette.avatarBlue)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                PersonGlyph(color: .white, size: glyphSize)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// 详情页头像：56pt 浅灰蓝圆 + 照片（没有照片时用人形占位）。
struct AvatarView: View {
    var image: UIImage?
    var size: CGFloat = Metrics.avatarDetail

    var body: some View {
        ZStack {
            Circle().fill(Palette.avatarBg)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(Palette.blue.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - 右侧圆角的浅蓝竖条（请假规则）

struct RuleStrip: View {
    var text: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(Typo.rule)
                    .foregroundStyle(Palette.blue)
            }
        }
        .padding(.vertical, Metrics.rulePadV)
        .frame(width: Metrics.ruleWidth)
        .background(Palette.ruleBg)
        .clipShape(RightRoundedShape(radius: Metrics.ruleRadius))
    }
}

/// 只有右侧两个角是圆角。
struct RightRoundedShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 导航条

struct NavHeader: View {
    @ObservedObject var store: TextStore
    let titleKey: String
    var showsBack: Bool = false
    var onBack: () -> Void = {}
    var trailing: [NavGlyph] = []
    var onTrailingTap: (Int) -> Void = { _ in }

    @Environment(\.editorCenter) private var editor

    var body: some View {
        ZStack {
            EditableText(text: store[titleKey], font: Typo.navTitle, color: Palette.navTitle)
                .lineLimit(1)
                .editTap(titleKey, store[titleKey])

            HStack(spacing: 0) {
                if showsBack {
                    Button(action: onBack) {
                        BackChevron()
                            .frame(width: 20, height: 20)
                            .frame(width: Metrics.backBox, height: Metrics.navHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                ForEach(Array(trailing.enumerated()), id: \.offset) { index, glyph in
                    Button {
                        onTrailingTap(index)
                    } label: {
                        glyph.view
                            .frame(width: 38, height: Metrics.navHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 4)
        }
        .frame(height: Metrics.navHeight)
        .frame(maxWidth: .infinity)
        .background(Palette.white)
    }
}

enum NavGlyph {
    case symbol(String, Color)
    case asset(String, Color)

    @ViewBuilder var view: some View {
        switch self {
        case let .symbol(name, color):
            Image(systemName: name)
                .font(.system(size: 18))
                .foregroundStyle(color)
        case let .asset(name, _):
            ArtImage(name: name, width: 22, height: 22)
        }
    }
}

// MARK: - 分区标题

struct SectionTitle: View {
    @ObservedObject var store: TextStore
    let labelKey: String
    var interactive: Bool = true

    var body: some View {
        EditableText(text: store[labelKey], font: Typo.section, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(labelKey, store[labelKey], enabled: interactive)
    }
}

// MARK: - 详情页信息行（标签列 103 + 值）

struct InfoRow: View {
    @ObservedObject var store: TextStore
    let labelKey: String
    let valueKey: String
    var interactive: Bool = true
    var valueColor: Color? = nil
    var valueAction: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EditableText(text: store[labelKey], font: Typo.row, color: Palette.textLabel)
                .frame(width: Metrics.labelWidth, alignment: .leading)
                .editTap(labelKey, store[labelKey], enabled: interactive)

            EditableText(text: store[valueKey],
                         font: Typo.row,
                         color: valueColor ?? Palette.textValue,
                         lineSpacing: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard interactive else { return }
                    if let valueAction { valueAction() }
                }
                .onLongPressGesture(minimumDuration: 0.45) {
                    guard interactive else { return }
                    editor.begin(key: valueKey, value: store[valueKey])
                }
        }
        .padding(.vertical, Metrics.rowPadV)
    }
}

// MARK: - 按钮样式

struct PrimaryButtonStyle: ViewModifier {
    var height: CGFloat = Metrics.bigButton
    var font: Font = Typo.sheetButton
    var enabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(enabled ? Palette.blue : Palette.disabled)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
    }
}

struct OutlineButtonStyle: ViewModifier {
    var height: CGFloat = Metrics.bigButton
    var font: Font = Typo.sheetButton
    var textColor: Color = Palette.textPrimary
    var border: Color = Palette.outline

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
    }
}

// MARK: - 点击热区辅助

struct TapLayer: View {
    var action: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { action() }
    }
}
