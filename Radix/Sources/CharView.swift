import SwiftUI

struct CharView: View {
    @State private var sub: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $sub) {
                Text("ASCII 码").tag(0)
                Text("汉字编码").tag(1)
                Text("Unicode").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            switch sub {
            case 0: ASCIIView()
            case 1: HanziView()
            default: UnicodeView()
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

// MARK: - ASCII 表

struct ASCIIView: View {
    @State private var search = ""
    @State private var onlyPrintable = false
    @State private var toast: String?

    private var entries: [ASCIIEntry] {
        ASCIITable.all.filter { e in
            if onlyPrintable && e.isControl { return false }
            if search.isEmpty { return true }
            return e.value.description.contains(search)
                || e.hex.uppercased().contains(search.uppercased())
                || e.bin.contains(search)
                || e.display == search
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.dim2)
                    TextField("查十进制 / 十六进制 / 字符", text: $search)
                        .foregroundStyle(Theme.value)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))

                HStack {
                    Toggle("仅可打印字符", isOn: $onlyPrintable)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.dim)
                        .tint(Theme.green)
                    Spacer()
                    Text("\(entries.count) 项")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim2)
                }

                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(entries, id: \.value) { e in
                            asciiRow(e)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            if let toast = toast {
                VStack {
                    Spacer()
                    ToastView(text: toast).padding(.bottom, 30)
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func asciiRow(_ e: ASCIIEntry) -> some View {
        Button {
            copyText("\(e.value) \(e.hex)H \(e.bin)B \(e.display)")
            showToast("已复制")
        } label: {
            HStack(spacing: 8) {
                Text(String(format: "%3d", e.value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 34, alignment: .trailing)

                Text(e.hex)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.purple)
                    .frame(width: 24)

                Text(e.bin)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.blue)
                    .frame(width: 66, alignment: .leading)

                Text(e.display)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(e.isControl ? Theme.orange : .white)
                    .frame(width: 26, alignment: .center)

                Text(e.name ?? "可打印")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card))
        }
        .buttonStyle(.plain)
    }

    private func showToast(_ t: String) {
        toast = t
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.toast == t { self.toast = nil }
        }
    }
}

// MARK: - 汉字编码

struct HanziView: View {
    @State private var qu = 54
    @State private var wei = 48
    @State private var jineiInput = "D6D0"
    @State private var mode: Int = 0  // 0 区位→国标/机内, 1 机内→区位
    @State private var matrixIndex = 0
    @State private var count = 1000
    @State private var toast: String?

    private var quwei: QuweiCode? { QuweiCode(qu: qu, wei: wei) }
    private var jinei: JineiCode? { JineiCode(hex: jineiInput) }
    private var matrix: (name: String, cols: Int, rows: Int) {
        FontMatrix.options[matrixIndex]
    }
    private var totalBytes: Int {
        FontMatrix.totalBytes(cols: matrix.cols, rows: matrix.rows, count: count)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    directionPicker
                    if mode == 0 { quweiToCode } else { codeToQuwei }
                    fontMatrixCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
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
        Text("汉字编码")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
    }

    private var directionPicker: some View {
        Picker("", selection: $mode) {
            Text("区位码 → 国标 / 机内").tag(0)
            Text("机内码 → 区位 / 国标").tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var quweiToCode: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                numberField("区号 (1-94)", value: $qu)
                numberField("位号 (1-94)", value: $wei)
            }

            if let q = quwei {
                VStack(spacing: 6) {
                    copyRow(title: "区位码", value: String(format: "%02d%02d", q.qu, q.wei), tint: Theme.blue)
                    copyRow(title: "国标码 (+2020H)", value: q.guobiaoHex + "H", tint: Theme.cyan)
                    copyRow(title: "机内码 (+8080H)", value: q.jineiHex + "H", tint: Theme.green)
                }
            } else {
                Text("区号 / 位号需在 1–94 之间")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.orange)
            }

