import Foundation
import Combine

// 订阅状态管理器 (当前为模拟，后续接入 StoreKit)
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPro: Bool = false // 是否为付费用户
    @Published var selectedPlan: PlanType = .free
    
    enum PlanType: String {
        case free = "免费版"
        case health = "健康版"
        case coach = "教练版"
    }
    
    // 模拟订阅（后续替换为真实 StoreKit 购买）
    func subscribe(plan: PlanType) {
        selectedPlan = plan
        isPro = plan != .free
    }
    
    func restore() {
        // 恢复购买逻辑
    }
}
