//
//  Models.swift
//  LeaveSim
//
//  TextStore：全站可改文案的唯一数据源。任何页面改一个字都写进这里，
//  再由 `set(_:_:)` 落到 UserDefaults —— 详情页和列表页读的是同一份 key，
//  所以「详情改完列表自动同步」「列表改完详情不被覆盖」都不需要额外同步代码。
//
//  key 命名与 Android 版一致（q.* / d.* / a.* / hd.* / hm.*），
//  额外补了页面级文案 key（list.* / l.* / f.* / rec.* / flt.* / pr.*）。
//

import Foundation
import SwiftUI
import UIKit
import Photos
import PhotosUI

// MARK: - 路由与局部状态

enum AppRoute: Hashable {
    case detail
    case form
    case records
    case promise
}

enum DetailTab: String, CaseIterable {
    case leave = "请假"
    case extend = "续假"
}

enum HomeTab {
    case apply
    case records
}

enum ImageSlot {
    case avatar
    case proof

    var key: String {
        switch self {
        case .avatar: return "img.avatar"
        case .proof:  return "img.proof"
        }
    }
}

enum FormField {
    case start
    case end
}

struct WheelState: Identifiable {
    let id = UUID()
    var field: FormField
    var isDate: Bool
}

// MARK: - 时间与时长

enum TimeFmt {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    static func parse(_ text: String) -> Date? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        return formatter.date(from: t)
    }

    static func stamp(_ date: Date = Date()) -> String {
        formatter.string(from: date)
    }

    /// 起止时间 → 分钟差。任一不能解析就返回 nil（此时不改时长）。
    static func minutes(from start: String, to end: String) -> Int? {
        guard let a = parse(start), let b = parse(end) else { return nil }
        let mins = Int((b.timeIntervalSince(a) / 60).rounded())
        return mins
    }

    /// 分钟 → 「X天X时X分」；不足一天省略「0天」。
    static func durationText(_ minutes: Int) -> String {
        let total = max(0, minutes)
        let d = total / 1440
        let h = (total % 1440) / 60
        let m = total % 60
        if d > 0 {
            return "\(d)天\(h)时\(m)分"
        }
        return "\(h)时\(m)分"
    }
}

// MARK: - 全部文案

final class TextStore: ObservableObject {

