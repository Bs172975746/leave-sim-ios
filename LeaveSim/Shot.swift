//
//  Shot.swift
//  LeaveSim
//
//  整页截图导出：ImageRenderer 渲染「静态版」页面 → 存相册 / 分享。
//  iOS 16 的 ImageRenderer 只能在主线程用，所以所有入口都是 @MainActor。
//

import SwiftUI
import UIKit

@MainActor
enum Shot {
    /// 把任意视图按 393pt 宽渲染成 3 倍图。
    static func render<V: View>(_ content: V, width: CGFloat = Metrics.captureWidth) -> UIImage? {
        let renderer = ImageRenderer(content: content.frame(width: width,
                                                            height: Metrics.captureHeight))
        renderer.scale = Metrics.captureScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// 每个页面各自持有一个，负责「导出弹窗 → 渲染 → 存相册 / 分享」的公共流程。
final class ShotExporter: ObservableObject {
    @Published var asking = false
    @Published var busy = false
    @Published var toast: String?
    @Published var share: SharePayload?

    @MainActor
    func export(_ image: UIImage?, share shouldShare: Bool) {
        guard let image else {
            flash("渲染失败，换一台真机再试")
            return
        }
        if shouldShare {
            busy = false
            share = SharePayload(image: image)
        } else {
            busy = true
            Task {
                do {
                    try await AlbumWriter.save(image)
                    busy = false
                    flash("已保存到相册")
                } catch {
                    busy = false
                    flash(error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    func flash(_ text: String) {
        withAnimation(.easeInOut(duration: 0.15)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.2)) { self.toast = nil }
        }
    }
}

struct ShotExportChain: ViewModifier {
    @ObservedObject var exporter: ShotExporter
    let capture: @MainActor () -> UIImage?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("导出这张截图", isPresented: $exporter.asking, titleVisibility: .visible) {
                Button("保存到相册") { exporter.export(capture(), share: false) }
                Button("分享截图") { exporter.export(capture(), share: true) }
                Button("取消", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if let toast = exporter.toast {
                    Text(toast)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.78))
                        .clipShape(Capsule())
                        .padding(.bottom, 96)
                }
            }
            .overlay {
                if exporter.busy {
                    ZStack {
                        Color.black.opacity(0.18).ignoresSafeArea()
                        ProgressView()
                            .padding(20)
                            .background(Palette.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .sheet(item: $exporter.share) { payload in
                ShareSheet(items: [payload.image])
            }
    }
}

extension View {
    /// `capture` 返回渲染好的图；调用方把静态版视图交给 `Shot.render` 即可。
    func shotExport(_ exporter: ShotExporter,
                    capture: @escaping @MainActor () -> UIImage?) -> some View {
        modifier(ShotExportChain(exporter: exporter, capture: capture))
    }
}
