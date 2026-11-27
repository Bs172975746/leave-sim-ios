//
//  EditSheet.swift
//  LeaveSim
//
//  点任意文字弹出的底部编辑浮层，以及它的键盘避让。
//
//  浮层不放在 .sheet 里（sheet 在 iOS 16 上会自己抢键盘、也会把自己压在键盘下面），
//  而是放在根视图的 ZStack 最上层，位置由 KeyboardMonitor 量到的键盘高度直接算，
//  所以它永远压在键盘上方，且不会把下面的页面顶起来。
//

import SwiftUI
import UIKit

// MARK: - 编辑目标

struct EditTarget: Identifiable {
    let id = UUID()
    let key: String
    let initial: String
}

final class EditorCenter: ObservableObject {
    @Published var target: EditTarget?

    func begin(key: String, value: String) {
        target = EditTarget(key: key, initial: value)
    }

    func end() {
        target = nil
    }
}

// MARK: - 环境注入（截图渲染时自动退化成空实现）

private struct EditorCenterKey: EnvironmentKey {
    static let defaultValue = EditorCenter()
}

extension EnvironmentValues {
    var editorCenter: EditorCenter {
        get { self[EditorCenterKey.self] }
        set { self[EditorCenterKey.self] = newValue }
    }
}

// MARK: - 点击改字

struct EditTap: ViewModifier {
    let key: String
    let text: String
    var enabled: Bool = true

    @Environment(\.editorCenter) private var editor

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                guard enabled else { return }
                editor.begin(key: key, value: text)
            }
    }
}

extension View {
    /// 先 `.frame(...)` 再调用，热区就是整个 frame。
    func editTap(_ key: String, _ text: String, enabled: Bool = true) -> some View {
        modifier(EditTap(key: key, text: text, enabled: enabled))
    }
}

// MARK: - 键盘高度

final class KeyboardMonitor: ObservableObject {
    @Published var height: CGFloat = 0

    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        let screenHeight = UIScreen.main.bounds.height

        observers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
                                           object: nil,
                                           queue: .main) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let end = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let overlap = max(0, screenHeight - end.minY)
            self.height = overlap < 1 ? 0 : overlap
        })

        observers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                           object: nil,
                                           queue: .main) { [weak self] _ in
            self?.height = 0
        })
    }

    deinit {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
    }
}

// MARK: - 浮层本体

struct EditPanel: View {
    let target: EditTarget
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    @State private var draft: String
    @FocusState private var focused: Bool

    init(target: EditTarget,
         onCommit: @escaping (String) -> Void,
         onCancel: @escaping () -> Void) {
        self.target = target
        self.onCommit = onCommit
        self.onCancel = onCancel
        _draft = State(initialValue: target.initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("修改文字")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            TextField("", text: $draft, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2...6)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
                .background(Palette.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                Button {
                    focused = false
                    onCancel()
                } label: {
                    Text("取消")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.textValue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Palette.fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    focused = false
                    onCommit(draft)
                } label: {
                    Text("确定")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Palette.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Palette.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 14)
        .onAppear {
            // 浮层进场动画和键盘同时触发时焦点会被吞掉，等一帧再要焦点。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                focused = true
            }
        }
    }
}
