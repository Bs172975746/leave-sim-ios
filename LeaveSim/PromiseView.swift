//
//  PromiseView.swift
//  LeaveSim
//
//  ③请假安全承诺书：纯白底、正文 15pt / 行距 2 / 段间距 18、
//  左右留白 40、首行缩进两个字（全角空格），底部勾选行 + 不同意 / 同意并继续。
//  数值对齐 screen_promise.xml。
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
            NavHeader(store: store,
                      titleKey: "nav.promise",
                      showsBack: true,
                      onBack: { dismiss() })

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            ScrollView(showsIndicators: false) {
                PromiseBody(store: store, agreed: $agreed, interactive: true)
            }

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            PromiseBottomBar(store: store,
                             agreed: $agreed,
                             interactive: true,
                             onDecline: { dismiss() },
                             onAgree: { path = [.form] })
        }
        .background(Palette.white)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .shotExport(exporter, capture: {
            Shot.render(CapturePromise(store: store, agreed: agreed))
        })
    }
}

// MARK: - 正文

struct PromiseBody: View {
    @ObservedObject var store: TextStore
    @Binding var agreed: Bool
    var interactive: Bool = true

    private let paragraphs = ["pr.1", "pr.2", "pr.3", "pr.4"]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.promiseParaGap) {
            ForEach(paragraphs, id: \.self) { key in
                Text("　　" + store[key])
                    .font(Typo.body)
                    .foregroundStyle(Palette.textValue)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .editTap(key, store[key], enabled: interactive)
            }
        }
        .padding(.horizontal, Metrics.promisePad)
        .padding(.top, Metrics.promiseTop)
        .padding(.bottom, Metrics.promisePadBottom)
    }
}

// MARK: - 底部勾选 + 两个按钮

struct PromiseBottomBar: View {
    @ObservedObject var store: TextStore
    @Binding var agreed: Bool
    var interactive: Bool = true
    var onDecline: () -> Void = {}
    var onAgree: () -> Void = {}

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                CheckMark(on: agreed)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        agreed.toggle()
                    }

                EditableText(text: store["pr.check"],
                             font: Typo.agree,
                             color: Palette.textPrimary,
                             lineSpacing: 3)
                    .padding(.leading, Metrics.checkGap)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap("pr.check", store["pr.check"], enabled: interactive)
            }
            .padding(.horizontal, Metrics.promisePad)
            .padding(.top, Metrics.promiseCheckTop)
            .padding(.bottom, Metrics.promiseCheckBottom)

            HStack(spacing: 0) {
                Text(store["pr.no"])
                    .font(Typo.sheetButton)
                    .foregroundStyle(Palette.textPrimary)
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
                        if interactive { onDecline() }
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: "pr.no", value: store["pr.no"])
                    }

                Text(store["pr.yes"])
                    .font(Typo.sheetButton)
                    .foregroundStyle(Palette.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.bigButton)
                    .background(
                        RoundedRectangle(cornerRadius: Metrics.smallRadius, style: .continuous)
                            .fill(agreed ? Palette.blue : Palette.disabled)
                    )
                    .contentShape(Rectangle())
                    .padding(.leading, Metrics.fwdGap)
                    .onTapGesture {
                        guard interactive else { return }
                        if agreed { onAgree() }
                    }
                    .onLongPressGesture(minimumDuration: 0.45) {
                        guard interactive else { return }
                        editor.begin(key: "pr.yes", value: store["pr.yes"])
                    }
            }
            .padding(.horizontal, Metrics.promisePad)
            .padding(.top, Metrics.promiseButtonTop)
            .padding(.bottom, Metrics.promiseButtonBottom)
        }
        .background(Palette.white)
    }
}

// MARK: - 截图用静态版

struct CapturePromise: View {
    @ObservedObject var store: TextStore
    var agreed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(store: store, titleKey: "nav.promise", showsBack: true)
            Rectangle().fill(Palette.divider).frame(height: 1)
            ScrollView(showsIndicators: false) {
                PromiseBody(store: store, agreed: .constant(agreed), interactive: false)
            }
            Rectangle().fill(Palette.divider).frame(height: 1)
            PromiseBottomBar(store: store, agreed: .constant(agreed), interactive: false)
        }
        .background(Palette.white)
        .frame(width: Metrics.captureWidth)
    }
}
