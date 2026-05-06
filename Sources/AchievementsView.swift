import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let description: String
    let isEarned: Bool
    let category: String
}

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 模拟勋章数据
    let achievements = [
        Achievement(title: "初露锋芒", icon: "figure.walk", color: .green, description: "累计步行超过 10 公里", isEarned: true, category: "里程碑"),
        Achievement(title: "百里行者", icon: "figure.run", color: .blue, description: "累计跑步超过 100 公里", isEarned: true, category: "里程碑"),
        Achievement(title: "速度达人", icon: "bolt.fill", color: .yellow, description: "配速达到 4'30\" 以内", isEarned: true, category: "极限挑战"),
        Achievement(title: "热量终结者", icon: "flame.fill", color: .orange, description: "单次运动消耗超过 500 大卡", isEarned: true, category: "每日习惯"),
        Achievement(title: "毅力之星", icon: "star.fill", color: .purple, description: "连续 7 天完成步数目标", isEarned: true, category: "每日习惯"),
        Achievement(title: "晨曦跑者", icon: "sunrise.fill", color: .orange, description: "在早上 6:00 前完成一次跑步", isEarned: false, category: "极限挑战"),
        Achievement(title: "月度冠军", icon: "trophy.fill", color: .yellow, description: "单月跑量超过 200 公里", isEarned: false, category: "里程碑"),
        Achievement(title: "半马勇士", icon: "medal.fill", color: .red, description: "完成一次 21.0975 公里跑步", isEarned: false, category: "极限挑战"),
        Achievement(title: "运动达人", icon: "person.3.fill", color: .cyan, description: "分享运动记录超过 10 次", isEarned: false, category: "每日习惯")
    ]
    
    var categories: [String] {
        Array(Set(achievements.map { $0.category })).sorted()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 顶部统计
                HStack(spacing: 40) {
                    AchievementStat(label: "已点亮", value: "5")
                    AchievementStat(label: "勋章总数", value: "12")
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
                ZStack {
                    Circle()
                        .fill(achievement.isEarned ? AnyShapeStyle(achievement.color.gradient.opacity(0.2)) : AnyShapeStyle(Color.gray.opacity(0.1)))
                        .frame(width: 85, height: 85)
                    
                    if achievement.isEarned {
                        Circle()
                            .stroke(achievement.color.opacity(0.3), lineWidth: 2)
                            .frame(width: 95, height: 95)
                    }
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32))
                        .foregroundColor(achievement.isEarned ? achievement.color : .gray.opacity(0.5))
                        .shadow(color: achievement.isEarned ? achievement.color.opacity(0.5) : .clear, radius: 10)
                    
                    if !achievement.isEarned {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .offset(x: 25, y: 25)
                    }
                }
                
                Text(achievement.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(achievement.isEarned ? .primary : .secondary)
            }
        }
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(achievement: achievement)
                .presentationDetents([.height(350)])
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

struct AchievementDetailSheet: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 25) {
            Capsule().fill(.gray.opacity(0.2)).frame(width: 40, height: 6).padding(.top)
            
            ZStack {
                Circle()
                    .fill(achievement.color.gradient.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: achievement.icon)
                    .font(.system(size: 44))
                    .foregroundColor(achievement.color)
            }
            
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
