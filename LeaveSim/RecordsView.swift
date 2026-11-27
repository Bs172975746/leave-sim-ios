//
//  RecordsView.swift
//  LeaveSim
//
//  请假记录页（导航标题「请假」，右上漏斗打开筛选弹层）+ 底部 tab 记录为选中态。
//

import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @State private var filterShown = false
    @State private var statusKey = "flt.s1"
    @StateObject private var exporter = ShotExporter()

    init(path: Binding<[AppRoute]>) {
        _path = path
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.record",
                      title: store["nav.record"],
                      showsBack: true,
                      onBack: { dismiss() },
                      trailingIcons: ["line.3.horizontal.decrease", "camera"],
                      onTrailingTap: { index in
                          if index == 0 {
                              filterShown = true
                          } else {
                              exporter.asking = true
                          }
                      })

            ScrollView(showsIndicators: false) {
                RecordsBody(store: store, interactive: true)
            }

            HomeTabBar(store: store,
                       selected: .records,
                       onApply: { path.removeAll() },
                       onRecord: {})
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if filterShown {
                FilterPanel(store: store,
                            statusKey: $statusKey,
                            onClose: { filterShown = false },
                            onReset: {
                                statusKey = "flt.s1"
                                exporter.flash("已重置筛选条件")
                            },
                            onConfirm: {
                                filterShown = false
                                exporter.flash("已按条件筛选")
                            })
            }
        }
        .shotExport(exporter, capture: { Shot.render(CaptureRecords(store: store)) })
    }
}

// MARK: - 记录正文

struct RecordsBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true

    @Environment(\.editorCenter) private var editor

    private let records: [(String, String, String, String, String, String)] = [
        ("rec1.title", "rec1.start", "rec1.end", "rec1.reason", "rec1.owner", "rec1.at"),
        ("rec2.title", "rec2.start", "rec2.end", "rec2.reason", "rec2.owner", "rec2.at"),
        ("rec3.title", "rec3.start", "rec3.end", "rec3.reason", "rec3.owner", "rec3.at")
    ]

    var body: some View {
        VStack(spacing: 0) {
            tipBar

            ForEach(Array(records.enumerated()), id: \.offset) { item in
                recordCard(item.element)
                    .padding(.horizontal, Metrics.cardMargin)
                    .padding(.top, 12)
            }

            EditableText(text: store["list.footer"],
                         font: .system(size: 13),
                         color: Palette.textTabIdle,
                         alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
                .editTap("list.footer", store["list.footer"], enabled: interactive)
                .padding(.vertical, 24)
        }
        .padding(.bottom, 12)
    }

    private var tipBar: some View {
        HStack(spacing: 0) {
            EditableText(text: store["rec.tip"],
                         font: .system(size: 12),
                         color: Palette.blue,
                         lineSpacing: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("rec.tip", store["rec.tip"], enabled: interactive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Palette.ruleBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 12)
    }

    private func recordCard(_ rec: (String, String, String, String, String, String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                EditableText(text: store[rec.0],
                             font: .system(size: 17, weight: .semibold),
                             color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap(rec.0, store[rec.0], enabled: interactive)

                EditableText(text: store["rec.status"],
                             font: .system(size: 13),
                             color: Palette.green)
                    .editTap("rec.status", store["rec.status"], enabled: interactive)
            }
            .padding(.bottom, 2)

            infoRow("l.l.start", rec.1)
            infoRow("l.l.end", rec.2)
            infoRow("l.l.reason", rec.3)

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
                .padding(.vertical, 10)

            HStack(spacing: 6) {
                AvatarView(image: store.avatar, size: 22)
                EditableText(text: store[rec.4], font: .system(size: 13), color: Palette.textValue)
                    .editTap(rec.4, store[rec.4], enabled: interactive)
                Spacer(minLength: 8)
                EditableText(text: store[rec.5], font: .system(size: 13), color: Palette.textLabel)
                    .editTap(rec.5, store[rec.5], enabled: interactive)
            }
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
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
}

// MARK: - 筛选弹层

struct FilterPanel: View {
    @ObservedObject var store: TextStore
    @Binding var statusKey: String
    let onClose: () -> Void
    let onReset: () -> Void
    let onConfirm: () -> Void

    @Environment(\.editorCenter) private var editor

    private let statuses = ["flt.s1", "flt.s2", "flt.s3", "flt.s4",
                            "flt.s5", "flt.s6", "flt.s7", "flt.s8"]

    init(store: TextStore,
         statusKey: Binding<String>,
         onClose: @escaping () -> Void,
         onReset: @escaping () -> Void,
         onConfirm: @escaping () -> Void) {
        self.store = store
        _statusKey = statusKey
        self.onClose = onClose
        self.onReset = onReset
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        typeRow
                        dateGroup("flt.start", "flt.date.a", "flt.date.b")
                        dateGroup("flt.leave", "flt.date.c", "flt.date.d")
                        durGroup
                        statusGroup
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 430)

                HStack(spacing: 12) {
                    Button {
                        onReset()
                    } label: {
                        Text(store["flt.reset"])
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.textValue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Palette.ghostBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onConfirm()
                    } label: {
                        Text(store["flt.ok"])
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Palette.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Palette.white)
            .clipShape(TopRoundedShape(radius: 16))
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom))
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(store["flt.title"])
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .contentShape(Rectangle())
                    .onTapGesture { editor.begin(key: "flt.title", value: store["flt.title"]) }

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.textLabel)
                            .frame(width: 40, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 52)
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
        }
    }

    private var typeRow: some View {
        HStack(spacing: 8) {
            labelText("flt.type")
            Spacer(minLength: 0)
            EditableText(text: store["flt.type.value"], font: Typo.value, color: Palette.textValue)
                .editTap("flt.type.value", store["flt.type.value"])
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textLabel)
        }
        .frame(height: 40)
        .padding(.horizontal, 12)
        .background(Palette.fieldBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dateGroup(_ titleKey: String, _ aKey: String, _ bKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelText(titleKey)
            HStack(spacing: 8) {
                box(aKey)
                Text("~")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textLabel)
                box(bKey)
            }
        }
    }

    private var durGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelText("flt.dur")
            HStack(spacing: 8) {
                box("flt.dur.a")
                Text("~")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textLabel)
                box("flt.dur.b")
            }
        }
    }

    private var statusGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("flt.status")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 10)],
                      alignment: .leading,
                      spacing: 10) {
                ForEach(statuses, id: \.self) { key in
                    statusChip(key)
                }
            }
        }
    }

    private func statusChip(_ key: String) -> some View {
        let on = statusKey == key
        return EditableText(text: store[key],
                            font: .system(size: 13),
                            color: on ? Palette.blue : Palette.textValue)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(on ? Palette.ruleBg : Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(on ? Palette.blue : Palette.ghostBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { statusKey = key }
            .onLongPressGesture(minimumDuration: 0.5) {
                editor.begin(key: key, value: store[key])
            }
    }

    private func labelText(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.label, color: Palette.textLabel)
            .editTap(key, store[key])
    }

    private func box(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.value, color: Palette.textLabel, alignment: .center)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Palette.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .editTap(key, store[key])
    }
}

// MARK: - 记录页截图

struct CaptureRecords: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.record", title: store["nav.record"], showsBack: true)
            RecordsBody(store: store, interactive: false)
            HomeTabBar(store: store, selected: .records, interactive: false, onApply: {}, onRecord: {})
        }
        .background(Palette.pageBg)
    }
}
