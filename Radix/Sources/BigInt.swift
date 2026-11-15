import Foundation

/// 任意精度有符号整数，内部用「符号 + 无符号绝对值」表示。
/// 除法采用向零截断（与 C / 计算器习惯一致），余数符号跟随被除数。
struct BigInt: Equatable {

    /// -1 负数 / 0 零 / 1 正数
    private(set) var sign: Int
    private(set) var magnitude: BigUInt

    init() {
        sign = 0
        magnitude = BigUInt()
    }

    init(_ magnitude: BigUInt, negative: Bool) {
        if magnitude.isZero {
            sign = 0
            self.magnitude = BigUInt()
        } else {
            sign = negative ? -1 : 1
            self.magnitude = magnitude
        }
    }

    var isZero: Bool { sign == 0 }

    /// 解析字符串（允许前导正负号）
    static func parse(_ text: String, radix: Int) -> BigInt? {
        var body = text.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return nil }
        var negative = false
        if body.hasPrefix("-") {
            negative = true
            body.removeFirst()
        } else if body.hasPrefix("+") {
            body.removeFirst()
        }
        guard !body.isEmpty, let m = BigUInt.parse(body, radix: radix) else { return nil }
        return BigInt(m, negative: negative)
    }

    func string(radix: Int) -> String {
        guard !isZero else { return "0" }
        return (sign < 0 ? "-" : "") + magnitude.string(radix: radix)
    }

    var negated: BigInt { BigInt(magnitude, negative: sign > 0) }

    func adding(_ other: BigInt) -> BigInt {
        if isZero { return other }
        if other.isZero { return self }
        if sign == other.sign {
            return BigInt(magnitude.adding(other.magnitude), negative: sign < 0)
        }
        let c = magnitude.compare(other.magnitude)
        if c == 0 { return BigInt() }
        if c > 0 {
            let diff = magnitude.subtracting(other.magnitude) ?? BigUInt()
            return BigInt(diff, negative: sign < 0)
        }
        let diff = other.magnitude.subtracting(magnitude) ?? BigUInt()
        return BigInt(diff, negative: other.sign < 0)
    }

    func subtracting(_ other: BigInt) -> BigInt {
        adding(other.negated)
    }

    func multiplied(_ other: BigInt) -> BigInt {
        if isZero || other.isZero { return BigInt() }
        return BigInt(magnitude.multiplied(other.magnitude), negative: (sign * other.sign) < 0)
    }

    /// 整数除法（向零截断），除数为 0 返回 nil
    func divided(by other: BigInt) -> (quotient: BigInt, remainder: BigInt)? {
        guard !other.isZero else { return nil }
        guard let r = magnitude.divided(by: other.magnitude) else { return nil }
        let q = BigInt(r.quotient, negative: (sign * other.sign) < 0)
        let rem = BigInt(r.remainder, negative: sign < 0)
        return (q, rem)
    }
}
