import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        // 自定义底栏样式，匹配我们的简约高级感
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("看板", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.primary) // 使用主色调作为激活颜色
    }
}

#Preview {
    MainTabView()
}
