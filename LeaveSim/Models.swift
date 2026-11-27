//
//  Models.swift
//  LeaveSim
//
//  全部可编辑文字 + 持久化 + 相册写入。
//  文本键名沿用 Android 版的 tag（tag 形如 "t:q.student"，这里直接用 "q.student"），
//  所以 Android 版改过的键在 iOS 版里语义一致。
//
//  所有姓名 / 手机号 / 地址 / 学校均为虚构占位数据（王小明、示例大学、示例省示例市…），
//  与任何真实个人无关。
//

import SwiftUI
import UIKit
import PhotosUI
import Photos

// MARK: - 路由 / Tab / 图片槽

enum AppRoute: Hashable {
    case detail      // 请假详情
    case form        // 请假申请表单
    case records     // 请假记录
    case promise     // 请假安全承诺书
}

enum DetailTab: Hashable {
    case leave      // 请假
    case extend     // 续假
}

enum HomeTab: Hashable {
    case apply      // 我要请假
    case records    // 请假记录
}

enum ImageSlot: String {
    case avatar = "img.avatar"
    case proof  = "img.proof"
}

// MARK: - 文字仓库

final class TextStore: ObservableObject {

    /// 所有可编辑字段（键, 默认值）。顺序无关，仅用于建表与恢复默认。
    static let fields: [(key: String, value: String)] = [
        // 首页
        ("nav.home",          "请假"),
        ("list.sec.active",   "进行中"),
        ("list.title",        "王小明的其它"),
        ("list.status",       "即将休假"),
        ("l.l.start",         "开始时间"),
        ("l.l.end",           "结束时间"),
        ("l.l.reason",        "请假原因"),
        ("list.start",        "2026-11-16 08:40"),
        ("list.end",          "2026-11-16 10:00"),
        ("list.reason",       "身体不舒服………"),
        ("list.owner",        "王小明"),
        ("list.time",         "2026-11-16 08:02"),
        ("list.more",         "更多"),
        ("list.revoke",       "撤销请假申请"),
        ("list.sec.create",   "发起"),
        ("list.type.other",   "其它"),
        ("list.type.sj",      "事假"),
        ("list.type.bj",      "病假"),
        ("list.footer",       "没有更多数据了~"),
        ("tab.apply",         "我要请假"),
        ("tab.record",        "请假记录"),

        // 详情页 · 导航 / Tab / 顶部卡
        ("nav.title",         "请假详情"),
        ("tab.qj",            "请假"),
        ("tab.xj",            "续假"),
        ("hd.rule",           "请假规则"),
        ("hd.name",           "王小明的其它"),
        ("hd.status",         "已通过"),

        // 详情页 · 请假内容
        ("sec.info",          "请假内容"),
        ("l.q.student",       "请假学生"),
        ("q.student",         "王小明"),
        ("l.q.start",         "开始时间"),
        ("q.start",           "2026-09-23 07:01"),
        ("l.q.end",           "结束时间"),
        ("q.end",             "2026-09-24 21:00"),
        ("l.q.dur",           "请假时长"),
        ("q.dur",             "1天13时59分"),
        ("l.q.course",        "影响课程"),
        ("q.course",          "无"),
        ("l.q.reason",        "请假原因"),
        ("q.reason",          "返乡回家，已购买23号的车票"),
        ("l.q.proof",         "证明材料"),
        ("q.proof",           "-"),
        ("l.q.place",         "发起位置"),
        ("q.place",           "示例省示例市示例区示例路88号"),

        // 详情页 · 请假去向
        ("sec.dest",          "请假去向"),
        ("l.d.left",          "是否离校"),
        ("d.left",            "是"),
        ("l.d.dest",          "目的地"),
        ("d.dest",            "示例省/示例市/示例区"),
        ("l.d.addr",          "详细地址"),
        ("d.addr",            "示例小区3号楼"),
        ("l.d.emerg",         "紧急联系人"),
        ("d.emerg",           "13800001234"),
        ("l.d.tel",           "联系电话"),
        ("d.tel",             "13900005678"),

        // 详情页 · 审批流程
        ("sec.approval",      "审批流程"),
        ("l.a.who",           "审批人"),
        ("a.who",             "辅导员 李老师"),
        ("l.a.res",           "审批结果"),
        ("a.res",             "已通过"),
        ("l.a.time",          "审批时间"),
        ("a.time",            "2026-09-23 08:15"),
        ("l.a.note",          "审批意见"),
        ("a.note",            "同意，返校后及时找辅导员销假"),

        // 详情页 · 续假内容
        ("sec.xj",            "续假内容"),
        ("l.x.student",       "续假学生"),
        ("x.student",         "王小明"),
        ("l.x.start",         "开始时间"),
        ("x.start",           "2026-09-24 21:00"),
        ("l.x.end",           "结束时间"),
        ("x.end",             "2026-09-26 21:00"),
        ("l.x.dur",           "续假时长"),
        ("x.dur",             "2天"),
        ("l.x.course",        "影响课程"),
        ("x.course",          "无"),
        ("l.x.reason",        "续假原因"),
        ("x.reason",          "车票改签，推迟返校"),
        ("l.x.proof",         "证明材料"),
        ("x.proof",           "-"),
        ("l.x.place",         "发起位置"),
        ("x.place",           "示例省示例市示例区示例路88号"),

        // 详情页 · 底栏
        ("bottom.more",       "更多"),
        ("bottom.fwd",        "转发"),

        // 请假申请表单页
        ("nav.form",          "请假"),
        ("f.hd.title",        "其它"),
        ("l.f.start",         "开始时间"),
        ("f.start",           "请选择"),
        ("l.f.end",           "结束时间"),
        ("f.end",             "请选择"),
        ("l.f.dur",           "请假时长"),
        ("f.dur.d",           "0"),
        ("f.dur.h",           "0"),
        ("f.dur.m",           "0"),
        ("f.unit.d",          "天"),
        ("f.unit.h",          "时"),
        ("f.unit.m",          "分"),
        ("l.f.course",        "影响课程"),
        ("f.course",          "无"),
        ("l.f.reason",        "请假原因"),
        ("f.reason",          ""),
        ("f.reason.ph",       "请输入"),
        ("l.f.proof",         "证明材料"),
        ("f.proof.count",     "0/4"),
        ("f.proof.hint",      "请上传证明材料"),
        ("l.f.place",         "发起位置"),
        ("f.place",           "示例省示例市示例区示例路88号"),
        ("f.relocate",        "重新定位"),
        ("l.f.left",          "是否离校"),
        ("f.left",            "请选择"),
        ("sec.cc",            "抄送人"),
        ("f.cc.title",        "常用抄送人（可点击下方标签选中人员）"),
        ("f.cc.edit",         "编辑"),
        ("f.cc.empty",        "暂无数据，请点击编辑进行设置"),
        ("f.cc.a",            "王老师"),
        ("f.cc.b",            "李老师"),
        ("f.cc.c",            "赵老师"),
        ("f.submit",          "提交"),

        // 请假记录页
        ("nav.record",        "请假"),
        ("rec.tip",           "当前学期累计完成请假5次，共计时长1天21时59分"),
        ("rec.sec",           "已完成"),
        ("rec.status",        "已完成"),
        ("rec1.title",        "王小明的其它"),
        ("rec1.start",        "2026-11-13 08:40"),
        ("rec1.end",          "2026-11-13 17:00"),
        ("rec1.reason",       "回家处理个人事务"),
        ("rec1.owner",        "王小明"),
        ("rec1.at",           "2026-11-13 08:02"),
        ("rec2.title",        "王小明的病假"),
        ("rec2.start",        "2026-10-20 08:30"),
        ("rec2.end",          "2026-10-21 18:00"),
        ("rec2.reason",       "感冒发烧，需要休息"),
        ("rec2.owner",        "王小明"),
        ("rec2.at",           "2026-10-20 08:05"),
        ("rec3.title",        "王小明的事假"),
        ("rec3.start",        "2026-09-30 14:00"),
        ("rec3.end",          "2026-09-30 18:00"),
        ("rec3.reason",       "参加校招宣讲会"),
        ("rec3.owner",        "王小明"),
        ("rec3.at",           "2026-09-30 09:12"),

        // 筛选弹层
        ("flt.title",         "筛选"),
        ("flt.type",          "请假类型"),
        ("flt.type.value",    "全部类型"),
        ("flt.start",         "发起时间"),
        ("flt.date.a",        "请选择日期"),
        ("flt.date.b",        "请选择日期"),
        ("flt.leave",         "请假时间"),
        ("flt.date.c",        "请选择日期"),
        ("flt.date.d",        "请选择日期"),
        ("flt.dur",           "请假时长"),
        ("flt.dur.a",         "请选择时长"),
        ("flt.dur.b",         "请选择时长"),
        ("flt.status",        "请假单状态"),
        ("flt.s1",            "全部"),
        ("flt.s2",            "审批中"),
        ("flt.s3",            "即将休假"),
        ("flt.s4",            "休假中"),
        ("flt.s5",            "销假逾期"),
        ("flt.s6",            "已撤销"),
        ("flt.s7",            "已驳回"),
        ("flt.s8",            "已完成"),
        ("flt.reset",         "重置"),
        ("flt.ok",            "确定"),

        // 请假安全承诺书
        ("nav.promise",       "请假安全承诺书"),
        ("pr.t",              "本人知晓学校关于学生请假管理的相关规定，并自愿作出如下承诺："),
        ("pr.1",              "一、请假期间严格遵守国家法律法规和学校各项规章制度，不参与任何违法违规活动，注意人身与财产安全。"),
        ("pr.2",              "二、已如实填写请假理由、去向及联系方式，保证信息真实有效；请假期间保持通讯畅通，随时接受学校、学院的核查。"),
        ("pr.3",              "三、如有弄虚作假、擅自更改去向或逾期不归，本人自愿承担由此产生的一切后果，并接受学校依据《示例大学学生管理规定》作出的处理。"),
        ("pr.4",              "四、保证在请假期满后按时返校销假；确需延长的，提前在系统中提交续假申请，未经批准不擅自延期。"),
        ("pr.check",          "本人已阅读知晓以上《请假安全承诺书》的所有内容，并同意上述承诺。"),
        ("pr.no",             "不同意"),
        ("pr.yes",            "同意并继续")
    ]

