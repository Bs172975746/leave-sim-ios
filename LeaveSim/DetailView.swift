//
//  DetailView.swift
//  LeaveSim
//
//  ②请假详情：请假 / 续假 两 tab、请假规则竖条、头像 + 姓名 + 状态、
//  请假内容、请假去向、可折叠审批流程、底部 更多 / 转发。
//  这里的每个值都是 q.* / d.* / a.* 这批 key，和列表页「进行中」卡片是同一份数据。
//

import SwiftUI
import PhotosUI

// MARK: - 详情页

struct DetailView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss

    @State private var tab: DetailTab = .leave
    @State private var approvalOpen = true
    @State private var showPicker = false
    @State private var pickerSlot: ImageSlot = .avatar
    @State private var pickerItem: PhotosPickerItem?
    @State private var showHelp = false
    @State private var showMoreMenu = false
    @State private var sharePayload: SharePayload?
    @StateObject private var exporter = ShotExporter()

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.detail",
                      title: store["nav.detail"],
                      showsBack: true,
                      onBack: { dismiss() },
                      trailing: [.symbol("camera")],
                      onTrailingTap: { _ in exporter.asking = true })

            DetailTabStrip(store: store, selected: $tab, interactive: true)

            ScrollView(showsIndicators: false) {
                DetailContent(store: store,
                              tab: tab,
                              approvalOpen: $approvalOpen,
                              interactive: true,
                              onPickImage: { slot in
                                  pickerSlot = slot
                                  showPicker = true
                              })
            }

            DetailBottomBar(store: store,
                            interactive: true,
                            onMore: { showMoreMenu = true },
                            onForward: { forward() })
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { item in
            let slot = pickerSlot
            Task {
                await store.loadImage(item, slot: slot)
                pickerItem = nil
            }
        }
        .shotExport(exporter, capture: {
            Shot.render(CaptureDetail(store: store, tab: tab, approvalOpen: approvalOpen))
        })
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: [payload.image])
        }
        .sheet(isPresented: $showHelp) {
            HelpSheet(store: store)
        }
        .confirmationDialog("更多操作", isPresented: $showMoreMenu, titleVisibility: .visible) {
            Button(store.leavesCampus ? "切换为「不离校」" : "切换为「离校」") {
                store.toggleLeaveType()
            }
            Button("换头像（也可长按头像）") {
                pickerSlot = .avatar
                showPicker = true
            }
            Button("恢复默认文字", role: .destructive) {
                store.resetAll()
            }
            Button("使用说明") { showHelp = true }
            Button("取消", role: .cancel) {}
        }
    }

    private func forward() {
        let image = Shot.render(CaptureDetail(store: store, tab: tab, approvalOpen: approvalOpen))
        guard let image else {
            exporter.flash("渲染失败，换一台真机再试")
            return
        }
        sharePayload = SharePayload(image: image)
    }
}

// MARK: - 顶部 请假 / 续假 切换

struct DetailTabStrip: View {
    @ObservedObject var store: TextStore
    @Binding var selected: DetailTab
    var interactive: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { item in
                let on = selected == item
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    EditableText(text: store[item.rawValue],
                                 font: .system(size: 15, weight: on ? .semibold : .regular),
                                 color: on ? Palette.blue : Palette.textTabIdle)
                        .editTap(item.rawValue, store[item.rawValue], enabled: interactive)
                    Spacer(minLength: 7)
                    Rectangle()
                        .fill(on ? Palette.blue : Color.clear)
                        .frame(width: Metrics.underlineWidth, height: Metrics.underlineHeight)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.tabHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    if interactive { selected = item }
                }
            }
        }
        .background(Palette.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.divider).frame(height: 0.5)
        }
    }
}

// MARK: - 详情主体

