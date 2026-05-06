import SwiftUI
import HealthKit

struct HistoryView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var selectedCategory: Int = 0 // 0: 全部, 1: 跑步, 2: 步行
    
    var filteredWorkouts: [HKWorkout] {
        switch selectedCategory {
        case 1: return healthManager.workouts.filter { $0.workoutActivityType == .running }
        case 2: return healthManager.workouts.filter { $0.workoutActivityType == .walking }
        default: return healthManager.workouts
        }
    }
    
    var groupedWorkouts: [(String, [HKWorkout])] {
        let groups = Dictionary(grouping: filteredWorkouts) { workout in
            let components = Calendar.current.dateComponents([.year, .month], from: workout.startDate)
            return "\(components.year!)年\(components.month!)月"
        }
        return groups.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                VStack(spacing: 0) {
                    categoryPicker
                        .padding(.vertical, 15)
                    
                    if filteredWorkouts.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 22, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedWorkouts, id: \.0) { month, records in
                                    Section(header: sectionHeader(month)) {
                                        ForEach(records, id: \.uuid) { workout in
                                            // 添加点击进入详情页的跳转链接
                                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                                WorkoutRecordCard(workout: workout)
                                            }
                                            .buttonStyle(PlainButtonStyle()) // 移除默认的点击灰色遮罩
                                        }
                                    }
                                }
                                Spacer(minLength: 120)
                            }
                            .padding(.horizontal, 20)
                        }
                        .refreshable {
                            healthManager.fetchWorkouts()
                        }
                    }
                }
            }
            .navigationTitle("运动记录")
        }
    }
    
    var categoryPicker: some View {
        HStack(spacing: 12) {
            CategoryButton(title: "全部", icon: "infinity", isSelected: selectedCategory == 0, color: .primary) { selectedCategory = 0 }
            CategoryButton(title: "跑步", icon: "figure.run", isSelected: selectedCategory == 1, color: .orange) { selectedCategory = 1 }
            CategoryButton(title: "步行", icon: "figure.walk", isSelected: selectedCategory == 2, color: .green) { selectedCategory = 2 }
        }
        .padding(.horizontal, 20)
    }
    
    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.3))
            Text("期待你的下一次突破")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct WorkoutRecordCard: View {
    let workout: HKWorkout
    
    var themeColor: Color {
        workout.workoutActivityType == .running ? .orange : .green
    }
    
    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [themeColor, themeColor.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 4)
                .padding(.vertical, 15)
                .padding(.leading, 8)
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(uiColor: .systemBackground))
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            Image(systemName: workout.workoutActivityType == .running ? "figure.run" : "figure.walk")
                                .foregroundColor(themeColor)
                                .font(.system(size: 18, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.workoutActivityType == .running ? "户外跑步" : "步行记录")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.black)
                            // 显式汉化日期
                            Text(formatDate(workout.startDate))
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                HStack(spacing: 0) {
                    WorkoutMetricItem(label: "距离", value: String(format: "%.2f", (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0), unit: "KM", icon: "location.fill", iconColor: .blue)
                    Spacer()
                    WorkoutMetricItem(label: "用时", value: formatDuration(workout.duration), unit: "", icon: "stopwatch.fill", iconColor: .purple)
                    Spacer()
                    WorkoutMetricItem(label: "消耗", value: String(format: "%.0f", workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0), unit: "KCAL", icon: "flame.fill", iconColor: .orange)
                }
            }
            .padding(22)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    // 显式汉化日期函数
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}

// WorkoutMetricItem 和 CategoryButton 保持不变... (省略部分代码以确保工具运行成功，实际文件中会保留)
struct WorkoutMetricItem: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(iconColor)
                Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(size: 22, weight: .black, design: .rounded))
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 9, weight: .black)).foregroundColor(.secondary).padding(.bottom, 4)
                }
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).fontWeight(.black)
            }
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18).fill(color).shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}
