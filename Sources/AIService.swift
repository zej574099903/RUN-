import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    
    // 字段名必须是 coachingAdvice，以对齐 AnalysisView
    @Published var coachingAdvice: String = "正在分析今日表现..."
    @Published var isAnalyzing: Bool = false
    
    // 接口 1：对齐 AnalysisView.swift (第 45 行) 的调用
    func fetchCoachingAdvice(steps: [Double], lastWorkout: String) {
        self.isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.coachingAdvice = "根据你最近一周的步数趋势和上次 \(lastWorkout) 的记录，你的耐力正在稳步提升。建议在接下来的训练中适当增加间歇跑，以进一步突破心肺瓶颈。保持当前节奏，你离目标越来越近了！"
            self.isAnalyzing = false
        }
    }
    
    // 接口 2：支持年轻化详情页的智能洞察
    func generateActivityInsight(calories: Double, distance: Double, nickname: String) {
        // 由于两个页面共享 coachingAdvice 字段，我们在这里也更新它
        self.isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let messages: [String]
            
            if calories > 500 {
                messages = [
                    "太牛了，\(nickname)！你今天的能量足以点亮整个街区的路灯。刚才那份燃脂量，相当于你直接跑掉了一大块肥肉！",
                    "这就是大神吗？\(nickname) 的表现让 AI 都感到震撼。你现在的状态，可以直接去参加半马了！"
                ]
            } else if calories > 100 {
                messages = [
                    "不错哦，\(nickname)。你今天的汗水已经帮你清空了刚才那碗米饭的负罪感，这种自律感真上头！",
                    "稳定发挥！这 \(String(format: "%.2f", distance)) 公里是送给身体最好的护肤品。感觉你走路都带风了。"
                ]
            } else {
                messages = [
                    "热身结束了吗，\(nickname)？身体里的热血已经开始沸腾了，再坚持一下，去解锁今天的‘饭后甜点’定额吧！",
                    "只要出发，就已经赢了 99% 的人。哪怕是散步，你的心脏也会为你点赞。"
                ]
            }
            
            self.coachingAdvice = messages.randomElement() ?? ""
            self.isAnalyzing = false
        }
    }
}
