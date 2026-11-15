import SwiftUI

/// 计算器式键盘发出的按键
enum KeypadKey: Hashable {
    case digit(String)
    case backspace
    case clear
    case sign
}

/// 内置键盘：只显示当前进制合法的按键，不需要系统键盘
struct Keypad: View {

    let base: Int
    let onKey: (KeypadKey) -> Void

    /// 当前进制下可用的字母键（A 开始，最多 26 个）
    private var letters: [String] {
        guard base > 10 else { return [] }
        let all = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let count = min(26, base - 10)
        return all.prefix(count).map { String($0) }
    }

    private var letterColumns: Int {
        if letters.count <= 6 { return 6 }
        if letters.count <= 12 { return 6 }
        return 9
    }

    var body: some View {
        VStack(spacing: 5) {
            if !letters.isEmpty {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: letterColumns),
                    spacing: 5
                ) {
                    ForEach(letters, id: \.self) { letter in
                        letterKey(letter)
                    }
                }
            }

            HStack(spacing: 5) {
                digitKey("7")
                digitKey("8")
                digitKey("9")
                functionKey("⌫", .backspace)
            }

            HStack(spacing: 5) {
                digitKey("4")
                digitKey("5")
                digitKey("6")
                functionKey("C", .clear)
            }

            HStack(spacing: 5) {
                digitKey("1")
                digitKey("2")
                digitKey("3")
                functionKey("±", .sign)
            }

            HStack(spacing: 5) {
                digitKey("0")
            }
        }
    }

    // MARK: - 按键

    private func digitKey(_ digit: String) -> some View {
        let value = Int(digit) ?? 99
        let enabled = value < base
        return Button {
            onKey(.digit(digit))
        } label: {
            Text(digit)
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundStyle(enabled ? Color.white : Color.white.opacity(0.16))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(white: enabled ? 0.145 : 0.07))
                )
        }
        .buttonStyle(KeypadButtonStyle())
        .disabled(!enabled)
    }

    private func letterKey(_ letter: String) -> some View {
        Button {
            onKey(.digit(letter))
        } label: {
            Text(letter)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(white: 0.145))
                )
        }
        .buttonStyle(KeypadButtonStyle())
    }

    private func functionKey(_ title: String, _ key: KeypadKey) -> some View {
        Button {
            onKey(key)
        } label: {
            Text(title)
                .font(.system(size: title == "⌫" ? 17 : 16, weight: .medium))
                .foregroundStyle(Theme.dim)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(white: 0.185))
                )
        }
        .buttonStyle(KeypadButtonStyle())
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
