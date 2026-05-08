import SwiftUI
import HealthKit
import CoreLocation

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var workouts: [HKWorkout] = []
    @Published var weeklySteps: [Double] = [0, 0, 0, 0, 0, 0, 0]
    @Published var workoutHeartRates: [Double] = []
    @Published var workoutCadence: Double = 0
    
    // 今日全天统计 (真实手机数据)
    @Published var todayActiveCalories: Double = 0
    @Published var todayWalkingDistance: Double = 0
    
    // MARK: - 用户体征资料 (支持 HealthKit + 手动维护)
    @AppStorage("userBirthDate") var userBirthDate: Double = 0 // 时间戳
    @AppStorage("userWeight") var userWeight: Double = 70.0 // kg
    @AppStorage("userHeight") var userHeight: Double = 175.0 // cm
    @AppStorage("userSex") var userSex: Int = 0 // 0: 未知, 1: 男, 2: 女
    @AppStorage("runningGoal") var runningGoal: String = "健康生活" // 减肥、健康、马拉松、突破记录
    @AppStorage("monthlyDistanceGoal") var monthlyDistanceGoal: Double = 100.0 // 默认 100km
    @AppStorage("targetWeight") var targetWeight: Double = 65.0 // 默认目标体重
    
    // 计算本月累计里程 (用于进度环)
    var currentMonthDistance: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        let startOfMonth = calendar.date(from: components)!
        
        return workouts.filter { $0.startDate >= startOfMonth }
            .reduce(0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) } / 1000.0
    }
    
    // MARK: - AI 处方引擎 (Pro 核心逻辑)
    struct Prescription {
        let title: String
        let subtitle: String
        let intensity: String // 低、中、高
        let color: Color
        let icon: String
    }
    
    var todayPrescription: Prescription {
        let loadRatio = thisWeekDistance / max(lastWeekDistance, 1.0)
        
        // 1. 疲劳/伤病保护优先
        if loadRatio > 1.5 && thisWeekDistance > 5 {
            return Prescription(title: "今日建议：积极恢复", subtitle: "本周跑量增幅较大，建议今日进行 15 分钟深度拉伸或轻快步行。", intensity: "低", color: .green, icon: "leaf.fill")
        }
        
        // 2. 根据目标导向
        switch runningGoal {
        case "减脂瘦身":
            return Prescription(title: "今日任务：燃脂慢跑", subtitle: "建议进行 30-40 分钟慢跑，心率保持在 130-140bpm 以最大化脂肪动员。", intensity: "中", color: .orange, icon: "flame.fill")
        case "马拉松挑战":
            return Prescription(title: "今日任务：有氧耐力跑", subtitle: "建议完成 10-12KM 匀速跑，模拟比赛后程节奏，注意呼吸频率。", intensity: "高", color: .blue, icon: "figure.run")
        case "突破成绩":
            return Prescription(title: "今日任务：间歇训练", subtitle: "建议进行 800m x 6 组间歇跑，以此提升你的最大摄氧量和抗乳酸能力。", intensity: "极高", color: .purple, icon: "bolt.fill")
        default:
            return Prescription(title: "今日建议：保持状态", subtitle: "今日天气和身体状态良好，建议进行 5KM 自由慢跑，释放压力。", intensity: "中", color: .cyan, icon: "heart.fill")
        }
    }
    
    var biologicalAge: Int {
        if userBirthDate == 0 { return 0 }
        let birth = Date(timeIntervalSince1970: userBirthDate)
        return Calendar.current.dateComponents([.year], from: birth, to: Date()).year ?? 0
    }
    
    @Published var heartRate: Double = 0
    @Published var todayHeartRateSamples: [(date: Date, value: Double)] = []
    @Published var hourlySteps: [(hour: Int, steps: Double)] = [] // 每小时步数
    @Published var flightsClimbed: Double = 0 // 爬楼层数
    
    // MARK: - 真实分析数据 (转正)
    @Published var thisWeekWorkouts: [HKWorkout] = []
    @Published var lastWeekWorkouts: [HKWorkout] = []
    
    // MARK: - 全量历史统计 (转正)
    @Published var totalDistance: Double = 0
    @Published var totalCalories: Double = 0
    @Published var totalWorkoutDays: Int = 0
    
    var thisWeekDistance: Double {
        thisWeekWorkouts.reduce(0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) } / 1000.0
    }
    
    var lastWeekDistance: Double {
        lastWeekWorkouts.reduce(0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) } / 1000.0
    }
    
    var weeklyScore: Int {
        // 简单的评分逻辑：结合次数和里程
        let base = min(thisWeekWorkouts.count * 15, 45)
        let dist = min(Int(thisWeekDistance * 3), 55)
        return base + dist
    }
    
    // MARK: - 完赛预测数据
    var predicted5K: String { calculatePrediction(for: 5000) }
    var predicted10K: String { calculatePrediction(for: 10000) }
    var predictedHalf: String { calculatePrediction(for: 21097.5) }
    
    private func calculatePrediction(for distance: Double) -> String {
        // 寻找最近的一次跑步
        guard let lastRunning = workouts.first(where: { $0.workoutActivityType == .running }),
              let dist = lastRunning.totalDistance?.doubleValue(for: .meter()),
              dist > 500 else { return "--:--" }
        
        let time = lastRunning.duration
        // Riegel's Formula: T2 = T1 * (D2/D1)^1.06
        let predictedSeconds = time * pow(distance / dist, 1.06)
        
        let hours = Int(predictedSeconds) / 3600
        let minutes = (Int(predictedSeconds) % 3600) / 60
        let seconds = Int(predictedSeconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - 雷达图五维模型数据
    var radarValues: [Double] {
        let runningWorkouts = workouts.filter { $0.workoutActivityType == .running }
        guard !runningWorkouts.isEmpty else { return [0.2, 0.2, 0.2, 0.2, 0.2] }
        
        // 1. 耐力 (Endurance): 看单次最长距离，21KM=1.0
        let maxDist = runningWorkouts.map { $0.totalDistance?.doubleValue(for: .meter()) ?? 0 }.max() ?? 0
        let endurance = min(maxDist / 21000.0, 1.0)
        
        // 2. 配速 (Pace): 平均配速，4分/km=1.0, 8分/km=0.2
        let avgPaceSeconds = runningWorkouts.map { $0.duration / (($0.totalDistance?.doubleValue(for: .meter()) ?? 1) / 1000.0) }.reduce(0, +) / Double(runningWorkouts.count)
        let pace = max(min(1.0 - (avgPaceSeconds - 240) / 360.0, 1.0), 0.2)
        
        // 3. 稳定 (Stability): 配速波动率，暂时简化为运动频率稳定性
        let stability = min(Double(runningWorkouts.count) / 12.0, 1.0) // 一个月12次即为1.0
        
        // 4. 爆发 (Explosiveness): 最近一次配速相对于平均配速的提升
        let lastPace = (runningWorkouts.first?.duration ?? 0) / ((runningWorkouts.first?.totalDistance?.doubleValue(for: .meter()) ?? 1) / 1000.0)
        let explosiveness = lastPace < avgPaceSeconds ? 0.8 : 0.5
        
        // 5. 恢复 (Recovery): 运动频率
        let recovery = min(Double(thisWeekWorkouts.count) / 4.0, 1.0) // 一周4次即为1.0
        
        return [endurance, explosiveness, stability, recovery, pace]
    }
    
    // 今日统计 (改为读取 Published 变量)
    var todayCalories: Double { todayActiveCalories }
    var todayDistance: Double { todayWalkingDistance }
    
    // 用户资料
    @Published var nickname: String {
        didSet { UserDefaults.standard.set(nickname, forKey: "user_nickname") }
    }
    @Published var avatarIndex: Int {
        didSet { UserDefaults.standard.set(avatarIndex, forKey: "user_avatar_index") }
    }
    @Published var customAvatarData: Data? {
        didSet { UserDefaults.standard.set(customAvatarData, forKey: "user_custom_avatar") }
    }
    
    let presetAvatars = ["🏃‍♂️", "🧘‍♀️", "🚴‍♂️", "🏋️‍♂️", "🏊‍♂️", "🥾", "🥊", "🧗‍♂️"]
    let avatarColors: [Color] = [.orange, .teal, .blue, .purple, .cyan, .green, .red, .indigo]
    let avatarNames = ["极速跑者", "禅意瑜伽", "竞速骑手", "硬核力量", "深海飞鱼", "户外探险", "热血格斗", "极限攀登"]
    
    init() {
        self.nickname = UserDefaults.standard.string(forKey: "user_nickname") ?? "RUN+ 跑者"
        self.avatarIndex = UserDefaults.standard.integer(forKey: "user_avatar_index")
        self.customAvatarData = UserDefaults.standard.data(forKey: "user_custom_avatar")
        requestAuthorization()
    }
    
    // MARK: - 核心：全 App 统一的高级头像组件
    func getUserAvatar(for specifiedIndex: Int? = nil, size: CGFloat = 100) -> AnyView {
        let activeIndex = specifiedIndex ?? avatarIndex
        
        return AnyView(
            ZStack {
                if activeIndex == -1, let data = customAvatarData, let uiImage = UIImage(data: data) {
                    // 自定义图片样式
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: size * 0.04))
                        .shadow(color: .black.opacity(0.1), radius: size * 0.1, x: 0, y: size * 0.05)
                } else {
                    // 3D Emoji 角色样式 (完全一致的光影)
                    let index = (activeIndex >= 0 && activeIndex < presetAvatars.count) ? activeIndex : 0
                    let color = avatarColors[index]
                    
                    ZStack {
                        // 1. 氛围光晕层 (增加 3D 深度)
                        Circle()
                            .fill(LinearGradient(colors: [color.opacity(0.25), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .blur(radius: size * 0.05)
                        
                        // 2. 玻璃态底板层
                        Circle()
                            .fill(.white)
                            .shadow(color: color.opacity(0.15), radius: size * 0.15, x: 0, y: size * 0.08)
                        
                        // 3. 核心 3D 角色
                        Text(presetAvatars[index])
                            .font(.system(size: size * 0.6))
                            .shadow(color: color.opacity(0.3), radius: size * 0.05, x: 0, y: size * 0.03)
                    }
                    .frame(width: size, height: size)
                }
            }
        )
    }

    func requestAuthorization(completion: (() -> Void)? = nil) {
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKSeriesType.workoutRoute() // 增加运动轨迹读取权限
        ]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success { 
                    self.fetchWorkouts()
                    self.fetchWeeklySteps()
                    self.fetchTodayActivityStats()
                    self.fetchLatestHeartRate()
                    self.fetchTodayHeartRateSeries()
                    self.fetchHourlySteps() // 抓取小时级分布
                    self.fetchWeeklyAnalysis() // 抓取周报数据
                    self.fetchUserProfile() // 抓取体征数据
                    self.fetchLifetimeStats() // 抓取历史总数据
                    completion?() // 执行回调
                } else {
                    completion?() // 失败也执行回调，防止 UI 卡死
                }
            }
        }
    }
    
    func fetchWorkouts() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: 500, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let workouts = samples as? [HKWorkout] {
                DispatchQueue.main.async { 
                    self.workouts = workouts 
                    self.fetchLifetimeStats()
                }
            }
        }
        healthStore.execute(query)
    }
    
    func fetchWorkoutDetails(for workout: HKWorkout) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrQuery = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let hrValues = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            DispatchQueue.main.async { self.workoutHeartRates = hrValues }
        }
        let cadenceType = HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!
        let cadenceQuery = HKSampleQuery(sampleType: cadenceType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            let totalCadence = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            let avgCadence = samples.isEmpty ? 0 : totalCadence / Double(samples.count)
            DispatchQueue.main.async { self.workoutCadence = avgCadence }
        }
        healthStore.execute(hrQuery)
        healthStore.execute(cadenceQuery)
    }
    
    func fetchWeeklySteps() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let startDate = calendar.date(byAdding: .day, value: -6, to: startOfDay)!
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startOfDay, intervalComponents: DateComponents(day: 1))
        query.initialResultsHandler = { _, results, _ in
            var steps: [Double] = []
            results?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let sum = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                steps.append(sum)
            }
            DispatchQueue.main.async { self.weeklySteps = steps }
        }
        healthStore.execute(query)
    }
    
    // 获取今日全天活动统计
    func fetchTodayActivityStats() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // 1. 查询热量 (Cumulative Sum)
        let energyQuery = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.todayActiveCalories = sum.doubleValue(for: .kilocalorie())
            }
        }
        
        // 2. 查询里程 (Cumulative Sum)
        let distanceQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.todayWalkingDistance = sum.doubleValue(for: .meter()) / 1000.0
            }
        }
        
        healthStore.execute(energyQuery)
        healthStore.execute(distanceQuery)
    }
    
    
    // 获取最新的一条心率数据
    func fetchLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self.heartRate = value
            }
        }
        healthStore.execute(query)
    }
    
    // 获取今日全天心率趋势序列
    func fetchTodayHeartRateSeries() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            let series = samples.map { (date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit(from: "count/min"))) }
            
            DispatchQueue.main.async {
                self.todayHeartRateSamples = series
            }
        }
        healthStore.execute(query)
    }
    
    // 获取今日每小时步数分布
    func fetchHourlySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: startOfDay, intervalComponents: DateComponents(hour: 1))
        
        query.initialResultsHandler = { _, results, _ in
            var hourlyData: [(hour: Int, steps: Double)] = []
            results?.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                let hour = Calendar.current.component(.hour, from: statistics.startDate)
                let sum = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                hourlyData.append((hour: hour, steps: sum))
            }
            DispatchQueue.main.async {
                self.hourlySteps = hourlyData
            }
        }
        
        // 顺便抓取楼层
        if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            let flightsQuery = HKStatisticsQuery(quantityType: flightsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                DispatchQueue.main.async { self.flightsClimbed = sum }
            }
            healthStore.execute(flightsQuery)
        }
        
        healthStore.execute(query)
    }
    
    // 获取特定运动的 GPS 轨迹坐标 (增强兼容性版)
    func fetchRoute(for workout: HKWorkout, completion: @escaping ([CLLocation]) -> Void) {
        let routePredicate = HKQuery.predicateForObjects(from: workout)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: routePredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            guard let routeSample = samples?.first as? HKWorkoutRoute else {
                print("DEBUG: 未找到关联轨迹 - \(error?.localizedDescription ?? "无错误信息")")
                completion([])
                return
            }
            
            var locations: [CLLocation] = []
            let dataQuery = HKWorkoutRouteQuery(route: routeSample) { (query, locationData, done, error) in
                if let data = locationData {
                    locations.append(contentsOf: data)
                }
                if done {
                    DispatchQueue.main.async {
                        print("DEBUG: 成功获取轨迹点数量: \(locations.count)")
                        completion(locations)
                    }
                }
            }
            self.healthStore.execute(dataQuery)
        }
        healthStore.execute(query)
    }
    
    // MARK: - 抓取本周与上周分析数据
    func fetchWeeklyAnalysis() {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. 本周 (周一至今)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 周一
        guard let startOfThisWeek = calendar.date(from: components) else { return }
        
        let thisWeekPredicate = HKQuery.predicateForSamples(withStart: startOfThisWeek, end: now, options: .strictStartDate)
        let thisWeekQuery = HKSampleQuery(sampleType: .workoutType(), predicate: thisWeekPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            if let workouts = samples as? [HKWorkout] {
                DispatchQueue.main.async { self.thisWeekWorkouts = workouts }
            }
        }
        
        // 2. 上周 (上周一至上周日)
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        let endOfLastWeek = calendar.date(byAdding: .second, value: -1, to: startOfThisWeek)!
        
        let lastWeekPredicate = HKQuery.predicateForSamples(withStart: startOfLastWeek, end: endOfLastWeek, options: .strictStartDate)
        let lastWeekQuery = HKSampleQuery(sampleType: .workoutType(), predicate: lastWeekPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            if let workouts = samples as? [HKWorkout] {
                DispatchQueue.main.async { self.lastWeekWorkouts = workouts }
            }
        }
        
        healthStore.execute(thisWeekQuery)
        healthStore.execute(lastWeekQuery)
    }
    
    // MARK: - 自动从 HealthKit 抓取体征资料
    func fetchUserProfile() {
        // 1. 获取出生日期
        do {
            let birthComponents = try healthStore.dateOfBirthComponents()
            if let date = birthComponents.date {
                DispatchQueue.main.async { self.userBirthDate = date.timeIntervalSince1970 }
            }
        } catch { print("DEBUG: 无法获取出生日期") }
        
        // 2. 获取性别
        do {
            let sex = try healthStore.biologicalSex().biologicalSex
            DispatchQueue.main.async {
                switch sex {
                case .male: self.userSex = 1
                case .female: self.userSex = 2
                default: self.userSex = 0
                }
            }
        } catch { print("DEBUG: 无法获取性别") }
        
        // 3. 获取最新体重
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let weightQuery = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                DispatchQueue.main.async { self.userWeight = weight }
            }
        }
        healthStore.execute(weightQuery)
        
        // 4. 获取最新身高
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        let heightQuery = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let height = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                DispatchQueue.main.async { self.userHeight = height }
            }
        }
        healthStore.execute(heightQuery)
    }
    
    // MARK: - 抓取历史累计数据
    func fetchLifetimeStats() {
        let runningType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        
        let query = HKSampleQuery(sampleType: runningType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }
            
            let totalDist = workouts.reduce(0) { $0 + ($1.totalDistance?.doubleValue(for: .meter()) ?? 0) } / 1000.0
            let totalCals = workouts.reduce(0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) }
            
            // 计算去重天数
            let dates = workouts.map { Calendar.current.startOfDay(for: $0.startDate) }
            let uniqueDays = Set(dates).count
            
            DispatchQueue.main.async {
                self.totalDistance = totalDist
                self.totalCalories = totalCals
                self.totalWorkoutDays = uniqueDays
            }
        }
        healthStore.execute(query)
    }
}
