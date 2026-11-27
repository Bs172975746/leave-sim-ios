//
//  PromiseView.swift
//  LeaveSim
//
//  请假安全承诺书页：四段承诺正文 + 勾选框 + 「不同意 / 同意并继续」。
//

import SwiftUI

struct PromiseView: View {
    @EnvironmentObject private var store: TextStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]

    @State private var agreed = false
    @StateObject private var exporter = ShotExporter()

    init(path: Binding<[AppRoute]>) {
        _path = path
    }

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.promise",
                      title: store["nav.promise"],
                      showsBack: true,
                      onBack: { dismiss() },
                      trailingIcons: ["camera"],
                      onTrailingTap: { _ in exporter.asking = true })

            ScrollView(showsIndicators: false) {
                PromiseBody(store: store,
                            interactive: true,
                            agreed: $agreed)
            }

            bottomBar
        }
        .background(Palette.pageBg)
        .toolbar(.hidden, for: .navigationBar)
        .shotExport(exporter, capture: { Shot.render(CapturePromise(store: store, agreed: agreed)) })
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text(store["pr.no"])
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
                    path.removeAll()
                } label: {
                    Text(store["pr.yes"])
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Palette.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!agreed)
                .opacity(agreed ? 1 : 0.4)
            }
            .padding(.horizontal, Metrics.cardMargin)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(Palette.white.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - 正文

struct PromiseBody: View {
    @ObservedObject var store: TextStore
    var interactive: Bool = true
    @Binding var agreed: Bool

    @Environment(\.editorCenter) private var editor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EditableText(text: store["pr.t"],
                         font: .system(size: 14, weight: .semibold),
                         color: Palette.textPrimary,
                         lineSpacing: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("pr.t", store["pr.t"], enabled: interactive)
                .padding(.bottom, 14)

            ForEach(["pr.1", "pr.2", "pr.3", "pr.4"], id: \.self) { key in
                EditableText(text: store[key],
                             font: .system(size: 13),
                             color: Palette.textValue,
                             lineSpacing: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editTap(key, store[key], enabled: interactive)
                    .padding(.bottom, 12)
            }

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
                .padding(.vertical, 12)

            checkRow
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .padding(.horizontal, Metrics.cardMargin)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var checkRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                guard interactive else { return }
                agreed.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(agreed ? Palette.blue : Palette.white)
                    Circle()
                        .stroke(agreed ? Palette.blue : Palette.ghostBorder, lineWidth: 1)
                    if agreed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            EditableText(text: store["pr.check"],
                         font: .system(size: 13),
                         color: Palette.textValue,
                         lineSpacing: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editTap("pr.check", store["pr.check"], enabled: interactive)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            agreed.toggle()
        }
    }
}

// MARK: - 承诺书截图

struct CapturePromise: View {
    @ObservedObject var store: TextStore
    var agreed: Bool

    var body: some View {
        VStack(spacing: 0) {
            NavHeader(titleKey: "nav.promise", title: store["nav.promise"], showsBack: true)
            PromiseBody(store: store, interactive: false, agreed: .constant(agreed))
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                Text(store["pr.no"])
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textValue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Palette.ghostBorder, lineWidth: 1)
                    )
                Text(store["pr.yes"])
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(agreed ? Palette.blue : Palette.textLabel)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, Metrics.cardMargin)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(Palette.white)
        }
        .background(Palette.pageBg)
    }
}