struct DetailContent: View {
    @ObservedObject var store: TextStore
    var tab: DetailTab = .leave
    @Binding var approvalOpen: Bool
    var interactive: Bool = true
    var onPickImage: (ImageSlot) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            if tab == .leave {
                headerCard
                leaveCard
                destCard
                approvalCard
            } else {
                extendHeaderCard
                extendCard
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 13)
        .padding(.bottom, 26)
    }

    // 头像 + 姓名 + 状态（左侧「请假规则」竖条）
    private var headerCard: some View {
        Card(padding: 0) {
            HStack(alignment: .top, spacing: 13) {
                RuleStrip(text: store["hd.rule"])
                    .editTap("hd.rule", store["hd.rule"], enabled: interactive)

                HStack(alignment: .center, spacing: 11) {
                    AvatarView(image: store.avatar, size: 44)
                        .contentShape(Circle())
                        .onLongPressGesture(minimumDuration: 0.45) {
                            if interactive { onPickImage(.avatar) }
                        }

                    VStack(alignment: .leading, spacing: 5) {
                        EditableText(text: store["hd.name"],
                                     font: .system(size: 16, weight: .semibold),
                                     color: Palette.textPrimary)
                            .editTap("hd.name", store["hd.name"], enabled: interactive)

                        EditableText(text: store["hd.status"],
                                     font: .system(size: 13, weight: .medium),
                                     color: store.statusColor(for: "hd.status"))
                            .editTap("hd.status", store["hd.status"], enabled: interactive)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 16)
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // 请假内容
    private var leaveCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.info"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.info", store["sec.info"], enabled: interactive)
                    .padding(.bottom, 10)

                InfoRow(store: store, labelKey: "l.q.student", valueKey: "q.student", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.start", valueKey: "q.start", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.end", valueKey: "q.end", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.dur", valueKey: "q.dur", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.course", valueKey: "q.course", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.reason", valueKey: "q.reason", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.proof", valueKey: "q.proof", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.place", valueKey: "q.place", interactive: interactive)

                if let proof = store.proof {
                    Image(uiImage: proof)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 66, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(.top, 8)
                        .onLongPressGesture(minimumDuration: 0.45) {
                            if interactive { onPickImage(.proof) }
                        }
                }
            }
        }
    }

    // 请假去向
    private var destCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.dest"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.dest", store["sec.dest"], enabled: interactive)
                    .padding(.bottom, 10)

                InfoRow(store: store,
                        labelKey: "l.d.left",
                        valueKey: "d.left",
                        interactive: interactive,
                        valueColor: Palette.blue,
                        valueAction: { store.toggleLeaveType() })

                if store.leavesCampus {
                    InfoRow(store: store, labelKey: "l.d.dest", valueKey: "d.dest", interactive: interactive)
                    InfoRow(store: store, labelKey: "l.d.addr", valueKey: "d.addr", interactive: interactive)
                    InfoRow(store: store, labelKey: "l.d.emerg", valueKey: "d.emerg", interactive: interactive)
                    InfoRow(store: store, labelKey: "l.d.tel", valueKey: "d.tel", interactive: interactive)
                }
            }
        }
    }

    // 审批流程（可折叠）
    private var approvalCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    EditableText(text: store["sec.approval"], font: Typo.sectionTitle, color: Palette.textPrimary)
                        .editTap("sec.approval", store["sec.approval"], enabled: interactive)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.textLabel)
                        .rotationEffect(.degrees(approvalOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if interactive {
                        withAnimation(.easeInOut(duration: 0.18)) { approvalOpen.toggle() }
                    }
                }
                .padding(.bottom, approvalOpen ? 10 : 0)

                if approvalOpen {
                    InfoRow(store: store, labelKey: "l.a.who", valueKey: "a.who", interactive: interactive)
                    InfoRow(store: store,
                            labelKey: "l.a.res",
                            valueKey: "a.res",
                            interactive: interactive,
                            valueColor: store.statusColor(for: "a.res"))
                    InfoRow(store: store, labelKey: "l.a.time", valueKey: "a.time", interactive: interactive)
                    InfoRow(store: store, labelKey: "l.a.note", valueKey: "a.note", interactive: interactive)
                }
            }
        }
    }

    // 续假 tab 头部
    private var extendHeaderCard: some View {
        Card(padding: 0) {
            HStack(alignment: .top, spacing: 13) {
                RuleStrip(text: store["hd.rule"])
                    .editTap("hd.rule", store["hd.rule"], enabled: interactive)

                HStack(alignment: .center, spacing: 11) {
                    AvatarView(image: store.avatar, size: 44)
                    VStack(alignment: .leading, spacing: 5) {
                        EditableText(text: store["hm.name"],
                                     font: .system(size: 16, weight: .semibold),
                                     color: Palette.textPrimary)
                            .editTap("hm.name", store["hm.name"], enabled: interactive)
                        EditableText(text: store["hm.status"],
                                     font: .system(size: 13, weight: .medium),
                                     color: store.statusColor(for: "hm.status"))
                            .editTap("hm.status", store["hm.status"], enabled: interactive)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 16)
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var extendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.xj"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.xj", store["sec.xj"], enabled: interactive)
                    .padding(.bottom, 10)

                InfoRow(store: store, labelKey: "l.hm.v1", valueKey: "hm.v1", interactive: interactive)
                InfoRow(store: store, labelKey: "l.hm.v2", valueKey: "hm.v2", interactive: interactive)
                InfoRow(store: store, labelKey: "l.hm.v3", valueKey: "hm.v3", interactive: interactive)
                InfoRow(store: store, labelKey: "l.hm.who", valueKey: "hm.who", interactive: interactive)
                InfoRow(store: store, labelKey: "l.hm.time", valueKey: "hm.time", interactive: interactive)
            }
        }
    }
}