    /// 默认文案。`key` 与 Android 版对齐；改这里就等于改「恢复默认」的目标。
    static let fields: [(key: String, value: String)] = [
        // ── 导航标题
        ("nav.home",    "请假"),
        ("nav.detail",  "请假详情"),
        ("nav.form",    "请假"),
        ("nav.record",  "请假"),
        ("nav.promise", "请假安全承诺书"),

        // ── 列表页
        ("list.active", "进行中"),
        ("list.start",  "发起"),
        ("list.more",   "更多"),
        ("revoke",      "撤销请假申请"),
        ("list.footer", "没有更多数据了~"),
        ("list.type.1", "其它"),
        ("list.type.2", "事假"),
        ("list.type.3", "病假"),

        // ── 底部 tab
        ("tab.apply",  "我要请假"),
        ("tab.record", "请假记录"),

        // ── 详情页 / 进行中卡片共用的业务字段
        ("请假", "请假"),
        ("续假", "续假"),
        ("hd.rule",   "请假规则"),
        ("sec.info",  "请假内容"),
        ("sec.dest",  "请假去向"),
        ("sec.approval", "审批流程"),
        ("sec.xj",    "续假信息"),
        ("hd.name",   "王小明的其它"),
        ("hd.status", "审批中"),
        ("q.student", "王小明"),
        ("q.start",   "2026-11-30 08:00"),
        ("q.end",     "2026-12-01 21:59"),
        ("q.dur",     "1天13时59分"),
        ("q.course",  "数据结构、计算机网络"),
        ("q.reason",  "家中有事，需回家处理，已与辅导员沟通"),
        ("q.proof",   "-"),
        ("q.place",   "示例省示例市示例区"),
        ("q.submit",  "2026-11-28 09:12 提交"),

        ("l.q.student", "学生姓名"),
        ("l.q.start",   "开始时间"),
        ("l.q.end",     "结束时间"),
        ("l.q.dur",     "请假时长"),
        ("l.q.course",  "课程"),
        ("l.q.reason",  "请假原因"),
        ("l.q.proof",   "证明材料"),
        ("l.q.place",   "发起位置"),

        ("d.left",  "是"),
        ("d.dest",  "回家"),
        ("d.addr",  "示例省示例市示例区示例路88号 示例小区3号楼"),
        ("d.emerg", "王大明 13800001234"),
        ("d.tel",   "13900005678"),

        ("l.d.left",  "是否离校"),
        ("l.d.dest",  "请假去向"),
        ("l.d.addr",  "详细地址"),
        ("l.d.emerg", "紧急联系人"),
        ("l.d.tel",   "联系电话"),

        ("a.who",  "辅导员 李老师"),
        ("a.res",  "审批中"),
        ("a.time", "2026-11-28 09:20"),
        ("a.note", "已收到，注意安全，按时返校"),

        ("l.a.who",  "审批人"),
        ("l.a.res",  "审批结果"),
        ("l.a.time", "审批时间"),
        ("l.a.note", "审批备注"),

        // ── 续假 tab
        ("hm.name",   "王小明的续假申请"),
        ("hm.status", "审批中"),
        ("hm.v1",     "2026-12-01 22:00 至 2026-12-03 18:00"),
        ("hm.v2",     "2天20时0分"),
        ("hm.v3",     "返程车票延误，需顺延两天"),
        ("hm.who",    "辅导员 李老师"),
        ("hm.time",   "2026-11-29 10:05"),

        ("l.hm.v1",   "续假时间"),
        ("l.hm.v2",   "续假时长"),
        ("l.hm.v3",   "续假原因"),
        ("l.hm.who",  "审批人"),
        ("l.hm.time", "申请时间"),

        ("bottom.more", "更多"),
        ("bottom.fwd",  "转发"),

        // ── 承诺书
        ("pr.t", "请假安全承诺书"),
        ("pr.1", "本人因个人事务申请离校，已充分阅读并理解学校《学生请假管理规定》及《学生安全教育手册》的全部内容，自愿作出如下承诺。"),
        ("pr.2", "一、本人保证所填写的请假事由、去向、联系方式等信息真实、准确、完整，如有隐瞒或虚报，愿承担由此产生的一切后果。"),
        ("pr.3", "二、离校期间严格遵守国家法律法规和校纪校规，不参与任何违法违纪活动，不前往疫情中高风险地区及无人值守的危险区域，注意交通、饮食、人身与财产安全。"),
        ("pr.4", "三、保持通讯畅通，主动向辅导员及家长报告行程，按时返校销假；如遇突发情况，第一时间联系辅导员 李老师（13800001234）。"),
        ("pr.check", "我已阅读并同意以上全部内容"),
        ("pr.no",    "不同意"),
        ("pr.yes",   "同意并继续"),

        // ── 申请表
        ("f.hd.title", "其它"),
        ("f.start",    "请选择"),
        ("f.end",      "请选择"),
        ("f.dur",      "天/时/分"),
        ("f.course",   ""),
        ("f.reason",   "请输入"),
        ("f.proof",    "请上传证明材料"),
        ("f.place",    "需要您授权移动APP平台位置信息，以便使用此功能"),
        ("f.left",     "是"),
        ("f.dest",     "请填写去向"),
        ("f.addr",     "请填写详细地址"),
        ("f.emerg",    "请填写紧急联系人"),
        ("f.tel",      "请填写联系电话"),
        ("f.submit",   "提交"),
        ("f.hint",     "此项为必填项"),

        ("sec.f.info", "请假内容"),
        ("sec.f.dest", "请假去向"),
        ("sec.cc",     "抄送人"),
        ("l.f.start",  "开始时间"),
        ("l.f.end",    "结束时间"),
        ("l.f.dur",    "请假时长"),
        ("l.f.course", "影响课程"),
        ("l.f.reason", "请假原因"),
        ("l.f.proof",  "证明材料"),
        ("l.f.place",  "请假地点"),
        ("l.f.left",   "是否离校"),
        ("l.f.dest",   "请假去向"),
        ("l.f.addr",   "详细地址"),
        ("l.f.emerg",  "紧急联系人"),
        ("l.f.tel",    "联系电话"),
        ("f.cc.1",     "辅导员 李老师"),
        ("f.cc.2",     "班长 赵同学"),
        ("f.cc.3",     "室友 陈同学"),
        ("f.cc.add",   "添加抄送人"),

        // ── 记录页
        ("rec.tip",    "本学期共提交 3 次请假，累计 5 天 6 时 0 分"),
        ("rec.sec",    "全部记录"),
        ("rec.status", "3 条"),
        ("rec.more",   "查看全部记录"),
        ("rec.footer", "没有更多数据了~"),

        ("rec1.name",   "王小明的请假申请"),
        ("rec1.time",   "2026-11-30 08:00 至 2026-12-01 21:59"),
        ("rec1.reason", "家中有事，需回家处理"),
        ("rec1.dur",    "1天13时59分"),
        ("rec1.status", "审批中"),

        ("rec2.name",   "王小明的请假申请"),
        ("rec2.time",   "2026-11-10 08:00 至 2026-11-11 18:00"),
        ("rec2.reason", "参加校级程序设计竞赛"),
        ("rec2.dur",    "1天10时0分"),
        ("rec2.status", "已完成"),

        ("rec3.name",   "王小明的请假申请"),
        ("rec3.time",   "2026-10-20 08:00 至 2026-10-21 12:00"),
        ("rec3.reason", "身体不适，前往医院就诊"),
        ("rec3.dur",    "1天4时0分"),
        ("rec3.status", "已驳回"),

        // ── 筛选弹层
        ("flt.title", "筛选"),
        ("flt.type",  "请假类型"),
        ("flt.date1", "请假开始时间"),
        ("flt.date2", "请假结束时间"),
        ("flt.dur",   "请假时长"),
        ("flt.status", "审批状态"),
        ("flt.reset", "重置"),
        ("flt.ok",    "确定"),
        ("flt.from",  "开始日期"),
        ("flt.to",    "结束日期"),
        ("flt.unit.d", "天"),
        ("flt.unit.h", "时"),
        ("flt.unit.m", "分"),
        ("flt.d1.s", "2026-10-01"),
        ("flt.d1.e", "2026-11-30"),
        ("flt.d2.s", "2026-10-01"),
        ("flt.d2.e", "2026-11-30"),
        ("flt.dur.d", "0"),
        ("flt.dur.h", "0"),
        ("flt.dur.m", "0"),
        ("flt.close", "关闭"),
        ("flt.type.1", "其它"),
        ("flt.type.2", "事假"),
        ("flt.type.3", "病假"),
        ("flt.type.4", "全部"),
        ("flt.s1", "待审批"),
        ("flt.s2", "审批中"),
        ("flt.s3", "已通过"),
        ("flt.s4", "已驳回"),
        ("flt.s5", "已撤销"),
        ("flt.s6", "已完成"),
        ("flt.s7", "即将休假"),
        ("flt.s8", "逾期")
    ]

