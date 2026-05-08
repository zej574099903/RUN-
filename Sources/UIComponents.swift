import SwiftUI

// MARK: - Pro 专属功能包装器 (通用组件)
struct ProFeatureWrapper<Content: View>: View {
    let title: String
    let isLocked: Bool
    let cornerRadius: CGFloat
    let onTapIfLocked: (() -> Void)? // 新增回调
    let content: () -> Content
    
    init(title: String, isLocked: Bool, cornerRadius: CGFloat = 30, onTapIfLocked: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.isLocked = isLocked
        self.cornerRadius = cornerRadius
        self.onTapIfLocked = onTapIfLocked
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .blur(radius: isLocked ? 12 : 0)
                .allowsHitTesting(!isLocked)
            
            if isLocked {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial.opacity(0.4))
                
                VStack(spacing: 12) {
                    ProLabel()
                    Text("解锁\(title)")
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                }
                // 使整个遮罩层可点击
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onTapIfLocked?()
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isLocked ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Pro 专属标签
struct ProLabel: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill").font(.system(size: 10)).foregroundColor(.yellow)
            Text("PRO 专属").font(.system(size: 10, weight: .black)).foregroundColor(.yellow)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
}

// MARK: - 玻璃拟态卡片容器 (可选)
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = 30, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(22)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - 通用雷达图形状算法
struct RadarDataShape: Shape {
    let values: [Double]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angleStep = (.pi * 2) / Double(values.count)
        
        for (i, val) in values.enumerated() {
            let angle = angleStep * Double(i) - .pi / 2
            let x = center.x + CGFloat(cos(angle)) * radius * CGFloat(val)
            let y = center.y + CGFloat(sin(angle)) * radius * CGFloat(val)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}
