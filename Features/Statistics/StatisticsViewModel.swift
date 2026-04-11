// StatisticsViewModel.swift
// Features/Statistics/
// SCR-003: 統計・レポート画面のViewModel

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class StatisticsViewModel {

    // MARK: - Period

    enum Period: String, CaseIterable {
        case week  = "週"
        case month = "月"
    }

    // MARK: - State

    var selectedPeriod: Period = .week
    var records: [DailyRecord] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: DailyRecordRepositoryProtocol

    init(repository: DailyRecordRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try await repository.recentRecords(limit: 90)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Derived: Period Records

    var periodRecords: [DailyRecord] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return records
            .filter { $0.date >= cutoff && !$0.isArchived }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Bar Chart Data（軸別積み上げ棒グラフ）

    var barChartData: [DailyChartEntry] {
        periodRecords.flatMap { record in
            CPAxis.allCases.map { axis in
                DailyChartEntry(date: record.date, axis: axis, cp: axis.cp(from: record))
            }
        }
    }

    // MARK: - Trend Data（合計 CP 折れ線グラフ）

    var trendData: [TrendEntry] {
        periodRecords.map { TrendEntry(date: $0.date, totalCP: $0.totalCP) }
    }

    // MARK: - Axis Averages（軸別平均 CP）

    var axisAverages: [(axis: CPAxis, average: Double)] {
        guard !periodRecords.isEmpty else {
            return CPAxis.allCases.map { ($0, 0.0) }
        }
        return CPAxis.allCases.map { axis in
            let sum = periodRecords.reduce(0) { $0 + axis.cp(from: $1) }
            return (axis, Double(sum) / Double(periodRecords.count))
        }
    }

    // MARK: - Summary Stats

    var periodTotalCP: Int { periodRecords.reduce(0) { $0 + $1.totalCP } }
    var bestDayCP: Int    { periodRecords.map(\.totalCP).max() ?? 0 }
    var recordedDays: Int { periodRecords.count }

    // MARK: - Calendar Heatmap（直近 90 日）

    var calendarData: [CalendarEntry] {
        records.map { CalendarEntry(date: $0.date, cp: $0.totalCP) }
    }
}

// MARK: - Chart Data Types

struct DailyChartEntry: Identifiable {
    let id   = UUID()
    let date: Date
    let axis: CPAxis
    let cp:   Int
}

struct TrendEntry: Identifiable {
    let id      = UUID()
    let date:   Date
    let totalCP: Int
}

struct CalendarEntry: Identifiable {
    let id  = UUID()
    let date: Date
    let cp:  Int

    var intensity: Double { min(Double(cp) / 500.0, 1.0) }
}
