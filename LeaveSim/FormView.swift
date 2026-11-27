//
//  FormView.swift
//  LeaveSim
//
//  请假申请表单页（导航标题「请假」）。所有文字照旧可点即改；
//  带 * 的是必填项，点行右侧的 chevron 打开日期 / 时间 / 是·否 选择。
//

import SwiftUI
import PhotosUI

enum FormField: Hashable {
    case start
    case end
}

struct WheelState: Identifiable {
    let id = UUID()
    var field: FormField
    var isDate: Bool
}

struct FormView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @State private var proofItem: PhotosPickerItem?
    @State private var proofPickerShown = false
    @State private var pickLeftShown = false
    @State private var wheel: WheelState?

    @State private var dateIndexes: [Int] = [2, 8, 22]
    @State private var timeIndexes: [Int] = [7, 1]
    @State private var stagingDate = "2026-09-23"

    @StateObject private var exporter = ShotExporter()

    init(path: Binding<[AppRoute]>) {
        _path = path
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.form",
                      title: store["nav.form"],
                      showsBack: true,
                      onBack: { dismiss() },
                      trailingIcons: ["camera"],
                      onTrailingTap: { _ in exporter.asking = true })

            ScrollView(showsIndicators: false) {
                FormBody(store: store,
                         interactive: true,
                         onPickStart: { openDate(.start) },
                         onPickEnd: { openDate(.end) },
                         onPickLeft: { pickLeftShown = true },
                         onPickProof: { proofPickerShown = true },
                         onRelocate: { exporter.flash("定位已刷新：示例省示例市示例区示例路88号") },
                         onEditCC: { exporter.flash("点下面的标签就能选中抄送人") })
                    .padding(.bottom, 12)
            }

            FormSubmitBar(store: store, interactive: true) {
                path.append(.promise)
            }
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if let wheel {
                WheelPanel(state: wheel,
                           dateIndexes: $dateIndexes,
                           timeIndexes: $timeIndexes,
                           onCancel: { self.wheel = nil },
                           onNext: {
                               if wheel.isDate {
                                   stagingDate = dateString()
                                   self.wheel = WheelState(field: wheel.field, isDate: false)
                               } else {
                                   let text = stagingDate + " " + timeString()
                                   store.set(wheel.field == .start ? "f.start" : "f.end", text)
                                   self.wheel = nil
                               }
                           })
            }
        }
        .photosPicker(isPresented: $proofPickerShown, selection: $proofItem, matching: .images)
        .onChange(of: proofItem) { item in
            guard item != nil else { return }
            Task {
                await store.loadImage(item, slot: .proof)
                proofItem = nil
            }
        }
        .confirmationDialog("是否离校", isPresented: $pickLeftShown, titleVisibility: .visible) {
            Button("是") { store.set("f.left", "是") }
            Button("否") { store.set("f.left", "否") }
            Button("取消", role: .cancel) {}
        }
        .shotExport(exporter, capture: { Shot.render(CaptureForm(store: store)) })
    }

    private func openDate(_ field: FormField) {
        stagingDate = dateString()
        wheel = WheelState(field: field, isDate: true)
    }

    private func dateString() -> String {
        let years = WheelData.years
        let months = WheelData.months
        let days = WheelData.days
        let y = years[min(max(dateIndexes[0], 0), years.count - 1)]
        let m = months[min(max(dateIndexes[1], 0), months.count - 1)]
        let d = days[min(max(dateIndexes[2], 0), days.count - 1)]
        return "\(y)-\(m)-\(d)"
    }

    private func timeString() -> String {
        let h = WheelData.hours[min(max(timeIndexes[0], 0), WheelData.hours.count - 1)]
        let m = WheelData.minutes[min(max(timeIndexes[1], 0), WheelData.minutes.count - 1)]
        return "\(h):\(m)"
    }
}

// MARK: - 表单正文

