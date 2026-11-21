import SwiftUI

struct CalcView: View {
    @State private var operandA = ""
    @State private var operandB = ""
    @State private var baseA = 10
    @State private var baseB = 10
    @State private var op: BinaryOp = .add
    @State private var activeSlot: Int = 0  // 0 = A, 1 = B
    @State private var outBase = 36
    @State private var showOutBaseSheet = false
    @State private var toast: String?

    private var parsedA: BigInt? {
        guard !operandA.isEmpty else { return nil }
        return BigInt.parse(operandA, radix: baseA)
    }
    private var parsedB: BigInt? {
        guard !operandB.isEmpty else { return nil }
        return BigInt.parse(operandB, radix: baseB)
    }

    private enum Outcome {
        case empty, invalid, divByZero
        case value(BigInt, BigInt?)  // 结果, 余数
    }

    private var outcome: Outcome {
        guard let a = parsedA, let b = parsedB else { return .empty }
        if operandA.contains("-") == false && BigUInt.parse(operandA, radix: baseA) == nil { return .invalid }
        if operandB.contains("-") == false && BigUInt.parse(operandB, radix: baseB) == nil { return .invalid }
        switch op {
        case .add:      return .value(a.adding(b), nil)
        case .subtract: return .value(a.subtracting(b), nil)
        case .multiply: return .value(a.multiplied(b), nil)
        case .divide:
            guard let qr = a.divided(by: b) else { return .divByZero }
            return .value(qr.quotient, qr.remainder)
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    operandCard("操作数 A", value: $operandA, base: $baseA, slot: 0)
                    opRow
                    operandCard("操作数 B", value: $operandB, base: $baseB, slot: 1)
                    resultSection
                    Text("整数运算 · 除法向零截断，余数与被除数同号")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.placeholder)
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
        .sheet(isPresented: $showOutBaseSheet) {
            outBaseSheet
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("四则运算")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("MIXED-RADIX")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.dim2)
            Spacer()
        }
    }

    private func operandCard(_ title: String, value: Binding<String>, base: Binding<Int>, slot: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(activeSlot == slot ? Theme.green : Theme.dim2)
                Spacer()
                baseMenu(base: base)
            }

            Text(group(value.wrappedValue, size: groupSize(base.wrappedValue)))
                .font(.system(size: 23, weight: .semibold, design: .monospaced))
                .foregroundStyle(activeSlot == slot ? Theme.value : Theme.dim)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { activeSlot = slot }
                .textSelection(.enabled)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(activeSlot == slot ? Theme.green.opacity(0.6) : Theme.line, lineWidth: activeSlot == slot ? 1.5 : 1)
        )
    }

    private func baseMenu(base: Binding<Int>) -> some View {
        Menu {
            ForEach(2...36, id: \.self) { b in
                Button("\(RadixLabel.full(b))") {
                    base.wrappedValue = b
                    if activeSlot == 0 { operandA = "" } else { operandB = "" }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text("\(RadixLabel.full(base.wrappedValue))")
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .heavy))
            }
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(Theme.purple)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Theme.purpleBg))
        }
    }

    private var opRow: some View {
        HStack(spacing: 8) {
            ForEach([BinaryOp.add, .subtract, .multiply, .divide], id: \.self) { item in
                Button {
                    op = item
                } label: {
                    Text(item.symbol)
                        .font(.system(size: 19, weight: .semibold, design: .monospaced))
                        .foregroundStyle(op == item ? .white : Theme.dim)
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

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                SectionTitle(text: "计算结果")
                Spacer()
                Button {
                    showOutBaseSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("\(RadixLabel.full(outBase))")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .heavy))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.purple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Theme.purpleBg))
                }
            }

            switch outcome {
            case .empty:
                emptyCard("输入 A、B 后自动计算")
            case .invalid:
                emptyCard("输入字符超出当前进制范围")
            case .divByZero:
                emptyCard("除数不能为 0")
            case .value(let v, let remainder):
                valueRows(v)
                if let r = remainder, op == .divide {
                    SectionTitle(text: "余数")
                    valueRows(r)
                }
            }

            // 键盘放在结果下方，按当前活动输入框的进制显示
            Keypad(base: activeSlot == 0 ? baseA : baseB) { key in
                handleKey(key)
            }
            .padding(.top, 4)
        }
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Theme.placeholder)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
    }

    private func valueRows(_ v: BigInt) -> some View {
        VStack(spacing: 6) {
            resultRow(label: RadixLabel.full(2), text: v.string(radix: 2), base: 2)
            resultRow(label: RadixLabel.full(8), text: v.string(radix: 8), base: 8)
            resultRow(label: RadixLabel.full(10), text: v.string(radix: 10), base: 10)
            resultRow(label: RadixLabel.full(16), text: v.string(radix: 16), base: 16)
            resultRow(label: RadixLabel.full(outBase), text: v.string(radix: outBase), base: outBase)
        }
    }

    private func resultRow(label: String, text: String, base: Int) -> some View {
        Button {
            copyText(text)
            showToast("已复制")
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 92, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(group(text, size: groupSize(base)))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.value)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        }
        .buttonStyle(.plain)
    }

    private var outBaseSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(2...36, id: \.self) { b in
                        Button {
                            outBase = b
                            showOutBaseSheet = false
                        } label: {
                            Text(RadixLabel.full(b))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(b == outBase ? .white : Theme.value)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(b == outBase ? Theme.green.opacity(0.25) : Theme.card2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("选择结果进制")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showOutBaseSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 辅助

    private func handleKey(_ key: KeypadKey) {
        let binding = activeSlot == 0 ? $operandA : $operandB
        switch key {
        case .digit(let d):
            if binding.wrappedValue.count < 200 { binding.wrappedValue += d }
        case .backspace:
            if !binding.wrappedValue.isEmpty { binding.wrappedValue.removeLast() }
        case .clear:
            binding.wrappedValue = ""
        case .sign:
            if binding.wrappedValue.hasPrefix("-") {
                binding.wrappedValue.removeFirst()
            } else if !binding.wrappedValue.isEmpty {
                binding.wrappedValue = "-" + binding.wrappedValue
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
