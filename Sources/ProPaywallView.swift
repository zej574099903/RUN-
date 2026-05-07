import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subManager = SubscriptionManager.shared
    @State private var selectedPlan: Int = 1 // 0=健康版, 1=教练版
    @State private var isAnimating = false
    
    private let features: [(icon: String, color: Color, title: String, health: Bool, coach: Bool)] = [
        ("chart.line.uptrend.xyaxis", .blue, "AI 进步周报", true, true),
        ("heart.text.square.fill", .red, "心率安全预警", true, true),
        ("figure.run.circle.fill", .orange, "个性化训练计划", false, true),
        ("trophy.fill", .yellow, "比赛备战模式", false, true),
        ("message.badge.waveform.fill", .purple, "AI 教练对话", false, true)
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.05, blue: 0.20),
                    Color(red: 0.05, green: 0.10, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 装饰光晕
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 120, y: 100)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // 顶部标题区
                    headerSection
                    
                    // 付费功能列表
                    featuresListSection
                    
                    // 套餐选择
                    planPickerSection
                    
                    // 订阅按钮
                    subscribeButtonSection
                    
                    // 底部说明
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 关闭按钮
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            // 皇冠图标
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .blur(radius: 2)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
            }
            
            VStack(spacing: 8) {
                Text("Run+ Pro")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("解锁你的体能天花板\n成为更科学的跑者")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    private var featuresListSection: some View {
        VStack(spacing: 0) {
            // 表头
            HStack {
                Spacer()
                Text("健康版")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 60)
                Text("教练版")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // 功能对比行
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(feature.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(feature.color)
                    }
                    
                    Text(feature.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 健康版标识
                    Group {
                        if feature.health {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                    .font(.system(size: 18))
                    .frame(width: 60)
                    
                    // 教练版标识
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 18))
                        .frame(width: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    feature.health ? Color.clear : Color.yellow.opacity(0.04)
                )
                
                if feature.title != features.last?.title {
                    Divider().background(Color.white.opacity(0.07)).padding(.leading, 64)
                }
            }
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var planPickerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 健康版
                PlanCard(
                    name: "健康版",
                    price: "¥18",
                    period: "/月",
                    isSelected: selectedPlan == 0,
                    badge: nil
                )
                .onTapGesture { withAnimation(.spring()) { selectedPlan = 0 } }
                
                // 教练版（推荐）
                PlanCard(
                    name: "教练版",
                    price: "¥38",
                    period: "/月",
                    isSelected: selectedPlan == 1,
                    badge: "推荐"
                )
                .onTapGesture { withAnimation(.spring()) { selectedPlan = 1 } }
            }
            
            // 年付选项
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("年付教练版 · ¥198/年")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("相当于每月 ¥16.5，比月付省 55%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: selectedPlan == 2 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedPlan == 2 ? .green : .white.opacity(0.3))
            }
            .padding(16)
            .background(
                selectedPlan == 2
                    ? LinearGradient(colors: [.green.opacity(0.2), .blue.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(selectedPlan == 2 ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .onTapGesture { withAnimation(.spring()) { selectedPlan = 2 } }
        }
    }
    
    private var subscribeButtonSection: some View {
        VStack(spacing: 14) {
            Button(action: handleSubscribe) {
                HStack {
                    Image(systemName: "crown.fill").font(.system(size: 16))
                    Text(subscribeButtonText)
                        .font(.system(size: 18, weight: .black))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            
            Button("恢复购买") {
                subManager.restore()
            }
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.4))
        }
    }
    
    private var footerSection: some View {
        Text("订阅将自动续费，可随时在「App Store」→「账户」中取消。\n订阅即表示你同意我们的用户协议与隐私政策。")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.3))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
    
    // MARK: - Helpers
    
    private var subscribeButtonText: String {
        switch selectedPlan {
        case 0: return "订阅健康版 ¥18/月"
        case 1: return "订阅教练版 ¥38/月"
        case 2: return "订阅年付版 ¥198/年"
        default: return "立即订阅"
        }
    }
    
    private func handleSubscribe() {
        let plan: SubscriptionManager.PlanType = selectedPlan == 0 ? .health : .coach
        subManager.subscribe(plan: plan)
        dismiss()
    }
}

// MARK: - Plan Card Component

struct PlanCard: View {
    let name: String
    let price: String
    let period: String
    let isSelected: Bool
    let badge: String?
    
    var body: some View {
        VStack(spacing: 8) {
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(20)
            } else {
                Spacer().frame(height: 20)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(price)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(period)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            isSelected
                ? LinearGradient(colors: [.yellow.opacity(0.15), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.yellow.opacity(0.6) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}
