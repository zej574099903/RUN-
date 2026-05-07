import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @Binding var selectedTab: Int
    @State private var showDailyHub = false
    @AppStorage("dailyStepGoal") var dailyStepGoal: Double = 10000
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        headerSection
                        NavigationLink(destination: ActivityInsightView()) {
                            MainActivityRingCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: HeartRateDetailView()) {
                            HeartRateCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 今日运动步数卡片 (支持跳转)
                        NavigationLink(destination: StepDetailView()) {
                            StepsCard(goal: dailyStepGoal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
                .refreshable { healthManager.fetchWorkouts() }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDailyHub) {
                DailyHubView(selectedTab: $selectedTab, stepGoal: $dailyStepGoal)
                    .presentationDetents([.height(520)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Date().formatted(.dateTime.weekday().month().day())).font(.subheadline).foregroundColor(.secondary)
            HStack {
                Text("RUN+").font(.system(size: 40, weight: .black, design: .rounded))
                Spacer()
                Button(action: { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); healthManager.fetchWorkouts() }) {
                    Image(systemName: "arrow.clockwise.circle.fill").font(.title2).foregroundColor(.gray.opacity(0.3))
                }
                
                // 首页头像入口 (调用统一的高级组件)
                Button(action: { 
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showDailyHub = true 
                }) {
                    healthManager.getUserAvatar(size: 44)
                }
            }
        }.padding(.top, 10)
    }
}

// MARK: - 今日动态概览 (同步版)
struct DailyHubView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    @Binding var selectedTab: Int
    @Binding var stepGoal: Double
    @State private var isEditingGoal = false
    
    @MainActor private var shareImage: Image {
        let renderer = ImageRenderer(content: ShareCardView(steps: 3051, goal: Int(stepGoal)))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage { return Image(uiImage: uiImage) }
        return Image(systemName: "photo")
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // 1. 顶部身份 (调用统一的高级组件)
            HStack(spacing: 15) {
                healthManager.getUserAvatar(size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("下午好，\(healthManager.nickname)").font(.headline)
                    Text("加油！今日目标已完成 32%").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
            }.padding(.top, 30)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("连续达标").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    ForEach(0..<7) { i in
                        VStack(spacing: 6) {
                            Image(systemName: "flame.fill").foregroundColor(i < 3 ? .orange : .gray.opacity(0.2)).font(.title3)
                            Text("D\(i+1)").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                        }.frame(maxWidth: .infinity)
                    }
                }.padding().background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.05)))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isEditingGoal ? "调整每日步数目标" : "下一枚勋章进度").font(.system(size: 14, weight: .bold)).foregroundColor(.secondary)
                    Spacer()
                    Text(isEditingGoal ? "\(Int(stepGoal)) 步" : "75/100 KM").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                }
                if isEditingGoal {
                    Slider(value: $stepGoal, in: 2000...20000, step: 500).tint(.orange).onChange(of: stepGoal) { _ in UISelectionFeedbackGenerator().selectionChanged() }
                } else {
                    ProgressView(value: 0.75).tint(.orange).scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }.padding(.bottom, 10)
            
            HStack(spacing: 15) {
                ShareLink(item: shareImage, preview: SharePreview("我的运动战报", image: shareImage)) {
                    QuickActionButton(icon: "sparkles", label: "高级战报", color: .purple)
                }
                Button(action: { withAnimation(.spring()) { isEditingGoal.toggle() }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }) {
                    QuickActionButton(icon: isEditingGoal ? "checkmark.circle.fill" : "target", label: isEditingGoal ? "完成" : "修改目标", color: .green)
                }
                Button(action: { dismiss(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { selectedTab = 3 } }) {
                    QuickActionButton(icon: "gearshape.fill", label: "设置", color: .gray)
                }
            }
            Spacer()
        }.padding(.horizontal, 25)
    }
}

