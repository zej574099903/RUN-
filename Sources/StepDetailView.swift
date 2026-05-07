import SwiftUI
import Charts

struct StepDetailView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var animateChart = false
    @State private var selectedHour: Int? = nil // 改为 Int 型，方便匹配
    @State private var isLoading = true // 增加加载状态
    
    let goal: Double = 15500
    
    var currentSteps: Double {
        healthManager.weeklySteps.last ?? 0
    }
    
    private var selectedStepsValue: Double? {
        guard let hour = selectedHour else { return nil }
        return healthManager.hourlySteps.first { $0.hour == hour }?.steps
    }
    
    var body: some View {
        ZStack {
            MeshBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    stepsCircularHeader
                    hourlyDistributionChart
                    metricsGrid
                    achievementsShelf
                    aiMovementInsight
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
            
            // 6. 加载遮罩层
            if isLoading {
                PremiumLoadingView(message: "同步今日活跃轨迹...")
                    .transition(.opacity)
            }
        }
        .navigationTitle("步数洞察")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 模拟数据加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut) {
                    isLoading = false
                }
            }
        }
    }
    
    var stepsCircularHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: min(currentSteps / goal, 1.0))
                    .stroke(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.5, dampingFraction: 0.8), value: currentSteps)
                
                VStack(spacing: 4) {
                    Text("\(Int(currentSteps))")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                    Text("目标 \(Int(goal))")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
        }
    }
    
    var hourlyDistributionChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("活跃度分布 (小时)").font(.subheadline.bold())
                Spacer()
                if let hour = selectedHour, let value = selectedStepsValue {
                    Text("\(hour):00 : ").font(.caption).foregroundColor(.secondary) +
                    Text("\(Int(value)) 步").font(.caption.bold()).foregroundColor(.blue)
                }
            }
            
            Chart {
                ForEach(healthManager.hourlySteps, id: \.hour) { item in
                    BarMark(
                        x: .value("小时", item.hour),
                        y: .value("步数", item.steps)
                    )
                    .foregroundStyle(
                        selectedHour == item.hour ? 
                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(4)
                }
                
                if let selectedHour {
                    RuleMark(x: .value("Selected", selectedHour))
                        .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 180)
            .chartXScale(domain: 0...23) // 强制全天 24 小时
            .chartXAxis {
                AxisMarks(values: [0, 4, 8, 12, 16, 20, 23]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.gray.opacity(0.1))
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedHour)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
    }
    
    var metricsGrid: some View {
        HStack(spacing: 12) {
            StepDetailStatBox(title: "行走里程", value: String(format: "%.2f", healthManager.todayDistance), unit: "KM", icon: "figure.walk", color: .blue)
            StepDetailStatBox(title: "爬升楼层", value: "\(Int(healthManager.flightsClimbed))", unit: "层", icon: "stairs", color: .orange)
            StepDetailStatBox(title: "活跃热量", value: "\(Int(healthManager.todayCalories))", unit: "KCAL", icon: "flame.fill", color: .red)
        }
    }
    
    var achievementsShelf: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("今日成就").font(.subheadline.bold())
            HStack(spacing: 15) {
                AchievementIcon(name: "初出茅庐", icon: "star.fill", color: .yellow, isUnlocked: currentSteps > 3000)
                AchievementIcon(name: "万步达成", icon: "bolt.fill", color: .orange, isUnlocked: currentSteps > 10000)
                AchievementIcon(name: "运动狂人", icon: "crown.fill", color: .purple, isUnlocked: currentSteps > 15000)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
    }
    
    var aiMovementInsight: some View {
        HStack(spacing: 15) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI 运动分析").font(.subheadline.bold())
                Text(aiStepLogic)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(30)
    }
    
    var aiStepLogic: String {
        if currentSteps < 5000 { return "今天稍微有点偷懒哦，建议晚饭后散步 15 分钟，激活身体代谢。" }
        if currentSteps < 10000 { return "表现不错！你已经完成了基础运动量，再加把劲就能达成万步成就了。" }
        return "太棒了！你今天的运动量已经超过了 90% 的用户，继续保持这份活力！"
    }
}

struct StepDetailStatBox: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .black, design: .rounded))
                Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(.ultraThinMaterial)
        .cornerRadius(22)
    }
}

struct AchievementIcon: View {
    let name: String; let icon: String; let color: Color; let isUnlocked: Bool
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 55, height: 55)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? color : .gray.opacity(0.3))
            }
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isUnlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
