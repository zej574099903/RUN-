import SwiftUI

struct MeshBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // 动态流动的彩色光斑
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .offset(x: animate ? 100 : -100, y: animate ? -200 : -100)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 350, height: 350)
                    .offset(x: animate ? -150 : 50, y: animate ? 100 : 200)
                
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: animate ? 50 : -50, y: animate ? 200 : 50)
            }
            .blur(radius: 80)
            .onAppear {
                withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
            
            // 顶层毛玻璃遮罩
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