    static let defaults: [String: String] = Dictionary(uniqueKeysWithValues: fields.map { ($0.key, $0.value) })

    // MARK: 状态

    @Published private(set) var values: [String: String]
    @Published private(set) var avatar: UIImage?
    @Published private(set) var proof: UIImage?

    private let ud = UserDefaults.standard

    /// 可以点开改的 key（不含空 key）
    static let editableKeys: Set<String> = Set(fields.map { $0.key })

    init() {
        var seed = TextStore.defaults
        for key in TextStore.defaults.keys {
            if let saved = UserDefaults.standard.string(forKey: key) {
                seed[key] = saved
            }
        }
        // 旧版本把标题存成「王小明的请假申请」，安卓版只显示「王小明的其它」：
        // 启动时把尾部的「申请」去掉，换成当前假别（其它 / 事假 / 病假）。
        let kind = (seed["f.hd.title"] ?? "").isEmpty ? "其它" : seed["f.hd.title"]!
        if var name = seed["hd.name"], name.hasSuffix("申请") {
            if name.hasSuffix("请假申请") { name = String(name.dropLast(4)) }
            else { name = String(name.dropLast(2)) }
            if name.hasSuffix("的") { name += kind }
            seed["hd.name"] = name
        }

        self.values = seed
        self.avatar = TextStore.loadImage(.avatar)
        self.proof = TextStore.loadImage(.proof)

        // 首次启动 / 旧版本 key：把缺的补进 UserDefaults，方便「重启后仍是改过的值」
        for (key, value) in seed where UserDefaults.standard.string(forKey: key) == nil {
            UserDefaults.standard.set(value, forKey: key)
        }
    }

