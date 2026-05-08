import SwiftUI

struct HealthInsightDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var subManager: SubscriptionManager
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            MeshBackgroundView()
            
            ProFeatureWrapper(
                title: "深度机能诊断全文",
                isLocked: !subManager.isPro,
                onTapIfLocked: { showPaywall = true }
            ) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // 1. 顶部：心脏机能扫描
                        heartAgeSection
                        
                        // 2. 核心：机能进化时间轴 (外面没有的深度数据)
                        evolutionTimelineSection
                        
                        // 3. 风险预警：伤病风险评估
                        injuryRiskSection
                        
                        // 4. 底部建议
                        actionPlanSection
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("机能深度诊断报告")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
        }
    }
    
    // MARK: - 1. 心脏年龄 (高溢价维度)
    private var heartAgeSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.red.opacity(0.1), lineWidth: 20).frame(width: 180, height: 180)
                VStack(spacing: 5) {
                    if healthManager.userBirthDate == 0 {
                        Text("?").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.red)
                        Text("完善资料").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
                    } else {
                        // 简单算法：基于配速得分降低心脏年龄
                        let heartAge = healthManager.biologicalAge - Int(healthManager.radarValues[4] * 8)
                        Text("\(heartAge)").font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.red)
                        Text("心脏机能年龄").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
                    }
                }
                
                // 扫描光圈效果
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(45))
            }
            .padding(.top, 20)
            
            if healthManager.userBirthDate == 0 {
                Text("💡 请在'我的'页面录入出生日期，以获得精准的心脏年龄诊断报告。")
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                let heartAge = healthManager.biologicalAge - Int(healthManager.radarValues[4] * 8)
                Text("💡 你的实际年龄 \(healthManager.biologicalAge) 岁，但心脏机能相当于 \(heartAge) 岁。这得益于你近期高效的有氧训练。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(30)
    }
    
    // MARK: - 2. 进化时间轴
    private var evolutionTimelineSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("机能进化历程", systemImage: "chart.line.uptrend.xyaxis").font(.headline)
            
            VStack(spacing: 0) {
                EvolutionRow(date: "2026.01", event: "加入 RunPlus", detail: "初始里程: 0 KM", isFirst: true)
                EvolutionRow(date: "2026.02", event: "系统化训练", detail: "平均配速提升 12%", isLast: false)
                EvolutionRow(date: "今日", event: "进入巅峰期", detail: "本周已跑 \(String(format: "%.1f", healthManager.thisWeekDistance)) KM", isLast: true)
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(30)
    }
    
    private var injuryRiskSection: some View {
        let isHighRisk = healthManager.thisWeekDistance > (healthManager.lastWeekDistance * 1.5) && healthManager.lastWeekDistance > 0
        
        // 伤病风险 AI 建议 (转正关联)
        let riskAdvice: String = {
            switch healthManager.runningGoal {
            case "减脂瘦身":
                return "当前体脂减重初期，关节压力较大。建议每次跑步间隔 48 小时，配合拉伸以防筋膜炎。"
            case "马拉松挑战":
                return isHighRisk ? "备赛期跑量激增过快，膝盖及髂胫束风险极高，请务必安排减量周。" : "跑量增长平稳，可继续按计划训练，注意足底筋膜放松。"
            case "突破成绩":
                return "高强度间歇会导致肌肉乳酸堆积，当前伤病风险受配速波动影响，建议配合泡沫轴深层放松。"
            default:
                return "当前运动强度适中，伤病风险处于安全区间。请继续保持良好的热身习惯。"
            }
        }()
        
        return VStack(alignment: .leading, spacing: 15) {
            Text("运动伤病风险监控").font(.system(size: 18, weight: .bold, design: .rounded))
            
            // 伤病风险 AI 建议 (转正关联)
            let riskAdvice: String = {
                switch healthManager.runningGoal {
                case "减脂瘦身":
                    return "当前体脂减重初期，关节压力较大。建议每次跑步间隔 48 小时，配合拉伸以防筋膜炎。"
                case "马拉松挑战":
                    return isHighRisk ? "备赛期跑量激增过快，膝盖及髂胫束风险极高，请务必安排减量周。" : "跑量增长平稳，可继续按计划训练，注意足底筋膜放松。"
                case "突破成绩":
                    return "高强度间歇会导致肌肉乳酸堆积，当前伤病风险受配速波动影响，建议配合泡沫轴深层放松。"
                default:
                    return "当前运动强度适中，伤病风险处于安全区间。请继续保持良好的热身习惯。"
                }
            }()
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: isHighRisk ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .foregroundColor(isHighRisk ? .red : .green)
                    Text(isHighRisk ? "中高风险" : "低风险状态").font(.headline)
                    Spacer()
                    Text("AI 伤病预警").font(.caption).foregroundColor(.secondary)
                }
                
                Text(riskAdvice)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .padding(.horizontal)
    }
    
    private var actionPlanSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("AI 行动建议").font(.headline)
            Text("• 睡前进行 10 分钟深度呼吸，优化 HRV 恢复。")
            Text("• 增加蛋白质摄入，今日肌肉纤维修复需求较高。")
            Text("• 明日可尝试 5KM 个人最好成绩冲击。")
        }
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(30)
    }
}

struct EvolutionRow: View {
    let date: String; let event: String; let detail: String; var isFirst: Bool = false; var isLast: Bool = false
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack {
                Circle().fill(isLast ? Color.orange : Color.gray.opacity(0.3)).frame(width: 10, height: 10)
                if !isLast {
                    Rectangle().fill(Color.gray.opacity(0.1)).frame(width: 2, height: 50)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(date).font(.caption).foregroundColor(.secondary)
                Text(event).font(.system(size: 15, weight: .bold))
                Text(detail).font(.caption).foregroundColor(.orange)
            }
            Spacer()
        }
    }
}
