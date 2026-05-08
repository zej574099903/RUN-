import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var dailyStepGoal: Double = 10000
    @State private var isEditingProfile = false
    @State private var tempNickname = ""
    
    @StateObject private var subManager = SubscriptionManager.shared
    
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
                        
                        // 开发者调试模块 (仅测试阶段)
                        debugSection
                        
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
            StatBox(value: "\(healthManager.totalWorkoutDays)", label: "累计天数", icon: "calendar", color: .blue)
            StatBox(value: String(format: "%.0f", healthManager.totalDistance), label: "累计公里", icon: "figure.run", color: .green)
            StatBox(value: "\(Int(healthManager.totalCalories / 1000))k", label: "累计热量", icon: "flame.fill", color: .red)
        }
        .padding(.horizontal)
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
    
    var debugSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "ladybug.fill").foregroundColor(.purple)
                Text("开发者调试模块").font(.system(size: 14, weight: .black))
                Spacer()
                Text("仅测试阶段可见").font(.system(size: 10)).foregroundColor(.secondary)
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    subManager.togglePro()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            }) {
                HStack {
                    Image(systemName: subManager.isPro ? "person.fill.xmark" : "person.fill.checkmark")
                    Text(subManager.isPro ? "降级为普通用户" : "一键开启 Pro 会员")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(subManager.isPro ? Color.red : Color.purple)
                .cornerRadius(15)
            }
            
            Text("当前身份：\(subManager.isPro ? "Pro 会员" : "免费用户")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.purple.opacity(0.1), lineWidth: 1))
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
                    
                    // 3. 跑步目的 (转正调查)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("跑步目的 (AI 将据此调整处方强度)").font(.system(size: 14, weight: .black)).foregroundColor(.secondary)
                        
                        let goals = [
                            ("减脂瘦身", "flame.fill", Color.orange),
                            ("健康生活", "heart.fill", Color.red),
                            ("马拉松挑战", "medal.fill", Color.blue),
                            ("突破成绩", "bolt.fill", Color.yellow)
                        ]
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(goals, id: \.0) { goal, icon, color in
                                Button {
                                    healthManager.runningGoal = goal
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    HStack {
                                        Image(systemName: icon)
                                            .foregroundColor(healthManager.runningGoal == goal ? .white : color)
                                        Text(goal)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(healthManager.runningGoal == goal ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(healthManager.runningGoal == goal ? color : Color.gray.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                    
                    // 4. 核心体征参数
                    VStack(alignment: .leading, spacing: 18) {
                        Text("身体参数 (影响 AI 诊断准确度)").font(.system(size: 14, weight: .black)).foregroundColor(.secondary)
                        
                        VStack(spacing: 0) {
                            DatePicker("出生日期", selection: Binding(get: { Date(timeIntervalSince1970: healthManager.userBirthDate) }, set: { healthManager.userBirthDate = $0.timeIntervalSince1970 }), displayedComponents: .date)
                                .environment(\.locale, Locale(identifier: "zh_CN"))
                                .padding()
                            
                            Divider().padding(.leading)
                            
                            HStack {
                                Text("身高")
                                Spacer()
                                TextField("175", text: Binding(
                                    get: { String(format: "%.0f", healthManager.userHeight) },
                                    set: { if let value = Double($0) { healthManager.userHeight = value } }
                                ))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("CM")
                            }.padding()
                            
                            Divider().padding(.leading)
                            
                            HStack {
                                Text("体重")
                                Spacer()
                                TextField("70", text: Binding(
                                    get: { String(format: "%.0f", healthManager.userWeight) },
                                    set: { if let value = Double($0) { healthManager.userWeight = value } }
                                ))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("KG")
                            }.padding()
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    // 4. 自定义选项
                    VStack(alignment: .leading, spacing: 15) {
                        Text("或者").font(.system(size: 12, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center)
                        
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("更换头像图片")
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
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear, .black.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 55, height: 55)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.primary)
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
