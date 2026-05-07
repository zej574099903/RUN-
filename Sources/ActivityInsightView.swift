import SwiftUI

struct ActivityInsightView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var isLoading = true
    
    private var fatBurnedGrams: Double { (healthManager.todayCalories / 9.0) }
    private var riceIncomeBowls: Double { (healthManager.todayCalories / 280.0) }
    
    var heartProgress: Double { min(healthManager.todayDistance / 5.0, 1.0) }
    var enduranceProgress: Double { min(healthManager.todayDistance / 8.0, 1.0) }
    var stressProgress: Double { min(healthManager.todayDistance / 3.0, 1.0) }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("今日战绩解析")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                HStack(spacing: 12) {
                    Label("数据源: Apple Health", systemImage: "applelogo")
                    Text("•")
                    Label("计算: RUN+ AI", systemImage: "cpu")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            
            HStack(spacing: 15) {
                BigStatCard(
                    title: "掉秤神器",
                    value: String(format: "%.1f", fatBurnedGrams),
                    unit: "克脂肪",
                    icon: "🔥",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                BigStatCard(
                    title: "饭券收入",
                    value: String(format: "%.1f", riceIncomeBowls),
                    unit: "碗米饭",
                    icon: "🍚",
                    gradient: LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("⚡️ 里程健康增益")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                    Spacer()
                    Text("\(String(format: "%.2f", healthManager.todayDistance)) KM")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(spacing: 12) {
                    PremiumInsightCard(title: "强心", subtitle: "心脏泵血效率提升", value: "+\(Int(heartProgress * 15))%", icon: "heart.fill", color: .red, progress: heartProgress)
                    PremiumInsightCard(title: "续航", subtitle: "基础代谢水平持续高燃", value: "活跃中", icon: "bolt.fill", color: .green, progress: enduranceProgress)
                    PremiumInsightCard(title: "解压", subtitle: "多巴胺分泌指数飙升", value: "巅峰期", icon: "sparkles", color: .purple, progress: stressProgress)
                }
            }
            .padding(25)
            .background(Color.white.opacity(0.4))
            .cornerRadius(35)
            .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
        }
        .padding(20)
        .overlay {
            if isLoading {
                PremiumLoadingView(message: "RUN+ AI 正在生成深度战报...")
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

struct BigStatCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let gradient: LinearGradient
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(icon).font(.system(size: 40)).shadow(radius: 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value).font(.system(size: 32, weight: .black, design: .rounded))
                    Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(gradient.opacity(0.1), lineWidth: 1))
    }
}

struct PremiumInsightCard: View {
    let title: String; let subtitle: String; let value: String; let icon: String; let color: Color; let progress: Double
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().stroke(color.opacity(0.1), lineWidth: 4)
                Circle().trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 5)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text(value).font(.system(size: 12, weight: .black, design: .rounded)).foregroundColor(color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(color.opacity(0.08)).cornerRadius(10)
        }
        .padding(12)
        .background(Color.white.opacity(0.2))
        .cornerRadius(18)
    }
}