// 其余高级战报和辅助组件保持不变...
struct ShareCardView: View {
    let steps: Int; let goal: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日运动简报").font(.system(size: 14, weight: .black)).tracking(2).foregroundColor(.white.opacity(0.6))
                    Text(Date().formatted(.dateTime.year().month().day())).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.white)
                }
                Spacer()
                ZStack { Circle().fill(.white.opacity(0.2)).frame(width: 50, height: 50); Image(systemName: "person.crop.circle.fill").font(.system(size: 40)).foregroundColor(.white) }
            }.padding(.top, 50).padding(.horizontal, 40)
            Spacer()
            VStack(alignment: .leading, spacing: -5) {
                Text("\(steps)").font(.system(size: 130, weight: .black, design: .rounded)).foregroundColor(.white).shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                Text("今日总步数").font(.system(size: 20, weight: .black)).tracking(1).foregroundColor(.white.opacity(0.8)).padding(.leading, 10)
            }.padding(.horizontal, 30)
            Spacer()
            HStack(spacing: 15) {
                CardMetric(label: "累计消耗", value: "324", unit: "KCAL")
                CardMetric(label: "运动里程", value: "2.8", unit: "KM")
                CardMetric(label: "达成目标", value: "\(Int(Double(steps)/Double(goal)*100))", unit: "%")
            }.padding(.horizontal, 30)
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("保持热爱，奔赴山海。").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Text("由 RUN+ AI 教练驱动生成").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text("RUN+").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
            }.padding(.bottom, 50).padding(.horizontal, 40)
        }
        .frame(width: 450, height: 800)
        .background(ZStack {
            LinearGradient(colors: [Color(hex: "1a1a1a"), Color(hex: "2d3436")], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color.orange.opacity(0.3)).frame(width: 400).blur(radius: 80).offset(x: 200, y: -200)
            Circle().fill(Color.purple.opacity(0.2)).frame(width: 300).blur(radius: 100).offset(x: -150, y: 200)
            Image(systemName: "rectangle.fill").resizable().opacity(0.02).blendMode(.overlay)
        })
    }
}
struct CardMetric: View {
    let label: String; let value: String; let unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 10, weight: .black)).foregroundColor(.white.opacity(0.5))
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.6)).padding(.bottom, 4)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.white.opacity(0.08)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
struct QuickActionButton: View {
    let icon: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            ZStack { Circle().fill(color.opacity(0.1)).frame(width: 50, height: 50); Image(systemName: icon).foregroundColor(color).font(.headline) }
            Text(label).font(.system(size: 11, weight: .bold))
        }.frame(maxWidth: .infinity)
    }
}
struct StepsCard: View {
    let goal: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("今日运动步数").font(.headline).foregroundColor(.secondary)
            HStack(alignment: .bottom, spacing: 5) {
                Text("3051").font(.system(size: 50, weight: .black, design: .rounded))
                Text("/ \(Int(goal)) 目标").font(.subheadline).bold().foregroundColor(.secondary).padding(.bottom, 8)
            }
            ProgressView(value: 3051 / goal).tint(.green).scaleEffect(x: 1, y: 3, anchor: .center)
        }.padding(25).background(.ultraThinMaterial).cornerRadius(35)
    }
}
struct MainActivityRingCard: View {
    @EnvironmentObject var healthManager: HealthKitManager
    
    var progress: Double {
        let goal: Double = 500 // 默认每日消耗目标 500kcal
        return min(healthManager.todayCalories / goal, 1.0)
    }
    
    var body: some View {
        HStack {
            // 左侧：圆环 (基于真实进度)
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.1), lineWidth: 16)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
                
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            Spacer() // 核心：将左右两部分推向边缘
            
            // 右侧：数据 (改为右对齐，增加呼吸感)
            VStack(alignment: .trailing, spacing: 18) {
                MetricRow(label: "累计消耗", value: String(format: "%.0f", healthManager.todayCalories), unit: "KCAL", icon: "flame.fill", color: .orange, isRightAligned: true)
                MetricRow(label: "运动里程", value: String(format: "%.2f", healthManager.todayDistance), unit: "KM", icon: "paperplane.fill", color: .blue, isRightAligned: true)
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity) // 强制撑满宽度
        .background(.ultraThinMaterial)
        .cornerRadius(35)
    }
}
struct HeartRateCard: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("实时心率监测").font(.subheadline).bold().foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text("\(Int(healthManager.heartRate))").font(.system(size: 48, weight: .black, design: .rounded))
                    Text("次/分").font(.headline).foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .scaleEffect(pulse)
                .shadow(color: .red.opacity(0.3), radius: 15)
                .onAppear {
                    let duration = 60.0 / max(healthManager.heartRate, 1.0)
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        pulse = 1.15
                    }
                }
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
    }
}
struct MetricRow: View {
    let label: String; let value: String; let unit: String; let icon: String; let color: Color
    var isRightAligned: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if isRightAligned {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(label).font(.caption).bold().foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(value).font(.system(size: 24, weight: .black, design: .rounded))
                        Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).padding(.bottom, 3)
                    }
                }
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).bold().foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(value).font(.system(size: 22, weight: .black, design: .rounded))
                        Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).padding(.bottom, 3)
                    }
                }
            }
        }
    }
}
