import SwiftUI
import HealthKit
import CoreLocation

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var workouts: [HKWorkout] = []
    @Published var weeklySteps: [Double] = [0, 0, 0, 0, 0, 0, 0]
    @Published var workoutHeartRates: [Double] = []
    @Published var workoutCadence: Double = 0
    
    // 今日全天统计 (真实手机数据)
    @Published var todayActiveCalories: Double = 0
    @Published var todayWalkingDistance: Double = 0
    @Published var userAge: Int = 25
    @Published var heartRate: Double = 72
    @Published var todayHeartRateSamples: [(date: Date, value: Double)] = []
    @Published var hourlySteps: [(hour: Int, steps: Double)] = [] // 每小时步数
    @Published var flightsClimbed: Double = 0 // 爬楼层数
    
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
                    self.fetchUserAge()
                    self.fetchLatestHeartRate()
                    self.fetchTodayHeartRateSeries()
                    self.fetchHourlySteps() // 抓取小时级分布
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
                DispatchQueue.main.async { self.workouts = workouts }
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
    
    // 获取用户真实年龄
    func fetchUserAge() {
        do {
            let birthDate = try healthStore.dateOfBirthComponents()
            if let year = birthDate.year {
                let currentYear = Calendar.current.component(.year, from: Date())
                DispatchQueue.main.async {
                    self.userAge = currentYear - year
                }
            }
        } catch {
            print("无法获取年龄数据: \(error.localizedDescription)")
        }
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
}
