import SwiftUI
import HealthKit

struct ProSharePosterView: View {
    let workout: HKWorkout
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var renderedImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 1. 预览区域 (增加滚动预览，因为图变长了)
                    if let image = renderedImage {
                        ScrollView(showsIndicators: false) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(15)
                                .padding(.horizontal, 50)
                                .shadow(color: .orange.opacity(0.1), radius: 20)
                        }
                    } else {
                        VStack(spacing: 20) {
                            ProgressView().tint(.orange)
                            Text("正在生成超高清精英海报...").foregroundColor(.secondary).font(.caption)
                        }
                    }
                    
                    Text("Pro 会员专享：高阶数据长图")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Spacer()
                    
                    // 2. 操作按钮
                    HStack(spacing: 20) {
                        Button(action: { dismiss() }) {
                            Text("返回")
                                .foregroundColor(.white)
                                .frame(width: 100, height: 50)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                        }
                        
                        Button(action: { saveImage() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("保存专业海报")
                            }
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("精英分享")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 延迟渲染，确保 UI 加载完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    renderPoster()
                }
            }
        }
    }
    
    @MainActor
    private func renderPoster() {
        let poster = PosterContentView(workout: workout, healthManager: healthManager)
        let renderer = ImageRenderer(content: poster)
        renderer.scale = UIScreen.main.scale * 1.5 // 极高清晰度
        if let uiImage = renderer.uiImage {
            self.renderedImage = uiImage
        }
    }
    
    private func saveImage() {
        guard let image = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        dismiss()
    }
}

// MARK: - 究极版海报模板
struct PosterContentView: View {
    let workout: HKWorkout
    let healthManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部身份卡 (身份象征)
            headerSection
            
            // 2. 核心大数区 (视觉中心)
            coreMetricsSection
            
            // 3. 跑步能力雷达 (专业证明)
            radarChartSection
            
            // 5. 进阶数据矩阵 (硬核支撑)
            advancedGridSection
            
            // 6. AI 精英复盘建议 (智慧结晶)
            aiEliteInsightSection
            
            // 7. 底部品牌 (调性收尾)
            footerSection
        }
        .frame(width: 400) // 稍宽一点，气场更足
        .background(Color(red: 0.05, green: 0.05, blue: 0.08))
    }
    
    // MARK: - 各板块实现
    
    private var headerSection: some View {
        HStack(spacing: 20) {
            healthManager.getUserAvatar(size: 80)
                .overlay(Circle().stroke(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom), lineWidth: 3))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(healthManager.nickname).font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.orange).font(.caption)
                }
                Text("RUNPLUS PRO ELITE").font(.system(size: 12, weight: .black)).foregroundColor(.orange).tracking(2)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("2026 / 02 / 11").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.6))
                Text("19:39 PM").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(35)
    }
    
    private var coreMetricsSection: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text("距离").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.4))
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(String(format: "%.2f", (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0)).font(.system(size: 64, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("KM").font(.system(size: 18, weight: .bold)).foregroundColor(.white.opacity(0.4))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                ZStack {
                    Circle().stroke(Color.orange.opacity(0.2), lineWidth: 4).frame(width: 80, height: 80)
                    VStack(spacing: 0) {
                        Text("\(healthManager.weeklyScore)").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.orange)
                        Text("AI 评分").font(.system(size: 10, weight: .bold)).foregroundColor(.orange.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 35)
        .padding(.bottom, 30)
    }
    
    private var radarChartSection: some View {
        VStack(spacing: 20) {
            HStack {
                Rectangle().fill(Color.orange).frame(width: 4, height: 15)
                Text("跑步能力模型").font(.system(size: 14, weight: .black)).foregroundColor(.white)
                Spacer()
            }
            
            ZStack {
                // 1. 背景网格
                Image(systemName: "pentagon").font(.system(size: 120)).foregroundColor(.white.opacity(0.1))
                Image(systemName: "pentagon").font(.system(size: 80)).foregroundColor(.white.opacity(0.05))
                Image(systemName: "pentagon").font(.system(size: 40)).foregroundColor(.white.opacity(0.05))
                
                // 2. 真实数据多边形
                RadarDataShape(values: healthManager.radarValues)
                    .fill(LinearGradient(colors: [.orange.opacity(0.6), .yellow.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                
                RadarDataShape(values: healthManager.radarValues)
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                // 维度标签
                Group {
                    RadarLabel(text: "耐力", x: 0, y: -75)
                    RadarLabel(text: "爆发", x: 75, y: -25)
                    RadarLabel(text: "稳定", x: 45, y: 60)
                    RadarLabel(text: "恢复", x: -45, y: 60)
                    RadarLabel(text: "配速", x: -75, y: -25)
                }
            }
            .frame(height: 160)
        }
        .padding(35)
        .background(Color.white.opacity(0.02))
    }
    
    private var advancedGridSection: some View {
        VStack(spacing: 25) {
            HStack {
                PosterMetricGridItem(label: "平均配速", value: formatPace(workout.duration / ((workout.totalDistance?.doubleValue(for: .meter()) ?? 1) / 1000.0)), unit: "/KM")
                PosterMetricGridItem(label: "平均步频", value: "182", unit: "SPM")
                PosterMetricGridItem(label: "平均步幅", value: "1.02", unit: "M")
            }
            HStack {
                PosterMetricGridItem(label: "累计消耗", value: String(format: "%.0f", workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0), unit: "KCAL")
                PosterMetricGridItem(label: "平均心率", value: "148", unit: "BPM")
                PosterMetricGridItem(label: "最大心率", value: "172", unit: "BPM")
            }
        }
        .padding(35)
    }
    
    private func formatPace(_ secondsPerKm: Double) -> String {
        let mins = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%02d'%02d\"", mins, secs)
    }
    
    private var aiEliteInsightSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(.purple)
                Text("AI 精英级复盘报告").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 20) {
                PosterInsightItem(icon: "bolt.heart.fill", color: .red, title: "乳酸阈值分析 (耐力上限)", detail: "本次训练对你的‘体能电池’扩容效果显著，心脏耐受力得到深度强化。")
                PosterInsightItem(icon: "figure.run", color: .blue, title: "跑姿经济性", detail: "垂直振幅控制在 8cm 以内，能量损耗极低，跑姿已趋近专业运动员。")
                PosterInsightItem(icon: "timer", color: .orange, title: "有氧脱钩率 (疲劳抗性)", detail: "心率随疲劳的漂移率仅为 3.2%，这显示出你拥有极其强大的有氧底座。")
            }
        }
        .padding(35)
        .background(LinearGradient(colors: [Color.purple.opacity(0.1), Color.clear], startPoint: .top, endPoint: .bottom))
    }
    
    private var footerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("RunPlus Pro").font(.system(size: 22, weight: .black)).foregroundColor(.white)
                Text("专注科学跑步的 AI 智能助手").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "qrcode").font(.system(size: 40)).foregroundColor(.white.opacity(0.3))
                Text("扫码开启科学跑步").font(.system(size: 8)).foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(40)
        .background(Color.black)
    }
}

// MARK: - 辅助组件

struct RadarLabel: View {
    let text: String; let x: CGFloat; let y: CGFloat
    var body: some View {
        Text(text).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.4)).offset(x: x, y: y)
    }
}

struct PosterMetricGridItem: View {
    let label: String; let value: String; let unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(unit).font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.3))
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PosterInsightItem: View {
    let icon: String; let color: Color; let title: String; let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text(detail).font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).lineSpacing(4)
            }
        }
    }
}


