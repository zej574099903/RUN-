import SwiftUI

struct MainTabView: View {
    // 将选中 Tab 提升到 State，以便子页面可以修改它
    @State private var selectedTab = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(selectedTab: $selectedTab)
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
        .accentColor(.primary)
    }
}
