//
//  RecordsView.swift
//  LeaveSim
//
//  ⑤请假记录：统计条 + 卡片列表 + 筛选入口 + 底部 tab；
//  ⑥筛选底部弹层：请假类型、两组日期区间、时长区间、8 个状态 chip、重置 / 确定。
//

import SwiftUI

// MARK: - 记录页

struct RecordsView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @StateObject private var exporter = ShotExporter()
    @State private var showFilter = false
    @State private var selection = FilterSelection()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                NavHeader(titleKey: "nav.record",
                          title: store["nav.record"],
                          showsBack: true,
                          onBack: { dismiss() },
                          trailing: [.asset(selection.isActive ? Art.filterActive : Art.filterInactive,
                                            selection.isActive ? Palette.blue : Palette.textLabel),
                                     .symbol("camera")],
                          onTrailingTap: { index in
                              if index == 0 {
                                  showFilter = true
                              } else {
                                  exporter.asking = true
                              }
                          })

                ScrollView(showsIndicators: false) {
                    RecordsBody(store: store,
                                interactive: true,
                                countText: selection.summary(store),
                                onOpenDetail: { path.append(.detail) })
                }

                HomeTabBar(store: store,
                           selected: .records,
                           interactive: true,
                           onApply: { path.removeAll() },
                           onRecord: {})
            }
            .background(Palette.pageBg)

            if showFilter {
                FilterPanel(store: store,
                            selection: $selection,
                            onClose: { showFilter = false },
                            onConfirm: { showFilter = false })
                    .transition(.move(edge: .bottom))
                    .zIndex(5)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: showFilter)
        .shotExport(exporter, capture: {
            Shot.render(CaptureRecords(store: store))
        })
    }
}

// MARK: - 筛选状态

struct FilterSelection {
    /// 1 / 2 / 3 = 其它 / 事假 / 病假；4 = 全部
    var type: Int = 4
    var statuses: Set<Int> = []

    var isActive: Bool {
        type != 4 || !statuses.isEmpty
    }

    func summary(_ store: TextStore) -> String {
        if !isActive { return store["rec.status"] }
        var parts: [String] = []
        if type != 4 { parts.append(store["flt.type.\(type)"]) }
        if !statuses.isEmpty {
            let names = statuses.sorted().map { store["flt.s\($0)"] }
            parts.append(names.joined(separator: "/"))
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - 记录主体

struct RecordsBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var countText: String? = nil
    var onOpenDetail: () -> Void = {}

    private let recordIndexes = [1, 2, 3]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            statBar

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.blue)
                    .frame(width: 3, height: 15)
                EditableText(text: store["rec.sec"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("rec.sec", store["rec.sec"], enabled: interactive)
                Spacer(minLength: 0)
                EditableText(text: countText ?? store["rec.status"],
                             font: .system(size: 12),
                             color: Palette.textLabel)
                    .editTap("rec.status", store["rec.status"], enabled: interactive)
            }
            .padding(.top, 2)

            ForEach(recordIndexes, id: \.self) { index in
                recordCard(index)
            }

            footer
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 13)
        .padding(.bottom, 20)
    }

    // 统计条
    private var statBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.blue)
            EditableText(text: store["rec.tip"], font: .system(size: 12), color: Palette.textValue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("rec.tip", store["rec.tip"], enabled: interactive)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.blueSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func recordCard(_ index: Int) -> some View {
        let nameKey = "rec\(index).name"
        let timeKey = "rec\(index).time"
        let reasonKey = "rec\(index).reason"
        let durKey = "rec\(index).dur"
        let statusKey = "rec\(index).status"

        return Card(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    EditableText(text: store[nameKey],
                                 font: .system(size: 15, weight: .semibold),
                                 color: Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap(nameKey, store[nameKey], enabled: interactive)

                    EditableText(text: store[statusKey],
                                 font: .system(size: 12, weight: .medium),
                                 color: store.statusColor(for: statusKey))
                        .editTap(statusKey, store[statusKey], enabled: interactive)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.textLabel)
                }

                EditableText(text: store[timeKey], font: .system(size: 12), color: Palette.textLabel)
                    .editTap(timeKey, store[timeKey], enabled: interactive)

                Divider().overlay(Palette.divider)

                HStack(alignment: .top, spacing: 10) {
                    EditableText(text: store[reasonKey], font: .system(size: 13), color: Palette.textValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap(reasonKey, store[reasonKey], enabled: interactive)

                    EditableText(text: store[durKey], font: .system(size: 12), color: Palette.textLabel)
                        .editTap(durKey, store[durKey], enabled: interactive)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onOpenDetail() }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            EditableText(text: store["rec.footer"], font: .system(size: 12), color: Palette.textLabel)
                .editTap("rec.footer", store["rec.footer"], enabled: interactive)
            Spacer()
        }
        .padding(.top, 14)
    }
}