// MARK: - 底部 更多 / 转发

struct DetailBottomBar: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onMore: () -> Void = {}
    var onForward: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 0.5)
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    ArtIcon(name: Art.more, width: 16, height: 12, tint: Palette.moreText)
                    EditableText(text: store["bottom.more"],
                                 font: .system(size: 14),
                                 color: Palette.moreText)
                        .editTap("bottom.more", store["bottom.more"], enabled: interactive)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if interactive { onMore() }
                }

                Spacer(minLength: 0)

                Text(store["bottom.fwd"])
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(width: 116, height: 38)
                    .background(Palette.blue)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .onTapGesture {
                        if interactive { onForward() }
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: "bottom.fwd", value: store["bottom.fwd"])
                    }
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
        }
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CaptureDetail: View {
    @ObservedObject var store: TextStore
    var tab: DetailTab = .leave
    var approvalOpen: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.detail", title: store["nav.detail"], showsBack: true)
            DetailTabStrip(store: store, selected: .constant(tab), interactive: false)
            ScrollView(showsIndicators: false) {
                DetailContent(store: store,
                              tab: tab,
                              approvalOpen: .constant(approvalOpen),
                              interactive: false)
            }
            DetailBottomBar(store: store, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}

// MARK: - 分享面板

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - 使用说明

struct HelpSheet: View {
    @ObservedObject var store: TextStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("怎么用")
                        .font(Typo.sectionTitle)
                    rule("点页面上的任意文字：弹出「修改文字」，改完点确定，立刻生效并写入 UserDefaults，重启 App 仍在。")
                    rule("详情页和列表页「进行中」卡片读的是同一批字段（q.start / q.end / q.reason / hd.name / hd.status / q.submit），改哪边另一边都会同步。")
                    rule("改开始 / 结束时间后，「请假时长」会自动重算成「X天X时X分」。")
                    rule("状态文字的颜色跟着内容走：已通过 / 已完成 / 即将休假 = 绿；审批中 / 待审批 = 蓝；已驳回 / 已撤销 / 逾期 = 灰。")
                    rule("流程：列表点「发起」卡 → 承诺书 → 勾选「已阅读并同意」→ 同意并继续 → 申请表 → 提交 → 回列表。")
                    rule("图标：相机 = 导出当前页 PNG（存相册 / 分享）；长按头像 = 换头像。")
                }
                .padding(20)
            }
            .background(Palette.pageBg)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .navigationTitle("使用说明")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func rule(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Palette.textValue)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
