//
//  FormView.swift
//  LeaveSim
//
//  ④请假申请表：请假内容 / 请假去向 / 抄送人 + 提交。
//  行距 46pt、标签列 108pt、必填项红星、缺项时红字提示在值下方。
//  提交时把 f.* 写回 q.* / d.*，再回列表 —— 列表的「进行中」卡片立刻变。
//

import SwiftUI
import PhotosUI

// MARK: - 表单页

struct FormView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @State private var wheel: WheelState?
    @State private var dateIndexes: [Int] = [2, 10, 29]
    @State private var timeIndexes: [Int] = [8, 0]
    @State private var reasonDraft: String = ""
    @State private var selectedCC: Set<Int> = []
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?

    @StateObject private var exporter = ShotExporter()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                NavHeader(titleKey: "nav.form",
                          title: store["nav.form"],
                          showsBack: true,
                          onBack: { dismiss() },
                          trailing: [.symbol("camera")],
                          onTrailingTap: { _ in exporter.asking = true })

                ScrollView(showsIndicators: false) {
                    FormBody(store: store,
                             interactive: true,
                             reasonDraft: $reasonDraft,
                             selectedCC: $selectedCC,
                             onStartTap: { openWheel(.start) },
                             onEndTap: { openWheel(.end) },
                             onProofTap: { showPicker = true })
                }

                FormSubmitBar(store: store, interactive: true, onSubmit: submit)
            }
            .background(Palette.pageBg)

            if let wheel {
                WheelPanel(state: wheel,
                           dateIndexes: $dateIndexes,
                           timeIndexes: $timeIndexes,
                           onCancel: { self.wheel = nil },
                           onNext: {
                               if wheel.isDate {
                                   self.wheel = WheelState(field: wheel.field, isDate: false)
                               } else {
                                   commitWheel(wheel.field)
                                   self.wheel = nil
                               }
                           })
                    .zIndex(5)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            reasonDraft = store.isFilled("f.reason") ? store["f.reason"] : ""
        }
        .onChange(of: reasonDraft) { text in
            store.set("f.reason", text)
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { item in
            Task {
                await store.loadImage(item, slot: .proof)
                if store.proof != nil { store.set("f.proof", "已选择 1 张证明材料") }
                pickerItem = nil
            }
        }
        .shotExport(exporter, capture: {
            Shot.render(CaptureForm(store: store))
        })
    }

    // MARK: 滚轮

    private func openWheel(_ field: FormField) {
        let key = field == .start ? "f.start" : "f.end"
        if let date = TimeFmt.parse(store[key]) {
            let cal = Calendar.current
            let c = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let yearText = String(format: "%04d", c.year ?? 2026)
            let yi = WheelData.years.firstIndex(of: yearText) ?? 2
            dateIndexes = [yi,
                           min(max((c.month ?? 1) - 1, 0), WheelData.months.count - 1),
                           min(max((c.day ?? 1) - 1, 0), WheelData.days.count - 1)]
            timeIndexes = [min(max(c.hour ?? 8, 0), 23), min(max(c.minute ?? 0, 0), 59)]
        }
        wheel = WheelState(field: field, isDate: true)
    }

    private func commitWheel(_ field: FormField) {
        let year = WheelData.years[min(dateIndexes[0], WheelData.years.count - 1)]
        let month = WheelData.months[min(dateIndexes[1], WheelData.months.count - 1)]
        let day = WheelData.days[min(dateIndexes[2], WheelData.days.count - 1)]
        let hour = WheelData.hours[min(timeIndexes[0], WheelData.hours.count - 1)]
        let minute = WheelData.minutes[min(timeIndexes[1], WheelData.minutes.count - 1)]
        let text = "\(year)-\(month)-\(day) \(hour):\(minute)"
        store.set(field == .start ? "f.start" : "f.end", text)
        // 起止都齐了就立刻把时长补上，让表单里看得见
        store.set("f.dur", store["f.dur"])
    }

    // MARK: 提交

    private func submit() {
        let missing = store.validateForm()
        guard missing == 0 else {
            exporter.flash("还有 \(missing) 项必填没填")
            return
        }
        store.commitForm()
        path.removeAll()
    }
}

// MARK: - 表单主体

