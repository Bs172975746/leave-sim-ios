//
//  HomeView.swift
//  LeaveSim
//
//  ①请假列表：进行中卡片 + 发起三卡（其它 / 事假 / 病假）+「没有更多数据了~」+ 底部两 tab。
//  进行中卡片与详情页共用 q.* / hd.* 同一批 key —— 卡片上改字即改详情，反之亦然。
//

import SwiftUI

// MARK: - 首页

struct HomeView: View {
    @EnvironmentObject private var store: TextStore
    @Binding var path: [AppRoute]

    @StateObject private var exporter = ShotExporter()
    @State private var confirmRevoke = false

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.home",
                      title: store["nav.home"],
                      trailing: [.symbol("camera")],
                      onTrailingTap: { _ in exporter.asking = true })

            ScrollView(showsIndicators: false) {
                HomeBody(store: store,
                         interactive: true,
                         onOpenDetail: { path.append(.detail) },
                         onStart: { start($0) },
                         onMore: { path.append(.detail) },
                         onRevoke: { confirmRevoke = true })
            }

            HomeTabBar(store: store,
                       selected: .apply,
                       interactive: true,
                       onApply: { },
                       onRecord: { path.append(.records) })
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .shotExport(exporter, capture: { Shot.render(CaptureHome(store: store)) })
        .confirmationDialog("撤销这次请假？", isPresented: $confirmRevoke, titleVisibility: .visible) {
            Button("撤销请假", role: .destructive) {
                store.set("hd.status", "已撤销")
                store.set("a.res", "已撤销")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("撤销后状态会变成「已撤销」，列表和详情同步变色。")
        }
    }

    private func start(_ key: String) {
        let name = store[key]
        store.set("f.hd.title", name == "其它" ? "请假申请" : name + "申请")
        path.append(.promise)
    }
}

// MARK: - 页面主体

struct HomeBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onOpenDetail: () -> Void = {}
    var onStart: (String) -> Void = { _ in }
    var onMore: () -> Void = {}
    var onRevoke: () -> Void = {}

    private let typeKeys = ["list.type.1", "list.type.2", "list.type.3"]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            sectionTitle("list.active")
            activeCard

            sectionTitle("list.start")
            VStack(spacing: 10) {
                ForEach(typeKeys, id: \.self) { key in
                    typeCard(key)
                }
            }

            footer
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // 小节标题：3pt 蓝色竖条 + 17pt 加粗
    private func sectionTitle(_ key: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Palette.blue)
                .frame(width: 3, height: 15)
            EditableText(text: store[key], font: Typo.sectionTitle, color: Palette.textPrimary)
                .editTap(key, store[key], enabled: interactive)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    // 进行中卡片
    private var activeCard: some View {
        Card(padding: 20) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    EditableText(text: store["hd.name"],
                                 font: Typo.cardTitle,
                                 color: Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap("hd.name", store["hd.name"], enabled: interactive)

                    EditableText(text: store["hd.status"],
                                 font: .system(size: 13, weight: .medium),
                                 color: store.statusColor(for: "hd.status"))
                        .editTap("hd.status", store["hd.status"], enabled: interactive)
                }
                .padding(.bottom, 6)

                InfoRow(store: store, labelKey: "l.q.start", valueKey: "q.start", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.end", valueKey: "q.end", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.reason", valueKey: "q.reason", interactive: interactive)
                InfoRow(store: store, labelKey: "l.q.dur", valueKey: "q.dur", interactive: interactive)

                Divider().overlay(Palette.divider).padding(.vertical, 11)

                HStack(spacing: 8) {
                    AvatarView(image: store.avatar, size: 22)
                    EditableText(text: store["q.student"], font: .system(size: 12), color: Palette.textValue)
                        .editTap("q.student", store["q.student"], enabled: interactive)
                    Spacer(minLength: 6)
                    EditableText(text: store["q.submit"], font: .system(size: 11), color: Palette.textLabel)
                        .editTap("q.submit", store["q.submit"], enabled: interactive)
                }

                Divider().overlay(Palette.divider).padding(.vertical, 11)

                HStack(spacing: 0) {
                    HStack(spacing: 5) {
                        ArtIcon(name: Art.more, width: 15, height: 11, tint: Palette.moreText)
                        EditableText(text: store["list.more"], font: .system(size: 13), color: Palette.moreText)
                            .editTap("list.more", store["list.more"], enabled: interactive)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if interactive { onMore() }
                    }

                    Spacer(minLength: 0)

                    Text(store["revoke"])
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.error)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Palette.error.opacity(0.5), lineWidth: 0.8)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if interactive { onRevoke() }
                        }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onOpenDetail() }
        }
    }

    // 发起卡：蓝圈人形（ic_join 位图）+ 类型名
    private func typeCard(_ key: String) -> some View {
        HStack(spacing: 12) {
            ArtImage(name: Art.join, width: 30, height: 30)
            EditableText(text: store[key], font: .system(size: 15), color: Palette.textPrimary)
                .editTap(key, store[key], enabled: interactive)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textLabel)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onStart(key) }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            EditableText(text: store["list.footer"], font: .system(size: 12), color: Palette.textLabel)
                .editTap("list.footer", store["list.footer"], enabled: interactive)
            Spacer()
        }
        .padding(.top, 18)
        .padding(.bottom, 6)
    }
}

// MARK: - 底部两 tab

struct HomeTabBar: View {
    @ObservedObject var store: TextStore
    var selected: HomeTab = .apply
    var interactive: Bool = true
    var onApply: () -> Void = {}
    var onRecord: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 0.5)
            HStack(spacing: 0) {
                item(activeAsset: Art.tabLeaveActive,
                     idleAsset: Art.tabLeaveInactive,
                     labelKey: "tab.apply",
                     width: 22,
                     active: selected == .apply,
                     action: onApply)
                item(activeAsset: Art.tabRecordActive,
                     idleAsset: Art.tabRecordInactive,
                     labelKey: "tab.record",
                     width: 17,
                     active: selected == .records,
                     action: onRecord)
            }
            .frame(height: Metrics.bottomTabHeight)
        }
        .background(Palette.white)
    }

    private func item(activeAsset: String,
                      idleAsset: String,
                      labelKey: String,
                      width: CGFloat,
                      active: Bool,
                      action: @escaping () -> Void) -> some View {
        let tint = active ? Palette.blue : Palette.textTabIdle
        return VStack(spacing: 3) {
            ArtIcon(name: active ? activeAsset : idleAsset,
                    width: width,
                    height: 22,
                    tint: tint)
            EditableText(text: store[labelKey],
                         font: .system(size: 11, weight: active ? .medium : .regular),
                         color: tint)
                .editTap(labelKey, store[labelKey], enabled: interactive)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.bottomTabHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive && !active { action() }
        }
    }
}

// MARK: - 截图用静态版

struct CaptureHome: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.home", title: store["nav.home"])
            ScrollView(showsIndicators: false) {
                HomeBody(store: store, interactive: false)
            }
            HomeTabBar(store: store, selected: .apply, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
