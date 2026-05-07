import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var aiService = AIService.shared
    @StateObject private var subManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // 0. AI 进步周报入口
                        weeklyReportEntryCard
                        
                        // 1. AI 科学指导 (聚焦心率与健康)
                        aiHeartRateInsightCard
                        
                        // 2. 心率训练区间分布 (核心模块：MAF180/Zone 2 引导)
                        heartRateZonesDistributionCard
                        
                        // 3. 跑者核心健康网格 (2x2 专业指标)
                        runnersHealthGrid
                        
                        // 4. 跑步效能趋势 (配速 vs 心率)
                        runningEfficiencyTrendCard
                        
                        // 5. Pro 专属功能（锁定）
                        if !subManager.isPro {
                            proLockedSection
                        }
                        
                        Spacer(minLength: 120)

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("科学分析")
            .onAppear {
                fetchAIData()
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
        }
    }
    
    // MARK: - 周报入口卡片
    
    var weeklyReportEntryCard: some View {
        Group {
            if subManager.isPro {
                // Pro 用户：可点击进入详情
                NavigationLink(destination: WeeklyReportView()) {
                    weeklyReportCardContent
                }
            } else {
                // 免费用户：模糊锁定状态
                ZStack {
                    weeklyReportCardContent
                        .blur(radius: 4)
                        .allowsHitTesting(false)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title)
                            .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        Text("解锁周报功能")
                            .font(.system(size: 15, weight: .black))
                        Text("升级 Pro 可查看完整周报")
                            .font(.caption).foregroundColor(.secondary)
                        Button(action: { showPaywall = true }) {
                            Text("立即解锁")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20).padding(.vertical, 8)
                                .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(20)
                        }
                    }
                }
                .clipped()
                .cornerRadius(30)
            }
        }
    }
    
    private var weeklyReportCardContent: some View {
        HStack(spacing: 16) {
            // 圆环预览
            ZStack {
                Circle().stroke(Color.orange.opacity(0.15), lineWidth: 8).frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: 0.82)
                    .stroke(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("82").font(.system(size: 18, weight: .black, design: .rounded))
                    Text("分").font(.system(size: 8)).foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("本周进步周报")
                        .font(.system(size: 16, weight: .black))
                    if subManager.isPro {
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                }
                Text("运动 3 次 · 跑量 20.1 KM · 消耗 1,842 千卡")
                    .font(.caption).foregroundColor(.secondary)
                HStack {
                    Text("比上周 +6 分").font(.system(size: 11, weight: .black)).foregroundColor(.green)
                    Text("· 持续进步中 🔥").font(.system(size: 11)).foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }
    
    private func fetchAIData() {
        let lastWorkout = healthManager.workouts.first.map { 
            "\($0.workoutActivityType == .running ? "跑步" : "步行")，距离 \(String(format: "%.2f", ($0.totalDistance?.doubleValue(for: .meter()) ?? 0)/1000))KM，时长 \(Int($0.duration/60))分钟"
        } ?? "最近暂无运动记录"
        
        aiService.fetchCoachingAdvice(steps: healthManager.weeklySteps, lastWorkout: lastWorkout)
    }
    
    // MARK: - Subviews
    
    var aiHeartRateInsightCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("科学跑建议")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                Spacer()
                if aiService.isAnalyzing {
                    ProgressView().scaleEffect(0.8)
                }
            }
            
            Text(aiService.coachingAdvice)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                Text("状态：").font(.caption).foregroundColor(.secondary)
                Text("基础耐力提升中").font(.caption.bold()).foregroundColor(.green)
                Spacer()
                NavigationLink(destination: HealthInsightDetailView()) {
                    Text("查看详情")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    var heartRateZonesDistributionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("心率训练区间分布")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Text("近 7 天累计运动时长占比").font(.caption).foregroundColor(.secondary)
            }
            
            Chart {
                let zones = [
                    (name: "热身", val: 15, color: Color.blue),
                    (name: "燃脂", val: 45, color: Color.green),
                    (name: "有氧", val: 25, color: Color.yellow),
                    (name: "无氧", val: 10, color: Color.orange),
                    (name: "极限", val: 5, color: Color.red)
                ]
                
                ForEach(zones, id: \.name) { zone in
                    BarMark(
                        x: .value("时长", zone.val),
                        stacking: .normalized
                    )
                    .foregroundStyle(zone.color.gradient)
                    .cornerRadius(5)
                }
            }
            .frame(height: 35)
            .chartXAxis(.hidden)
            
            // 区间详细图解
            HStack(spacing: 0) {
                ZoneLegend(name: "基础耐力区", percentage: "45%", color: .green)
                Spacer()
                ZoneLegend(name: "强度训练区", percentage: "40%", color: .orange)
                Spacer()
                ZoneLegend(name: "热身恢复区", percentage: "15%", color: .blue)
            }
            
            Text("建议：保持 70% 以上的时间在基础耐力区，能最有效地提高心脏耐力，同时减少运动损伤风险。")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    var runnersHealthGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            AnalysisMetricBox(title: "最大摄氧量", value: "48.2", unit: "ml/kg", icon: "lungs.fill", color: .blue, trend: "+1.2")
            AnalysisMetricBox(title: "静息心率", value: "58", unit: "BPM", icon: "heart.fill", color: .red, trend: "-2")
            AnalysisMetricBox(title: "心脏恢复率", value: "32", unit: "BPM", icon: "waveform.path.ecg", color: .orange, trend: "稳定")
            AnalysisMetricBox(title: "训练负荷", value: "342", unit: "中等", icon: "bolt.fill", color: .purple, trend: "正常")
        }
    }
    
    var runningEfficiencyTrendCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("跑步效能趋势")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Text("同样心率下的配速表现").font(.caption).foregroundColor(.secondary)
            }
            
            Chart {
                // 模拟效能增长数据
                let data = [
                    (d: "1周前", v: 1.0),
                    (d: "5天前", v: 1.05),
                    (d: "3天前", v: 1.03),
                    (d: "昨天", v: 1.12),
                ]
                
                ForEach(data, id: \.d) { item in
                    LineMark(x: .value("日期", item.d), y: .value("效能", item.v))
                        .foregroundStyle(Color.blue.gradient)
                        .symbol(Circle())
                        .interpolationMethod(.catmullRom)
                    
                    AreaMark(x: .value("日期", item.d), y: .value("效能", item.v))
                        .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
            .frame(height: 150)
            .chartYAxis(.hidden)
            
            HStack {
                Text("你的跑步经济性比上月提升了").font(.subheadline).foregroundColor(.secondary)
                Text("8.4%").font(.subheadline.bold()).foregroundColor(.blue)
                Spacer()
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
    
    // MARK: - Pro 锁定区域
    
    var proLockedSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                Text("Pro 专属功能").font(.system(size: 18, weight: .black))
                Spacer()
            }
            
            LockedFeatureCard(icon: "chart.line.uptrend.xyaxis", color: .blue, title: "AI 进步周报", description: "每周一自动生成你的体能进步分析", onUnlock: { showPaywall = true })
            LockedFeatureCard(icon: "figure.run.circle.fill", color: .orange, title: "个性化训练计划", description: "AI 根据心率数据制定专属计划", onUnlock: { showPaywall = true })
            LockedFeatureCard(icon: "message.badge.waveform.fill", color: .purple, title: "AI 跳步教练对话", description: "24小时随时提问，AI 读取你的数据回答", onUnlock: { showPaywall = true })
            
            Button(action: { showPaywall = true }) {
                HStack {
                    Image(systemName: "crown.fill").font(.system(size: 14))
                    Text("解锁全部 Pro 功能").font(.system(size: 16, weight: .black))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(18)
                .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
}

struct LockedFeatureCard: View {
    let icon: String; let color: Color; let title: String; let description: String; let onUnlock: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.primary.opacity(0.4))
                Text(description).font(.system(size: 12)).foregroundColor(.secondary.opacity(0.5))
            }
            Spacer()
            Image(systemName: "lock.fill").font(.system(size: 14)).foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .onTapGesture { onUnlock() }
    }
}

// MARK: - Helper Components

struct ZoneLegend: View {
    let name: String
    let percentage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
            }
            Text(percentage).font(.system(size: 16, weight: .black, design: .rounded))
        }
    }
}

struct AnalysisMetricBox: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color; let trend: String
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 14, weight: .bold))
                Spacer()
                Text(trend).font(.system(size: 11, weight: .black)).foregroundColor(trend.contains("-") || trend == "正常" || trend == "稳定" ? .green : .orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 26, weight: .black, design: .rounded))
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
                Text(unit).font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
            }
        }.padding(20).background(.ultraThinMaterial).cornerRadius(25)
    }
}
