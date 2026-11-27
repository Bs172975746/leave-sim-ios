//
//  DetailView.swift
//  LeaveSim
//
//  请假详情。Tab「请假 / 续假」共用一套内容，切「续假」换成续假卡片。
//  注意：没有「销假内容」卡片（按需求删除整个销假模块）。
//
//  截图：Shot.render(...) 用同一套静态视图（interactive = false）整页渲染，
//  包含导航条、Tab 条、全部卡片和底栏 —— 与 Android 版 renderShot() 拼接
//  navbar / tabs / content / bottombar 四段的做法对应，但不含状态栏。
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - 详情页

struct DetailView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editorCenter) private var editor

    @State private var tab: DetailTab = .leave
    @State private var approvalOpen = false

    @State private var avatarItem: PhotosPickerItem?
    @State private var proofItem: PhotosPickerItem?
    @State private var avatarPickerShown = false
    @State private var proofPickerShown = false

    @State private var busy = false
    @State private var toast: String?
    @State private var sharePayload: SharePayload?
    @State private var showHelp = false
    @State private var confirmReset = false

    init() {}

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.title",
                      title: store["nav.title"],
                      showsBack: true,
                      onBack: { dismiss() })

            DetailTabStrip(store: store,
                           tab: tab,
                           onSelect: { tab = $0 },
                           interactive: true)

            ScrollView(showsIndicators: false) {
                DetailContent(store: store,
                              approvalOpen: $approvalOpen,
                              tab: tab,
                              interactive: true,
                              onPickAvatar: { avatarPickerShown = true },
                              onPickProof: { proofPickerShown = true })
                    .padding(.bottom, 12)
            }

            DetailBottomBar(store: store,
                            onSave: { saveShot(share: false) },
                            onShare: { saveShot(share: true) },
                            onReset: { confirmReset = true },
                            onToggle: { store.toggleLeaveType() },
                            onHelp: { showHelp = true })
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.78))
                    .clipShape(Capsule())
                    .padding(.bottom, 96)
                    .transition(.opacity)
            }
        }
        .overlay {
            if busy {
                ZStack {
                    Color.black.opacity(0.18).ignoresSafeArea()
                    ProgressView()
                        .padding(20)
                        .background(Palette.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .photosPicker(isPresented: $avatarPickerShown, selection: $avatarItem, matching: .images)
        .photosPicker(isPresented: $proofPickerShown, selection: $proofItem, matching: .images)
        .onChange(of: avatarItem) { item in
            guard item != nil else { return }
            Task {
                await store.loadImage(item, slot: .avatar)
                avatarItem = nil
            }
        }
        .onChange(of: proofItem) { item in
            guard item != nil else { return }
            Task {
                await store.loadImage(item, slot: .proof)
                proofItem = nil
            }
        }
        .confirmationDialog("恢复默认文字？", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("恢复默认", role: .destructive) {
                store.resetAll()
                flash("已恢复默认文字")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("所有改过的文字和放进来的图片都会被清掉。")
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.image])
        }
        .sheet(isPresented: $showHelp) {
            HelpSheet(store: store)
        }
    }

    // MARK: 截图

    private func saveShot(share: Bool) {
        guard !busy else { return }
        busy = true

        guard let image = Shot.render(CaptureDetail(store: store,
                                                    tab: tab,
                                                    approvalOpen: approvalOpen)) else {
            busy = false
            flash("渲染失败，换一台设备再试")
            return
        }

        if share {
            busy = false
            sharePayload = SharePayload(image: image)
        } else {
            Task {
                do {
                    try await AlbumWriter.save(image)
                    busy = false
                    flash("已保存到相册")
                } catch {
                    busy = false
                    flash(error.localizedDescription)
                }
            }
        }
    }

    private func flash(_ text: String) {
        withAnimation(.easeInOut(duration: 0.15)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.2)) { toast = nil }
        }
    }
}

// MARK: - Tab 条

struct DetailTabStrip: View {
    @ObservedObject var store: TextStore
    let tab: DetailTab
    let onSelect: (DetailTab) -> Void
    var interactive: Bool = true

    @Environment(\.editorCenter) private var editor

    var body: some View {
        HStack(spacing: 0) {
            item(key: "tab.qj", selected: tab == .leave, target: .leave)
            item(key: "tab.xj", selected: tab == .extend, target: .extend)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.tabHeight)
        .background(Palette.white)
    }

