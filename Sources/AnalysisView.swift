import SwiftUI
import HealthKit

struct AnalysisView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var aiService = AIService.shared
    @EnvironmentObject var subManager: SubscriptionManager
    @State private var showPaywall = false
    
    private var racePredictionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("完赛潜力预测", systemImage: "timer")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.orange)
                Spacer()
                Text("基于最近一次跑步表现估算").font(.system(size: 10)).foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                PredictionItem(distance: "5 KM", time: healthManager.predicted5K, color: .green)
                PredictionItem(distance: "10 KM", time: healthManager.predicted10K, color: .blue)
                PredictionItem(distance: "半程马", time: healthManager.predictedHalf, color: .purple)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                ProFeatureWrapper(
                    title: "科学分析全家桶",
                    isLocked: !subManager.isPro,
                    onTapIfLocked: { showPaywall = true }
                ) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            headerArea
                            
                            // 1. 完赛预测
                            racePredictionSection
                            
                            // 2. AI 科学处方
                            aiCoachingPrescriptionCard
                            
                            // 3. 本周进步周报
                            weeklyReportCardContent
                            
                            // 4. 状态与疲劳趋势
                            analysisCharts
                            
                            // 5. 跑步能力模型 (雷达图)
                            radarChartView
                            
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("科学分析")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
        }
    }
    
    var headerArea: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("当前生理机能状态").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("状态：充沛").font(.system(size: 28, weight: .black, design: .rounded))
                Text("建议：尝试间歇跑").font(.system(size: 14, weight: .bold)).foregroundColor(.green)
            }
            
            // 进度条显示恢复程度
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.1)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * 0.85, height: 8)
                }
            }.frame(height: 8).padding(.vertical, 5)
            
            Text("💡 生理审计：你的 HRV（心率变异性）显示自主神经系统已完全恢复。当前心脏储备极佳，建议抓住窗口期进行一次高强度间歇跑，以有效提升最大耐力。").font(.caption).foregroundColor(.secondary).lineSpacing(4)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private var aiCoachingPrescriptionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("AI 科学处方", systemImage: "sparkles")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
                if aiService.isAnalyzing {
                    ProgressView().scaleEffect(0.8)
                }
            }
            
            Text(aiService.coachingAdvice)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(.primary.opacity(0.9))
            
            HStack(spacing: 12) {
                ActionTag(text: "夯实有氧地基", color: .blue)
                ActionTag(text: "心脏低压运行", color: .green)
            }
            
            NavigationLink(destination: HealthInsightDetailView()) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("查看深度机能诊断全文")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.purple)
                .padding(.vertical, 12)
                .padding(.horizontal, 15)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(15)
            }
        }
        .padding(25)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.purple.opacity(0.1), lineWidth: 1))
    }
    
    private var weeklyReportCardContent: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.orange.opacity(0.15), lineWidth: 8).frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: CGFloat(Double(healthManager.weeklyScore) / 100.0))
                    .stroke(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(healthManager.weeklyScore)").font(.system(size: 18, weight: .black, design: .rounded))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("本周进步周报").font(.system(size: 16, weight: .black))
                Text("运动 \(healthManager.thisWeekWorkouts.count) 次 · 跑量 \(String(format: "%.1f", healthManager.thisWeekDistance)) KM").font(.caption).foregroundColor(.secondary)
                
                let diff = healthManager.thisWeekDistance - healthManager.lastWeekDistance
                Text(diff >= 0 ? "比上周 +\(String(format: "%.1f", diff)) KM" : "比上周 -\(String(format: "%.1f", abs(diff))) KM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(diff >= 0 ? .green : .red)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary.opacity(0.5))
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    private var radarChartView: some View {
        VStack(spacing: 20) {
            Text("跑步能力模型").font(.system(size: 16, weight: .bold))
            RadarView(values: healthManager.radarValues)
                .frame(height: 200)
            HStack(spacing: 15) {
                RadarLegendItem(text: "耐力", value: String(format: "%.0f", healthManager.radarValues[0] * 100), color: .orange)
                RadarLegendItem(text: "爆发", value: String(format: "%.0f", healthManager.radarValues[1] * 100), color: .red)
                RadarLegendItem(text: "稳定性", value: String(format: "%.0f", healthManager.radarValues[2] * 100), color: .green)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    private var analysisCharts: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("状态与疲劳趋势").font(.system(size: 16, weight: .bold))
            
            VStack(spacing: 5) {
                ZStack(alignment: .bottom) {
                    TrendChartView()
                        .frame(height: 120)
                        .padding(.vertical, 10)
                    
                    // 坐标轴说明
                    HStack {
                        Text("6天前").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.5))
                        Spacer()
                        Text("3天前").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.5))
                        Spacer()
                        Text("今日").font(.system(size: 10, weight: .bold)).foregroundColor(.orange)
                    }
                    .padding(.horizontal, 5)
                    .offset(y: 15)
                }
                
                HStack(spacing: 20) {
                    LegendItem(color: .blue, text: "体能储备 (底子)")
                    LegendItem(color: .red, text: "身体疲劳 (压力)")
                }
                .padding(.top, 25)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
}

// MARK: - Reusable Components


struct LegendItem: View {
    let color: Color; let text: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct RadarLegendItem: View {
    let text: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(color)
            Text(text).font(.system(size: 10)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionTag: View {
    let text: String; let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct PredictionItem: View {
    let distance: String; let time: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Text(distance).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
            Text(time).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(color)
            
            // 小进度条模拟信心度
            Capsule().fill(color.opacity(0.1)).frame(height: 3)
                .overlay(GeometryReader { geo in Capsule().fill(color).frame(width: geo.size.width * 0.7) })
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - 绘图组件补全

struct RadarView: View {
    let values: [Double]
    var body: some View {
        ZStack {
            // 背景网格
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: CGFloat(i) * 60, height: CGFloat(i) * 60)
            }
            
            // 数据多边形
            RadarDataShape(values: values)
                .fill(LinearGradient(colors: [.orange.opacity(0.4), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom))
            
            RadarDataShape(values: values)
                .stroke(Color.orange, lineWidth: 2)
        }
    }
}

struct TrendChartView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 蓝线：体能
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.6))
                    path.addCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.3),
                                 control1: CGPoint(x: geo.size.width * 0.4, y: geo.size.height * 0.7),
                                 control2: CGPoint(x: geo.size.width * 0.6, y: geo.size.height * 0.2))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                // 红线：疲劳
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.7))
                    path.addCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.8),
                                 control1: CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.2),
                                 control2: CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.9))
                }
                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }
}


