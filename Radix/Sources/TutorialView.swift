import SwiftUI

/// 新手教程（文字说明版）。首次运行自动弹出，关于页可随时再次查看。
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        welcomeCard

                        SectionTitle(text: "功能一览")
                        feature("转换", "2–36 进制全部列出，输入进制后下方一次性显示全部进制结果，点任意一行即复制。")
                        feature("运算", "A、B 各自独立选进制，可直接做二进制 + 十六进制之类的混合加减乘除，超大整数不溢出。")
                        feature("码制", "真值 / 机器数 / 原码 / 反码 / 补码互转，支持 8 / 16 / 32 位，既能看表示也能反查真值。")
                        feature("字符", "ASCII 全表、汉字区位码 / 国标码 / 机内码互转、字模容量计算、Unicode 与 UTF-8。")

                        SectionTitle(text: "内置键盘")
                        feature("键盘", "全程使用 App 内置键盘，不弹系统键盘。数字键只保留当前进制合法的键，进制 ≥ 11 时自动出现字母键。⌫ 退格、C 清空、± 切换正负号。绿色描边表示当前正在输入的框。")

                        SectionTitle(text: "支持进制")
                        supportGrid
                        Text("字母标志：B=二进制 O=八进制 D=十进制 H=十六进制；其余以基数标注，如「十二进制(12)」。")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 30)
                    .padding(.bottom, 18)
                }

                finishButton
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            Text("欢迎使用 Radix")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("多进制转换 · 运算 · 码制 · 字符编码")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("这是一个纯离线的小工具，打开即用，无需联网、无需登录。")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.value)
            Text("底部有五个页签：转换、运算、码制、字符、关于。所有输入都用内置键盘完成，点结果行即可复制。")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.value)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }

    private var supportGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(2...36, id: \.self) { b in
                Text(RadixLabel.full(b))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card2))
            }
        }
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
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var finishButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onFinish()
            dismiss()
        } label: {
            Text("开始使用")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.green))
        }
        .buttonStyle(KeypadButtonStyle())
    }
}
