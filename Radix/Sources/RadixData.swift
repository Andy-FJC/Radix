import Foundation

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

// MARK: - 进制标签

/// 进制的中文名与字母后缀。
/// 2/8/10/16 采用公认字母 B/O/D/H；其余进制没有公认单字母，
/// 用基数本身作后缀（如「十二进制(12)」），避免杜撰字母造成误导。
enum RadixLabel {
    static let digits = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    static func letter(_ base: Int) -> String {
        switch base {
        case 2: return "B"
        case 8: return "O"
        case 10: return "D"
        case 16: return "H"
        default: return "\(base)"
        }
    }

    static func name(_ base: Int) -> String {
        switch base {
        case 2: return "二进制"
        case 8: return "八进制"
        case 10: return "十进制"
        case 16: return "十六进制"
        default: return "\(base)进制"
        }
    }

    static func full(_ base: Int) -> String { "\(name(base))（\(letter(base))）" }

    static func binary(_ value: Int, width: Int) -> String {
        var s = ""
        var i = width - 1
        while i >= 0 {
            s.append(((value >> i) & 1) == 1 ? "1" : "0")
            i -= 1
        }
        return s
    }
}

// MARK: - 机器码制（真值 / 原码 / 反码 / 补码）

struct MachineCode {
    let width: Int  // 8 / 16 / 32
    let value: Int  // 真值（已按字长夹紧）

    init(width: Int, value: Int) {
        let w = [8, 16, 32].contains(width) ? width : 8
        self.width = w
        let maxV = (1 << (w - 1)) - 1
        let minV = -(1 << (w - 1))
        self.value = max(minV, min(maxV, value))
    }

    var negative: Bool { value < 0 }

    /// 原码 = 符号位 + 绝对值
    var signMagnitude: String {
        let mag = abs(value)
        return (negative ? "1" : "0") + RadixLabel.binary(mag, width: width - 1)
    }

    /// 反码：正数同原码；负数符号位不变、数值位按位取反
    var onesComplement: String {
        if !negative { return signMagnitude }
        let mag = abs(value)
        let inv = ((1 << (width - 1)) - 1) ^ mag
        return "1" + RadixLabel.binary(inv, width: width - 1)
    }

    /// 补码：正数同原码；负数 = 反码末位 +1，等价于 value mod 2^width
    var twosComplement: String {
        if !negative { return signMagnitude }
        let mod = 1 << width
        let u = (value % mod + mod) % mod
        return RadixLabel.binary(u, width: width)
    }
}

enum CodeParser {
    static func parseBinary(_ s: String) -> Int {
        var v = 0
        for ch in s { v = v * 2 + (ch == "1" ? 1 : 0) }
        return v
    }

    private static func onlyBits(_ s: String) -> Bool {
        !s.isEmpty && s.allSatisfy { $0 == "0" || $0 == "1" }
    }
    private static func valid(_ s: String) -> Bool {
        [8, 16, 32].contains(s.count) && onlyBits(s)
    }

    static func value(fromSignMagnitude s: String) -> Int? {
        guard valid(s) else { return nil }
        let neg = s.first == "1"
        let mag = parseBinary(String(s.dropFirst()))
        return neg ? -mag : mag
    }

    static func value(fromOnesComplement s: String) -> Int? {
        guard valid(s) else { return nil }
        let neg = s.first == "1"
        let body = String(s.dropFirst())
        if !neg { return parseBinary(body) }
        let n = s.count - 1
        let mag = (1 << n) - 1 - parseBinary(body)
        return -mag
    }

    static func value(fromTwosComplement s: String) -> Int? {
        guard valid(s) else { return nil }
        let n = s.count
        let u = parseBinary(s)
        let sign = (u >> (n - 1)) & 1
        return sign == 1 ? u - (1 << n) : u
    }
}

// MARK: - 汉字编码（区位码 / 国标码 / 机内码）

struct QuweiCode {
    let qu: Int  // 区号 1-94
    let wei: Int // 位号 1-94

    init?(qu: Int, wei: Int) {
        guard (1...94).contains(qu), (1...94).contains(wei) else { return nil }
        self.qu = qu
        self.wei = wei
    }

    /// 国标码 = 区位码 + 2020H
    var guobiaoBytes: (Int, Int) { (qu + 0x20, wei + 0x20) }
    var guobiaoHex: String {
        String(format: "%02X%02X", guobiaoBytes.0, guobiaoBytes.1)
    }

    /// 机内码 = 国标码 + 8080H
    var jineiBytes: (Int, Int) { (guobiaoBytes.0 + 0x80, guobiaoBytes.1 + 0x80) }
    var jineiHex: String {
        String(format: "%02X%02X", jineiBytes.0, jineiBytes.1)
    }
}

struct JineiCode {
    let b1: Int  // 0xA1-0xFE
    let b2: Int

