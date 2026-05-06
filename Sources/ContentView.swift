import SwiftUI

struct ContentView: View {
    var body: some View {
        ZPrincipalView()
    }
}

struct ZPrincipalView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var animatePulse = false
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        headerSection
                        
                        // 核心圆环卡片
                        HStack(spacing: 35) {
                            ActivityRingView(
                                progress: healthManager.steps / 10000,
                                color: .green,
                                icon: "figure.walk"
                            )
                            .frame(width: 150, height: 150)
                            .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 10)
                            
                            VStack(alignment: .leading, spacing: 22) {
                                GlassMetricRow(title: "消耗热量", value: "\(Int(healthManager.calories))", unit: "KCAL", icon: "flame.fill", color: .orange)
                                GlassMetricRow(title: "行走距离", value: String(format: "%.2f", healthManager.distance), unit: "KM", icon: "location.fill", color: .blue)
                            }
                        }
                        .padding(.vertical, 25)
                        .padding(.horizontal, 25)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(35)
                        .overlay(RoundedRectangle(cornerRadius: 35).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 15)
                        
                        // 动态监测区域
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("实时心率监测")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text(String(format: "%.0f", healthManager.heartRate))
                                            .font(.system(size: 44, weight: .black, design: .rounded))
                                        Text("次/分")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 10)
                                    }
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .scaleEffect(animatePulse ? 1.4 : 1.0)
                                        .opacity(animatePulse ? 0 : 0.5)
                                    
                                    Image(systemName: "heart.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 32))
                                        .scaleEffect(animatePulse ? 1.1 : 1.0)
                                }
                            }
                            .padding(25)
                            .background(.thinMaterial)
                            .cornerRadius(30)
                            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            
                            GlassDetailCard(
                                title: "今日运动步数",
                                value: String(format: "%.0f", healthManager.steps),
                                goal: "10,000",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 120) // 给底栏留出空间
                    }
                    .padding(.top, 10)
                }
                .refreshable {
                    // 完美的下拉刷新支持
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    healthManager.fetchAllData()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                healthManager.requestAuthorization()
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            }
        }
    }
    
    var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.month().day().weekday()))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text("RUN+")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Spacer()
            
            HStack(spacing: 15) {
                // 顶部精致刷新按钮
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    healthManager.fetchAllData()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "person.crop.circle.fill").font(.title2).foregroundColor(.secondary))
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
    }
}

// MARK: - Components (保持不变)
struct MeshBackgroundView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            Circle()
                .fill(Color.blue.opacity(0.05))
                .blur(radius: 100)
                .offset(x: animate ? 100 : -100, y: animate ? -200 : -100)
            Circle()
                .fill(Color.purple.opacity(0.05))
                .blur(radius: 100)
                .offset(x: animate ? -150 : 150, y: animate ? 200 : 100)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct ActivityRingView: View {
    var progress: Double
    var color: Color
    var icon: String
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 18)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(AngularGradient(colors: [color, color.opacity(0.6)], center: .center), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
            Image(systemName: icon).font(.system(size: 28, weight: .bold)).foregroundColor(color)
        }
    }
}

struct GlassMetricRow: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.secondary)
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value).font(.system(size: 24, weight: .black, design: .rounded))
                    Text(unit).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).padding(.bottom, 4)
                }
            }
        }
    }
}

struct GlassDetailCard: View {
    let title: String
    let value: String
    let goal: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title).font(.headline).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom) {
                    Text(value).font(.system(size: 48, weight: .black, design: .rounded))
                    Text("/ \(goal) 目标").font(.subheadline).fontWeight(.bold).foregroundColor(.secondary).padding(.bottom, 12)
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.05)).frame(height: 12)
                    Capsule().fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: CGFloat(min((Double(value) ?? 0) / 10000, 1.0)) * 280, height: 12)
                        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
        }
        .padding(25).background(.thinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

#Preview {
    ContentView()
}
