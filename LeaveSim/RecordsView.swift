//
//  RecordsView.swift
//  LeaveSim
//
//  ⑤请假记录：导航下独立 40pt 筛选行 + 浅蓝统计条 + 卡片列表 + 底部 tab；
//  ⑥筛选底部弹层：上圆角 18 的白面板，字段 44 高、状态 chip 每行 3 个、重置 / 确定。
//  数值对齐 screen_records.xml / sheet_filter.xml 与 MainActivity.makeRecordCard。
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
                NavHeader(store: store,
                          titleKey: "nav.record",
                          showsBack: true,
                          onBack: { dismiss() })

                filterRow

                ScrollView(showsIndicators: false) {
                    RecordsBody(store: store,
                                interactive: true,
                                onOpenDetail: { path.append(.detail) })
                }

                HomeTabBar(store: store,
                           selected: .records,
                           interactive: true,
                           onApply: { path.removeAll() },
                           onRecord: {})

                // 真机最底部那条 #F9F9F9 色带
                Palette.systemBar
                    .frame(height: Metrics.bottomBand)
            }
            .background(Palette.pageBg)
            .ignoresSafeArea(edges: .bottom)

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

    // 导航下一条独立白底行，漏斗靠右（rc_filter 58×48、marginEnd 6、padding 10）
    private var filterRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                showFilter = true
            } label: {
                ArtImage(name: selection.isActive ? Art.filterActive : Art.filterInactive,
                         width: Metrics.filterIconSize, height: Metrics.filterIconSize)
                    .padding(Metrics.filterIconPad)
                    .frame(width: Metrics.backBox, height: Metrics.filterRowH)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, Metrics.filterRowEnd)
        }
        .frame(height: Metrics.filterRowH)
        .background(Palette.white)
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
    var onOpenDetail: () -> Void = {}

    private let recordIndexes = [1, 2, 3]

    var body: some View {
        VStack(spacing: 0) {
            banner

            ForEach(recordIndexes, id: \.self) { index in
                recordCard(index)
                    .padding(.top, index == recordIndexes.first ? Metrics.cardTopFirst : Metrics.cardTopGap)
            }
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.recordsTop)
        .padding(.bottom, Metrics.pageBottom)
    }

    // 浅蓝统计条：bg_banner #E8F0FE r6、上下 10 / 左右 12、13pt 蓝、居中
    private var banner: some View {
        Text(store["rec.tip"])
            .font(Typo.status)
            .foregroundStyle(Palette.blue)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Metrics.bannerPadV)
            .padding(.horizontal, Metrics.bannerPadH)
            .background(
                RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                    .fill(Palette.banner)
            )
            .padding(.top, Metrics.bannerTop)
            .contentShape(Rectangle())
            .editTap("rec.tip", store["rec.tip"], enabled: interactive)
    }

    // 记录卡：padding 22/18/22/18，标题 15 粗体 + 状态 13，三行信息 13pt 灰，底部头像行
    private func recordCard(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                EditableText(text: store["rec\(index).name"],
                             font: Typo.recordTitle,
                             color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("rec\(index).name", store["rec\(index).name"], enabled: interactive)

                EditableText(text: store["rec\(index).status"],
                             font: Typo.status,
                             color: StatusTone.color(store["rec\(index).status"]))
                    .editTap("rec\(index).status", store["rec\(index).status"], enabled: interactive)
            }

            infoLine(labelKey: "l.q.start", value: window(index).0, top: Metrics.recInfoTop1)
            infoLine(labelKey: "l.q.end", value: window(index).1, top: Metrics.recInfoTop2)
            infoLine(labelKey: "l.q.reason", value: store["rec\(index).reason"], top: Metrics.recInfoTop2)

            HStack(spacing: 0) {
                AvatarBadge(image: nil, size: Metrics.avatarSmall, glyphSize: Metrics.recordAvatarIcon)
                EditableText(text: store["rec\(index).name"],
                             font: Typo.recordName,
                             color: Palette.textPrimary)
                    .padding(.leading, 10)
                    .layoutPriority(1)
                    .editTap("rec\(index).name", store["rec\(index).name"], enabled: interactive)
                Spacer(minLength: 8)
                EditableText(text: store["rec\(index).time"],
                             font: Typo.status,
                             color: Palette.textLabel)
                    .editTap("rec\(index).time", store["rec\(index).time"], enabled: interactive)
            }
            .padding(.top, Metrics.recFootTop)
        }
        .padding(.horizontal, Metrics.recCardPadH)
        .padding(.vertical, Metrics.recCardPadV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onOpenDetail() }
        }
    }

    // 「2026-11-16 08:40 至 2026-11-16 10:00」→（开始, 结束）
    private func window(_ index: Int) -> (String, String) {
        let text = store["rec\(index).time"]
        let parts = text.components(separatedBy: "至")
        if parts.count >= 2 {
            return (parts[0].trimmingCharacters(in: .whitespaces),
                    parts[1].trimmingCharacters(in: .whitespaces))
        }
        return (text, "")
    }

    private func infoLine(labelKey: String, value: String, top: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(store[labelKey] + "：")
                .font(Typo.row)
                .foregroundStyle(Palette.textLabel)
                .editTap(labelKey, store[labelKey], enabled: interactive)
            Text(value)
                .font(Typo.row)
                .foregroundStyle(Palette.textLabel)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, top)
    }
}

