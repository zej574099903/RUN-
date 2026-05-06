import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var dailyStepGoal: Double = 10000
    
    // 头像上传相关
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        // 1. 高级头像区 (点击可换)
                        headerArea
                        
                        // 2. 生涯总览
                        careerStatsGrid
                        
                        // 3. 荣誉勋章墙
                        achievementWall
                        
                        // 4. 设置列表
                        settingsSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("个人中心")
        }
    }
    
    var headerArea: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack {
                    // 呼吸光晕
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // 头像容器
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 110, height: 110)
                        
                        if let avatarImage = avatarImage {
                            avatarImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 105, height: 105)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 105, height: 105)
                                .clipShape(Circle())
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        
                        // 换头像提示小标
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.orange))
                            .offset(x: 35, y: 35)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                }
            }
            .onChange(of: avatarItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            avatarImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            
            VStack(spacing: 6) {
                Text("RUN+ 跑者")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                Text("保持热爱，奔赴山海")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    var careerStatsGrid: some View {
        HStack(spacing: 15) {
            StatBox(value: "128", label: "累计天数", icon: "calendar", color: .blue)
            StatBox(value: "452", label: "累计公里", icon: "figure.run", color: .green)
            StatBox(value: "12k", label: "累计热量", icon: "flame.fill", color: .red)
        }
    }
    
    var achievementWall: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("荣誉勋章")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                NavigationLink(destination: AchievementsView()) {
                    Text("全部 12")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 25) {
                    BadgeView(icon: "bolt.fill", color: .yellow, title: "速度达人")
                    BadgeView(icon: "flame.fill", color: .orange, title: "热量终结者")
                    BadgeView(icon: "star.fill", color: .purple, title: "毅力之星")
                    BadgeView(icon: "figure.walk", color: .green, title: "百里行者")
                }
                .padding(.vertical, 5)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    var settingsSection: some View {
        VStack(spacing: 1) {
            SettingsRow(icon: "heart.fill", color: .red, title: "HealthKit 状态", value: healthManager.isAuthorized ? "已连接" : "未授权")
            Divider().padding(.leading, 60).opacity(0.1)
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                        .font(.headline)
                        .frame(width: 30)
                    Text("每日步数目标")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text("\(Int(dailyStepGoal))")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }
                Slider(value: $dailyStepGoal, in: 5000...20000, step: 1000)
                    .accentColor(.orange)
            }
            .padding(20)
            
            Divider().padding(.leading, 60).opacity(0.1)
            SettingsRow(icon: "bell.fill", color: .blue, title: "运动提醒", value: "已开启")
        }
        .background(.ultraThinMaterial)
        .cornerRadius(30)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct BadgeView: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 70, height: 70)
                
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 3)
            }
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.primary.opacity(0.8))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 14, weight: .bold))
            }
            .frame(width: 40)
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .medium))
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(20)
    }
}
