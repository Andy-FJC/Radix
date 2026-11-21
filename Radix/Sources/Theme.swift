import SwiftUI
import UIKit

enum Theme {
    static let bg          = Color(red: 0.039, green: 0.039, blue: 0.047)
    static let card        = Color(red: 0.082, green: 0.082, blue: 0.098)
    static let card2       = Color(red: 0.11,  green: 0.11,  blue: 0.13)
    static let line        = Color.white.opacity(0.07)
    static let dim         = Color(red: 0.55,  green: 0.55,  blue: 0.58)
    static let dim2        = Color(red: 0.50,  green: 0.50,  blue: 0.53)
    static let value       = Color(red: 0.91,  green: 0.91,  blue: 0.93)
    static let placeholder = Color(red: 0.23,  green: 0.23,  blue: 0.26)
    static let green       = Color(red: 0.302, green: 0.878, blue: 0.478)
    static let purple      = Color(red: 0.820, green: 0.541, blue: 1.000)
    static let blue        = Color(red: 0.478, green: 0.722, blue: 1.000)
    static let cyan        = Color(red: 0.373, green: 0.847, blue: 0.925)
    static let orange      = Color(red: 1.000, green: 0.702, blue: 0.251)

    static let blueBg   = Color(red: 0.039, green: 0.518, blue: 1.000).opacity(0.13)
    static let cyanBg   = Color(red: 0.251, green: 0.784, blue: 0.878).opacity(0.12)
    static let greenBg  = Color(red: 0.188, green: 0.820, blue: 0.345).opacity(0.12)
    static let orangeBg = Color(red: 1.000, green: 0.624, blue: 0.039).opacity(0.12)
    static let purpleBg = Color(red: 0.749, green: 0.353, blue: 0.949).opacity(0.12)
}

/// 复制到剪贴板并给出触感反馈
func copyText(_ text: String) {
    UIPasteboard.general.string = text
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

/// 分区标题
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Theme.dim2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 细分隔线
struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
    }
}

/// 轻提示气泡
struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color(white: 0.16)))
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            .transition(.opacity)
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