    init?(hex: String) {
        var t = hex.trimmingCharacters(in: .whitespaces).uppercased()
        t = t.replacingOccurrences(of: "0X", with: "")
        t = t.replacingOccurrences(of: "H", with: "")
        guard t.count == 4 else { return nil }
        var bytes: [Int] = []
        var i = t.startIndex
        while i < t.endIndex {
            let next = t.index(i, offsetBy: 2)
            guard let v = UInt8(t[i..<next], radix: 16) else { return nil }
            bytes.append(Int(v))
            i = next
        }
        guard bytes.count == 2 else { return nil }
        self.b1 = bytes[0]
        self.b2 = bytes[1]
    }

    var qu: Int { b1 - 0xA0 }
    var wei: Int { b2 - 0xA0 }
    var quweiValid: Bool {
        (1...94).contains(qu) && (1...94).contains(wei)
    }
    var guobiaoHex: String {
        String(format: "%02X%02X", b1 - 0x80, b2 - 0x80)
    }
}

enum FontMatrix {
    static let options: [(name: String, cols: Int, rows: Int)] = [
        ("16×16", 16, 16),
        ("24×24", 24, 24),
        ("32×32", 32, 32),
        ("48×48", 48, 48),
    ]
    static func bytesPerChar(cols: Int, rows: Int) -> Int { cols * rows / 8 }
    static func totalBytes(cols: Int, rows: Int, count: Int) -> Int {
        bytesPerChar(cols: cols, rows: rows) * max(0, count)
    }
}

// MARK: - Unicode / UTF-8

struct UnicodeInfo {
    let scalars: [UInt32]
    let codePointsHex: [String]
    let utf8Bytes: [UInt8]

    var utf8Hex: String {
        utf8Bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    var utf8Binary: String {
        utf8Bytes.map { RadixLabel.binary(Int($0), width: 8) }.joined(separator: " ")
    }
    var codePointsJoined: String { codePointsHex.joined(separator: " ") }
}

enum UnicodeCodec {
    static func utf8(_ cp: UInt32) -> [UInt8] {
        if cp <= 0x7F {
            return [UInt8(cp)]
        } else if cp <= 0x7FF {
            return [UInt8(0xC0 | (cp >> 6)), UInt8(0x80 | (cp & 0x3F))]
        } else if cp <= 0xFFFF {
            return [UInt8(0xE0 | (cp >> 12)), UInt8(0x80 | ((cp >> 6) & 0x3F)), UInt8(0x80 | (cp & 0x3F))]
        } else {
            return [
                UInt8(0xF0 | (cp >> 18)),
                UInt8(0x80 | ((cp >> 12) & 0x3F)),
                UInt8(0x80 | ((cp >> 6) & 0x3F)),
                UInt8(0x80 | (cp & 0x3F)),
            ]
        }
    }

    static func encode(_ text: String) -> UnicodeInfo {
        let scalars = text.unicodeScalars.map { $0.value }
        var bytes: [UInt8] = []
        for cp in scalars { bytes += utf8(cp) }
        let cps = scalars.map { String(format: "U+%04X", $0) }
        return UnicodeInfo(scalars: scalars, codePointsHex: cps, utf8Bytes: bytes)
    }

    static func character(fromCodePoint hex: String) -> String? {
        var t = hex.trimmingCharacters(in: .whitespaces).uppercased()
        if t.hasPrefix("U+") { t.removeFirst(2) }
        guard let v = UInt32(t, radix: 16), let scalar = UnicodeScalar(v) else { return nil }
        return String(Character(scalar))
    }
}

// MARK: - ASCII 表

struct ASCIIEntry {
    let value: Int
    let display: String
    let name: String?

    var hex: String { String(format: "%02X", value) }
    var bin: String { RadixLabel.binary(value, width: 8) }
    var isControl: Bool { name != nil }
}

enum ASCIITable {
    private static let controlNames: [Int: String] = [
        0: "NUL 空字符", 1: "SOH 标题开始", 2: "STX 正文开始", 3: "ETX 正文结束",
        4: "EOT 传输结束", 5: "ENQ 请求", 6: "ACK 确认", 7: "BEL 响铃",
        8: "BS 退格", 9: "HT 水平制表", 10: "LF 换行", 11: "VT 垂直制表",
        12: "FF 换页", 13: "CR 回车", 14: "SO 移出", 15: "SI 移入",
        16: "DLE 数据链路转义", 17: "DC1 设备控制1", 18: "DC2 设备控制2",
        19: "DC3 设备控制3", 20: "DC4 设备控制4", 21: "NAK 否认", 22: "SYN 同步",
        23: "ETB 传输块结束", 24: "CAN 取消", 25: "EM 介质结束", 26: "SUB 替换",
        27: "ESC 转义", 28: "FS 文件分隔符", 29: "GS 组分隔符",
        30: "RS 记录分隔符", 31: "US 单元分隔符", 127: "DEL 删除",
    ]

    static let all: [ASCIIEntry] = (0...127).map { v in
        let name = controlNames[v]
        let display: String
        if let n = name {
            display = n.split(separator: " ").first.map(String.init) ?? "·"
        } else if v == 32 {
            display = "␠"
        } else if let scalar = UnicodeScalar(v) {
            display = String(Character(scalar))
        } else {
            display = "·"
        }
        return ASCIIEntry(value: v, display: display, name: name)
    }
}
