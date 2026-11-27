//
//  HomeView.swift
//  LeaveSim
//
//  请假列表（首页）。导航标题「请假」，区块「进行中」「发起」，底部两个 tab。
//  「我要请假」和「发起」里的三张卡片都进「请假申请表单页」，「进行中」卡片进「请假详情」。
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TextStore
    @Binding var path: [AppRoute]

    @State private var confirmRevoke = false
    @State private var banner: String?
    @StateObject private var exporter = ShotExporter()

    init(path: Binding<[AppRoute]>) {
        _path = path
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.home",
                      title: store["nav.home"],
                      trailingIcons: ["camera"],
                      onTrailingTap: { _ in exporter.asking = true })

            ScrollView(showsIndicators: false) {
                HomeBody(store: store,
                         interactive: true,
                         onOpen: { route in path.append(route) },
                         onRevokeTap: { confirmRevoke = true })
            }

            HomeTabBar(store: store,
                       selected: .apply,
                       onApply: { path.append(.form) },
                       onRecord: { path.append(.records) })
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("确定撤销这条请假申请吗？", isPresented: $confirmRevoke, titleVisibility: .visible) {
            Button("撤销申请", role: .destructive) { banner = "已提交撤销申请" }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: Binding(get: { banner != nil },
                                          set: { if !$0 { banner = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(banner ?? "")
        }
        .shotExport(exporter, capture: { Shot.render(CaptureHome(store: store)) })
    }
}

// MARK: - 首页正文（首页与截图共用）

struct HomeBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onOpen: (AppRoute) -> Void = { _ in }
    var onRevokeTap: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    private let typeCards: [(key: String, card: String)] = [
        ("list.type.other", "list.type.other"),
        ("list.type.sj",    "list.type.sj"),
        ("list.type.bj",    "list.type.bj")
    ]

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader("list.sec.active")
            activeCard
                .padding(.horizontal, Metrics.cardMargin)

            sectionHeader("list.sec.create")
            typeCardList
                .padding(.horizontal, Metrics.cardMargin)

            footerText
        }
        .padding(.bottom, 18)
    }

    private func sectionHeader(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.sectionTitle, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key], enabled: interactive)
            .padding(.horizontal, Metrics.cardMargin)
            .padding(.top, 18)
            .padding(.bottom, 10)
    }

    private var activeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                EditableText(text: store["list.title"],
                             font: .system(size: 17, weight: .semibold),
                             color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("list.title", store["list.title"], enabled: interactive)

                EditableText(text: store["list.status"],
                             font: .system(size: 13),
                             color: Palette.green)
                    .editTap("list.status", store["list.status"], enabled: interactive)
            }
            .padding(.bottom, 2)

            infoRow("l.l.start",  "list.start")
            infoRow("l.l.end",    "list.end")
            infoRow("l.l.reason", "list.reason")

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
                .padding(.vertical, 10)

            HStack(spacing: 6) {
                AvatarView(image: store.avatar, size: 22)
                EditableText(text: store["list.owner"], font: .system(size: 13), color: Palette.textValue)
                    .editTap("list.owner", store["list.owner"], enabled: interactive)
                Spacer(minLength: 8)
                EditableText(text: store["list.time"], font: .system(size: 13), color: Palette.textLabel)
                    .editTap("list.time", store["list.time"], enabled: interactive)
            }

            HStack(spacing: 8) {
                EditableText(text: store["list.more"], font: .system(size: 13), color: Palette.textLabel)
                    .editTap("list.more", store["list.more"], enabled: interactive)
                Spacer(minLength: 8)
                revokeButton
            }
            .padding(.top, 12)
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            onOpen(.detail)
        }
    }

    private func infoRow(_ labelKey: String, _ valueKey: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            EditableText(text: store[labelKey], font: Typo.label, color: Palette.textLabel)
                .frame(width: Metrics.labelWidth, alignment: .leading)
                .editTap(labelKey, store[labelKey], enabled: interactive)

            EditableText(text: store[valueKey], font: Typo.value, color: Palette.textValue, lineSpacing: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap(valueKey, store[valueKey], enabled: interactive)
        }
        .frame(minHeight: Metrics.rowHeight, alignment: .topLeading)
        .padding(.vertical, 8)
    }

    private var revokeButton: some View {
        Text(store["list.revoke"])
            .font(.system(size: 13))
            .foregroundStyle(Palette.textValue)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Palette.ghostBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard interactive else { return }
                onRevokeTap()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                guard interactive else { return }
                editor.begin(key: "list.revoke", value: store["list.revoke"])
            }
    }

    private var typeCardList: some View {
        VStack(spacing: 10) {
            ForEach(Array(typeCards.enumerated()), id: \.offset) { item in
                HStack(spacing: 12) {
                    CircleBadge(systemName: "person.fill.badge.plus", size: 32)
                    EditableText(text: store[item.element.key],
                                 font: .system(size: 15),
                                 color: Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap(item.element.key, store[item.element.key], enabled: interactive)
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.white)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard interactive else { return }
                    onOpen(.form)
                }
            }
        }
    }

    private var footerText: some View {
        EditableText(text: store["list.footer"],
                     font: .system(size: 13),
                     color: Palette.textTabIdle,
                     alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
            .editTap("list.footer", store["list.footer"], enabled: interactive)
            .padding(.top, 26)
            .padding(.bottom, 26)
    }
}

// MARK: - 底部 tab 栏

struct HomeTabBar: View {
    @ObservedObject var store: TextStore
    var selected: HomeTab = .apply
    var interactive: Bool = true
    let onApply: () -> Void
    let onRecord: () -> Void

    @Environment(\.editorCenter) private var editor

    init(store: TextStore,
         selected: HomeTab = .apply,
         interactive: Bool = true,
         onApply: @escaping () -> Void,
         onRecord: @escaping () -> Void) {
        self.store = store
        self.selected = selected
        self.interactive = interactive
        self.onApply = onApply
        self.onRecord = onRecord
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            HStack(spacing: 0) {
                item(icon: "bag.badge.plus",
                     key: "tab.apply",
                     active: selected == .apply,
                     action: onApply)
                item(icon: "person.crop.circle",
                     key: "tab.record",
                     active: selected == .records,
                     action: onRecord)
            }
            .frame(height: 56)
        }
        .background(Palette.white.ignoresSafeArea(edges: .bottom))
    }

    private func item(icon: String, key: String, active: Bool, action: @escaping () -> Void) -> some View {
        let tint = active ? Palette.blue : Palette.textTabIdle
        return VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(tint)
            EditableText(text: store[key],
                         font: .system(size: 12),
                         color: tint)
                .editTap(key, store[key], enabled: interactive)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            action()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            guard interactive else { return }
            editor.begin(key: key, value: store[key])
        }
    }
}

// MARK: - 首页截图

struct CaptureHome: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.home", title: store["nav.home"])
            HomeBody(store: store, interactive: false)
            HomeTabBar(store: store, selected: .apply, interactive: false, onApply: {}, onRecord: {})
        }
        .background(Palette.pageBg)
    }
}
