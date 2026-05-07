import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var dailyStepGoal: Double = 10000
    @State private var isEditingProfile = false
    @State private var tempNickname = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                MeshBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        headerArea
                        careerStatsGrid
                        achievementWall
                        settingsSection
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("个人中心")
            .sheet(isPresented: $isEditingProfile) {
                ProfileEditView(tempNickname: $tempNickname)
                    .presentationDetents([.height(550)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    var headerArea: some View {
        VStack(spacing: 20) {
            Button(action: { 
                tempNickname = healthManager.nickname
                isEditingProfile = true 
            }) {
                ZStack {
                    healthManager.getUserAvatar(size: 110)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    // 编辑角标
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(healthManager.avatarColors[max(0, healthManager.avatarIndex)])
                        .background(Circle().fill(.white))
                        .offset(x: 35, y: 35)
                }
            }
            
            VStack(spacing: 6) {
                Text(healthManager.nickname).font(.system(size: 26, weight: .black, design: .rounded))
                Text("保持热爱，奔赴山海").font(.system(size: 14)).foregroundColor(.secondary)
            }
        }.padding(.top, 20)
    }
    
    // 其余 StatsGrid, AchievementWall 保持不变...
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
                Text("荣誉勋章").font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                NavigationLink(destination: AchievementsView()) {
                    Text("全部 12").font(.system(size: 13, weight: .bold)).foregroundColor(.orange)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 25) {
                    BadgeView(icon: "bolt.fill", color: .yellow, title: "速度达人")
                    BadgeView(icon: "flame.fill", color: .orange, title: "热量终结者")
                    BadgeView(icon: "star.fill", color: .purple, title: "毅力之星")
                    BadgeView(icon: "figure.walk", color: .green, title: "百里行者")
                }.padding(.vertical, 5)
            }
        }.padding(22).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    var settingsSection: some View {
        VStack(spacing: 1) {
            SettingsRow(icon: "heart.fill", color: .red, title: "HealthKit 状态", value: healthManager.isAuthorized ? "已连接" : "未授权")
            Divider().padding(.leading, 60).opacity(0.1)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "target").foregroundColor(.orange).font(.headline).frame(width: 30)
                    Text("每日步数目标").font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text("\(Int(dailyStepGoal))").font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.orange)
                }
                Slider(value: $dailyStepGoal, in: 5000...20000, step: 1000).accentColor(.orange)
            }.padding(20)
            Divider().padding(.leading, 60).opacity(0.1)
            SettingsRow(icon: "bell.fill", color: .blue, title: "运动提醒", value: "已开启")
        }.background(.ultraThinMaterial).cornerRadius(30)
    }
}

// MARK: - 3D 头像库选择器 (重构版)
struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthManager: HealthKitManager
    @Binding var tempNickname: String
    @State private var avatarItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 35) {
                    // 1. 昵称输入
                    VStack(alignment: .leading, spacing: 12) {
                        Text("你的昵称").font(.system(size: 14, weight: .black)).foregroundColor(.secondary)
                        TextField("给你的跑者身份起个名", text: $tempNickname)
                            .font(.title3.bold())
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.05), lineWidth: 1))
                    }
                    
                    // 2. 3D 角色库 (横向卡片)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("3D 运动头像库").font(.system(size: 14, weight: .black)).foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<healthManager.presetAvatars.count, id: \.self) { index in
                                    Button(action: { 
                                        withAnimation(.spring()) { healthManager.avatarIndex = index }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }) {
                                        VStack(spacing: 12) {
                                            healthManager.getUserAvatar(for: index, size: 70)
                                                .scaleEffect(healthManager.avatarIndex == index ? 1.1 : 1.0)
                                            
                                            Text(healthManager.avatarNames[index])
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(healthManager.avatarIndex == index ? healthManager.avatarColors[index] : .secondary)
                                            
                                            Circle()
                                                .fill(healthManager.avatarIndex == index ? healthManager.avatarColors[index] : Color.clear)
                                                .frame(width: 4, height: 4)
                                        }
                                        .frame(width: 100, height: 150)
                                        .background(healthManager.avatarIndex == index ? healthManager.avatarColors[index].opacity(0.08) : Color.gray.opacity(0.03))
                                        .cornerRadius(25)
                                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(healthManager.avatarIndex == index ? healthManager.avatarColors[index].opacity(0.2) : Color.clear, lineWidth: 2))
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    
                    // 3. 自定义选项
                    VStack(alignment: .leading, spacing: 15) {
                        Text("或者").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center)
                        
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("从相册选择照片")
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
                .padding(25)
            }
            .navigationTitle("编辑跑者资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { healthManager.nickname = tempNickname; dismiss() }
                        .font(.system(size: 16, weight: .black)).foregroundColor(.orange)
                }
            }
            .onChange(of: avatarItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        healthManager.customAvatarData = data
                        healthManager.avatarIndex = -1
                    }
                }
            }
        }
    }
}

// 其余辅助组件保持不变...
struct StatBox: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.primary)
            Text(label).font(.system(size: 12, weight: .bold)).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 22).background(.ultraThinMaterial).cornerRadius(25).overlay(RoundedRectangle(cornerRadius: 25).stroke(color.opacity(0.2), lineWidth: 1)).shadow(color: color.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
struct BadgeView: View {
    let icon: String; let color: Color; let title: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 70, height: 70)
                Circle().stroke(color.opacity(0.2), lineWidth: 2).frame(width: 80, height: 80)
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(color).shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 3)
            }
            Text(title).font(.system(size: 12, weight: .black)).foregroundColor(.primary.opacity(0.8))
        }
    }
}
struct SettingsRow: View {
    let icon: String; let color: Color; let title: String; let value: String
    var body: some View {
        HStack {
            ZStack { Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32); Image(systemName: icon).foregroundColor(color).font(.system(size: 14, weight: .bold)) }.frame(width: 40)
            Text(title).font(.system(size: 16, weight: .bold))
            Spacer()
            Text(value).foregroundColor(.secondary).font(.system(size: 14, weight: .medium))
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary.opacity(0.5))
        }.padding(20)
    }
}