struct FormBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    @Binding var reasonDraft: String
    @Binding var selectedCC: Set<Int>
    var onStartTap: () -> Void = {}
    var onEndTap: () -> Void = {}
    var onProofTap: () -> Void = {}

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            titleCard
            infoCard
            destCard
            ccCard
        }
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 13)
        .padding(.bottom, 22)
    }

    private var titleCard: some View {
        Card(padding: 18) {
            HStack(spacing: 10) {
                EditableText(text: store["f.hd.title"],
                             font: Typo.cardTitle,
                             color: Palette.textPrimary)
                    .editTap("f.hd.title", store["f.hd.title"], enabled: interactive)
                Spacer(minLength: 0)
                EditableText(text: store["hd.status"],
                             font: .system(size: 12, weight: .medium),
                             color: store.statusColor(for: "hd.status"))
                    .editTap("hd.status", store["hd.status"], enabled: interactive)
                ArtImage(name: Art.join, width: 26, height: 26)
            }
        }
    }

    private var infoCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.f.info"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.f.info", store["sec.f.info"], enabled: interactive)
                    .padding(.bottom, 6)

                FormRow(store: store, labelKey: "l.f.start", valueKey: "f.start",
                        required: true, interactive: interactive, hint: true,
                        onValueTap: onStartTap)
                FormRow(store: store, labelKey: "l.f.end", valueKey: "f.end",
                        required: true, interactive: interactive, hint: true,
                        onValueTap: onEndTap)
                FormRow(store: store, labelKey: "l.f.dur", valueKey: "f.dur",
                        interactive: interactive, valueColor: Palette.blue)

                FormRow(store: store, labelKey: "l.f.course", valueKey: "f.course",
                        required: true, interactive: interactive, hint: true)

                reasonRow

                proofRow

                FormRow(store: store, labelKey: "l.f.place", valueKey: "f.place",
                        required: true, interactive: interactive, hint: true)
            }
        }
    }

    // 多行原因：直接编辑，右上角 0/1000
    private var reasonRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                EditableText(text: store["l.f.reason"], font: Typo.label, color: Palette.textLabel)
                    .editTap("l.f.reason", store["l.f.reason"], enabled: interactive)
                Text("*").font(.system(size: 13)).foregroundStyle(Palette.error)
                Spacer(minLength: 0)
                Text("\(reasonDraft.count)/1000")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textLabel)
            }

            ZStack(alignment: .topLeading) {
                if reasonDraft.isEmpty {
                    Text(store["f.reason"])
                        .font(Typo.value)
                        .foregroundStyle(Palette.textLabel)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }
                TextField("", text: $reasonDraft, axis: .vertical)
                    .font(Typo.value)
                    .foregroundStyle(Palette.textValue)
                    .lineLimit(3...8)
                    .padding(9)
                    .disabled(!interactive)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))

            if !store[store.requiredHint("f.reason")].isEmpty {
                Text(store[store.requiredHint("f.reason")])
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.error)
            }
        }
        .padding(.vertical, 8)
    }

    // 证明材料：虚线框，点一下选图
    private var proofRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                EditableText(text: store["l.f.proof"], font: Typo.label, color: Palette.textLabel)
                    .editTap("l.f.proof", store["l.f.proof"], enabled: interactive)
                    .frame(width: Metrics.formLabelWidth, alignment: .leading)

                HStack(spacing: 10) {
                    if let proof = store.proof {
                        Image(uiImage: proof)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    EditableText(text: store["f.proof"], font: Typo.value, color: Palette.textLabel)
                        .editTap("f.proof", store["f.proof"], enabled: interactive)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Metrics.formRowPitch)

            Button {
                if interactive { onProofTap() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("上传证明材料")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Palette.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(Palette.ghostBorder)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private var destCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.f.dest"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.f.dest", store["sec.f.dest"], enabled: interactive)
                    .padding(.bottom, 6)

                InfoRow(store: store,
                        labelKey: "l.f.left",
                        valueKey: "f.left",
                        interactive: interactive,
                        valueColor: Palette.blue,
                        valueAction: {
                            store.set("f.left", store["f.left"].hasPrefix("否") ? "是" : "否")
                        })

                if !store["f.left"].hasPrefix("否") {
                    FormRow(store: store, labelKey: "l.f.dest", valueKey: "f.dest", interactive: interactive)
                    FormRow(store: store, labelKey: "l.f.addr", valueKey: "f.addr", interactive: interactive)
                    FormRow(store: store, labelKey: "l.f.emerg", valueKey: "f.emerg", interactive: interactive)
                    FormRow(store: store, labelKey: "l.f.tel", valueKey: "f.tel", interactive: interactive)
                }
            }
        }
    }

    private var ccCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                EditableText(text: store["sec.cc"], font: Typo.sectionTitle, color: Palette.textPrimary)
                    .editTap("sec.cc", store["sec.cc"], enabled: interactive)
                    .padding(.bottom, 10)

                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { index in
                        ccChip(index)
                    }
                    Spacer(minLength: 0)
                }

                Text(store["f.cc.add"])
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.blue)
                    .padding(.top, 12)
                    .editTap("f.cc.add", store["f.cc.add"], enabled: interactive)
            }
        }
    }

    private func ccChip(_ index: Int) -> some View {
        let key = "f.cc.\(index)"
        let on = selectedCC.contains(index)
        return Text(store[key])
            .font(.system(size: 12))
            .foregroundStyle(on ? Palette.blue : Palette.textLabel)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(on ? Palette.blueSoft : Palette.fieldBg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(on ? Palette.blue.opacity(0.4) : Color.clear, lineWidth: 0.8)
            )
            .contentShape(Capsule())
            .onTapGesture {
                guard interactive else { return }
                if on { selectedCC.remove(index) } else { selectedCC.insert(index) }
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                guard interactive else { return }
                editorBegin(key: key)
            }
    }

    @Environment(\.editorCenter) private var editor
    private func editorBegin(key: String) {
        editor.begin(key: key, value: store[key])
    }
}