    // MARK: 读写

    subscript(_ key: String) -> String {
        values[key] ?? TextStore.defaults[key] ?? ""
    }

    func set(_ key: String, _ value: String) {
        guard !key.isEmpty else { return }
        if values[key] != value {
            values[key] = value
            ud.set(value, forKey: key)
        }
        // 联动：改起止时间就地重算时长（详情 q.* 与表单 f.* 各一套）
        switch key {
        case "q.start", "q.end":
            refreshDuration(prefix: "q")
        case "f.start", "f.end":
            refreshDuration(prefix: "f")
        default:
            break
        }
    }

    private func refreshDuration(prefix: String) {
        guard let mins = TimeFmt.minutes(from: self["\(prefix).start"], to: self["\(prefix).end"]) else { return }
        let text = TimeFmt.durationText(mins)
        let key = "\(prefix).dur"
        if values[key] != text {
            values[key] = text
            ud.set(text, forKey: key)
        }
    }

    // MARK: 派生状态

    /// 是否离校：值为「是 / 否」之类。
    var leavesCampus: Bool {
        let v = self["d.left"].trimmingCharacters(in: .whitespaces)
        if v.hasPrefix("否") || v.hasPrefix("不") { return false }
        let low = v.lowercased()
        if low.hasPrefix("no") || low.hasPrefix("false") || v.hasPrefix("0") { return false }
        return true
    }

    func toggleLeaveType() {
        // 先定好目标值再写，避免第一句改完 d.left 后 leavesCampus 已经变了导致两边不一致
        let next = leavesCampus ? "否" : "是"
        set("d.left", next)
        set("f.left", next)
    }

    func statusColor(for key: String) -> Color {
        StatusTone.color(self[key])
    }

    // MARK: 表单校验

    private static let blankValues: Set<String> = ["", "-", "—", "请选择", "请选择开始时间", "请选择结束时间",
                                                   "请填写", "点击填写", "请输入", "天/时/分", "请上传证明材料"]

    func isFilled(_ key: String) -> Bool {
        let v = self[key].trimmingCharacters(in: .whitespacesAndNewlines)
        if TextStore.blankValues.contains(v) { return false }
        if v.hasPrefix("请填写") || v.hasPrefix("请选择") || v.hasPrefix("点击上传") { return false }
        if v.hasPrefix("请输入") || v.hasPrefix("需要您授权") || v.hasPrefix("请上传") { return false }
        return true
    }

    /// 表单必填项（顺序即提示顺序）
    static let requiredFormKeys = ["f.start", "f.end", "f.course", "f.reason", "f.place"]

    /// 缺失项的红字：安卓版每种字段的提示语不一样（请选择 / 请输入）
    static let requiredHintText: [String: String] = [
        "f.start": "请选择",
        "f.end": "请选择",
        "f.course": "请输入",
        "f.reason": "请输入",
        "f.place": "请选择"
    ]

    func requiredHint(_ key: String) -> String {
        "f.hint." + key
    }

    /// 返回缺失项数量；同时把红字提示写进 `f.hint.<key>`。
    @discardableResult
    func validateForm() -> Int {
        var missing: [String] = []
        for key in TextStore.requiredFormKeys where !isFilled(key) {
            missing.append(key)
        }
        for key in TextStore.requiredFormKeys {
            let text = missing.contains(key) ? (TextStore.requiredHintText[key] ?? self["f.hint"]) : ""
            set(requiredHint(key), text)
        }
        return missing.count
    }

