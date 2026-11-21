import SwiftUI

struct ConvertView: View {
    @State private var rawInput = ""
    @State private var inBase = 10
    @State private var toast: String?

    private var value: BigInt? {
        guard !rawInput.isEmpty else { return nil }
        return BigInt.parse(rawInput, radix: inBase)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    basePicker

                    inputCard

                    SectionTitle(text: "2 – 36 进制对照（点任意行复制）")

                    resultList
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }

            if let toast = toast {
                VStack {
                    Spacer()
                    ToastView(text: toast)
                        .padding(.bottom, 30)
                }
                .allowsHitTesting(false)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("进制转换")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("RADIX CONVERTER")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.dim2)
            Spacer()
        }
    }

    private var basePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "输入进制（全部列出）")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                spacing: 6
            ) {
                ForEach(2...36, id: \.self) { b in
                    Button {
                        inBase = b
                        rawInput = ""
                    } label: {
                        Text("\(b)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(b == inBase ? .white : Theme.dim)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(b == inBase ? Theme.green.opacity(0.22) : Color(white: 0.10))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(b == inBase ? Theme.green : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("当前：\(RadixLabel.full(inBase))")
                .font(.system(size: 11))
                .foregroundStyle(Theme.dim2)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("输入")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                Spacer()
                Text(RadixLabel.letter(inBase))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.greenBg))
            }

            Text(displayText)
                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                .foregroundStyle(rawInput.isEmpty ? Theme.placeholder : Theme.value)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .textSelection(.enabled)

            Keypad(base: inBase) { key in
                handleKey(key)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.line, lineWidth: 1))
    }

    private var displayText: String {
        guard !rawInput.isEmpty else { return "0" }
        return group(rawInput, size: groupSize(inBase))
    }

    private var resultList: some View {
        VStack(spacing: 6) {
            if let v = value {
                ForEach(2...36, id: \.self) { base in
                    resultRow(base: base, text: v.string(radix: base))
                }
            } else {
                Text("输入有效数字后显示 2–36 进制对照")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.placeholder)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            }
        }
    }

    private func resultRow(base: Int, text: String) -> some View {
        Button {
            copyText(text)
            showToast("已复制 \(RadixLabel.name(base))")
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(RadixLabel.full(base))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 92, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(group(text, size: groupSize(base)))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.value)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 辅助

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            let maxLen = 200
            guard rawInput.count < maxLen else { return }
            rawInput += d
        case .backspace:
            if !rawInput.isEmpty { rawInput.removeLast() }
        case .clear:
            rawInput = ""
        case .sign:
            if rawInput.hasPrefix("-") {
                rawInput.removeFirst()
            } else if !rawInput.isEmpty {
                rawInput = "-" + rawInput
            }
        }
    }

    private func group(_ s: String, size: Int) -> String {
        let neg = s.hasPrefix("-")
        let body = neg ? String(s.dropFirst()) : s
        guard size > 0 else { return s }
        var out: [String] = []
        var idx = body.endIndex
        while idx > body.startIndex {
            let start = body.index(idx, offsetBy: -size, limitedBy: body.startIndex) ?? body.startIndex
            out.append(String(body[start..<idx]))
            idx = start
        }
        return (neg ? "-" : "") + out.reversed().joined(separator: " ")
    }

    private func groupSize(_ base: Int) -> Int {
        switch base {
        case 2: return 8
        case 8: return 3
        case 16: return 4
        default: return 0
        }
    }

    private func showToast(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.toast == text { self.toast = nil }
        }
    }
}
