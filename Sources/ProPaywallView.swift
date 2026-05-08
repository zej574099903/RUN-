import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionManager.PlanType = .monthly
    
    private let proFeatures: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("sparkles", .purple, "AI 运动深度复盘", "每一场运动都有专业教练点评"),
        ("chart.bar.fill", .blue, "跑步能力雷达图", "全方位评估你的耐力与爆发力"),
        ("bolt.heart.fill", .red, "状态与疲劳监控", "科学预防受伤，掌握身体节奏"),
        ("calendar.badge.checkmark", .green, "AI 科学训练处方", "基于你的体能状态量身定制")
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // 顶部关闭按钮 (调整位置)
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 10)
                    
                    // 标题区
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.2)).frame(width: 80, height: 80).blur(radius: 10)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        }
                        
                        Text("升级 RunPlus Pro")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("开启你的科学跑步之旅")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // 功能清单
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(proFeatures, id: \.title) { feature in
                            HStack(spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundColor(feature.color)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                    Text(feature.subtitle).font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .padding(25)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(25)
                    
                    // 订阅选项
                    VStack(spacing: 15) {
                        HStack(spacing: 12) {
                            PlanCard(plan: .monthly, price: "¥15", period: "/月", isSelected: selectedPlan == .monthly, badge: "7天免费试用")
                                .onTapGesture { withAnimation { selectedPlan = .monthly } }
                            
                            PlanCard(plan: .yearly, price: "¥128", period: "/年", isSelected: selectedPlan == .yearly)
                                .onTapGesture { withAnimation { selectedPlan = .yearly } }
                        }
                        
                        // 终身版
                        LifetimePlanCard(isSelected: selectedPlan == .lifetime)
                            .onTapGesture { withAnimation { selectedPlan = .lifetime } }
                    }
                    
                    // 订阅按钮
                    Button(action: {
                        Task {
                            try? await subManager.purchasePro()
                            dismiss()
                        }
                    }) {
                        Text(selectedPlan == .monthly ? "开始 7 天免费试用" : "立即升级")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    
                    // 底部声明与恢复购买 (弱化处理)
                    VStack(spacing: 10) {
                        HStack(spacing: 15) {
                            Button("恢复购买") {
                                Task {
                                    await subManager.restorePurchases()
                                }
                            }
                            Text("|").opacity(0.2)
                            Button("服务条款") { }
                            Text("|").opacity(0.2)
                            Button("隐私政策") { }
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        
                        Text("确认购买后，费用将从您的 iTunes 账户扣除。\n您可以随时在账户设置中管理或取消订阅。")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.2))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 25)
            }
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionManager.PlanType
    let price: String
    let period: String
    let isSelected: Bool
    var badge: String? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(5)
            }
            
            Text(plan.rawValue)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(price).font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(period).font(.caption).foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.orange : Color.white.opacity(0.1), lineWidth: 2))
    }
}

struct LifetimePlanCard: View {
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("终身专业版").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text("一次性付费，永久解锁所有功能").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text("¥288").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
        }
        .padding(20)
        .background(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.orange : Color.white.opacity(0.1), lineWidth: 2))
    }
}
