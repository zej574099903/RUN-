import SwiftUI

struct PremiumLoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(colors: [.blue.opacity(0.5), .cyan.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                }
                
                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("RUN+ AI 正在为您同步健康数据")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
            }
        }
    }
}
