import SwiftUI
import UIKit

enum Theme {
    static let bg          = Color(red: 0.039, green: 0.039, blue: 0.047)
    static let card        = Color(red: 0.082, green: 0.082, blue: 0.098)
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

enum ScreenMode: Hashable {
    case convert
    case calculate
}

enum BinaryOp: Hashable, CaseIterable {
    case add
    case subtract
    case multiply
    case divide

    var symbol: String {
        switch self {
        case .add:      return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide:   return "÷"
        }
    }
}

enum CalcOutcome {
    case empty
    case invalid
    case divByZero
    case value(BigInt, BigInt?)
}

struct ContentView: View {

    // MARK: - 状态

    @State private var mode: ScreenMode = .convert

    // 转换页
    @State private var rawInput = ""
    @State private var inBase = 10
    @State private var customOutBase = 36
    @State private var showBaseSheet = false

    // 计算页
    @State private var operandA = ""
    @State private var operandB = ""
    @State private var op: BinaryOp = .add

    /// 键盘当前写入的目标
    private enum Slot: Hashable {
        case convert
        case a
        case b
    }

    @State private var activeSlot: Slot = .convert

    @State private var toastText: String?

    // MARK: - 进制常量

    private let baseTitles = ["二进制", "八进制", "十进制", "十六进制", "其他"]
    private let baseValues = [2, 8, 10, 16, 0]

    // MARK: - 主体

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    modeSwitch
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 12)

