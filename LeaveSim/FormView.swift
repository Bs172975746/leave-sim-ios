//
//  FormView.swift
//  LeaveSim
//
//  ④请假申请表：请假内容 / 请假去向 / 抄送人 + 提交。
//  数值对齐 screen_form.xml（1dp = 1pt）：行上下 15、标签列 108、星号 6 间距、
//  缺项红字 12 在值下方、证明材料 54pt 虚线框、提交 48pt 蓝底圆角 10。
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
                NavHeader(store: store,
                          titleKey: "nav.form",
                          showsBack: true,
                          onBack: { dismiss() })

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

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: Metrics.cardGap) {
            titleCard
            infoCard
            destCard
            ccCard
        }
        .padding(.bottom, Metrics.formContentBottom)
    }

    // MARK: 头卡（竖排「请假规则」+ 假别）

    private var titleCard: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                EditableText(text: store["f.hd.title"], font: Typo.formTitle, color: Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("f.hd.title", store["f.hd.title"], enabled: interactive)
            }
            .padding(.leading, Metrics.headerPadStart)
            .padding(.trailing, Metrics.headerPadEnd)
            .padding(.vertical, Metrics.formHeaderPadV)

            RuleStrip(text: store["hd.rule"])
                .editTap("hd.rule", store["hd.rule"], enabled: interactive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    // MARK: 请假内容

    private var infoCard: some View {
        VStack(spacing: 0) {
            sectionTitle("sec.f.info")

            FormRow(store: store, labelKey: "l.f.start", valueKey: "f.start",
                    required: true, interactive: interactive,
                    chevron: true, onValueTap: onStartTap)

            FormRow(store: store, labelKey: "l.f.end", valueKey: "f.end",
                    required: true, interactive: interactive,
                    chevron: true, onValueTap: onEndTap)

            FormRow(store: store, labelKey: "l.f.dur", valueKey: "f.dur",
                    required: true, interactive: interactive)

            FormRow(store: store, labelKey: "l.f.course", valueKey: "f.course",
                    required: true, interactive: interactive)

            reasonRow
            proofRow
            placeRow
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.cardPadTop)
        .padding(.bottom, Metrics.cardPadBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    private var reasonRow: some View {
        HStack(alignment: .top, spacing: 0) {
            labelColumn("l.f.reason", required: true)

            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if reasonDraft.isEmpty {
                        Text(store["f.reason"].isEmpty ? "请输入" : store["f.reason"])
                            .font(Typo.formRow)
                            .foregroundStyle(Palette.textHint)
                            .padding(.top, 1)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $reasonDraft, axis: .vertical)
                        .font(Typo.formRow)
                        .foregroundStyle(Palette.textValue)
                        .lineSpacing(2)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(!interactive)
                }
                .frame(minHeight: Metrics.reasonMinHeight, alignment: .topLeading)

                Text("\(reasonDraft.count)/1000")
                    .font(Typo.counter)
                    .foregroundStyle(Palette.textHint)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let hint = hintText("f.reason") {
                    Text(hint)
                        .font(Typo.errHint)
                        .foregroundStyle(Palette.error)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                }
            }
        }
        .padding(.top, Metrics.formRowPadV)
        .padding(.bottom, 2)
    }

    private var proofRow: some View {
        HStack(alignment: .top, spacing: 0) {
            labelColumn("l.f.proof", required: false)

            VStack(alignment: .leading, spacing: Metrics.proofHintTop) {
                Button {
                    if interactive { onProofTap() }
                } label: {
                    if let proof = store.proof {
                        Image(uiImage: proof)
                            .resizable()
                            .scaledToFill()
                            .frame(width: Metrics.proofBox, height: Metrics.proofBox)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous))
                    } else {
                        VStack(spacing: 0) {
                            Text("+")
                                .font(.system(size: 22))
                                .foregroundStyle(Palette.textLabel)
                            Text("0/4")
                                .font(Typo.counter)
                                .foregroundStyle(Palette.textLabel)
                        }
                        .frame(width: Metrics.proofBox, height: Metrics.proofBox)
                        .background(
                            RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                                .fill(Palette.white)
                        )
                        .overlay(
                            DashedBorder(radius: Metrics.smallRadius, color: Palette.dashed)
                        )
                        .onLongPressGesture(minimumDuration: 0.45) {
                            guard interactive else { return }
                            editor.begin(key: "f.proof", value: store["f.proof"])
                        }
                    }
                }
                .buttonStyle(.plain)

                Text("请上传证明材料")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.textHint)
            }
        }
        .padding(.top, Metrics.proofPadTop)
        .padding(.bottom, Metrics.proofPadBottom)
    }

    private var placeRow: some View {
        HStack(alignment: .top, spacing: 0) {
            labelColumn("l.f.place", required: true)

            HStack(spacing: 0) {
                EditableText(text: store["f.place"],
                             font: Typo.formRow,
                             color: Palette.blue,
                             lineSpacing: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("f.place", store["f.place"], enabled: interactive)

                Rectangle()
                    .fill(Palette.divider)
                    .frame(width: 1, height: Metrics.placeDividerW)
                    .padding(.horizontal, Metrics.inlineGap)

                Text("去授权 >")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.blue)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if interactive { store.set("f.place", "示例省示例市示例区示例路88号") }
                    }
            }
            .padding(.top, 2)
        }
        .padding(.top, Metrics.placePadTop)
        .padding(.bottom, Metrics.placePadBottom)
    }

    // MARK: 请假去向

    private var destCard: some View {
        VStack(spacing: 0) {
            sectionTitle("sec.f.dest")

            FormRow(store: store, labelKey: "l.f.left", valueKey: "f.left",
                    required: true, interactive: interactive,
                    chevron: true,
                    valueAction: { store.toggleLeaveType() })

            if store.leavesCampus {
                FormRow(store: store, labelKey: "l.f.dest", valueKey: "f.dest",
                        required: false, interactive: interactive)
                FormRow(store: store, labelKey: "l.f.addr", valueKey: "f.addr",
                        required: false, interactive: interactive)
                FormRow(store: store, labelKey: "l.f.emerg", valueKey: "f.emerg",
                        required: false, interactive: interactive)
                FormRow(store: store, labelKey: "l.f.tel", valueKey: "f.tel",
                        required: false, interactive: interactive)
            }
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.cardPadTop)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    // MARK: 抄送人

    private var ccCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("sec.cc")

            Button {
                if interactive {
                    let open = (1...3).filter { !selectedCC.contains($0) }.first
                    if let index = open {
                        withAnimation(.easeInOut(duration: 0.15)) { _ = selectedCC.insert(index) }
                    }
                }
            } label: {
                VStack(spacing: 0) {
                    Text("+")
                        .font(.system(size: 22))
                        .foregroundStyle(Palette.textLabel)
                }
                .frame(width: Metrics.ccBox, height: Metrics.ccBox)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                        .fill(Palette.white)
                )
                .overlay(
                    DashedBorder(radius: Metrics.smallRadius, color: Palette.dashed)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, Metrics.ccTop)

            HStack(spacing: 0) {
                Text("常用抄送人（可点击下方标签选中人员）")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.textLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("编辑")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.blue)
            }
            .padding(.top, Metrics.ccTop)

            if selectedCC.isEmpty {
                Text("暂无数据，请点击编辑进行设置")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.textHint)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Metrics.ccListTop)
            } else {
                HStack(spacing: Metrics.filterChipGap) {
                    ForEach(1...3, id: \.self) { index in
                        if selectedCC.contains(index) {
                            CcChip(store: store,
                                   index: index,
                                   interactive: interactive,
                                   onRemove: { selectedCC.remove(index) })
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, Metrics.ccListTop)
            }
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.cardPadTop)
        .padding(.bottom, Metrics.ccPadBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
    }

    // MARK: 小组件

    private func sectionTitle(_ key: String) -> some View {
        EditableText(text: store[key], font: Typo.section, color: Palette.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .editTap(key, store[key], enabled: interactive)
            .padding(.top, Metrics.sectionPadTop)
            .padding(.bottom, Metrics.sectionPadBottom)
    }

    private func labelColumn(_ key: String, required: Bool) -> some View {
        HStack(spacing: 0) {
            if required {
                Text("*")
                    .font(Typo.formRow)
                    .foregroundStyle(Palette.error)
                    .frame(width: 12, alignment: .leading)
            }
            EditableText(text: store[key], font: Typo.formRow, color: Palette.textLabel, lineSpacing: 2)
                .editTap(key, store[key], enabled: interactive)
            Spacer(minLength: 0)
        }
        .frame(width: Metrics.formLabelWidth, alignment: .leading)
        .padding(.top, 1)
    }

    private func hintText(_ valueKey: String) -> String? {
        let key = store.requiredHint(valueKey)
        let text = store[key]
        return text.isEmpty ? nil : text
    }
}

// MARK: - 表单行

struct FormRow: View {
    @ObservedObject var store: TextStore
    var labelKey: String
    var valueKey: String
    var required: Bool = false
    var interactive: Bool = true
    var valueColor: Color? = nil
    var chevron: Bool = false
    var onValueTap: (() -> Void)? = nil
    var valueAction: (() -> Void)? = nil

    @Environment(\.editorCenter) private var editor

    private var hint: String? {
        let key = store.requiredHint(valueKey)
        let text = store[key]
        return text.isEmpty ? nil : text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: 0) {
                if required {
                    Text("*")
                        .font(Typo.formRow)
                        .foregroundStyle(Palette.error)
                        .frame(width: Metrics.starWidth, alignment: .leading)
                }
                EditableText(text: store[labelKey], font: Typo.formRow,
                             color: Palette.textValue, lineSpacing: 2)
                    .editTap(labelKey, store[labelKey], enabled: interactive)
                Spacer(minLength: 0)
            }
            .frame(width: Metrics.formLabelWidth, alignment: .leading)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    EditableText(text: store[valueKey],
                                 font: Typo.formRow,
                                 color: valueColor ?? (store.isFilled(valueKey) ? Palette.textValue : Palette.textHint),
                                 lineSpacing: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .editTap(valueKey, store[valueKey], enabled: interactive)

                    if chevron {
                        ChevronRight(color: Palette.chevron)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard interactive else { return }
                    if let onValueTap { onValueTap() }
                    else if let valueAction { valueAction() }
                }

                if let hint {
                    Text(hint)
                        .font(Typo.errHint)
                        .foregroundStyle(Palette.error)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                }
            }
        }
        .padding(.top, Metrics.formRowPadV)
        .padding(.bottom, Metrics.formRowPadV)
    }
}

