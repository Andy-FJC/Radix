import SwiftUI

struct AboutView: View {
    @Binding var showTutorial: Bool

    private let version = "2.0.2"
    private let build = "22"
    private let repoURL = "https://github.com/Andy-FJC/Radix"

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                appIcon
                titleBlock
                infoCard
                tutorialButton
                rightsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var appIcon: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 19))
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

            HStack {
                Text("GitHub")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.dim2)
                Spacer()
                if let url = URL(string: repoURL) {
                    Link("Andy-FJC", destination: url)
                        .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.green)
                }
            }
            .padding(.vertical, 11)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
    }

    private var tutorialButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showTutorial = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("查看新手教程")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.value)
                    Text("功能说明、支持进制与内置键盘用法")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dim2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(KeypadButtonStyle())
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
                .foregroundStyle(Theme.value)
        }
        .padding(.vertical, 11)
    }
}
