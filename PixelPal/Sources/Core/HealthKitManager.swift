import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    /// Today's step count (for display).
    @Published var currentSteps: Double = 0

    /// 7-day average steps (for baseline reference).
    @Published var baselineSteps: Double = 0

    /// Cumulative steps since user profile creation.
    @Published var cumulativeSteps: Int = 0

    /// Whether HealthKit is authorized.
    @Published var isAuthorized: Bool = false

    /// Last sync timestamp.
    @Published var lastSync: Date?

    /// Cache duration for cumulative steps (1 hour).
    private let cacheDuration: TimeInterval = 3600

    /// Cached cumulative value and timestamp.
    private var cumulativeCache: (steps: Int, timestamp: Date)?

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

    /// Fetches all data including cumulative steps since baseline.
    /// - Parameter baselineDate: The date to start cumulative counting from.
    func fetchAllData(since baselineDate: Date) {
        fetchTodaySteps()
        fetchBaselineSteps()
        fetchCumulativeSteps(since: baselineDate)
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
                self.lastSync = Date()
            }
        }
        healthStore.execute(query)
    }

    private func fetchBaselineSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

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

    // MARK: - Cumulative Step Tracking (v1.1)

    /// Fetches cumulative steps since the given baseline date.
    /// Uses caching to avoid expensive re-queries.
    /// - Parameter baselineDate: Start date for cumulative counting (usually UserProfile.createdAt).
    func fetchCumulativeSteps(since baselineDate: Date) {
        // Check cache validity
        if let cache = cumulativeCache,
           Date().timeIntervalSince(cache.timestamp) < cacheDuration {
            // Cache is valid, use cached value
            return
        }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: baselineDate, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self else { return }

            if let error = error {
                print("HealthKitManager: Failed to fetch cumulative steps: \(error)")
                return
            }

            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.cumulativeSteps = 0
                    self.cumulativeCache = (0, Date())
                }
                return
            }

            let total = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.cumulativeSteps = total
                self.cumulativeCache = (total, Date())
                self.lastSync = Date()
            }
        }
        healthStore.execute(query)
    }

    /// Forces a refresh of cumulative steps, bypassing cache.
    /// - Parameter baselineDate: Start date for cumulative counting.
    func refreshCumulativeSteps(since baselineDate: Date) {
        cumulativeCache = nil
        fetchCumulativeSteps(since: baselineDate)
    }

    /// Async version of cumulative step fetch.
    /// - Parameter baselineDate: Start date for cumulative counting.
    /// - Returns: Total cumulative steps.
    func fetchCumulativeStepsAsync(since baselineDate: Date) async -> Int {
        // Check cache validity
        if let cache = cumulativeCache,
           Date().timeIntervalSince(cache.timestamp) < cacheDuration {
            return cache.steps
        }

        return await withCheckedContinuation { continuation in
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let now = Date()
            let predicate = HKQuery.predicateForSamples(withStart: baselineDate, end: now, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let total = Int(sum.doubleValue(for: HKUnit.count()))

                DispatchQueue.main.async {
                    self?.cumulativeSteps = total
                    self?.cumulativeCache = (total, Date())
                    self?.lastSync = Date()
                }

                continuation.resume(returning: total)
            }
            healthStore.execute(query)
        }
    }

    /// Invalidates the cumulative cache (call when user pulls to refresh).
    func invalidateCache() {
        cumulativeCache = nil
    }
}
