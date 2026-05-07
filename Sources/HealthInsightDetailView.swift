import SwiftUI
import Charts

struct HealthInsightDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部总评
                topAuditHeader
                
                // 2. 五维体能雷达图
                performanceRadarSection
                
                // 3. 体能与疲劳趋势
                fitnessFatigueChart
                
                // 4. 心脏恢复能力深度评估
                heartRecoveryDetailCard
                
                // 5. AI 精准训练处方
                aiTrainingPrescriptionCard
                
                Spacer(minLength: 50)
            }
            .padding(.top, 20)
        }
        .background(MeshBackgroundView())
        .navigationTitle("AI 体能深度报告")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private var topAuditHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 15)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.82)
                    .stroke(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("82").font(.system(size: 40, weight: .black, design: .rounded))
                    Text("综合评分").font(.caption2).foregroundColor(.secondary)
                }
            }
            
            Text("当前状态：体能巅峰期")
                .font(.headline)
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
        }
    }
    
    private var performanceRadarSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("五维体能评估")
                .font(.system(size: 20, weight: .black, design: .rounded))
            
            VStack(spacing: 12) {
                AttributeRow(label: "心肺耐力（越高越能跑得远）", value: 0.85, color: .blue)
                AttributeRow(label: "心脏恢复（运动后心率回落速度）", value: 0.92, color: .green)
                AttributeRow(label: "肌肉抗疲劳（长距离后腿部状态）", value: 0.70, color: .orange)
                AttributeRow(label: "无氧爆发（冲刺速度能力）", value: 0.45, color: .red)
                AttributeRow(label: "配速稳定性（跑步节奏均匀程度）", value: 0.88, color: .purple)
            }
            
            Text("💡 AI 点评：你的基础耐力和心脏恢复能力非常出色，是典型的长距离跑者体质。建议增加一些短距离冲刺训练，提升最后阶段的爆发能力。")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(15)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .padding(.horizontal)
    }
    
    private var fitnessFatigueChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("体能积累与疲劳趋势")
                        .font(.headline)
                    Text("近 4 周的训练状态变化")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Chart {
                let fitness = [(1, 40), (2, 42), (3, 45), (4, 48), (5, 47), (6, 50), (7, 52)]
                let fatigue = [(1, 30), (2, 55), (3, 40), (4, 65), (5, 45), (6, 35), (7, 38)]
                
                ForEach(fitness, id: \.0) { day, val in
                    LineMark(x: .value("周", day), y: .value("体能", val))
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                }
                
                ForEach(fatigue, id: \.0) { day, val in
                    LineMark(x: .value("周", day), y: .value("疲劳", val))
                        .foregroundStyle(Color.red.opacity(0.5))
                        .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 150)
            .chartXAxis(.hidden)
            
            HStack(spacing: 20) {
                HStack {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("体能积累").font(.caption).foregroundColor(.secondary)
                }
                HStack {
                    Circle().fill(Color.red.opacity(0.5)).frame(width: 8, height: 8)
                    Text("疲劳程度").font(.caption).foregroundColor(.secondary)
                }
            }
            
            Text("💡 AI 解读：体能曲线持续上升，说明你的训练计划非常有效。疲劳值在合理范围内波动，没有过度训练的风险。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .padding(.horizontal)
    }
    
    private var heartRecoveryDetailCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("心脏恢复能力报告")
                        .font(.headline)
                    Text("运动结束后心率下降速度，越快越好")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text("超越 92% 同龄人")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 25) {
                RecoveryMetric(label: "运动后 1 分钟", value: "-32", unit: "BPM", rating: "极佳")
                Divider().frame(height: 40)
                RecoveryMetric(label: "运动后 2 分钟", value: "-51", unit: "BPM", rating: "极佳")
            }
            
            Text("💡 AI 结论：你的心脏恢复速度非常快，表明心血管系统已充分适应了跑步训练。这意味着你可以承受更高频次的训练而不必担心过度疲劳。")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(15)
                .background(Color.green.opacity(0.05))
                .cornerRadius(15)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .padding(.horizontal)
    }
    
    private var aiTrainingPrescriptionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("本周 AI 训练计划", systemImage: "wand.and.stars")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text("根据你的体能状态，AI 为你制定了本周精准训练建议：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                PrescriptionRow(day: "周一（今天）", task: "30 分钟轻松慢跑", intensity: "心率保持 < 135")
                PrescriptionRow(day: "周三", task: "45 分钟节奏跑", intensity: "心率 145 ~ 155")
                PrescriptionRow(day: "周五", task: "800 米冲刺 × 6 组", intensity: "心率 165 ~ 175")
            }
            
            Text("⚠️ 周二、周四、周六安排休息或拉伸，让肌肉充分恢复。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .padding(.horizontal)
    }
}

// MARK: - Helper Components

struct AttributeRow: View {
    let label: String; let value: Double; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption.bold()).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value * 100)) 分").font(.caption.bold()).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.1)).frame(height: 6)
                    Capsule().fill(color.gradient).frame(width: geo.size.width * value, height: 6)
                }
            }.frame(height: 6)
        }
    }
}

struct RecoveryMetric: View {
    let label: String; let value: String; let unit: String; let rating: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .black, design: .rounded))
                Text(unit).font(.caption2.bold()).foregroundColor(.secondary)
            }
            Text(rating).font(.system(size: 10, weight: .bold)).foregroundColor(.green)
        }
    }
}

struct PrescriptionRow: View {
    let day: String; let task: String; let intensity: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day).font(.caption.bold()).foregroundColor(.secondary)
                Text(task).font(.system(size: 15, weight: .bold))
            }
            Spacer()
            Text(intensity)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.1)))
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}