    static let defaults: [String: String] =
        Dictionary(uniqueKeysWithValues: fields.map { ($0.key, $0.value) })

    @Published private(set) var values: [String: String] = [:]
    @Published private(set) var avatar: UIImage?
    @Published private(set) var proof: UIImage?

    private let ud = UserDefaults.standard

    init() {
        var loaded = Self.defaults
        for (key, _) in Self.fields {
            if let saved = ud.string(forKey: key) {
                loaded[key] = saved
            }
        }
        values = loaded

        if let data = ud.data(forKey: ImageSlot.avatar.rawValue) {
            avatar = UIImage(data: data)
        }
        if let data = ud.data(forKey: ImageSlot.proof.rawValue) {
            proof = UIImage(data: data)
        }
    }

    subscript(_ key: String) -> String {
        values[key] ?? Self.defaults[key] ?? ""
    }

    func set(_ key: String, _ value: String) {
        values[key] = value
        ud.set(value, forKey: key)
    }

    var isOffCampus: Bool {
        let v = self["d.left"].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if v.isEmpty { return false }
        return v.hasPrefix("否") || v.hasPrefix("不") || v.hasPrefix("no")
            || v.hasPrefix("false") || v.hasPrefix("0")
    }

    func toggleLeaveType() {
        set("d.left", isOffCampus ? "是" : "否")
    }

