import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var currentSteps: Double = 0
    @Published var baselineSteps: Double = 0
    @Published var isAuthorized: Bool = false
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchData()
                }
                completion(success)
            }
        }
    }
    
    func fetchData() {
        fetchTodaySteps()
        fetchBaselineSteps()
    }
    
    private func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            DispatchQueue.main.async {
                self.currentSteps = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchBaselineSteps() {
        // Calculate 7-day average
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        // We want daily totals, then average them.
        // For MVP simplicity, we'll just get the total for the last 7 days and divide by 7.
        // This is a rough approximation (includes today partial).
        // A better way is HKStatisticsCollectionQuery, but let's keep it simple for MVP.
        
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            let totalSteps = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                self.baselineSteps = totalSteps / 7.0
            }
        }
        healthStore.execute(query)
    }
}
