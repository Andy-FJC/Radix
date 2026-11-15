import Foundation

/// 任意精度无符号整数（32 位 limb，小端存储：limbs[0] 是低位）。
/// 支持加减乘除与任意进制解析/输出，用于超大整数的四则运算。
struct BigUInt: Equatable {

    /// 空的 limbs 表示 0
    private var limbs: [UInt32] = []

    init() {}

    init(_ value: UInt64) {
        guard value > 0 else { return }
        limbs = [UInt32(value & 0xFFFF_FFFF)]
        let high = UInt32((value >> 32) & 0xFFFF_FFFF)
        if high > 0 { limbs.append(high) }
    }

    init(limbs: [UInt32]) {
        var l = limbs
        while let last = l.last, last == 0 { l.removeLast() }
        self.limbs = l
    }

    var isZero: Bool { limbs.isEmpty }

    /// 二进制位数（0 返回 0）
    var bitLength: Int {
        guard let last = limbs.last else { return 0 }
        return (limbs.count - 1) * 32 + (32 - last.leadingZeroBitCount)
    }

    func bit(at index: Int) -> Bool {
        guard index >= 0 else { return false }
        let limbIndex = index >> 5
        guard limbIndex < limbs.count else { return false }
        return ((limbs[limbIndex] >> UInt32(index & 31)) & 1) == 1
    }

    // MARK: - 解析

    /// 把字符串按指定进制解析为数值。非法字符返回 nil。
    static func parse(_ text: String, radix: Int) -> BigUInt? {
        guard radix >= 2, radix <= 36 else { return nil }
        var value = BigUInt()
        let r = UInt64(radix)
        for ch in text.uppercased() {
            guard let d = digitValue(ch), d < radix else { return nil }
            value = value.multiplied(bySmall: r)
            value = value.adding(small: UInt64(d))
        }
        return value
    }

    static func digitValue(_ c: Character) -> Int? {
        guard let s = c.unicodeScalars.first else { return nil }
        switch s.value {
        case 48...57:  return Int(s.value - 48)   // 0-9
        case 65...90:  return Int(s.value - 55)   // A-Z
        case 97...122: return Int(s.value - 87)   // a-z
        default:       return nil
        }
    }

    // MARK: - 比较

    /// -1 小于 / 0 相等 / 1 大于
    func compare(_ other: BigUInt) -> Int {
        if limbs.count != other.limbs.count {
            return limbs.count < other.limbs.count ? -1 : 1
        }
        var i = limbs.count - 1
        while i >= 0 {
            if limbs[i] != other.limbs[i] {
                return limbs[i] < other.limbs[i] ? -1 : 1
            }
            if i == 0 { break }
            i -= 1
        }
        return 0
    }

    // MARK: - 四则运算

    func adding(_ other: BigUInt) -> BigUInt {
        if other.isZero { return self }
        if isZero { return other }
        let n = max(limbs.count, other.limbs.count)
        var out: [UInt32] = []
        out.reserveCapacity(n + 1)
        var carry: UInt64 = 0
        for i in 0..<n {
            let a: UInt64 = i < limbs.count ? UInt64(limbs[i]) : 0
            let b: UInt64 = i < other.limbs.count ? UInt64(other.limbs[i]) : 0
            let sum = a + b + carry
            out.append(UInt32(sum & 0xFFFF_FFFF))
            carry = sum >> 32
        }
        if carry > 0 { out.append(UInt32(carry)) }
        return BigUInt(limbs: out)
    }

    /// 减法；若 self < other 返回 nil（无符号不支持负结果）
    func subtracting(_ other: BigUInt) -> BigUInt? {
        if other.isZero { return self }
        guard compare(other) >= 0 else { return nil }
        var out: [UInt32] = []
        out.reserveCapacity(limbs.count)
        var borrow: Int64 = 0
        for i in 0..<limbs.count {
            let a = Int64(limbs[i])
            let b = i < other.limbs.count ? Int64(other.limbs[i]) : 0
            var diff = a - b - borrow
            if diff < 0 {
                diff += 0x1_0000_0000
                borrow = 1
            } else {
                borrow = 0
            }
            out.append(UInt32(diff))
        }
        return BigUInt(limbs: out)
    }