// MARK: - 抄送人标签

struct CcChip: View {
    @ObservedObject var store: TextStore
    var index: Int
    var interactive: Bool = true
    var onRemove: () -> Void = {}

    var body: some View {
        Text(store["f.cc.\(index)"])
            .font(Typo.formRow)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: Metrics.chipRadius, style: .continuous)
                    .fill(Palette.chipBg)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if interactive { onRemove() }
            }
    }
}

// MARK: - 虚线框

struct DashedBorder: View {
    var radius: CGFloat = 6
    var color: Color = Palette.dashed

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
    }
}

// MARK: - 提交栏

struct FormSubmitBar: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    var onSubmit: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        HStack(spacing: 0) {
            Text(store["f.submit"])
                .font(Typo.submit)
                .foregroundStyle(Palette.white)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.submitHeight)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                        .fill(Palette.blue)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if interactive { onSubmit() }
                }
                .onLongPressGesture(minimumDuration: 0.45) {
                    guard interactive else { return }
                    editor.begin(key: "f.submit", value: store["f.submit"])
                }
        }
        .padding(.horizontal, Metrics.pagePadding)
        .padding(.top, Metrics.submitPadV)
        .padding(.bottom, Metrics.submitPadV)
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CaptureForm: View {
    @ObservedObject var store: TextStore

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(store: store, titleKey: "nav.form", showsBack: true)
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
