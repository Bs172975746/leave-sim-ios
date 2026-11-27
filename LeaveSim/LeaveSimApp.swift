//
//  LeaveSimApp.swift
//  LeaveSim
//
//  入口 + 全局编辑浮层。
//
//  为什么浮层不用 .sheet：
//  sheet 会用系统自己的键盘避让逻辑，一弹键盘就把面板顶走或把输入框压到键盘下面，
//  而且 sheet 再弹 sheet（相册 / 分享）会互相打架。这里改成在根 ZStack 里自己画：
//  根 ZStack 加 .ignoresSafeArea(.keyboard) 让键盘完全不参与布局，
//  KeyboardMonitor 监听 keyboardWillChangeFrame 量出键盘占掉的高度，
//  再把面板 .padding(.bottom, 键盘高度 + 12) 顶上去 —— 面板始终浮在键盘上方。
//

import SwiftUI

@main
struct LeaveSimApp: App {
    @StateObject private var store = TextStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)   // 深色模式不影响截图
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: TextStore

    @StateObject private var editor = EditorCenter()
    @StateObject private var keyboard = KeyboardMonitor()
    @State private var path: [AppRoute] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $path) {
                HomeView(path: $path)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .detail:
                            DetailView()
                        case .form:
                            FormView(path: $path)
                        case .records:
                            RecordsView(path: $path)
                        case .promise:
                            PromiseView(path: $path)
                        }
                    }
            }
            .environment(\.editorCenter, editor)
            .zIndex(0)

            if let target = editor.target {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { editor.end() }
                    .zIndex(1)
                    .transition(.opacity)

                EditPanel(target: target,
                          onCommit: { text in
                              store.set(target.key, text)
                              editor.end()
                          },
                          onCancel: { editor.end() })
                    .padding(.bottom, editorBottomPadding)
                    .zIndex(2)
                    .transition(.move(edge: .bottom))
            }
        }
        .background(Palette.pageBg)
        // 关键：整个根视图不参与键盘避让，键盘高度由 KeyboardMonitor 手动算。
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeOut(duration: 0.22), value: editor.target?.id)
        .animation(.easeOut(duration: 0.22), value: keyboard.height)
    }

    private var editorBottomPadding: CGFloat {
        keyboard.height > 0 ? keyboard.height + 12 : 26
    }
}