    /// 提交：把表单值写回详情页/列表共用的 q.* 字段，并回到列表。
    func commitForm() {
        set("q.start", self["f.start"])
        set("q.end", self["f.end"])
        set("q.course", self["f.course"])
        set("q.reason", self["f.reason"])
        if isFilled("f.proof") { set("q.proof", self["f.proof"]) }
        set("q.place", self["f.place"])
        set("d.left", self["f.left"])
        if isFilled("f.dest")  { set("d.dest", self["f.dest"]) }
        if isFilled("f.addr")  { set("d.addr", self["f.addr"]) }
        if isFilled("f.emerg") { set("d.emerg", self["f.emerg"]) }
        if isFilled("f.tel")   { set("d.tel", self["f.tel"]) }

        set("hd.status", "审批中")
        set("a.res", "审批中")
        set("q.submit", TimeFmt.stamp() + " 提交")

        let name = self["q.student"].isEmpty ? "王小明" : self["q.student"]
        let kind = self["f.hd.title"].isEmpty ? "其它" : self["f.hd.title"]
        set("hd.name", name + "的" + kind)
    }

    /// 把详情页的当前内容灌进表单，作为「再次发起」的初值。
    func prefillForm() {
        set("f.start", self["q.start"])
        set("f.end", self["q.end"])
        set("f.dur", self["q.dur"])
        set("f.course", self["q.course"])
        set("f.reason", self["q.reason"])
        set("f.proof", self["q.proof"])
        set("f.place", self["q.place"])
        set("f.left", self["d.left"])
        set("f.dest", self["d.dest"])
        set("f.addr", self["d.addr"])
        set("f.emerg", self["d.emerg"])
        set("f.tel", self["d.tel"])
        for key in TextStore.requiredFormKeys {
            set(requiredHint(key), "")
        }
    }

    // MARK: 图片

    func image(for slot: ImageSlot) -> UIImage? {
        switch slot {
        case .avatar: return avatar
        case .proof:  return proof
        }
    }

    func loadImage(_ item: PhotosPickerItem?, slot: ImageSlot) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let small = image.resized(maxDimension: 640)
        await MainActor.run {
            self.store(image: small, slot: slot)
        }
    }

    func store(image: UIImage, slot: ImageSlot) {
        switch slot {
        case .avatar:
            avatar = image
            TextStore.write(image, slot: slot)
        case .proof:
            proof = image
            TextStore.write(image, slot: slot)
        }
    }

    func clearImage(_ slot: ImageSlot) {
        switch slot {
        case .avatar: avatar = nil
        case .proof:  proof = nil
        }
        if let url = TextStore.imageURL(slot) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func imageURL(_ slot: ImageSlot) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(slot.key + ".jpg")
    }

    private static func write(_ image: UIImage, slot: ImageSlot) {
        guard let url = imageURL(slot), let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func loadImage(_ slot: ImageSlot) -> UIImage? {
        guard let url = imageURL(slot), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: 恢复默认

    /// 只把筛选弹层用到的 flt.* 恢复默认，不动用户改过的业务数据。
    func resetFilterFields() {
        for (key, value) in TextStore.defaults where key.hasPrefix("flt.") {
            values[key] = value
            ud.set(value, forKey: key)
        }
    }

    func resetAll() {
        for (key, value) in TextStore.defaults {
            values[key] = value
            ud.set(value, forKey: key)
        }
        clearImage(.avatar)
        clearImage(.proof)
        refreshDuration(prefix: "q")
        refreshDuration(prefix: "f")
    }
}

// MARK: - UIImage 缩放

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - 存相册

enum AlbumWriter {
    enum Failure: LocalizedError {
        case denied

        var errorDescription: String? {
            switch self {
            case .denied: return "没有相册权限，请到「设置 → 隐私 → 照片」里允许写入"
            }
        }
    }

    static func save(_ image: UIImage) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        var granted = status == .authorized || status == .limited

        if status == .notDetermined {
            granted = await withCheckedContinuation { cont in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { new in
                    cont.resume(returning: new == .authorized || new == .limited)
                }
            }
        }
        guard granted else { throw Failure.denied }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

// MARK: - 分享

struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}
