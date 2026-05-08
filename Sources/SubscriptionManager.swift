import Foundation
import StoreKit

// MARK: - 订阅管理器 (StoreKit 2 正式版架构)
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var isPro: Bool = false
    
    enum PlanType: String {
        case monthly = "月度专业版"
        case yearly = "年度专业版"
        case lifetime = "终身专业版"
        
        var price: String {
            switch self {
            case .monthly: return "¥15"
            case .yearly: return "¥128"
            case .lifetime: return "¥288"
            }
        }
    }
    
    // 监听任务
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        // 1. 启动时监听交易更新 (如：用户在系统设置里续费)
        updateListenerTask = listenForTransactions()
        
        // 2. 启动时立即检查一次现有权限
        Task {
            await updateStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 核心方法
    
    /// 检查当前 Apple ID 是否拥有 Pro 权限
    func updateStatus() async {
        var hasActiveSubscription = false
        
        // 遍历所有当前的有效交易 ( entitlements )
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // 如果找到任何已付费且未过期的 Pro 项目
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                }
            } catch {
                print("验证交易失败: \(error)")
            }
        }
        
        self.isPro = hasActiveSubscription
    }
    
    /// 模拟购买方法 (实际购买时调用)
    func purchasePro() async throws {
        // 这里后续会填入真正的 Product ID 购买逻辑
        self.isPro = true 
    }
    
    /// 开发者调试：一键切换 Pro 状态
    func togglePro() {
        self.isPro.toggle()
    }
    
    /// 恢复购买
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateStatus()
    }
    
    // MARK: - 私有助手
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // 这里的 checkVerified 现在是 nonisolated 的，可以安全调用
                    let transaction = try self.checkVerified(result)
                    await self.updateStatus()
                    await transaction.finish()
                } catch {
                    print("监听交易失败")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