// MARK: - 表单行

struct FormRow: View {
    @ObservedObject var store: TextStore
    let labelKey: String
    let valueKey: String
    var required: Bool = false
    var interactive: Bool = true
    var valueColor: Color? = nil
    var hint: Bool = false
    var onValueTap: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 3) {
                    EditableText(text: store[labelKey], font: Typo.label, color: Palette.textLabel)
                        .editTap(labelKey, store[labelKey], enabled: interactive)
                    if required {
                        Text("*")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.error)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: Metrics.formLabelWidth, alignment: .leading)

                if let onValueTap {
                    EditableText(text: store[valueKey],
                                 font: Typo.value,
                                 color: valueColor ?? Palette.textValue,
                                 lineSpacing: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if interactive { onValueTap() }
                        }
                        .onLongPressGesture(minimumDuration: 0.45) {
                            guard interactive else { return }
                            editor.begin(key: valueKey, value: store[valueKey])
                        }
                } else {
                    EditableText(text: store[valueKey],
                                 font: Typo.value,
                                 color: valueColor ?? Palette.textValue,
                                 lineSpacing: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap(valueKey, store[valueKey], enabled: interactive)
                }
            }
            .frame(minHeight: Metrics.formRowPitch)

            if hint {
                let tip = store[store.requiredHint(valueKey)]
                if !tip.isEmpty {
                    Text(tip)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.error)
                        .padding(.leading, Metrics.formLabelWidth)
                        .padding(.bottom, 6)
                }
            }
        }
    }
}

// MARK: - 底部提交

struct FormSubmitBar: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onSubmit: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 0.5)
            Text(store["f.submit"])
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Palette.blue)
                .clipShape(Capsule())
                .contentShape(Capsule())
                .padding(.horizontal, Metrics.cardMargin)
                .padding(.vertical, 12)
                .onTapGesture {
                    if interactive { onSubmit() }
                }
                .onLongPressGesture(minimumDuration: 0.45) {
                    guard interactive else { return }
                    editor.begin(key: "f.submit", value: store["f.submit"])
                }
        }
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CaptureForm: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.form", title: store["nav.form"], showsBack: true)
            ScrollView(showsIndicators: false) {
                FormBody(store: store,
                         interactive: false,
                         reasonDraft: .constant(store.isFilled("f.reason") ? store["f.reason"] : ""),
                         selectedCC: .constant([]))
            }
            FormSubmitBar(store: store, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
