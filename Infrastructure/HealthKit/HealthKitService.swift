// HealthKitService.swift
// Infrastructure/HealthKit/
//
// CLAUDE.md Key Rule 7（HealthKit データ取得タイミング）:
//   - 歩数・消費カロリー: バックグラウンド（HKObserverQuery）+ 起動時
//   - ワークアウト: 起動時
//   - 睡眠分析: 朝の起動時のみ（前夜分を取得）—バックグラウンド禁止
//   - 心拍数・体重: 統計画面表示時

import Foundation
import HealthKit

// MARK: - Protocol

protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func fetchTodaySteps() async throws -> Int
    func fetchTodayCalories() async throws -> Int
    func fetchLastNightSleep() async throws -> Double  // 時間単位
    func startStepCountObserver(onUpdate: @escaping (Int) -> Void)
}

// MARK: - 実装

@MainActor
final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()

    // MARK: - 読み取り権限を要求するデータ型

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount)           { types.insert(steps) }
        if let cal   = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)  { types.insert(cal) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)       { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    // MARK: - AvailabilityCheck

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - 認可フロー（CLAUDE.md Key Rule 7 準拠）

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - 歩数取得（起動時 + バックグラウンド対象）

    func fetchTodaySteps() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end:       Date(),
            options:   .strictStartDate
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType:   stepType,
                quantitySamplePredicate: predicate,
                options:        .cumulativeSum
            ) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                continuation.resume(returning: steps)
            }
            store.execute(query)
        }
    }

    // MARK: - カロリー取得

    func fetchTodayCalories() async throws -> Int {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end:       Date(),
            options:   .strictStartDate
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType:   calType,
                quantitySamplePredicate: predicate,
                options:        .cumulativeSum
            ) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                let cal = Int(result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
                continuation.resume(returning: cal)
            }
            store.execute(query)
        }
    }

    // MARK: - 睡眠データ取得（朝の起動時のみ・CLAUDE.md Key Rule 7 準拠）

    func fetchLastNightSleep() async throws -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let yesterday  = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let sleepStart = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday)!
        let wakeEnd    = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let predicate  = HKQuery.predicateForSamples(withStart: sleepStart, end: wakeEnd, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType:   sleepType,
                predicate:    predicate,
                limit:        HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let asleepSamples = (samples as? [HKCategorySample])?.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                } ?? []
                let totalSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            store.execute(query)
        }
    }

    // MARK: - 歩数バックグラウンド監視（歩数・カロリーのみ）

    func startStepCountObserver(onUpdate: @escaping (Int) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard error == nil, let self else { return }
            Task { @MainActor in
                let steps = (try? await self.fetchTodaySteps()) ?? 0
                onUpdate(steps)
            }
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: stepType, frequency: .immediate) { _, _ in }
    }
}
