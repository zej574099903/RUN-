import SwiftUI
import Charts

struct HeartRateDetailView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var animateRipple = false
    @State private var selectedDate: Date? = nil
    @State private var isLoading = true // 增加加载状态
    
    // 基础参数
    private var maxHR_Limit: Double { Double(220 - healthManager.biologicalAge) }
    private var currentHR: Double { healthManager.heartRate }
    
    // 今日统计
    private var minHR: Double { healthManager.todayHeartRateSamples.map(\.value).min() ?? 0 }
    private var maxHR_Today: Double { healthManager.todayHeartRateSamples.map(\.value).max() ?? 0 }
    private var avgHR: Double { 
        let values = healthManager.todayHeartRateSamples.map(\.value)
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
    
    var body: some View {
        ZStack {
            MeshBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // 1. 核心圆环
                    vibrantHeartHeader
                    
                    // 2. 交互趋势图
                    interactiveTrendChart
                    
                    // 3. 数据仪表盘
                    todayStatsGrid
                    
                    // 4. 重点：可视化区间频谱图 (替代原本的列表)
                    zoneSpectrumGauge
                    
                    // 5. AI 智能解读
                    aiInsightCard
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            
            // 6. 加载遮罩层
            if isLoading {
                PremiumLoadingView(message: "同步心率基准数据...")
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthManager.fetchTodayHeartRateSeries()
            
            // 模拟 AI 解析过程
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
    
    var vibrantHeartHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.05), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: currentHR / maxHR_Limit)
                    .stroke(
                        LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                        .scaleEffect(animateRipple ? 1.2 : 1.0)
                    
                    Text("\(Int(currentHR))")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("BPM").font(.caption.bold()).foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    animateRipple = true
                }
            }
        }
    }
    
    var interactiveTrendChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("趋势图").font(.subheadline.bold())
                Spacer()
                if let date = selectedDate, let value = healthManager.todayHeartRateSamples.first(where: { abs($0.date.timeIntervalSince(date)) < 300 })?.value {
                    Text("\(Int(value)) BPM").font(.caption.bold()).foregroundColor(.red)
                }
            }
            
            Chart {
                ForEach(healthManager.todayHeartRateSamples, id: \.date) { item in
                    AreaMark(x: .value("Time", item.date), y: .value("HR", item.value))
                        .foregroundStyle(LinearGradient(colors: [.red.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Time", item.date), y: .value("HR", item.value))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                }
                if let selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            .frame(height: 160)
            // 强制 X 轴覆盖全天 (0:00 - 23:59)
            .chartXScale(domain: Calendar.current.startOfDay(for: Date())...Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399))
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.gray.opacity(0.1))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let hour = Calendar.current.component(.hour, from: date)
                            Text("\(hour):00")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }

    var todayStatsGrid: some View {
        HStack(spacing: 12) {
            HRStatBox(title: "最低", value: "\(Int(minHR))", color: .blue)
            HRStatBox(title: "平均", value: "\(Int(avgHR))", color: .green)
            HRStatBox(title: "最高", value: "\(Int(maxHR_Today))", color: .orange)
        }
    }

    // 可视化区间频谱仪表盘
    var zoneSpectrumGauge: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("实时心率区间").font(.subheadline.bold())
            
            // 核心频谱条
            ZStack(alignment: .leading) {
                // 底色条 (5 段颜色)
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.4)).frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4).fill(Color.green.opacity(0.4)).frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.4)).frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.4)).frame(maxWidth: .infinity)
                }
                .frame(height: 8)
                
                // 动态指示器 (光点)
                let progress = CGFloat(max(min((currentHR - maxHR_Limit * 0.5) / (maxHR_Limit * 0.5), 1.0), 0.0))
                
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(.white)
                            .shadow(radius: 4)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .scaleEffect(1.5)
                    }
                    .frame(width: 16, height: 16)
                    .offset(x: progress * (geo.size.width - 16), y: -4)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: currentHR)
                }
                .frame(height: 8)
            }
            .padding(.top, 5)
            
            // 底部刻度
            HStack(spacing: 0) {
                ZoneLabel(name: "热身", index: 1)
                ZoneLabel(name: "燃脂", index: 2)
                ZoneLabel(name: "有氧", index: 3)
                ZoneLabel(name: "无氧", index: 4)
                ZoneLabel(name: "极限", index: 5)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
    }

    var aiInsightCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
            Text("AI 报告：今日心率波动平稳，你的心脏很有活力。")
                .font(.system(size: 14, weight: .medium))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(25)
    }
}

struct ZoneLabel: View {
    let name: String; let index: Int
    var body: some View {
        VStack(spacing: 4) {
            Text("Z\(index)").font(.system(size: 10, weight: .black, design: .rounded))
            Text(name).font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
    }
}

struct HRStatBox: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption2.bold()).foregroundColor(.secondary)
            Text(value).font(.system(size: 22, weight: .black, design: .rounded))
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
