import SwiftUI
import HealthKit
import Charts

struct WorkoutDetailView: View {
    let workout: HKWorkout
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.dismiss) var dismiss
    
    // 交互状态
    @State private var selectedIndex: Int? = nil
    
    var themeColor: Color {
        workout.workoutActivityType == .running ? .orange : .green
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                // 1. 头部区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: workout.workoutActivityType == .running ? "figure.run" : "figure.walk")
                            .font(.title2)
                            .foregroundColor(themeColor)
                        Text(workout.workoutActivityType == .running ? "户外跑步" : "步行记录")
                            .font(.title2.bold())
                        Spacer()
                        sourceTag
                    }
                    Text(formatChineseDate(workout.startDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 2. 核心大数字
                VStack(alignment: .leading, spacing: -5) {
                    Text(String(format: "%.2f", (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0))
                        .font(.system(size: 80, weight: .black, design: .rounded))
                    Text("总公里数 (KM)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                }
                .padding(.horizontal)
                
                // 3. 数据网格
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        DetailStatBox(label: "用时", value: formatDuration(workout.duration), unit: "", icon: "stopwatch.fill", color: .purple)
                        DetailStatBox(label: "消耗", value: String(format: "%.0f", workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0), unit: "KCAL", icon: "flame.fill", color: .orange)
                    }
                    HStack(spacing: 15) {
                        DetailStatBox(label: "平均配速", value: calculatePace(), unit: "/KM", icon: "timer", color: .blue)
                        if healthManager.workoutCadence > 0 {
                            DetailStatBox(label: "平均步频", value: String(format: "%.0f", healthManager.workoutCadence), unit: "SPM", icon: "figure.run.square.stack.fill", color: .green)
                        } else if !healthManager.workoutHeartRates.isEmpty {
                            DetailStatBox(label: "平均心率", value: String(format: "%.0f", healthManager.workoutHeartRates.reduce(0, +) / Double(healthManager.workoutHeartRates.count)), unit: "BPM", icon: "heart.fill", color: .red)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 4. 极致交互心率图
                if !healthManager.workoutHeartRates.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        // 动态交互页眉
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("心率波动")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                if let index = selectedIndex, index < healthManager.workoutHeartRates.count {
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text("\(Int(healthManager.workoutHeartRates[index]))")
                                            .font(.system(size: 34, weight: .black, design: .rounded))
                                            .foregroundColor(themeColor)
                                        Text("BPM")
                                            .font(.caption.bold())
                                            .foregroundColor(themeColor)
                                        Text("• 第 \(index + 1) 分钟")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("滑动图表查看详情")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                            }
                            Spacer()
                            if selectedIndex == nil {
                                VStack(alignment: .trailing) {
                                    Text("最高")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                    Text("\(Int(healthManager.workoutHeartRates.max() ?? 0))")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 60)
                        
                        Chart {
                            ForEach(Array(healthManager.workoutHeartRates.enumerated()), id: \.offset) { index, value in
                                LineMark(
                                    x: .value("时间", index),
                                    y: .value("心率", value)
                                )
                                .foregroundStyle(themeColor.gradient)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("时间", index),
                                    y: .value("心率", value)
                                )
                                .foregroundStyle(LinearGradient(colors: [themeColor.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                                
                                // 选中时的磁吸光点和全高指示线
                                if let selectedIndex = selectedIndex, selectedIndex == index {
                                    RuleMark(x: .value("时间", index))
                                        .foregroundStyle(.primary.opacity(0.1))
                                    
                                    // 叠加两个点来实现“带圈”的效果
                                    PointMark(x: .value("时间", index), y: .value("心率", value))
                                        .foregroundStyle(themeColor)
                                        .symbolSize(200)
                                    
                                    PointMark(x: .value("时间", index), y: .value("心率", value))
                                        .foregroundStyle(.white)
                                        .symbolSize(80)
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXSelection(value: $selectedIndex)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(30)
                        .padding(.horizontal)
                    }
                    .animation(.spring(response: 0.3), value: selectedIndex)
                }
                
                Spacer(minLength: 50)
            }
        }
        .background(MeshBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthManager.fetchWorkoutDetails(for: workout)
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    private func calculatePace() -> String {
        let distanceKM = (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0
        guard distanceKM > 0 else { return "0'00\"" }
        let paceSeconds = workout.duration / distanceKM
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

struct DetailStatBox: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
