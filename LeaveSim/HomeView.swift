//
//  HomeView.swift
//  LeaveSim
//
//  ①请假列表：48pt 导航条 + 「进行中」卡 + 「发起」三卡 + 底部两个 tab。
//  数值全部对齐 screen_home.xml / buildHomeCards()。
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TextStore
    @Binding var path: [AppRoute]

    @StateObject private var exporter = ShotExporter()
    @State private var confirmRevoke = false

    var body: some View {
        VStack(spacing: 0) {
            nav

            ScrollView(showsIndicators: false) {
                HomeBody(store: store,
                         interactive: true,
                         onOpenDetail: { path.append(.detail) },
                         onStart: { start($0) },
                         onRevoke: { confirmRevoke = true })
            }

            HomeTabBar(store: store,
                       selected: .apply,
                       interactive: true,
                       onApply: { },
                       onRecord: { path.append(.records) })

            // 真机最底部：先一条 0.5pt 分隔线，下面才是 #F9F9F9 色带
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Palette.hairlineColor)
                    .frame(height: 0.5)
                Palette.systemBar
                    .frame(height: Metrics.bottomBand)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .shotExport(exporter, capture: { Shot.render(CaptureHome(store: store)) })
        .confirmationDialog("撤销这次请假申请？",
                            isPresented: $confirmRevoke,
                            titleVisibility: .visible) {
            Button("撤销", role: .destructive) {
                store.set("hd.status", "已撤销")
                store.set("a.res", "已撤销")
            }
            Button("取消", role: .cancel) { }
        }
    }

    private var nav: some View {
        NavHeader(store: store, titleKey: "nav.home", showsBack: true)
    }

    // 点发起卡：先记下假别，再过承诺书
    private func start(_ label: String) {
        store.set("f.hd.title", label)
        path.append(.promise)
    }
}

// MARK: - 列表主体