    private func item(key: String, selected: Bool, target: DetailTab) -> some View {
        VStack(spacing: 5) {
            Text(store[key])
                .font(.system(size: 15, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Palette.blue : Palette.textTabIdle)
                .lineLimit(1)

            Rectangle()
                .fill(selected ? Palette.blue : Color.clear)
                .frame(width: Metrics.underlineWidth, height: Metrics.underlineHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.tabHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            onSelect(target)
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            guard interactive else { return }
            editor.begin(key: key, value: store[key])
        }
    }
}

// MARK: - 内容（详情页与截图共用）

struct DetailContent: View {
    @ObservedObject var store: TextStore
    @Binding var approvalOpen: Bool
    let tab: DetailTab
    var interactive: Bool = true
    var onPickAvatar: (() -> Void)? = nil
    var onPickProof: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            headerCard

            if tab == .leave {
                leaveCard
                destCard
                approvalCard
            } else {
                extendCard
            }
        }
        .padding(.top, 0)
    }

    // MARK: 顶部头像卡

    private var headerCard: some View {
        HStack(spacing: 0) {
            RuleStrip(text: store["hd.rule"])
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .editTap("hd.rule", store["hd.rule"], enabled: interactive)
                )

            HStack(spacing: 10) {
                AvatarView(image: store.avatar, size: 56)
                    .contentShape(Circle())
                    .onTapGesture {
                        guard interactive else { return }
                        onPickAvatar?()
                    }

                EditableText(text: store["hd.name"],
                             font: .system(size: 17, weight: .semibold),
                             color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("hd.name", store["hd.name"], enabled: interactive)

                EditableText(text: store["hd.status"],
                             font: .system(size: 15),
                             color: Palette.green)
                    .editTap("hd.status", store["hd.status"], enabled: interactive)
            }
            .padding(.leading, 20)
            .padding(.trailing, 22)
            .padding(.vertical, 21)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    // MARK: 请假内容

    private var leaveCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("sec.info")
                row("l.q.student", "q.student", link: true)
                row("l.q.start",   "q.start")
                row("l.q.end",     "q.end")
                row("l.q.dur",     "q.dur")
                row("l.q.course",  "q.course")
                row("l.q.reason",  "q.reason")
                row("l.q.proof",   "q.proof", proofRow: true)
                row("l.q.place",   "q.place", link: true)
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, Metrics.cardSpacing)
    }

    // MARK: 请假去向

    private var destCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("sec.dest")
                row("l.d.left", "d.left")

