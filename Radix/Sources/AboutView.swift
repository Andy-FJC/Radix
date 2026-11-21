import SwiftUI

struct AboutView: View {
    private let version = "2.0.0"
    private let build = "20"

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                appIcon
                titleBlock
                infoCard
                featuresCard
                rightsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Theme.purple, Theme.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 84, height: 84)
            Text("R")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("Radix")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("多进制转换 · 运算 · 码制 · 字符编码")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(title: "版本号", value: "v\(version)")
            DividerLine()
            infoRow(title: "Build", value: build)
            DividerLine()
            infoRow(title: "GitHub", value: "Andy-FJC")
            DividerLine()
            infoRow(title: "支持进制", value: "2 – 36")
            DividerLine()
            infoRow(title: "最低系统", value: "iOS 16.0")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(text: "功能")
            feature("转换", "2–36 进制全对照，任意进制输入")
            feature("运算", "混合进制加减乘除，超大整数不溢出")
            feature("码制", "真值 / 原码 / 反码 / 补码互转，8/16/32 位")
            feature("字符", "ASCII 全表、区位/国标/机内码、Unicode/UTF-8")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var rightsCard: some View {
        VStack(spacing: 6) {
            Text("© 2026 Andy-FJC. All Rights Reserved.")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.dim)
            Text("保留所有权利 · 未经许可不得复制、修改或分发")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.dim2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.dim2)
            Spacer()
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(title == "GitHub" ? Theme.green : Theme.value)
        }
        .padding(.vertical, 11)
    }

    private func feature(_ name: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(name)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(Theme.purple)
                .frame(width: 40, alignment: .leading)
            Text(desc)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