    func resetAll() {
        for (key, _) in Self.fields {
            ud.removeObject(forKey: key)
        }
        ud.removeObject(forKey: ImageSlot.avatar.rawValue)
        ud.removeObject(forKey: ImageSlot.proof.rawValue)
        values = Self.defaults
        avatar = nil
        proof = nil
    }

    // MARK: 图片

    @MainActor
    func loadImage(_ item: PhotosPickerItem?, slot: ImageSlot) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let small = image.resized(maxDimension: 320)
        guard let jpeg = small.jpegData(compressionQuality: 0.9) else { return }
        ud.set(jpeg, forKey: slot.rawValue)
        let decoded = UIImage(data: jpeg)
        switch slot {
        case .avatar: avatar = decoded
        case .proof:  proof = decoded
        }
    }

    func clearImage(_ slot: ImageSlot) {
        ud.removeObject(forKey: slot.rawValue)
        switch slot {
        case .avatar: avatar = nil
        case .proof:  proof = nil
        }
    }
}

// MARK: - 图片缩放

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let ratio = maxDimension / longest
        let target = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - 相册写入

enum AlbumWriter {
    static func save(_ image: UIImage) async throws {
        let status = await requestAddOnly()
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "LeaveSim", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "没有相册写入权限，去「设置 → 隐私 → 照片」打开"])
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "LeaveSim", code: -2,
                                                                  userInfo: [NSLocalizedDescriptionKey: "保存失败"]))
                }
            }
        }
    }

    private static func requestAddOnly() async -> PHAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: - 分享负载

struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}
