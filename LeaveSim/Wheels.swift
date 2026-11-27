//
//  Wheels.swift
//  LeaveSim
//
//  底部「选择日期 / 选择时间」滚轮。日期选完点「下一步」再选时间，
//  时间选完点「确定」把 "yyyy-MM-dd HH:mm" 写回字段。
//

import SwiftUI
import UIKit

enum WheelData {
    static let years   = ["2024", "2025", "2026", "2027", "2028", "2029", "2030"]
    static let months  = (1...12).map { String(format: "%02d", $0) }
    static let days    = (1...31).map { String(format: "%02d", $0) }
    static let hours   = (0...23).map { String(format: "%02d", $0) }
    static let minutes = (0...59).map { String(format: "%02d", $0) }
}

struct TopRoundedShape: Shape {
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct WheelPanel: View {
    let state: WheelState
    @Binding var dateIndexes: [Int]
    @Binding var timeIndexes: [Int]
    let onCancel: () -> Void
    let onNext: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        onCancel()
                    } label: {
                        Text("取消")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.textValue)
                            .frame(height: 48)
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    Text("请选择")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer(minLength: 0)

                    Button {
                        onNext()
                    } label: {
                        Text(state.isDate ? "下一步" : "确定")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.blue)
                            .frame(height: 48)
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)

                Rectangle()
                    .fill(Palette.divider)
                    .frame(height: 1)

                if state.isDate {
                    HStack(spacing: 0) {
                        wheel(WheelData.years,   $dateIndexes[0])
                        wheel(WheelData.months,  $dateIndexes[1])
                        wheel(WheelData.days,    $dateIndexes[2])
                    }
                } else {
                    HStack(spacing: 0) {
                        wheel(WheelData.hours,   $timeIndexes[0])
                        wheel(WheelData.minutes, $timeIndexes[1])
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Palette.white)
            .clipShape(TopRoundedShape(radius: 16))
            .ignoresSafeArea(edges: .bottom)
            .transition(.move(edge: .bottom))
        }
    }

    private func wheel(_ data: [String], _ selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(0..<data.count, id: \.self) { index in
                Text(data[index])
                    .font(.system(size: 16))
                    .tag(index)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipped()
    }
}
