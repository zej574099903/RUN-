import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // 1. 实时 AI 运动见解 (字体加大)
                        aiInsightCard
                        
                        // 2. 本周步数趋势 (增加数值标注)
                        weeklyStepsChart
                        
                        // 3. 核心专业指标 (2x2 网格，优化显示)
                        professionalMetricsGrid
                        
                        // 4. 运动比例分布 (放大环形图和文本)
                        activityDistributionCard
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("数据分析")
            .onAppear {
                fetchAIData()
            }
        }
    }
    
    private func fetchAIData() {
        let lastWorkout = healthManager.workouts.first.map { 
            "\($0.workoutActivityType == .running ? "跑步" : "步行")，距离 \(String(format: "%.2f", ($0.totalDistance?.doubleValue(for: .meter()) ?? 0)/1000))KM，时长 \(Int($0.duration/60))分钟"
        } ?? "最近暂无运动记录"
        
        aiService.fetchCoachingAdvice(steps: healthManager.weeklySteps, lastWorkout: lastWorkout)
    }
    
    var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("AI 运动见解", systemImage: "sparkles")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
                if aiService.isAnalyzing {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button(action: fetchAIData) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(aiService.coachingAdvice)
                .font(.system(size: 16, design: .rounded)) // 字号从 13 提升到 16
                .fontWeight(.medium)
                .lineSpacing(6)
                .foregroundColor(.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    var weeklyStepsChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("周步数趋势")
                .font(.system(size: 20, weight: .black, design: .rounded))
            
            Chart {
                ForEach(Array(healthManager.weeklySteps.enumerated()), id: \.offset) { index, steps in
                    BarMark(x: .value("天", "D\(index + 1)"), y: .value("步数", steps))
                        .foregroundStyle(steps > 8000 ? Color.orange.gradient : Color.blue.gradient)
                        .cornerRadius(8)
                }
                RuleMark(y: .value("目标", 10000)).foregroundStyle(.secondary.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) { 
                        Text("目标 10k")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary) 
                    }
            }
            .frame(height: 200)
            .padding(.top, 10)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    var professionalMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            AnalysisMetricBox(title: "最大摄氧量", value: "48.2", unit: "ml/kg/min", icon: "lungs.fill", color: .blue, trend: "+1.2")
            AnalysisMetricBox(title: "静息心率", value: "58", unit: "BPM", icon: "heart.fill", color: .red, trend: "-2")
            AnalysisMetricBox(title: "平均心率恢复", value: "32", unit: "BPM", icon: "waveform.path.ecg", color: .orange, trend: "稳定")
            AnalysisMetricBox(title: "睡眠时长", value: "7.5", unit: "小时", icon: "bed.double.fill", color: .purple, trend: "+0.5")
        }
    }
    
    var activityDistributionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("运动比例分配")
                .font(.system(size: 20, weight: .black, design: .rounded))
            
            HStack(spacing: 35) {
                ZStack {
                    Circle().stroke(Color.green.opacity(0.1), lineWidth: 20)
                    Circle().trim(from: 0, to: 0.7).stroke(Color.orange.gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack { 
                        Text("70%")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("跑步")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary) 
                    }
                }.frame(width: 110, height: 110)
                
                VStack(alignment: .leading, spacing: 15) {
                    DistributionRow(label: "户外跑步", color: .orange, value: "12.4 KM")
                    DistributionRow(label: "日常步行", color: .green, value: "45.8 KM")
                    DistributionRow(label: "其他运动", color: .blue, value: "2.5 小时")
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
}

struct AnalysisMetricBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 14, weight: .bold))
                Spacer()
                Text(trend).font(.system(size: 11, weight: .black)).foregroundColor(trend.contains("-") || trend == "稳定" ? .green : .orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 26, weight: .black, design: .rounded))
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            }
        }.padding(20).background(.ultraThinMaterial).cornerRadius(25)
    }
}

struct DistributionRow: View {
    let label: String
    let color: Color
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: .black))
        }
    }
}