                ScrollView {
                    Group {
                        if mode == .convert {
                            convertContent
                        } else {
                            calculateContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }

                keypadArea
            }

            if let t = toastText {
                VStack {
                    Spacer()
                    Text(t)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(white: 0.19)))
                        .padding(.bottom, 300)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.18), value: toastText)
        .sheet(isPresented: $showBaseSheet) {
            BasePickerSheet(selected: inBase) { n in
                selectBase(n)
            }
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 顶部

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                Text(mode == .convert ? "01" : "02")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.green)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.green.opacity(0.25), lineWidth: 1)
                    )

                Text("Radix")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Rectangle()
                    .fill(Color.white.opacity(0.13))
                    .frame(width: 1, height: 13)
                    .padding(.leading, 3)

                Text(mode == .convert ? "进制" : "运算")
                    .font(.system(size: 11.5, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim2)
            }

            Text(mode == .convert
                 ? "2 – 36 进制任意互转 · 支持超大整数"
                 : "任意进制加减乘除 · 支持负数与超大整数")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.dim2)
                .padding(.leading, 37)
        }
    }

    private var modeSwitch: some View {
        HStack(spacing: 2) {
            modeButton("进制转换", .convert)
            modeButton("四则运算", .calculate)
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.09)))
    }

    private func modeButton(_ title: String, _ target: ScreenMode) -> some View {
        Button {
            guard mode != target else { return }
            mode = target
            activeSlot = target == .convert ? .convert : .a
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(mode == target ? Color.white : Theme.dim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(mode == target ? Color(white: 0.18) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 转换页

    private var convertContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            inputCard
            resultCard
            Text("点击任意一行复制 · 最后一行可切换目标进制")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.placeholder)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
        }
    }

    private var inputCard: some View {
        VStack(spacing: 8) {
            baseSelector

            HStack(spacing: 6) {
                Text(rawInput.isEmpty ? "0" : rawInput)
                    .font(.system(size: inputFontSize, weight: .medium, design: .monospaced))
                    .foregroundStyle(rawInput.isEmpty ? Theme.placeholder : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(.black))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(activeSlot == .convert ? Theme.green.opacity(0.55) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { activeSlot = .convert }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var baseSelector: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { index in
                Button {
                    if baseValues[index] == 0 {
                        showBaseSheet = true
                    } else {
                        selectBase(baseValues[index])
                    }
                } label: {
                    Text(buttonTitle(index))
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(isSelected(index) ? Color.white : Theme.dim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(isSelected(index) ? Color(white: 0.185) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black))
    }

    private var resultCard: some View {
        VStack(spacing: 0) {
            resultRow(title: "二进制",   letter: "B", base: 2,  fg: Theme.blue,   bg: Theme.blueBg)
            divider
            resultRow(title: "八进制",   letter: "O", base: 8,  fg: Theme.cyan,   bg: Theme.cyanBg)
            divider
            resultRow(title: "十进制",   letter: "D", base: 10, fg: Theme.green,  bg: Theme.greenBg)
            divider
            resultRow(title: "十六进制", letter: "H", base: 16, fg: Theme.orange, bg: Theme.orangeBg)
            divider
            customResultRow
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
    }

    private func tagView(_ title: String, _ letter: String, _ fg: Color, _ bg: Color) -> some View {
        HStack(spacing: 0) {
            Text(title)
            Text("(\(letter))").opacity(0.62)
        }
        .font(.system(size: 10.5, weight: .bold))
        .foregroundStyle(fg)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(width: 74)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7).fill(bg))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(fg.opacity(0.18), lineWidth: 1)
        )
    }

    private func resultRow(title: String, letter: String, base: Int, fg: Color, bg: Color) -> some View {
        let text = display(base)
        return HStack(spacing: 11) {
            tagView(title, letter, fg, bg)

            Text(text)
                .font(.system(size: valueFont(text), weight: .regular, design: .monospaced))
                .foregroundStyle(hasValue ? Theme.value : Theme.placeholder)
                .lineLimit(text.count > 26 ? 2 : 1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            copyButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture { copy(raw(base)) }
    }

    private var customResultRow: some View {
        let text = display(customOutBase)
        return HStack(spacing: 11) {
            Menu {
                ForEach(2...36, id: \.self) { n in
                    Button("\(n) 进制") { customOutBase = n }
                }
            } label: {
                customBaseTag
            }

            Text(text)
                .font(.system(size: valueFont(text), weight: .regular, design: .monospaced))
                .foregroundStyle(hasValue ? Theme.value : Theme.placeholder)
                .lineLimit(text.count > 26 ? 2 : 1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            copyButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture { copy(raw(customOutBase)) }
    }

    private var copyButton: some View {
        Image(systemName: "doc.on.doc")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Theme.dim2)
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
    }

    // MARK: - 计算页

    private var calculateContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            operateCard
            calcResultSection
            Text("点击任意一行复制 · 末行可切换目标进制")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.placeholder)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var operateCard: some View {
        VStack(spacing: 7) {
            baseSelector

            operandRow("A", .a)
            opRow
            operandRow("B", .b)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private func operandRow(_ label: String, _ field: Slot) -> some View {
        let text = field == .a ? operandA : operandB
        let isActive = currentSlot == field
        return HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.dim2)
                .frame(width: 14, alignment: .leading)

            Text(text.isEmpty ? "0" : text)
                .font(.system(size: operandFontSize(text), weight: .medium, design: .monospaced))
                .foregroundStyle(text.isEmpty ? Theme.placeholder : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Theme.green.opacity(0.55) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { activeSlot = field }
    }

    private var opRow: some View {
        HStack(spacing: 6) {
            ForEach(BinaryOp.allCases, id: \.self) { item in
                Button {
                    op = item
                } label: {
                    Text(item.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(op == item ? Color.black : Theme.dim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(op == item ? Theme.green : Color(white: 0.13))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 结果（多进制并列）

    private var calcResultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("计算结果")
                    .font(.system(size: 11.5, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.dim2)

                baseChip

                Spacer()
            }

            switch calcOutcome {
            case .value(let v, let remainder):
                valueRowsCard(v)

                if let remainder = remainder, op == .divide {
                    Text("余数")
                        .font(.system(size: 11.5, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Theme.dim2)
                        .padding(.top, 8)

                    valueRowsCard(remainder)
                }
            case .empty:
                messageCard("填入 A 和 B 即可算出结果")
            case .invalid:
                messageCard("输入不合法，请检查字符是否超出当前进制")
            case .divByZero:
                messageCard("除数不能为 0")
            }
        }
    }

    private func valueRowsCard(_ value: BigInt) -> some View {
        VStack(spacing: 0) {
            valueRow("二进制",   "B", 2,  Theme.blue,   Theme.blueBg,   value)
            divider
            valueRow("八进制",   "O", 8,  Theme.cyan,   Theme.cyanBg,   value)
            divider
            valueRow("十进制",   "D", 10, Theme.green,  Theme.greenBg,  value)
            divider
            valueRow("十六进制", "H", 16, Theme.orange, Theme.orangeBg, value)
            divider
            customValueRow(value)
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private func valueRow(_ title: String, _ letter: String, _ base: Int, _ fg: Color, _ bg: Color, _ value: BigInt) -> some View {
        let text = readable(value, base: base)
        return HStack(spacing: 11) {
            tagView(title, letter, fg, bg)

            Text(text)
                .font(.system(size: valueFont(text), weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.value)
                .lineLimit(text.count > 26 ? 2 : 1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            copyButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture { copyText(value.string(radix: base)) }
    }

    private func customValueRow(_ value: BigInt) -> some View {
        let text = readable(value, base: customOutBase)
        return HStack(spacing: 11) {
            Menu {
                ForEach(2...36, id: \.self) { n in
                    Button("\(n) 进制") { customOutBase = n }
                }
            } label: {
                customBaseTag
            }

            Text(text)
                .font(.system(size: valueFont(text), weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.value)
                .lineLimit(text.count > 26 ? 2 : 1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            copyButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture { copyText(value.string(radix: customOutBase)) }
    }

    private var customBaseTag: some View {
        HStack(spacing: 3) {
            Text("\(customOutBase) 进制")
            Image(systemName: "chevron.down")
                .font(.system(size: 7, weight: .heavy))
                .opacity(0.75)
        }
        .font(.system(size: 10.5, weight: .bold))
        .foregroundStyle(Theme.purple)
        .lineLimit(1)
        .frame(width: 74)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.purpleBg))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Theme.purple.opacity(0.18), lineWidth: 1)
        )
    }

    private func messageCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.5))
            .foregroundStyle(Theme.placeholder)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }

    private var baseChip: some View {
        Text("\(inBase) 进制输入")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Theme.purple)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.purpleBg))
    }

    // MARK: - 键盘

    private var keypadArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(slotLabel)
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.dim2)

                Spacer()

                Text("\(inBase) 进制")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Theme.purple)
            }
            .padding(.horizontal, 16)

            Keypad(base: inBase, onKey: handleKey)
                .padding(.horizontal, 12)
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            Theme.bg
                .overlay(
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private var slotLabel: String {
        switch currentSlot {
        case .convert: return "输入 · 转换框"
        case .a:       return "输入 · 操作数 A"
        case .b:       return "输入 · 操作数 B"
        }
    }

    private var currentSlot: Slot {
        guard mode == .calculate else { return .convert }
        return activeSlot == .b ? .b : .a
    }

    private var slotText: String {
        switch currentSlot {
        case .convert: return rawInput
        case .a:       return operandA
        case .b:       return operandB
        }
    }

    private func setSlotText(_ text: String) {
        switch currentSlot {
        case .convert: rawInput = text
        case .a:       operandA = text
        case .b:       operandB = text
        }
    }

    private func handleKey(_ key: KeypadKey) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var text = slotText

        switch key {
        case .digit(let d):
            text = sanitize(text + d)
        case .backspace:
            if !text.isEmpty { text.removeLast() }
        case .clear:
            text = ""
        case .sign:
            if text.hasPrefix("-") {
                text.removeFirst()
            } else {
                text = "-" + text
            }
        }

        setSlotText(text)
    }

    // MARK: - 计算逻辑

    private var calcOutcome: CalcOutcome {
        let aText = operandA.trimmingCharacters(in: .whitespaces)
        let bText = operandB.trimmingCharacters(in: .whitespaces)
        guard !aText.isEmpty, !bText.isEmpty else { return .empty }
        guard let a = BigInt.parse(aText, radix: inBase),
              let b = BigInt.parse(bText, radix: inBase) else { return .invalid }

        switch op {
        case .add:
            return .value(a.adding(b), nil)
        case .subtract:
            return .value(a.subtracting(b), nil)
        case .multiply:
            return .value(a.multiplied(b), nil)
        case .divide:
            guard let r = a.divided(by: b) else { return .divByZero }
            return .value(r.quotient, r.remainder)
        }
    }

    private func readable(_ value: BigInt, base: Int) -> String {
        let s = value.string(radix: base)
        if s.hasPrefix("-") {
            return "-" + group(String(s.dropFirst()), size: groupSize(base))
        }
        return group(s, size: groupSize(base))
    }

    private func groupSize(_ base: Int) -> Int {
        switch base {
        case 2:  return 8
        case 8:  return 3
        case 16: return 4
        default: return 0
        }
    }

    // MARK: - 转换逻辑

    private var parsed: (negative: Bool, value: BigUInt)? {
        guard !rawInput.isEmpty else { return nil }
        var body = rawInput
        var negative = false
        if body.hasPrefix("-") {
            negative = true
            body.removeFirst()
        }
        guard !body.isEmpty, let v = BigUInt.parse(body, radix: inBase) else { return nil }
        return (negative, v)
    }

    private var hasValue: Bool { parsed != nil }

    /// 不带空格的原始值，用于复制
    private func raw(_ base: Int) -> String {
        guard let p = parsed else { return "" }
        let sign = (p.negative && !p.value.isZero) ? "-" : ""
        return sign + p.value.string(radix: base)
    }

    /// 带分组空格的显示值
    private func display(_ base: Int) -> String {
        guard let p = parsed else { return "—" }
        let sign = (p.negative && !p.value.isZero) ? "-" : ""
        let body = p.value.string(radix: base)
        return sign + group(body, size: groupSize(base))
    }

    private func group(_ s: String, size: Int) -> String {
        guard size > 0, s.count > size else { return s }
        let chars = Array(s)
        var parts: [String] = []
        var i = 0
        while i < chars.count {
            let end = min(i + size, chars.count)
            parts.append(String(chars[i..<end]))
            i = end
        }
        return parts.joined(separator: " ")
    }

    private func valueFont(_ s: String) -> CGFloat {
        switch s.count {
        case 0...16:  return 15.5
        case 17...22: return 14
        case 23...30: return 12.5
        case 31...40: return 11.5
        default:      return 10.5
        }
    }

    private var inputFontSize: CGFloat {
        let n = rawInput.count
        if n <= 10 { return 27 }
        if n <= 14 { return 23 }
        if n <= 20 { return 19 }
        return 16
    }

    private func operandFontSize(_ s: String) -> CGFloat {
        let n = s.count
        if n <= 10 { return 19 }
        if n <= 16 { return 17 }
        if n <= 24 { return 15 }
        return 13
    }

    // MARK: - 输入处理

    /// 过滤非法字符，只保留当前进制允许的字符；负号仅允许出现在开头
    private func sanitize(_ s: String) -> String {
        var out = ""
        for ch in s.uppercased() {
            if ch == "-" {
                if out.isEmpty { out.append("-") }
                continue
            }
            if ch == " " || ch == "_" || ch == "," { continue }
            if let d = BigUInt.digitValue(ch), d < inBase { out.append(ch) }
        }
        return out
    }

    private func selectBase(_ base: Int) {
        inBase = base
        rawInput = ""
        operandA = ""
        operandB = ""
    }

    private var isCommonBase: Bool {
        inBase == 2 || inBase == 8 || inBase == 10 || inBase == 16
    }

    /// 第五个按钮：常用进制时显示"其他"，选了自定义进制就显示"N 进制"
    private func buttonTitle(_ index: Int) -> String {
        if baseValues[index] == 0 {
            return isCommonBase ? "其他" : "\(inBase) 进制"
        }
        return baseTitles[index]
    }

    private func isSelected(_ index: Int) -> Bool {
        if baseValues[index] == 0 { return !isCommonBase }
        return inBase == baseValues[index]
    }

    // MARK: - 动作

    private func copy(_ s: String) {
        guard hasValue, !s.isEmpty else { return }
        copyText(s)
    }

    private func copyText(_ s: String) {
        guard !s.isEmpty else { return }
        UIPasteboard.general.string = s
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        toast("已复制")
    }

    private func toast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            if toastText == text { toastText = nil }
        }
    }
}

// MARK: - 自定义进制选择

struct BasePickerSheet: View {
    let selected: Int
    let onPick: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("选择进制")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button("取消") { dismiss() }
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.blue)
            }
            .padding(.top, 20)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(2...36, id: \.self) { n in
                    Button {
                        onPick(n)
                        dismiss()
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(n == selected ? Color.black : Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(n == selected ? Theme.green : Color(white: 0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.card)
    }
}
