import SwiftUI
import Charts

struct WeeklyReportView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var aiService = AIService.shared
    @Environment(\.dismiss) var dismiss
    
    // 模拟本周数据（后续对接真实 HealthKit 数据）
    private let weekScore: Double = 82
    private let lastWeekScore: Double = 76
    
    private let weeklyData: [(day: String, hr: Double, km: Double)] = [
        ("周一", 142, 0),
        ("周二", 155, 6.2),
        ("周三", 138, 0),
        ("周四", 148, 5.8),
        ("周五", 0, 0),
        ("周六", 152, 8.1),
        ("周日", 0, 0),
    ]
    
    var totalKM: Double { weeklyData.reduce(0) { $0 + $1.km } }
    var avgHR: Double {
        let active = weeklyData.filter { $0.hr > 0 }
        return active.isEmpty ? 0 : active.reduce(0) { $0 + $1.hr } / Double(active.count)
    }
    var zone2Days: Int { weeklyData.filter { $0.hr > 0 && $0.hr < 150 }.count }
    
    var weekDateRangeText: String {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日"
        return "\(fmt.string(from: weekStart)) — \(fmt.string(from: weekEnd)) 周报"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                // 1. 周报头部评分
                weekScoreHeader
                
                // 2. 四大核心数据
                coreMetricsGrid
                
                // 3. 本周心率区间趋势图
                heartRateTrendCard
                
                // 4. AI 文字报告
                aiNarrativeCard
                
                // 5. 下周训练建议
                nextWeekPlanCard
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(MeshBackgroundView())
        .navigationTitle("本周进步报告")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            generateReport()
        }
    }
    
    // MARK: - Subviews
    
    private var weekScoreHeader: some View {
        VStack(spacing: 15) {
            HStack(alignment: .center, spacing: 30) {
                // 大圆环评分
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.15), lineWidth: 14)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0, to: weekScore / 100)
                        .stroke(
                            LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(weekScore))")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                        Text("本周评分").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
                
                // 进步幅度
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("较上周").font(.caption).foregroundColor(.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Image(systemName: "arrow.up.right").font(.headline).foregroundColor(.green)
                            Text("+\(Int(weekScore - lastWeekScore)) 分")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("持续进步中 🔥")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.12))
                        .foregroundColor(.orange)
                        .cornerRadius(20)
                }
                
                Spacer()
            }
            
            // 本周日期范围
            Text(weekDateRangeText)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    private var coreMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            WeeklyMetricBox(
                icon: "figure.run",
                color: .orange,
                title: "总跑量",
                value: String(format: "%.1f", totalKM),
                unit: "KM",
                change: "+2.1 KM",
                isPositive: true
            )
            WeeklyMetricBox(
                icon: "heart.fill",
                color: .red,
                title: "平均心率",
                value: String(format: "%.0f", avgHR),
                unit: "BPM",
                change: "燃脂区间",
                isPositive: true
            )
            WeeklyMetricBox(
                icon: "flame.fill",
                color: .yellow,
                title: "总消耗",
                value: "1,842",
                unit: "千卡",
                change: "+315 千卡",
                isPositive: true
            )
            WeeklyMetricBox(
                icon: "timer",
                color: .blue,
                title: "最佳配速",
                value: "6'48\"",
                unit: "/KM",
                change: "快了 15 秒",
                isPositive: true
            )
        }
    }
    
    private var heartRateTrendCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("本周运动心率分布")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Text("有 \(zone2Days) 天保持在基础耐力区（< 150 BPM）")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Chart {
                // 基础耐力区阴影
                RuleMark(y: .value("上限", 150))
                    .foregroundStyle(Color.green.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("燃脂上限 150").font(.system(size: 9)).foregroundColor(.green)
                    }
                
                ForEach(weeklyData.filter { $0.hr > 0 }, id: \.day) { item in
                    BarMark(
                        x: .value("日期", item.day),
                        y: .value("心率", item.hr)
                    )
                    .foregroundStyle(
                        item.hr < 150
                            ? Color.green.gradient
                            : Color.orange.gradient
                    )
                    .cornerRadius(8)
                }
            }
            .frame(height: 160)
            .chartYScale(domain: 100...180)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Capsule().fill(Color.green).frame(width: 16, height: 6)
                    Text("基础耐力区").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Capsule().fill(Color.orange).frame(width: 16, height: 6)
                    Text("高强度区").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    private var aiNarrativeCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("AI 周报解读", systemImage: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.purple)
                Spacer()
                if aiService.isAnalyzing {
                    ProgressView().scaleEffect(0.7).tint(.purple)
                }
            }
            
            Text(aiService.coachingAdvice.isEmpty
                 ? "本周你共完成了 3 次有效训练，累计跑量 \(String(format: "%.1f", totalKM))KM。其中有 \(zone2Days) 次训练保持在基础耐力区，说明你的训练强度控制得很好。平均心率 \(String(format: "%.0f", avgHR)) BPM 处于理想区间，心肺系统正在高效适应当前训练负荷。继续保持这个节奏，你的马拉松破 PB 梦想正在变为现实！"
                 : aiService.coachingAdvice)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var nextWeekPlanCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("下周训练建议", systemImage: "calendar.badge.checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
            
            VStack(spacing: 10) {
                NextWeekRow(day: "周二", type: "轻松恢复跑", duration: "30 分钟", heartRate: "< 140 BPM", color: .green)
                NextWeekRow(day: "周四", type: "节奏跑", duration: "45 分钟", heartRate: "145 ~ 155 BPM", color: .orange)
                NextWeekRow(day: "周六", type: "长距离慢跑", duration: "60 分钟", heartRate: "135 ~ 148 BPM", color: .blue)
            }
            
            HStack {
                Image(systemName: "moon.zzz.fill").foregroundColor(.purple)
                Text("其余 4 天建议休息或拉伸，充分恢复")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.purple.opacity(0.06))
            .cornerRadius(12)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    // MARK: - Helpers
    
    private func generateReport() {
        let summary = "本周跑量 \(String(format: "%.1f", totalKM))KM，平均心率 \(String(format: "%.0f", avgHR)) BPM，基础耐力区训练 \(zone2Days) 次"
        aiService.fetchCoachingAdvice(steps: healthManager.weeklySteps, lastWorkout: summary)
    }
}

// MARK: - Components

struct WeeklyMetricBox: View {
    let icon: String; let color: Color; let title: String
    let value: String; let unit: String; let change: String; let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(color)
                Spacer()
                Text(change)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(isPositive ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value).font(.system(size: 24, weight: .black, design: .rounded))
                    Text(unit).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
                }
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct NextWeekRow: View {
    let day: String; let type: String; let duration: String; let heartRate: String; let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(day)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type).font(.system(size: 14, weight: .bold))
                Text("\(duration) · 心率 \(heartRate)").font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(color)
                )
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
    }
}