            Text("例：「中」区位码 5448 → 国标码 5650H → 机内码 D6D0H")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.dim2)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var codeToQuwei: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("机内码 (4 位十六进制)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                Spacer()
            }
            TextField("例如 D6D0", text: $jineiInput)
                .font(.system(size: 20, design: .monospaced))
                .foregroundStyle(Theme.value)
                .textFieldStyle(.plain)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card2))

            if let j = jinei, j.quweiValid {
                VStack(spacing: 6) {
                    copyRow(title: "国标码", value: j.guobiaoHex + "H", tint: Theme.cyan)
                    copyRow(title: "区位码", value: String(format: "%02d%02d", j.qu, j.wei), tint: Theme.blue)
                }
            } else {
                Text("机内码需在 A1A1–FEFE 范围内")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.orange)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private func numberField(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.dim2)
            TextField("", value: value, formatter: NumberFormatter())
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(Theme.value)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card2))
        }
    }

    private func copyRow(title: String, value: String, tint: Color) -> some View {
        Button {
            copyText(value)
            showToast("已复制")
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 128, alignment: .leading)
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card2))
        }
        .buttonStyle(.plain)
    }

    private var fontMatrixCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "字模数字化与存储容量")

            HStack(spacing: 6) {
                ForEach(FontMatrix.options.indices, id: \.self) { i in
                    Button {
                        matrixIndex = i
                    } label: {
                        Text(FontMatrix.options[i].name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(matrixIndex == i ? .white : Theme.dim)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(matrixIndex == i ? Theme.orange.opacity(0.25) : Color(white: 0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("字数")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.dim2)
                Spacer()
                TextField("", value: $count, formatter: NumberFormatter())
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(Theme.value)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .frame(width: 100)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.card2))
            }

            DividerLine()

            HStack {
                Text("每字 \(matrix.cols)×\(matrix.rows) = \(matrix.cols * matrix.rows) bit")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
                Spacer()
                Text("\(FontMatrix.bytesPerChar(cols: matrix.cols, rows: matrix.rows)) 字节/字")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
            }

            HStack {
                Text("总容量")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                Spacer()
                Text("\(totalBytes) B  ·  \(String(format: "%.2f", Double(totalBytes) / 1024.0)) KB")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.green)
            }

            Text("点阵中每个亮点占 1 位（bit），8 位 = 1 字节。字数 × 每字字节数即字库存储容量。")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.dim2)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private func showToast(_ t: String) {
        toast = t
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.toast == t { self.toast = nil }
        }
    }
}

// MARK: - Unicode / UTF-8

struct UnicodeView: View {
    @State private var charInput = "中"
    @State private var codeInput = "4E2D"
    @State private var mode: Int = 0
    @State private var toast: String?

    private var info: UnicodeInfo { UnicodeCodec.encode(charInput) }
    private var decoded: String? { UnicodeCodec.character(fromCodePoint: codeInput) }
    private var decodedInfo: UnicodeInfo? {
        guard let d = decoded else { return nil }
        return UnicodeCodec.encode(d)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Unicode / UTF-8")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Picker("", selection: $mode) {
                        Text("字符 → 码点/UTF-8").tag(0)
                        Text("码点 → 字符").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if mode == 0 { charToCode } else { codeToChar }

                    utf8RuleCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
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

    private var charToCode: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SectionTitle(text: "输入字符（可多个，含 emoji）")
                TextField("例如 中文😀", text: $charInput)
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.value)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card2))
            }

            VStack(spacing: 6) {
                copyRow(title: "Unicode 码点", value: info.codePointsJoined, tint: Theme.purple)
                copyRow(title: "UTF-8 十六进制", value: info.utf8Hex, tint: Theme.green)
                copyRow(title: "UTF-8 二进制", value: info.utf8Binary, tint: Theme.blue)
                infoRow(title: "字节数", value: "\(info.utf8Bytes.count) 字节")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var codeToChar: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SectionTitle(text: "输入码点（十六进制，可带 U+）")
                TextField("例如 4E2D 或 U+1F600", text: $codeInput)
                    .font(.system(size: 20, design: .monospaced))
                    .foregroundStyle(Theme.value)
                    .textFieldStyle(.plain)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card2))
            }

            if let d = decoded, let di = decodedInfo {
                HStack {
                    Text("对应字符")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.dim2)
                    Spacer()
                    Button {
                        copyText(d)
                        showToast("已复制字符")
                    } label: {
                        Text(d)
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card2))

                VStack(spacing: 6) {
                    copyRow(title: "UTF-8 十六进制", value: di.utf8Hex, tint: Theme.green)
                    copyRow(title: "字节数", value: "\(di.utf8Bytes.count)", tint: Theme.cyan)
                }
            } else {
                Text("请输入有效的 Unicode 码点（≤ 10FFFF，不含代理区）")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.orange)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var utf8RuleCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "UTF-8 编码规则")
            rule("1 字节", "0xxxxxxx", "U+0000 – U+007F（ASCII）")
            rule("2 字节", "110xxxxx 10xxxxxx", "U+0080 – U+07FF")
            rule("3 字节", "1110xxxx 10xxxxxx 10xxxxxx", "U+0800 – U+FFFF（含常用汉字）")
            rule("4 字节", "11110xxx 10xxxxxx 10xxxxxx 10xxxxxx", "U+10000 – U+10FFFF（emoji 等）")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card.opacity(0.6)))
    }

    private func rule(_ bytes: String, _ pattern: String, _ range: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(bytes)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.cyan)
                Text(range)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.dim2)
            }
            Text(pattern)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.blue)
        }
    }

    private func copyRow(title: String, value: String, tint: Color) -> some View {
        Button {
            copyText(value)
            showToast("已复制")
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.dim2)
                    .frame(width: 118, alignment: .leading)
                Text(value)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundStyle(tint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card2))
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.dim2)
            Spacer()
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.value)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card2))
    }

    private func showToast(_ t: String) {
        toast = t
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.toast == t { self.toast = nil }
        }
    }
}