    func multiplied(_ other: BigUInt) -> BigUInt {
        if isZero || other.isZero { return BigUInt() }
        var out = [UInt64](repeating: 0, count: limbs.count + other.limbs.count + 1)
        for i in 0..<limbs.count {
            var carry: UInt64 = 0
            let a = UInt64(limbs[i])
            for j in 0..<other.limbs.count {
                let cur = out[i + j] + a * UInt64(other.limbs[j]) + carry
                out[i + j] = cur & 0xFFFF_FFFF
                carry = cur >> 32
            }
            var k = i + other.limbs.count
            while carry > 0 {
                let cur = out[k] + carry
                out[k] = cur & 0xFFFF_FFFF
                carry = cur >> 32
                k += 1
            }
        }
        return BigUInt(limbs: out.map { UInt32($0 & 0xFFFF_FFFF) })
    }

    /// 长除法（逐位试商）。除数为 0 时返回 nil。
    func divided(by other: BigUInt) -> (quotient: BigUInt, remainder: BigUInt)? {
        guard !other.isZero else { return nil }
        if compare(other) < 0 { return (BigUInt(), self) }

        var q = [UInt32](repeating: 0, count: limbs.count)
        var r = BigUInt()
        var i = bitLength - 1
        while i >= 0 {
            r = r.shiftedLeftOne()
            if bit(at: i) { r = r.adding(small: 1) }
            if r.compare(other) >= 0 {
                r = r.subtracting(other) ?? BigUInt()
                q[i >> 5] |= UInt32(1) << UInt32(i & 31)
            }
            i -= 1
        }
        return (BigUInt(limbs: q), r)
    }

    // MARK: - 小整数辅助（解析与输出用）

    private func multiplied(bySmall m: UInt64) -> BigUInt {
        if limbs.isEmpty || m == 0 { return BigUInt() }
        var out: [UInt32] = []
        out.reserveCapacity(limbs.count + 2)
        var carry: UInt64 = 0
        for l in limbs {
            let product = UInt64(l) * m + carry
            out.append(UInt32(product & 0xFFFF_FFFF))
            carry = product >> 32
        }
        while carry > 0 {
            out.append(UInt32(carry & 0xFFFF_FFFF))
            carry >>= 32
        }
        return BigUInt(limbs: out)
    }

    private func adding(small a: UInt64) -> BigUInt {
        if a == 0 { return self }
        var out = limbs.isEmpty ? [UInt32(0)] : limbs
        var carry = a
        var i = 0
        while carry > 0 {
            if i < out.count {
                let sum = UInt64(out[i]) + carry
                out[i] = UInt32(sum & 0xFFFF_FFFF)
                carry = sum >> 32
            } else {
                out.append(UInt32(carry & 0xFFFF_FFFF))
                carry >>= 32
            }
            i += 1
        }
        return BigUInt(limbs: out)
    }

    private func shiftedLeftOne() -> BigUInt {
        if limbs.isEmpty { return BigUInt() }
        var out = [UInt32](repeating: 0, count: limbs.count)
        var carry: UInt32 = 0
        for i in 0..<limbs.count {
            out[i] = (limbs[i] << 1) | carry
            carry = limbs[i] >> 31
        }
        if carry > 0 { out.append(carry) }
        return BigUInt(limbs: out)
    }

    /// 除以一个小整数，返回（商，余数）
    private func divided(bySmall d: UInt32) -> (quotient: BigUInt, remainder: UInt32) {
        guard !limbs.isEmpty, d > 0 else { return (BigUInt(), 0) }
        var q = [UInt32](repeating: 0, count: limbs.count)
        var rem: UInt64 = 0
        var i = limbs.count - 1
        while i >= 0 {
            let cur = (rem << 32) | UInt64(limbs[i])
            q[i] = UInt32(cur / UInt64(d))
            rem = cur % UInt64(d)
            if i == 0 { break }
            i -= 1
        }
        return (BigUInt(limbs: q), UInt32(rem))
    }

    // MARK: - 输出

    /// 转成指定进制的字符串（大写字母）
    func string(radix: Int) -> String {
        guard radix >= 2, radix <= 36 else { return "" }
        if isZero { return "0" }
        let digits = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var current = self
        var out: [Character] = []
        while !current.isZero {
            let (q, r) = current.divided(bySmall: UInt32(radix))
            out.append(digits[Int(r)])
            current = q
        }
        return String(out.reversed())
    }
}
