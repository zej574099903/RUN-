import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var coachingAdvice: String = "正在扫描生理机能数据..."
    @Published var isAnalyzing: Bool = false
    
    // 接口 1：科学处方点评 (对齐 AnalysisView)
    func fetchCoachingAdvice(steps: [Double], lastWorkout: String) {
        self.isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.coachingAdvice = "分析显示，你最近的训练负荷稳步增加，且心脏回血效率提升了 5%。建议今日进行一次 Zone 2（基础有氧）训练，这能像夯实地基一样，为你未来的长距离奔跑提供更强大的爆发力支持。保持节奏，你的身体正在进化。"
            self.isAnalyzing = false
        }
    }
    
    // 接口 2：智能洞察点评 (对齐年轻化详情页)
    func generateActivityInsight(calories: Double, distance: Double, nickname: String) {
        self.isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let messages: [String]
            
            if calories > 500 {
                messages = [
                    "精英表现，\(nickname)！这次高强度的能量消耗有效激活了你的肌肉线粒体。你现在的代谢状态就像一台高性能赛车，正在高效地将脂肪转化为前进动力。",
                    "震撼的数据！你的体能储备正在发生质变。刚才这 \(String(format: "%.1f", distance)) 公里不仅是汗水，更是你心肺系统的一次‘硬核升级’。"
                ]
            } else if calories > 100 {
                messages = [
                    "稳扎稳打，\(nickname)。这种中等强度的运动是维持‘有氧地基’最好的方式。你现在的身体恢复指数非常理想，建议今晚配合拉伸，加速代谢产物的排除。",
                    "高效率的一天！你的心脏在这种节奏下运行得最稳健。长期保持这种‘有效积累’，你的乳酸阈值将会在下个月迎来突破。"
                ]
            } else {
                messages = [
                    "不错的积极恢复，\(nickname)。哪怕是低强度的活动，也在润滑你的关节并激活血液循环。记住，每一公里的积累都是在为下一次的 PB（个人最好成绩）做铺垫。",
                    "保持动态！今天的轻量运动有助于降低皮质醇水平。你的身体正在从疲劳中恢复，为明天的挑战储备能量。"
                ]
            }
            
            self.coachingAdvice = messages.randomElement() ?? ""
            self.isAnalyzing = false
        }
    }
}