// MARK: - 筛选底部弹层

struct FilterPanel: View {
    @ObservedObject var store: TextStore
    @Binding var selection: FilterSelection
    var onClose: () -> Void = {}
    var onConfirm: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                header
                Rectangle().fill(Palette.divider).frame(height: 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        section("flt.type")
                        typeChips

                        section("flt.date1")
                        rangeRow(sKey: "flt.d1.s", eKey: "flt.d1.e")

                        section("flt.date2")
                        rangeRow(sKey: "flt.d2.s", eKey: "flt.d2.e")

                        section("flt.dur")
                        durRow

                        section("flt.status")
                        statusChips
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: 520)

                bottomBar
            }
            .background(Palette.white)
            .clipShape(TopRoundedShape(radius: 18))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            EditableText(text: store["flt.title"], font: .system(size: 16, weight: .semibold), color: Palette.textPrimary)
                .editTap("flt.title", store["flt.title"])
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.textLabel)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .frame(height: 52)
    }

    private func section(_ key: String) -> some View {
        EditableText(text: store[key], font: .system(size: 13, weight: .medium), color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key])
            .padding(.top, 16)
            .padding(.bottom, 10)
    }

    private var typeChips: some View {
        HStack(spacing: 10) {
            ForEach(1...4, id: \.self) { index in
                chip(key: "flt.type.\(index)",
                     on: selection.type == index) {
                    selection.type = index
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var statusChips: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                  spacing: 10) {
            ForEach(1...8, id: \.self) { index in
                chip(key: "flt.s\(index)",
                     on: selection.statuses.contains(index)) {
                    if selection.statuses.contains(index) {
                        selection.statuses.remove(index)
                    } else {
                        selection.statuses.insert(index)
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }

    private func chip(key: String, on: Bool, action: @escaping () -> Void) -> some View {
        Text(store[key])
            .font(.system(size: 13))
            .foregroundStyle(on ? Palette.blue : Palette.textValue)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(on ? Palette.blueSoft : Palette.fieldBg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(on ? Palette.blue.opacity(0.45) : Color.clear, lineWidth: 0.8)
            )
            .contentShape(Capsule())
            .onTapGesture { action() }
            .onLongPressGesture(minimumDuration: 0.45) {
                editor.begin(key: key, value: store[key])
            }
    }

    // 一组日期区间：开始日期 ~ 结束日期
    private func rangeRow(sKey: String, eKey: String) -> some View {
        HStack(spacing: 10) {
            dateBox(key: sKey, caption: "flt.from")
            Text("~")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textLabel)
            dateBox(key: eKey, caption: "flt.to")
        }
    }

    private func dateBox(key: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            EditableText(text: store[caption], font: .system(size: 10), color: Palette.textLabel)
                .editTap(caption, store[caption])
            EditableText(text: store[key], font: .system(size: 13), color: Palette.textValue)
                .editTap(key, store[key])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fieldBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
    }

    // 时长区间：天 / 时 / 分
    private var durRow: some View {
        HStack(spacing: 10) {
            durBox(key: "flt.dur.d", unitKey: "flt.unit.d")
            durBox(key: "flt.dur.h", unitKey: "flt.unit.h")
            durBox(key: "flt.dur.m", unitKey: "flt.unit.m")
        }
    }

    private func durBox(key: String, unitKey: String) -> some View {
        HStack(spacing: 4) {
            EditableText(text: store[key], font: .system(size: 13), color: Palette.textValue)
                .frame(maxWidth: .infinity, alignment: .center)
                .editTap(key, store[key])
            EditableText(text: store[unitKey], font: .system(size: 11), color: Palette.textLabel)
                .editTap(unitKey, store[unitKey])
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Palette.fieldBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Text(store["flt.reset"])
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.textValue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Palette.fieldBg)
                .clipShape(Capsule())
                .contentShape(Capsule())
                .onTapGesture {
                    selection = FilterSelection()
                    store.resetFilterFields()
                }
                .onLongPressGesture(minimumDuration: 0.45) {
                    editor.begin(key: "flt.reset", value: store["flt.reset"])
                }

            Text(store["flt.ok"])
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Palette.blue)
                .clipShape(Capsule())
                .contentShape(Capsule())
                .onTapGesture { onConfirm() }
                .onLongPressGesture(minimumDuration: 0.45) {
                    editor.begin(key: "flt.ok", value: store["flt.ok"])
                }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 26)
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CaptureRecords: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.record", title: store["nav.record"], showsBack: true)
            ScrollView(showsIndicators: false) {
                RecordsBody(store: store, interactive: false)
            }
            HomeTabBar(store: store, selected: .records, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
