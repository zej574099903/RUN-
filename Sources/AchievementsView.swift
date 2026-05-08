import SwiftUI

struct Achievement: Identifiable {
    var id: String { title } // 使用标题作为稳定 ID，防止刷新时 ID 变化导致弹窗关闭
    let title: String
    let icon: String
    let color: Color
    let description: String
    let isEarned: Bool
    let category: String
}

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var healthManager = HealthKitManager.shared
    
    // 勋章逻辑“转正” (增加安全保护)
    var achievements: [Achievement] {
        // 安全获取雷达图得分
        let paceScore = (healthManager.radarValues.count > 4) ? healthManager.radarValues[4] : 0
        
        return [
            Achievement(title: "初露锋芒", icon: "figure.walk", color: .green, 
                        description: "累计里程超过 10 公里", 
                        isEarned: healthManager.totalDistance >= 10, category: "里程碑"),
            
            Achievement(title: "百里行者", icon: "figure.run", color: .blue, 
                        description: "累计跑步超过 100 公里", 
                        isEarned: healthManager.totalDistance >= 100, category: "里程碑"),
            
            Achievement(title: "速度达人", icon: "bolt.fill", color: .yellow, 
                        description: "配速曾达到 4'30\" 以内", 
                        isEarned: paceScore >= 0.8, category: "极限挑战"),
            
            Achievement(title: "热量终结者", icon: "flame.fill", color: .orange, 
                        description: "单次运动消耗超过 500 大卡", 
                        isEarned: !healthManager.workouts.isEmpty && healthManager.workouts.contains { ($0.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) >= 500 }, category: "每日习惯"),
            
            Achievement(title: "毅力之星", icon: "star.fill", color: .purple, 
                        description: "累计运动天数达到 7 天", 
                        isEarned: healthManager.totalWorkoutDays >= 7, category: "每日习惯"),
            
            Achievement(title: "晨曦跑者", icon: "sunrise.fill", color: .orange, 
                        description: "在早上 6:00 前完成过一次跑步", 
                        isEarned: !healthManager.workouts.isEmpty && healthManager.workouts.contains { Calendar.current.component(.hour, from: $0.startDate) < 6 }, category: "极限挑战"),
            
            Achievement(title: "月度冠军", icon: "trophy.fill", color: .yellow, 
                        description: "累计运动天数超过 20 天", 
                        isEarned: healthManager.totalWorkoutDays >= 20, category: "里程碑"),
            
            Achievement(title: "半马勇士", icon: "medal.fill", color: .red, 
                        description: "完成过一次半程马拉松 (21.0975KM)", 
                        isEarned: !healthManager.workouts.isEmpty && healthManager.workouts.contains { ($0.totalDistance?.doubleValue(for: .meter()) ?? 0) >= 21097 }, category: "极限挑战"),
            
            Achievement(title: "运动达人", icon: "person.3.fill", color: .cyan, 
                        description: "累计运动总次数超过 10 次", 
                        isEarned: healthManager.workouts.count >= 10, category: "每日习惯")
        ]
    }
    
    var categories: [String] {
        Array(Set(achievements.map { $0.category })).sorted()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 顶部统计
                HStack(spacing: 40) {
                    AchievementStat(label: "已点亮", value: "\(achievements.filter { $0.isEarned }.count)")
                    AchievementStat(label: "勋章总数", value: "\(achievements.count)")
                    AchievementStat(label: "超越跑者", value: "88%")
                }
                .padding(.top, 20)
                
                // 按分类展示
                ForEach(categories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 15) {
                        Text(category)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .padding(.leading, 5)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(achievements.filter { $0.category == category }) { achievement in
                                MedalCell(achievement: achievement)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(20)
        }
        .background(MeshBackgroundView())
        .navigationTitle("荣誉勋章馆")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MedalCell: View {
    let achievement: Achievement
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: 12) {
                AchievementBadge(
                    title: achievement.title,
                    icon: achievement.icon,
                    color: achievement.color,
                    isLocked: !achievement.isEarned
                )
            }
        }
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(achievement: achievement)
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct AchievementStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let color: Color
    let isLocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // 1. 勋章基座 (外层金属圈)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                isLocked ? .gray.opacity(0.3) : color.opacity(0.8),
                                isLocked ? .gray.opacity(0.1) : color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear, .black.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                
                // 2. 内部珐琅/玻璃层
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .shadow(color: .white.opacity(0.5), radius: 2, x: -2, y: -2)
                
                // 3. 核心图标 (浮雕效果)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(
                        isLocked ? 
                        AnyShapeStyle(.gray.opacity(0.5)) :
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [.white, color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 1, y: 1)
                
                // 4. 锁定遮罩
                if isLocked {
                    Circle()
                        .fill(.black.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(.gray))
                        .offset(x: 35, y: 35)
                }
            }
            
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isLocked ? .secondary : .primary)
        }
    }
}

struct AchievementDetailSheet: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 25) {
            Capsule().fill(.gray.opacity(0.2)).frame(width: 40, height: 6).padding(.top)
            
            AchievementBadge(
                title: "",
                icon: achievement.icon,
                color: achievement.color,
                isLocked: !achievement.isEarned
            )
            .scaleEffect(1.5)
            .padding(.vertical, 30)
            
            VStack(spacing: 10) {
                Text(achievement.title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text(achievement.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if achievement.isEarned {
                Text("已于 2024年5月6日 达成")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.green.opacity(0.1)))
            } else {
                Text("尚未解锁")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