struct HomeBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onOpenDetail: () -> Void = {}
    var onStart: (String) -> Void = { _ in }
    var onRevoke: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    private let typeKeys = ["list.type.1", "list.type.2", "list.type.3"]

    var body: some View {
        VStack(spacing: 0) {
            SectionTitle(store: store, labelKey: "list.active", interactive: interactive)
                .padding(.top, Metrics.homeSectionTop)

            activeCard
                .padding(.top, Metrics.homeCardTop)

            SectionTitle(store: store, labelKey: "list.start", interactive: interactive)
                .padding(.top, Metrics.homeSection2Top)

            VStack(spacing: Metrics.homeTypeGap) {
                ForEach(typeKeys, id: \.self) { key in
                    typeCard(key)
                }
            }
            .padding(.top, Metrics.homeTypeFirstTop)

            footer
                .padding(.top, Metrics.homeFootTop)
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.bottom, Metrics.pageBottom)
    }

    // MARK: 进行中卡片

    private var activeCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                EditableText(text: store["hd.name"],
                             font: Typo.homeTitle,
                             color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("hd.name", store["hd.name"], enabled: interactive)

                EditableText(text: store["hd.status"], font: Typo.status, color: StatusTone.color(store["hd.status"]))
                    .editTap("hd.status", store["hd.status"], enabled: interactive)
            }

            VStack(spacing: 0) {
                infoLine(labelKey: "l.q.start", valueKey: "q.start")
                infoLine(labelKey: "l.q.end", valueKey: "q.end")
                infoLine(labelKey: "l.q.reason", valueKey: "q.reason")
            }
            .padding(.top, Metrics.homeInfoTop)

            HStack(spacing: 0) {
                AvatarBadge(image: store.avatar)
                EditableText(text: store["q.student"],
                             font: Typo.avatarName,
                             color: Palette.textPrimary)
                    .padding(.leading, Metrics.whoGap)
                    .editTap("q.student", store["q.student"], enabled: interactive)
                Spacer(minLength: 8)
                EditableText(text: submittedText, font: Typo.row, color: Palette.textLabel)
                    .editTap("q.submit", store["q.submit"], enabled: interactive)
            }
            .padding(.top, Metrics.homeWhoTop)

            HStack(spacing: 0) {
                EditableText(text: store["list.more"], font: Typo.more, color: Palette.textLabel)
                    .editTap("list.more", store["list.more"], enabled: interactive)
                Spacer(minLength: 8)
                revokeButton
            }
            .padding(.top, Metrics.homeMoreTop)
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.homeCardPadTop)
        .padding(.bottom, Metrics.homeCardPadBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onOpenDetail() }
        }
    }

    /// 安卓卡里是单行整句「开始时间：2026-11-16 08:40」。
    private func infoLine(labelKey: String, valueKey: String) -> some View {
        (Text(store[labelKey] + "：").foregroundColor(Palette.textLabel)
            + Text(store[valueKey]).foregroundColor(Palette.textValue))
            .font(Typo.row)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Metrics.homeInfoPad)
            .contentShape(Rectangle())
            .editTap(valueKey, store[valueKey], enabled: interactive)
    }

    /// 提交时间去掉了「提交」二字，只留时间。
    private var submittedText: String {
        var text = store["q.submit"]
        for suffix in [" 提交", "提交"] where text.hasSuffix(suffix) {
            text = String(text.dropLast(suffix.count))
            break
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    private var revokeButton: some View {
        Text(store["revoke"])
            .font(Typo.revokeButton)
            .foregroundStyle(Palette.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minWidth: Metrics.revokeMinWidth, minHeight: Metrics.revokeHeight)
            .background(Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                    .strokeBorder(Palette.fwdBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if interactive { onRevoke() }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                guard interactive else { return }
                editor.begin(key: "revoke", value: store["revoke"])
            }
    }

    // MARK: 发起三卡

    private func typeCard(_ key: String) -> some View {
        HStack(spacing: 0) {
            ArtImage(name: Art.join, width: Metrics.homeTypeIcon, height: Metrics.homeTypeIcon)
            EditableText(text: store[key], font: Typo.typeLabel, color: Palette.textPrimary)
                .padding(.leading, Metrics.typeTextGap)
                .editTap(key, store[key], enabled: interactive)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.pagePadding)
        .frame(height: Metrics.homeTypeHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onStart(store[key]) }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            EditableText(text: store["list.footer"], font: Typo.footer, color: Palette.footerText)
                .editTap("list.footer", store["list.footer"], enabled: interactive)
            Spacer()
        }
    }
}

// MARK: - 底部 tab

struct HomeTabBar: View {
    @ObservedObject var store: TextStore
    var selected: HomeTab = .apply
    var interactive: Bool = true
    var onApply: () -> Void = {}
    var onRecord: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: Metrics.hairline)

            HStack(spacing: 0) {
                item(tab: .apply,
                     iconOn: Art.tabLeaveActive,
                     iconOff: Art.tabLeaveInactive,
                     iconSize: Metrics.tabIcon,
                     textKey: "tab.apply",
                     action: onApply)
                item(tab: .records,
                     iconOn: Art.tabRecordActive,
                     iconOff: Art.tabRecordInactive,
                     iconSize: Metrics.tabIconRecord,
                     textKey: "tab.record",
                     action: onRecord)
            }
            .frame(height: Metrics.tabBarRow)
        }
        .background(Palette.white)
    }

    private func item(tab: HomeTab,
                      iconOn: String,
                      iconOff: String,
                      iconSize: CGFloat,
                      textKey: String,
                      action: @escaping () -> Void) -> some View {
        let on = selected == tab
        return VStack(spacing: Metrics.tabTextTop) {
            ArtImage(name: on ? iconOn : iconOff, width: iconSize, height: iconSize,
                     tint: on ? Palette.blue : Palette.textTabIdle)
            EditableText(text: store[textKey],
                         font: on ? Typo.tabBarActive : Typo.tabBar,
                         color: on ? Palette.blue : Palette.textTabIdle)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { action() }
        }
    }
}

// MARK: - 截图用静态版

struct CaptureHome: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(store: store, titleKey: "nav.home", showsBack: true)
            ScrollView(showsIndicators: false) {
                HomeBody(store: store, interactive: false)
            }
            HomeTabBar(store: store, selected: .apply, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
