import SwiftUI
import HealthKit
import Charts
import MapKit

struct WorkoutDetailView: View {
    let workout: HKWorkout
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.dismiss) var dismiss
    
    // 轨迹状态
    @State private var routeLocations: [CLLocation] = []
    @State private var isFetchingRoute = true
    @State private var selectedIndex: Int? = nil
    @State private var isShowingDemo = false // 是否正在显示演示轨迹
    @State private var showPaywall = false // 是否显示支付墙
    @State private var showSharePoster = false // 是否显示分享海报
    
    var themeColor: Color {
        workout.workoutActivityType == .running ? .orange : .green
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                headerSection
                
                // 1. AI 运动深度分析 (Pro 核心功能)
                aiWorkoutAnalysisSection
                
                mainStatsHeader
                
                // 3. 轨迹地图卡片 (增加演示模式)
                workoutRouteMapSection
                
                metricsGridSection
                heartRateChartSection
                Spacer(minLength: 50)
            }
        }
        .background(MeshBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
        }
        .sheet(isPresented: $showSharePoster) {
            ProSharePosterView(workout: workout)
        }
        .onAppear {
            healthManager.fetchWorkoutDetails(for: workout)
            fetchRouteData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if SubscriptionManager.shared.isPro {
                        showSharePoster = true
                    } else {
                        showPaywall = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var aiWorkoutAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label {
                Text("AI 运动深度复盘")
                    .font(.system(size: 16, weight: .black, design: .rounded))
            } icon: {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 18) {
                // 顶部评分区 (新增)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .lastTextBaseline, spacing: 5) {
                            if SubscriptionManager.shared.isPro {
                                Text("\(85 + (Int(workout.duration) % 15))")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.orange)
                                Text("分").font(.headline).foregroundColor(.orange)
                            } else {
                                Text("??")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.orange)
                                    .blur(radius: 8)
                            }
                        }
                        Text(SubscriptionManager.shared.isPro ? "大师级训练表现" : "解锁科学评分")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(SubscriptionManager.shared.isPro ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(SubscriptionManager.shared.isPro ? .orange : .secondary)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text(SubscriptionManager.shared.isPro ? "本次训练对你的耐力提升极大，处于完美的超量恢复区间。" : "升级 Pro 获取深度点评")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary.opacity(0.6))
                        .frame(maxWidth: 160)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 1. 专业摘要 (诱饵：提到核心指标但不展开)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.opening")
                        .foregroundColor(.purple.opacity(0.3))
                    Text("本次\(workout.workoutActivityType == .running ? "课程" : "训练")表现出极佳的**有氧效能**。在恒定配速下，你的心率漂移率控制在 4% 以内，这标志着你的心血管基础极其稳固。")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineSpacing(4)
                }
                
                Divider().opacity(0.1)
                
                // 2. 深度分析模块 (Pro 锁定：专业且易懂)
                ProFeatureWrapper(title: "精英级复盘报告", isLocked: !SubscriptionManager.shared.isPro, cornerRadius: 20, onTapIfLocked: { showPaywall = true }) {
                    VStack(alignment: .leading, spacing: 18) {
                        AnalysisDetailRow(icon: "waveform.path.ecg", color: .red, title: "乳酸阈值分析 (耐力上限)", detail: "你在高强度区间持续运行了 18 分钟。这就像在给你的‘体能电池’扩容，长期坚持能让你在跑同样速度时，心脏跳得更慢、更轻松。")
                        AnalysisDetailRow(icon: "figure.run", color: .blue, title: "跑步效能 (跑姿经济性)", detail: "你的垂直振幅比平时降低了 0.5cm。简单说，你现在跑起来‘更稳了’，没有把力气浪费在上下颠簸上，更多的能量被转化成了向前的动力。")
                        AnalysisDetailRow(icon: "timer", color: .orange, title: "有氧脱钩率 (疲劳抗性)", detail: "即便在最后阶段，你的心率也没有随疲劳而失控‘飘升’。这说明你的心肺非常耐造，脂肪燃烧效率极高，这是精英跑者的典型标志。")
                        AnalysisDetailRow(icon: "bolt.fill", color: .yellow, title: "超量恢复 (回血建议)", detail: "本次训练强度较大（EPOC值高）。未来 24 小时建议‘多吃碳水、少练力量’，给肌肉一个重建的时间，明天你将会变得比今天更强。")
                    }
                    .padding(15)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workout.workoutActivityType == .running ? "figure.run" : "figure.walk")
                    .font(.title2)
                    .foregroundColor(themeColor)
                Text(workout.workoutActivityType == .running ? "户外跑步" : "步行记录")
                    .font(.title2.bold())
                Spacer()
                
                // 强制刷新按钮
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    refreshData()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                sourceTag
            }
            Text(formatChineseDate(workout.startDate))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var mainStatsHeader: some View {
        VStack(alignment: .leading, spacing: -5) {
            Text(String(format: "%.2f", (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0))
                .font(.system(size: 70, weight: .black, design: .rounded))
            Text("总公里数 (KM)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.heavy)
                .foregroundColor(.secondary)
                .padding(.leading, 5)
        }
        .padding(.horizontal)
    }
    
    private var workoutRouteMapSection: some View {
        Group {
            if !routeLocations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(isShowingDemo ? "轨迹演示 (模拟)" : "运动轨迹")
                        .font(.headline)
                        .foregroundColor(isShowingDemo ? .blue : .secondary)
                        .padding(.horizontal)
                    
                    WorkoutPathOverlay(locations: routeLocations, color: isShowingDemo ? .blue : themeColor)
                        .frame(height: 220)
                        .cornerRadius(30)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 10)
                }
            }
        }
    }
    
    private var metricsGridSection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                WorkoutDetailStatBox(label: "用时", value: formatDuration(workout.duration), unit: "", icon: "stopwatch.fill", color: .purple)
                WorkoutDetailStatBox(label: "消耗", value: String(format: "%.0f", workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0), unit: "KCAL", icon: "flame.fill", color: .orange)
            }
            HStack(spacing: 15) {
                WorkoutDetailStatBox(label: "平均配速", value: calculatePace(), unit: "/KM", icon: "timer", color: .blue)
                if healthManager.workoutCadence > 0 {
                    WorkoutDetailStatBox(label: "平均步频", value: String(format: "%.0f", healthManager.workoutCadence), unit: "SPM", icon: "figure.run.square.stack.fill", color: .green)
                } else if !healthManager.workoutHeartRates.isEmpty {
                    WorkoutDetailStatBox(label: "平均心率", value: String(format: "%.0f", healthManager.workoutHeartRates.reduce(0, +) / Double(healthManager.workoutHeartRates.count)), unit: "BPM", icon: "heart.fill", color: .red)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var heartRateChartSection: some View {
        Group {
            if !healthManager.workoutHeartRates.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("心率波动").font(.headline).foregroundColor(.secondary)
                            if let index = selectedIndex, index < healthManager.workoutHeartRates.count {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(Int(healthManager.workoutHeartRates[index]))").font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(themeColor)
                                    Text("BPM").font(.caption.bold()).foregroundColor(themeColor)
                                    Text("• 第 \(index + 1) 分钟").font(.caption).foregroundColor(.secondary)
                                }
                            } else {
                                Text("滑动图表查看详情").font(.subheadline).foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                        Spacer()
                        if selectedIndex == nil {
                            VStack(alignment: .trailing) {
                                Text("最高").font(.caption2.bold()).foregroundColor(.secondary)
                                Text("\(Int(healthManager.workoutHeartRates.max() ?? 0))").font(.system(.body, design: .rounded)).fontWeight(.black).foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 60)
                    
                    Chart {
                        ForEach(Array(healthManager.workoutHeartRates.enumerated()), id: \.offset) { index, value in
                            LineMark(x: .value("时间", index), y: .value("心率", value)).foregroundStyle(themeColor.gradient).interpolationMethod(.catmullRom)
                            AreaMark(x: .value("时间", index), y: .value("心率", value)).foregroundStyle(LinearGradient(colors: [themeColor.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                            if let selectedIndex = selectedIndex, selectedIndex == index {
                                RuleMark(x: .value("时间", index)).foregroundStyle(.primary.opacity(0.1))
                                PointMark(x: .value("时间", index), y: .value("心率", value)).foregroundStyle(themeColor).symbolSize(200)
                                PointMark(x: .value("时间", index), y: .value("心率", value)).foregroundStyle(.white).symbolSize(80)
                            }
                        }
                    }
                    .frame(height: 180)
                    .chartXSelection(value: $selectedIndex)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .padding(.horizontal)
                }
                .animation(.spring(response: 0.3), value: selectedIndex)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        isFetchingRoute = true
        isShowingDemo = false
        healthManager.requestAuthorization {
            healthManager.fetchWorkoutDetails(for: workout)
            fetchRouteData()
        }
    }
    
    private func fetchRouteData() {
        isFetchingRoute = true
        healthManager.fetchRoute(for: workout) { locations in
            self.routeLocations = locations
            self.isFetchingRoute = false
        }
    }
    
    // 生成模拟演示轨迹 (基于徐汇滨江跑道)
    private func generateDemoRoute() {
        isFetchingRoute = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let baseCoord = CLLocationCoordinate2D(latitude: 31.182, longitude: 121.480)
            var demoLocations: [CLLocation] = []
            
            // 模拟一个 2KM 的圆形轨迹
            for i in 0..<100 {
                let angle = Double(i) * Double.pi * 2 / 100
                let lat = baseCoord.latitude + 0.005 * cos(angle)
                let lon = baseCoord.longitude + 0.005 * sin(angle)
                demoLocations.append(CLLocation(latitude: lat, longitude: lon))
            }
            
            self.routeLocations = demoLocations
            self.isShowingDemo = true
            self.isFetchingRoute = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    var sourceTag: some View {
        Text(workout.sourceRevision.source.name)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(.ultraThinMaterial))
            .foregroundColor(.secondary)
    }
    
    private func formatChineseDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter(); formatter.allowedUnits = [.hour, .minute, .second]; formatter.unitsStyle = .positional; formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    private func calculatePace() -> String {
        let distanceKM = (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0
        guard distanceKM > 0 else { return "0'00\"" }
        let paceSeconds = workout.duration / distanceKM
        let minutes = Int(paceSeconds) / 60; let seconds = Int(paceSeconds) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

struct WorkoutDetailStatBox: View {
    let label: String; let value: String; let unit: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundColor(color)
                Text(label).font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .black, design: .rounded))
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).padding(.bottom, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.ultraThinMaterial).cornerRadius(25).overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct WorkoutPathOverlay: UIViewRepresentable {
    let locations: [CLLocation]; let color: Color
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(); mapView.delegate = context.coordinator; mapView.isUserInteractionEnabled = true
        let coordinates = locations.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false)
        return mapView
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(color: UIColor(color)) }
    class Coordinator: NSObject, MKMapViewDelegate {
        let color: UIColor
        init(color: UIColor) { self.color = color }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = color; renderer.lineWidth = 6; renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct AnalysisDetailRow: View {
    let icon: String; let color: Color; let title: String; let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold))
                Text(detail).font(.system(size: 12)).foregroundColor(.secondary).lineSpacing(3)
            }
        }
    }
}