// MARK: - 筛选弹层

struct FilterPanel: View {
    @ObservedObject var store: TextStore
    @Binding var selection: FilterSelection
    var onClose: () -> Void = {}
    var onConfirm: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.shade
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(Palette.divider)
                    .frame(height: Metrics.hairline)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        section("flt.type", first: true)
                        typeField

                        section("flt.date1")
                        rangeRow(sKey: "flt.d1.s", eKey: "flt.d1.e")

                        section("flt.date2")
                        rangeRow(sKey: "flt.d2.s", eKey: "flt.d2.e")

                        section("flt.dur")
                        durRow

                        section("flt.status")
                        statusChips
                    }
                    .padding(.top, Metrics.filterBodyTop)
                    .padding(.bottom, Metrics.sheetBodyBottom)
                }
                .frame(maxHeight: 520)

                bottomBar
            }
            .padding(.horizontal, Metrics.pagePadding)
            .padding(.bottom, Metrics.filterPadBottom)
            .background(Palette.white)
            .clipShape(TopRoundedShape(radius: Metrics.sheetRadius))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // 标题 17 居中、✕ 18pt #999 靠右，行高 52
    private var header: some View {
        ZStack {
            EditableText(text: store["flt.title"], font: Typo.filterTitle, color: Palette.navTitle)
                .editTap("flt.title", store["flt.title"])

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.textLabel)
                        .frame(width: Metrics.sheetCloseW, height: Metrics.filterRowHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: Metrics.filterRowHeight)
    }

    private func section(_ key: String, first: Bool = false) -> some View {
        EditableText(text: store[key], font: Typo.filterSection, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key])
            .padding(.top, first ? Metrics.sectionPadTop : Metrics.filterSectionTop)
    }

    // 请假类型：44 高字段 + 行尾 chevron，点一下在三类 / 全部之间切换
    private var typeField: some View {
        HStack(spacing: 0) {
            EditableText(text: store["flt.type.\(selection.type)"],
                         font: Typo.field,
                         color: selection.type == 4 ? Palette.textHint : Palette.textValue)
                .frame(maxWidth: .infinity, alignment: .leading)
            ChevronRight(color: Palette.chevron)
        }
        .padding(.horizontal, Metrics.sheetFieldPadH)
        .frame(height: Metrics.fieldHeight)
        .background(
            RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                .fill(Palette.fieldBg)
        )
        .padding(.top, Metrics.filterFieldTop)
        .contentShape(Rectangle())
        .onTapGesture {
            selection.type = selection.type >= 4 ? 1 : selection.type + 1
        }
    }

    // 状态 chip：8 个、每行 3 个（末行不足补位）、高 34、选中蓝底白字
    private var statusChips: some View {
        let rows = [Array(1...3), Array(4...6), Array(7...8)]
        return VStack(spacing: Metrics.filterChipGap) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: Metrics.filterChipGap) {
                    ForEach(0..<3, id: \.self) { column in
                        let items = rows[rowIndex]
                        if column < items.count {
                            chip(index: items[column])
                        } else {
                            Color.clear.frame(height: Metrics.chipHeight)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(.top, Metrics.filterChipTop)
    }

    private func chip(index: Int) -> some View {
        let on = selection.statuses.contains(index)
        return Text(store["flt.s\(index)"])
            .font(Typo.field)
            .foregroundStyle(on ? Palette.white : Palette.textValue)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.chipHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous)
                    .fill(on ? Palette.chipOn : Palette.chipBg)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if on { selection.statuses.remove(index) }
                else { selection.statuses.insert(index) }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                editor.begin(key: "flt.s\(index)", value: store["flt.s\(index)"])
            }
    }

    // 一组日期区间：两个 44 高字段中间夹「~」
    private func rangeRow(sKey: String, eKey: String) -> some View {
        HStack(spacing: Metrics.filterChipGap) {
            field(key: sKey, caption: "flt.from")
            Text("~")
                .font(Typo.field)
                .foregroundStyle(Palette.textLabel)
            field(key: eKey, caption: "flt.to")
        }
        .padding(.top, Metrics.filterFieldTop)
    }

    private func field(key: String, caption: String) -> some View {
        EditableText(text: store[key], font: Typo.field, color: Palette.textHint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.sheetFieldPadH)
            .frame(height: Metrics.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                    .fill(Palette.fieldBg)
            )
            .editTap(key, store[key])
            .onLongPressGesture(minimumDuration: 0.45) {
                editor.begin(key: caption, value: store[caption])
            }
    }

    private var durRow: some View {
        HStack(spacing: Metrics.filterChipGap) {
            durBox(key: "flt.dur.d", unitKey: "flt.unit.d")
            durBox(key: "flt.dur.h", unitKey: "flt.unit.h")
            durBox(key: "flt.dur.m", unitKey: "flt.unit.m")
        }
        .padding(.top, Metrics.filterFieldTop)
    }

    private func durBox(key: String, unitKey: String) -> some View {
        HStack(spacing: 4) {
            EditableText(text: store[key], font: Typo.field, color: Palette.textHint)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .editTap(key, store[key])
            EditableText(text: store[unitKey], font: Typo.field, color: Palette.textHint)
                .editTap(unitKey, store[unitKey])
        }
        .padding(.horizontal, Metrics.sheetFieldPadH)
        .frame(height: Metrics.fieldHeight)
        .background(
            RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                .fill(Palette.fieldBg)
        )
    }

    // 重置（描边蓝字）/ 确定（蓝底白字），各占一半、46 高
    private var bottomBar: some View {
        HStack(spacing: 0) {
            Text(store["flt.reset"])
                .font(Typo.sheetButton)
                .foregroundStyle(Palette.blue)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.bigButton)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                        .fill(Palette.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                        .strokeBorder(Palette.outline, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = FilterSelection()
                    store.resetFilterFields()
                }
                .onLongPressGesture(minimumDuration: 0.45) {
                    editor.begin(key: "flt.reset", value: store["flt.reset"])
                }

            Text(store["flt.ok"])
                .font(Typo.sheetButton)
                .foregroundStyle(Palette.white)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.bigButton)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                        .fill(Palette.blue)
                )
                .contentShape(Rectangle())
                .padding(.leading, Metrics.fwdGap)
                .onTapGesture { onConfirm() }
                .onLongPressGesture(minimumDuration: 0.45) {
                    editor.begin(key: "flt.ok", value: store["flt.ok"])
                }
        }
        .padding(.top, Metrics.filterButtonTop)
    }
}

// MARK: - 截图用静态版

struct CaptureRecords: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(store: store, titleKey: "nav.record", showsBack: true)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ArtImage(name: Art.filterInactive, width: 20, height: 20)
                    .padding(10)
                    .frame(width: Metrics.backBox, height: 40)
                    .padding(.trailing, 6)
            }
            .frame(height: 40)
            .background(Palette.white)
            ScrollView(showsIndicators: false) {
                RecordsBody(store: store, interactive: false)
            }
            HomeTabBar(store: store, selected: .records, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
