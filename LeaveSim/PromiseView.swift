//
//  PromiseView.swift
//  LeaveSim
//
//  ③请假安全承诺书：四段正文 + 勾选框 + 不同意 / 同意并继续。
//  勾选前「同意并继续」是灰色禁用态；勾上才变蓝，点了才进 ④申请表。
//  流程：列表「发起」卡 → 本页 → 申请表 → 提交 → 回列表。
//

import SwiftUI

struct PromiseView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @State private var agreed = false
    @StateObject private var exporter = ShotExporter()

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.promise",
                      title: store["nav.promise"],
                      showsBack: true,
                      onBack: { dismiss() },
                      trailing: [.symbol("camera")],
                      onTrailingTap: { _ in exporter.asking = true })

            ScrollView(showsIndicators: false) {
                PromiseBody(store: store, agreed: $agreed, interactive: true)
            }

            PromiseBottomBar(store: store,
                             agreed: agreed,
                             interactive: true,
                             onDecline: { dismiss() },
                             onAgree: {
                                 // 进申请表：把导航栈换成 [.form]，返回键直接回列表
                                 path = [.form]
                             })
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .shotExport(exporter, capture: {
            Shot.render(CapturePromise(store: store, agreed: agreed))
        })
    }
}

// MARK: - 主体

struct PromiseBody: View {
    @ObservedObject var store: TextStore
    @Binding var agreed: Bool
    var interactive: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EditableText(text: store["pr.t"],
                         font: Typo.sectionTitle,
                         color: Palette.textPrimary,
                         alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
                .editTap("pr.t", store["pr.t"], enabled: interactive)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 14) {
                paragraph("pr.1")
                paragraph("pr.2")
                paragraph("pr.3")
                paragraph("pr.4")
            }

            Divider().overlay(Palette.divider).padding(.vertical, 18)

            checkRow
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 13)
        .padding(.bottom, 24)
    }

    private func paragraph(_ key: String) -> some View {
        EditableText(text: store[key],
                     font: .system(size: 13),
                     color: Palette.textValue,
                     lineSpacing: 6)
            .editTap(key, store[key], enabled: interactive)
    }

    private var checkRow: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(agreed ? Palette.blue : Color.clear)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(agreed ? Palette.blue : Palette.ghostBorder, lineWidth: 1)
                if agreed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 20, height: 20)

            EditableText(text: store["pr.check"],
                         font: .system(size: 13),
                         color: Palette.textValue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("pr.check", store["pr.check"], enabled: interactive)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive {
                withAnimation(.easeInOut(duration: 0.12)) { agreed.toggle() }
            }
        }
    }
}

// MARK: - 底部两个按钮

struct PromiseBottomBar: View {
    @ObservedObject var store: TextStore
    var agreed: Bool = false
    var interactive: Bool = true
    var onDecline: () -> Void = {}
    var onAgree: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 0.5)
            HStack(spacing: 12) {
                Text(store["pr.no"])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.textValue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Palette.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Palette.ghostBorder, lineWidth: 1))
                    .contentShape(Capsule())
                    .onTapGesture {
                        if interactive { onDecline() }
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: "pr.no", value: store["pr.no"])
                    }

                Text(store["pr.yes"])
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(agreed ? Palette.blue : Palette.disabled)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .onTapGesture {
                        guard interactive, agreed else { return }
                        onAgree()
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: "pr.yes", value: store["pr.yes"])
                    }
            }
            .padding(.horizontal, Metrics.cardMargin)
            .padding(.vertical, 12)
        }
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CapturePromise: View {
    @ObservedObject var store: TextStore
    var agreed: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.promise", title: store["nav.promise"], showsBack: true)
            ScrollView(showsIndicators: false) {
                PromiseBody(store: store, agreed: .constant(agreed), interactive: false)
            }
            PromiseBottomBar(store: store, agreed: agreed, interactive: false)
        }
        .background(Palette.pageBg)
        .frame(width: Metrics.captureWidth)
    }
}
