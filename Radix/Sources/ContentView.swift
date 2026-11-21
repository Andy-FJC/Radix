import SwiftUI

struct ContentView: View {
    @AppStorage("radixTutorialSeen") private var tutorialSeen = false
    @State private var showTutorial = false
    @State private var tab: Int = 0

    private let tabs: [(title: String, icon: String)] = [
        ("转换", "arrow.left.arrow.right"),
        ("运算", "plusminus"),
        ("码制", "number"),
        ("字符", "textformat"),
        ("关于", "info.circle"),
    ]

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        TabView(selection: $tab) {
            ConvertView().tag(0)
            CalcView().tag(1)
            CodeView().tag(2)
            CharView().tag(3)
            AboutView(showTutorial: $showTutorial).tag(4)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            glassTabBar
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .onAppear {
            guard !tutorialSeen else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showTutorial = true
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView {
                tutorialSeen = true
            }
        }
    }

    /// iOS 毛玻璃质感浮动标签栏
    private var glassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { idx in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { tab = idx }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tabs[idx].icon)
                            .font(.system(size: 19, weight: tab == idx ? .semibold : .regular))
                        Text(tabs[idx].title)
                            .font(.system(size: 10, weight: tab == idx ? .semibold : .medium))
                    }
                    .foregroundStyle(tab == idx ? .white : Theme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(tab == idx ? Theme.green.opacity(0.20) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
        )
    }
}