                if !store.isOffCampus {
                    row("l.d.dest",  "d.dest")
                    row("l.d.addr",  "d.addr")
                    row("l.d.emerg", "d.emerg")
                    row("l.d.tel",   "d.tel", link: true)
                }
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
    }

    // MARK: 审批流程

    private var approvalCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    sectionTitle("sec.approval")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textLabel)
                        .rotationEffect(.degrees(approvalOpen ? 180 : 0))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard interactive else { return }
                    withAnimation(.easeInOut(duration: 0.18)) { approvalOpen.toggle() }
                }

                if approvalOpen {
                    row("l.a.who",  "a.who")
                    row("l.a.res",  "a.res")
                    row("l.a.time", "a.time")
                    row("l.a.note", "a.note")
                }
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
    }

    // MARK: 续假内容

    private var extendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("sec.xj")
                row("l.x.student", "x.student", link: true)
                row("l.x.start",   "x.start")
                row("l.x.end",     "x.end")
                row("l.x.dur",     "x.dur")
                row("l.x.course",  "x.course")
                row("l.x.reason",  "x.reason")
                row("l.x.proof",   "x.proof")
                row("l.x.place",   "x.place", link: true)
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, Metrics.cardSpacing)
    }

    // MARK: 行

    private func sectionTitle(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.sectionTitle, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key], enabled: interactive)
            .padding(.bottom, 5)
    }

    private func row(_ labelKey: String,
                     _ valueKey: String,
                     link: Bool = false,
                     proofRow: Bool = false,
                     trailingHint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                EditableText(text: store[labelKey], font: Typo.label, color: Palette.textLabel)
                    .frame(width: Metrics.labelWidth, alignment: .leading)
                    .editTap(labelKey, store[labelKey], enabled: interactive)

                EditableText(text: store[valueKey],
                             font: Typo.value,
                             color: link ? Palette.blue : Palette.textValue,
                             lineSpacing: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap(valueKey, store[valueKey], enabled: interactive)
                    .onTapGesture {
                        // 「是否离校」点一下直接切换，改字请长按
                        guard interactive, valueKey == "d.left" else { return }
                        store.toggleLeaveType()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        guard interactive else { return }
                        if valueKey == "d.left" {
                            editor.begin(key: valueKey, value: store[valueKey])
                        } else if proofRow {
                            onPickProof?()
                        }
                    }
            }
            .frame(minHeight: 22, alignment: .topLeading)
            .padding(.vertical, 8)

            if proofRow, let proof = store.proof {
                HStack(spacing: 0) {
                    Color.clear.frame(width: Metrics.labelWidth)
                    Image(uiImage: proof)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Palette.divider, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.5) {
                            guard interactive else { return }
                            editor.beginImage?()
                        }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - 左侧竖排小条

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
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - 底栏

struct DetailBottomBar: View {
    @ObservedObject var store: TextStore
    var onSave: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    var onToggle: (() -> Void)? = nil
    var onHelp: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    private var interactive: Bool { onSave != nil }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            HStack(spacing: 12) {
                if interactive {
                    Menu {
                        Button {
                            onSave?()
                        } label: {
                            Label("保存截图到相册", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            onShare?()
                        } label: {
                            Label("分享截图", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            onToggle?()
                        } label: {
                            Label(store.isOffCampus ? "切换为 不离校" : "切换为 离校",
                                  systemImage: "arrow.left.arrow.right")
                        }
                        Button {
                            onReset?()
                        } label: {
                            Label("恢复默认文字", systemImage: "arrow.counterclockwise")
                        }
                        Button {
                            onHelp?()
                        } label: {
                            Label("使用说明", systemImage: "questionmark.circle")
                        }
                    } label: {
                        moreBlock
                    }
                } else {
                    moreBlock
                }

                shareBlock
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(Palette.white.ignoresSafeArea(edges: .bottom))
    }

    private var moreBlock: some View {
        VStack(spacing: 3) {
            MoreGlyph()
            EditableText(text: store["bottom.more"],
                         font: .system(size: 12),
                         color: Palette.moreText)
                .editTap("bottom.more", store["bottom.more"], enabled: interactive)
        }
        .frame(width: 56)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            guard interactive else { return }
            editor.begin(key: "bottom.more", value: store["bottom.more"])
        }
    }

    private var shareBlock: some View {
        Group {
            if interactive {
                Button {
                    onShare?()
                } label: {
                    shareLabel
                }
                .buttonStyle(.plain)
            } else {
                shareLabel
            }
        }
    }

    private var shareLabel: some View {
        Text(store["bottom.fwd"])
            .font(.system(size: 15))
            .foregroundStyle(Palette.blue)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Palette.ghostBorder, lineWidth: 1)
            )
    }
}

// MARK: - 「更多」小图标（三横线 + 三点）

struct MoreGlyph: View {
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().frame(width: 12, height: 2)
                }
            }
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().frame(width: 2, height: 2)
                }
            }
        }
        .foregroundStyle(Palette.moreText)
        .frame(height: 14)
    }
}

// MARK: - 截图视图

struct CaptureDetail: View {
    @ObservedObject var store: TextStore
    let tab: DetailTab
    let approvalOpen: Bool

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.title", title: store["nav.title"], showsBack: true)

            DetailTabStrip(store: store, tab: tab, onSelect: { _ in }, interactive: false)

            VStack(spacing: 0) {
                DetailContent(store: store,
                              approvalOpen: .constant(approvalOpen),
                              tab: tab,
                              interactive: false)
                    .padding(.bottom, 12)
            }
            .background(Palette.pageBg)

            DetailBottomBar(store: store)
        }
        .background(Palette.pageBg)
    }
}

// MARK: - 分享面板

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 使用说明

struct HelpSheet: View {
    @ObservedObject var store: TextStore
    @Environment(\.dismiss) private var dismiss

    private let lines: [(String, String)] = [
        ("点一下字", "任意文字都会弹出底部编辑框，改完点「确定」立即生效，重启 App 还在。"),
        ("长按有额外功能", "Tab「请假 / 续假」、底部「更多」、首页两个 tab 长按才能改字。"),
        ("点头像", "打开相册换头像。长按「证明材料」那一行的值可以放一张缩略图。"),
        ("是否离校", "点值一下在 是 / 否 之间切换；填「否、不、no、false、0」开头的值，后面四行自动隐藏。"),
        ("审批流程", "点标题展开或收起审批明细。"),
        ("更多菜单", "保存截图到相册 / 分享截图 / 切换离校 / 恢复默认文字。"),
        ("续假", "详情页顶部切到「续假」就是续假页，截图截的是当前这一页。")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("使用说明")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.textLabel)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.element.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            Text(item.element.1)
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.textValue)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            }
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(Palette.white)
    }
}