struct FormBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onPickStart: () -> Void = {}
    var onPickEnd: () -> Void = {}
    var onPickLeft: () -> Void = {}
    var onPickProof: () -> Void = {}
    var onRelocate: () -> Void = {}
    var onEditCC: () -> Void = {}

    @Environment(\.editorCenter) private var editor
    @State private var selectedCC: Set<String> = []

    private let red = Color(hex: 0xFF3B30)

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            headerCard
            infoCard
            destCard
            ccCard
        }
    }

    // MARK: 头卡

    private var headerCard: some View {
        HStack(spacing: 0) {
            RuleStrip(text: store["hd.rule"])
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .editTap("hd.rule", store["hd.rule"], enabled: interactive)
                )

            EditableText(text: store["f.hd.title"],
                         font: .system(size: 17, weight: .semibold),
                         color: Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("f.hd.title", store["f.hd.title"], enabled: interactive)
                .padding(.leading, 20)
                .padding(.trailing, 22)
                .padding(.vertical, 21)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    // MARK: 请假内容

    private var infoCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("sec.info")

                // * 开始时间
                row(labelKey: "l.f.start", required: true) {
                    pickerValue(key: "f.start", action: onPickStart)
                }
                // * 结束时间
                row(labelKey: "l.f.end", required: true) {
                    pickerValue(key: "f.end", action: onPickEnd)
                }
                // * 请假时长 天 / 时 / 分
                row(labelKey: "l.f.dur", required: true) {
                    HStack(spacing: 4) {
                        unitValue("f.dur.d")
                        unitText("f.unit.d")
                        unitValue("f.dur.h")
                        unitText("f.unit.h")
                        unitValue("f.dur.m")
                        unitText("f.unit.m")
                        Spacer(minLength: 0)
                    }
                }
                // * 影响课程
                row(labelKey: "l.f.course", required: true) {
                    EditableText(text: store["f.course"], font: Typo.value, color: Palette.textValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap("f.course", store["f.course"], enabled: interactive)
                }
                // * 请假原因
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 0) {
                        label("l.f.reason", required: true)
                        VStack(alignment: .trailing, spacing: 4) {
                            reasonEditor
                            Text("\(store["f.reason"].count)/1000")
                                .font(.system(size: 11))
                                .foregroundStyle(Palette.textLabel)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 8)

                // 证明材料
                HStack(alignment: .top, spacing: 0) {
                    label("l.f.proof", required: false)
                    VStack(alignment: .leading, spacing: 6) {
                        proofBox
                        EditableText(text: store["f.proof.hint"],
                                     font: .system(size: 12),
                                     color: Palette.textLabel)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .editTap("f.proof.hint", store["f.proof.hint"], enabled: interactive)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)

                // * 发起位置
                row(labelKey: "l.f.place", required: true) {
                    HStack(spacing: 8) {
                        EditableText(text: store["f.place"],
                                     font: Typo.value,
                                     color: Palette.textValue,
                                     lineSpacing: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .editTap("f.place", store["f.place"], enabled: interactive)

                        EditableText(text: store["f.relocate"],
                                     font: .system(size: 13),
                                     color: Palette.blue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard interactive else { return }
                                onRelocate()
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                guard interactive else { return }
                                editor.begin(key: "f.relocate", value: store["f.relocate"])
                            }
                    }
                }
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, Metrics.cardSpacing)
    }

    private var reasonEditor: some View {
        let text = store["f.reason"]
        return Text(text.isEmpty ? store["f.reason.ph"] : text)
            .font(Typo.value)
            .foregroundStyle(text.isEmpty ? Palette.textLabel : Palette.textValue)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .background(Palette.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .editTap("f.reason", text, enabled: interactive)
    }

    private var proofBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Palette.ghostBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

            if let proof = store.proof {
                Image(uiImage: proof)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.textLabel)
                    EditableText(text: store["f.proof.count"],
                                 font: .system(size: 12),
                                 color: Palette.textLabel)
                        .editTap("f.proof.count", store["f.proof.count"], enabled: interactive)
                }
            }
        }
        .frame(height: 92)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            onPickProof()
        }
    }

    // MARK: 请假去向

    private var destCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("sec.dest")
                row(labelKey: "l.f.left", required: true) {
                    pickerValue(key: "f.left", action: onPickLeft)
                }
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
    }

    // MARK: 抄送人

    private var ccCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    sectionTitle("sec.cc")
                    Spacer(minLength: 0)
                    EditableText(text: store["f.cc.edit"], font: .system(size: 13), color: Palette.blue)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard interactive else { return }
                            onEditCC()
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            guard interactive else { return }
                            editor.begin(key: "f.cc.edit", value: store["f.cc.edit"])
                        }
                }

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Palette.ghostBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .frame(height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Palette.textLabel)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        onEditCC()
                    }

                EditableText(text: store["f.cc.title"],
                             font: .system(size: 13),
                             color: Palette.textValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("f.cc.title", store["f.cc.title"], enabled: interactive)

                EditableText(text: store["f.cc.empty"],
                             font: .system(size: 13),
                             color: Palette.textLabel,
                             alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .editTap("f.cc.empty", store["f.cc.empty"], enabled: interactive)
                    .padding(.vertical, 2)

                HStack(spacing: 10) {
                    chip("f.cc.a")
                    chip("f.cc.b")
                    chip("f.cc.c")
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, Metrics.cardMargin)
    }

    private func chip(_ key: String) -> some View {
        let on = selectedCC.contains(key)
        return EditableText(text: store[key],
                            font: .system(size: 13),
                            color: on ? Palette.blue : Palette.textValue)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(on ? Palette.ruleBg : Palette.white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(on ? Palette.blue : Palette.ghostBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard interactive else { return }
                if on {
                    selectedCC.remove(key)
                } else {
                    selectedCC.insert(key)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                guard interactive else { return }
                editor.begin(key: key, value: store[key])
            }
    }

    // MARK: 原子

    private func sectionTitle(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.sectionTitle, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key], enabled: interactive)
            .padding(.bottom, 5)
    }

    private func label(_ key: String, required: Bool) -> some View {
        HStack(alignment: .top, spacing: 2) {
            Text("*")
                .font(.system(size: 13))
                .foregroundStyle(red)
                .opacity(required ? 1 : 0)
            EditableText(text: store[key], font: Typo.label, color: Palette.textLabel)
                .editTap(key, store[key], enabled: interactive)
        }
        .frame(width: Metrics.labelWidth, alignment: .leading)
    }

    private func row<Content: View>(labelKey: String,
                                    required: Bool,
                                    @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 0) {
            label(labelKey, required: required)
            content()
        }
        .frame(minHeight: 22, alignment: .topLeading)
        .padding(.vertical, 8)
    }

    private func pickerValue(key: String, action: @escaping () -> Void) -> some View {
        let empty = store[key] == "请选择"
        return HStack(spacing: 8) {
            EditableText(text: store[key],
                         font: Typo.value,
                         color: empty ? Palette.textLabel : Palette.textValue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap(key, store[key], enabled: interactive)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.textLabel)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            action()
        }
    }

    private func unitValue(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.value, color: Palette.textValue, alignment: .center)
            .frame(width: 34)
            .padding(.vertical, 3)
            .background(Palette.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .editTap(key, store[key], enabled: interactive)
    }

    private func unitText(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.value, color: Palette.textLabel)
            .editTap(key, store[key], enabled: interactive)
    }
}

// MARK: - 提交条

struct FormSubmitBar: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    let onSubmit: () -> Void

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            Group {
                if interactive {
                    Button {
                        onSubmit()
                    } label: {
                        buttonLabel
                    }
                    .buttonStyle(.plain)
                } else {
                    buttonLabel
                }
            }
            .padding(.horizontal, Metrics.cardMargin)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Palette.white.ignoresSafeArea(edges: .bottom))
    }

    private var buttonLabel: some View {
        Text(store["f.submit"])
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Palette.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                guard interactive else { return }
                editor.begin(key: "f.submit", value: store["f.submit"])
            }
    }
}

// MARK: - 表单截图

struct CaptureForm: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.form", title: store["nav.form"], showsBack: true)
            FormBody(store: store, interactive: false)
            FormSubmitBar(store: store, interactive: false, onSubmit: {})
        }
        .background(Palette.pageBg)
    }
}
