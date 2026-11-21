import SwiftUI

struct CodeView: View {
    @State private var width: Int = 8
    @State private var trueInput = "-5"
    @State private var toast: String?

    private var parsedValue: Int? { Int(trueInput.trimmingCharacters(in: .whitespaces)) }

    private var code: MachineCode? {
        guard let v = parsedValue else { return nil }
        return MachineCode(width: width, value: v)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    widthPicker
                    trueValueCard

                    SectionTitle(text: "同一数值的五种表示")

                    if let c = code {
                        codeCard(c)
                        ReverseLookupView(width: $width) { v in
                            trueInput = "\(v)"
                        }
                    } else {
                        emptyHint
                    }

                    noteCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }

            if let toast = toast {
                VStack {
                    Spacer()
                    ToastView(text: toast).padding(.bottom, 30)
                }
                .allowsHitTesting(false)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("机器码制")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("TRUE · SIGN · COMPLEMENT")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Theme.dim2)
            Spacer()
        }
    }

    private var widthPicker: some View {
        HStack(spacing: 8) {
            SectionTitle(text: "字长")
            Spacer()
            ForEach([8, 16, 32], id: \.self) { w in
                Button {
                    width = w
                } label: {
                    Text("\(w) 位")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(width == w ? .white : Theme.dim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(width == w ? Theme.green.opacity(0.22) : Color(white: 0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(width == w ? Theme.green : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 真值输入：内置键盘，不弹系统键盘
    private var trueValueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "真值（十进制，可正负）")

            HStack {
                Text(trueInput.isEmpty ? "0" : trueInput)
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(trueInput.isEmpty ? Theme.placeholder : Theme.value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)

                if let v = parsedValue {
                    let lo = -(1 << (width - 1))
                    let hi = (1 << (width - 1)) - 1
                    if v < lo || v > hi {
                        Text("超出字长范围，已自动夹紧")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.orange)
                    }
                }
            }

            Keypad(base: 10) { key in
                handleKey(key)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private func codeCard(_ c: MachineCode) -> some View {
        VStack(spacing: 6) {
            codeRow(title: "机器数（补码形式）", value: c.twosComplement, tint: Theme.green)
            codeRow(title: "原码", value: c.signMagnitude, tint: Theme.blue)
            codeRow(title: "反码", value: c.onesComplement, tint: Theme.cyan)
            codeRow(title: "补码", value: c.twosComplement, tint: Theme.purple)
        }
    }

    private func codeRow(title: String, value: String, tint: Color) -> some View {
        Button {
            copyText(value)
            showToast("已复制")
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 118, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(splitBits(value))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(tint)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        }
        .buttonStyle(.plain)
    }

    private var emptyHint: some View {
        Text("输入合法十进制真值后显示原码 / 反码 / 补码")
            .font(.system(size: 12))
            .foregroundStyle(Theme.placeholder)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
    }

    /// 说明改成逐条列表，正常字号，不折叠
    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("说明")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.orange)

            noteItem("正数", "原码 = 反码 = 补码，最高位（符号位）为 0。")
            noteItem("负数·原码", "符号位为 1，数值位是绝对值的二进制。")
            noteItem("负数·反码", "符号位不变，数值位按位取反（0↔1）。")
            noteItem("负数·补码", "反码末位加 1，等价于真值对 2^字长 取模。")
            noteItem("机器数", "计算机内部以补码存储，故机器数与补码相同。")
            noteItem("表示范围", "\(width) 位补码：\( -(1 << (width - 1)) ) ～ \( (1 << (width - 1)) - 1 )；原码/反码：\( -((1 << (width - 1)) - 1) ) ～ \( (1 << (width - 1)) - 1 )。")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card.opacity(0.6)))
    }

    private func noteItem(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.cyan)
                .frame(width: 72, alignment: .leading)
            Text(body)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.value)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func splitBits(_ s: String) -> String {
        var out: [String] = []
        var idx = s.endIndex
        while idx > s.startIndex {
            let start = s.index(idx, offsetBy: -4, limitedBy: s.startIndex) ?? s.startIndex
            out.append(String(s[start..<idx]))
            idx = start
        }
        return out.reversed().joined(separator: " ")
    }

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            if trueInput.count < 12 { trueInput += d }
        case .backspace:
            if !trueInput.isEmpty { trueInput.removeLast() }
        case .clear:
            trueInput = ""
        case .sign:
            if trueInput.hasPrefix("-") {
                trueInput.removeFirst()
            } else if !trueInput.isEmpty {
                trueInput = "-" + trueInput
            }
        }
    }

    private func showToast(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.toast == text { self.toast = nil }
        }
    }
}

/// 从任意一种码反查真值（内置键盘，不弹系统键盘）
struct ReverseLookupView: View {
    @Binding var width: Int
    let onResolve: (Int) -> Void

    @State private var kind: Int = 2  // 0 原码 1 反码 2 补码
    @State private var bits = ""
    @State private var resolved: Int?

    private let kinds = ["原码", "反码", "补码"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "反查：由码求真值")

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Button {
                        kind = i
                        reResolve()
                    } label: {
                        Text(kinds[i])
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(kind == i ? .white : Theme.dim)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(kind == i ? Theme.purple.opacity(0.3) : Color(white: 0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text(bits.isEmpty ? "点下方键盘输入 \(width) 位 0/1" : bits)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(bits.isEmpty ? Theme.placeholder : Theme.value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let r = resolved {
                    Button {
                        onResolve(r)
                    } label: {
                        Text("= \(r)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card2))

            Keypad(base: 2) { key in
                handleKey(key)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
        .onAppear { reResolve() }
    }

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            if bits.count < width { bits += d }
        case .backspace:
            if !bits.isEmpty { bits.removeLast() }
        case .clear:
            bits = ""
        case .sign:
            break
        }
        reResolve()
    }

    private func reResolve() {
        let s = String(bits.filter { $0 == "0" || $0 == "1" }.prefix(width))
        guard s.count == width else { resolved = nil; return }
        switch kind {
        case 0: resolved = CodeParser.value(fromSignMagnitude: s)
        case 1: resolved = CodeParser.value(fromOnesComplement: s)
        default: resolved = CodeParser.value(fromTwosComplement: s)
        }
    }
}
