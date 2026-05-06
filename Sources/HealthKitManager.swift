import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var steps: Double = 0
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var distance: Double = 0
    @Published var weeklySteps: [Double] = []
    @Published var workouts: [HKWorkout] = []
    
    // 用于详情页的详细数据
    @Published var workoutHeartRates: [Double] = []
    @Published var workoutCadence: Double = 0
    
    var coachingMessage: String {
        if steps >= 10000 {
            return "目标已达成！今日表现极佳，建议保持状态。💪"
        } else if steps > 5000 {
            return "已经走了一半路程了，加油再接再厉！🚀"
        } else {
            return "身体是革命的本钱，出门走走呼吸新鲜空气吧。🌳"
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchAllData()
                }
            }
        }
    }
    
    func fetchAllData() {
        fetchTodaySteps()
        fetchLatestHeartRate()
        fetchTodayCalories()
        fetchTodayDistance()
        fetchWeeklySteps()
        fetchWorkouts()
    }
    
    func fetchWorkouts() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: 500, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }
            DispatchQueue.main.async {
                self.workouts = workouts.filter { 
                    $0.workoutActivityType == .running || $0.workoutActivityType == .walking 
                }
            }
        }
        healthStore.execute(query)
    }
    
    func fetchWorkoutDetails(for workout: HKWorkout) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let hrSamples = samples as? [HKQuantitySample] else { return }
            let hrValues = hrSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            DispatchQueue.main.async {
                self.workoutHeartRates = hrValues
            }
        }
        
        let cadenceType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let cadenceQuery = HKStatisticsQuery(quantityType: cadenceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let durationInMinutes = workout.duration / 60.0
            let totalSteps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async {
                self.workoutCadence = durationInMinutes > 1.0 ? (totalSteps / durationInMinutes) : 0
            }
        }
        
        healthStore.execute(hrQuery)
        healthStore.execute(cadenceQuery)
    }
    
    func fetchWeeklySteps() {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: startOfToday)!
        
        let interval = DateComponents(day: 1)
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: sevenDaysAgo, intervalComponents: interval)
        
        query.initialResultsHandler = { _, results, _ in
            var stepsData: [Double] = []
            results?.enumerateStatistics(from: sevenDaysAgo, to: now) { statistics, _ in
                let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                stepsData.append(steps)
            }
            DispatchQueue.main.async {
                self.weeklySteps = stepsData
            }
        }
        healthStore.execute(query)
    }
    
    func fetchTodaySteps() {
        fetchSum(for: .stepCount, unit: .count()) { self.steps = $0 }
    }
    
    func fetchTodayCalories() {
        fetchSum(for: .activeEnergyBurned, unit: .kilocalorie()) { self.calories = $0 }
    }
    
    func fetchTodayDistance() {
        fetchSum(for: .distanceWalkingRunning, unit: .meter()) { self.distance = $0 / 1000.0 } // Convert to KM
    }
    
    private func fetchSum(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            DispatchQueue.main.async {
                completion(sum)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchLatestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        healthStore.execute(query)
    }
}
