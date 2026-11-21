import SwiftUI

struct ContentView: View {
    @State private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            ConvertView()
                .tabItem {
                    Label("转换", systemImage: "arrow.left.arrow.right")
                }
                .tag(0)

            CalcView()
                .tabItem {
                    Label("运算", systemImage: "plusminus")
                }
                .tag(1)

            CodeView()
                .tabItem {
                    Label("码制", systemImage: "number")
                }
                .tag(2)

            CharView()
                .tabItem {
                    Label("字符", systemImage: "textformat")
                }
                .tag(3)

            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
                .tag(4)
        }
        .tint(Theme.green)
    }
}
