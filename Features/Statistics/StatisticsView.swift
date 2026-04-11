// StatisticsView.swift
// Features/Statistics/
// SCR-003: 統計・レポート画面
//
// Swift Charts パターン参考:
//   - jordibruin/Swift-Charts-Examples: BarMark 積み上げ・RuleMark 目標線
//   - nalexn/clean-architecture-swiftui: ViewModel 注入パターン

import SwiftUI
import Charts

// MARK: - StatisticsView

struct StatisticsView: View {

    @State private var viewModel: StatisticsViewModel

    init(repository: DailyRecordRepositoryProtocol) {
        _viewModel = State(initialValue: StatisticsViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                    .padding(.horizontal)

                summaryCards
                    .padding(.horizontal)

                cpBarChart
                    .padding(.horizontal)

                axisAveragesCard
                    .padding(.horizontal)

                calendarHeatmapCard
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("期間", selection: $viewModel.selectedPeriod) {
            ForEach(StatisticsViewModel.Period.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 10) {
            StatSummaryCard(
                title:  "合計 CP",
                value:  "\(viewModel.periodTotalCP)",
                unit:   "CP",
                icon:   "star.fill",
                color:  .vcCP
            )
            StatSummaryCard(
                title:  "最高記録",
                value:  "\(viewModel.bestDayCP)",
                unit:   "CP/日",
                icon:   "crown.fill",
                color:  .vcExercise
            )
            StatSummaryCard(
                title:  "記録日数",
                value:  "\(viewModel.recordedDays)",
                unit:   "日",
                icon:   "calendar",
                color:  .vcSleep
            )
        }
    }

    // MARK: - CP 積み上げ棒グラフ

    private var cpBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日別 CP 記録")
                .font(.headline)

            if viewModel.barChartData.isEmpty {
                emptyPlaceholder("記録がありません", icon: "chart.bar.xaxis")
            } else {
                Chart {
                    // 積み上げ棒グラフ（軸別）
                    ForEach(viewModel.barChartData) { entry in
                        BarMark(
                            x: .value("日付", entry.date, unit: .day),
                            y: .value("CP",   entry.cp)
                        )
                        .foregroundStyle(by: .value("軸", entry.axis.shortName))
                        .cornerRadius(3)
                    }
                    // 目標ライン: 1日 500 CP
                    RuleMark(y: .value("目標", 500))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .foregroundStyle(Color.vcCP.opacity(0.7))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("500 CP 目標")
                                .font(.caption2)
                                .foregroundStyle(Color.vcCP)
                        }
                }
                // 軸→色のスケール（CLAUDE.md Key Rule 1 の5軸カラーを適用）
                .chartForegroundStyleScale([
                    "運動": Color.vcExercise,
                    "食事": Color.vcDiet,
                    "飲酒": Color.vcAlcohol,
                    "睡眠": Color.vcSleep,
                    "習慣": Color.vcLifestyle,   // CPAxis.shortName は "習慣"
                ])
                .chartXAxis {
                    let count = viewModel.selectedPeriod == .week ? 7 : 8
                    AxisMarks(values: .automatic(desiredCount: count)) { _ in
                        AxisValueLabel(format: .dateTime.month(.twoDigits).day())
                            .font(.caption2)
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 100, 200, 300, 400, 500]) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                        AxisGridLine()
                    }
                }
                .chartYScale(domain: 0...500)
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 220)
                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedPeriod)
            }
        }
        .padding()
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 軸別平均 CP

    private var axisAveragesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("軸別平均 CP（\(viewModel.selectedPeriod.rawValue)）")
                .font(.headline)

            ForEach(viewModel.axisAverages, id: \.axis) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.axis.icon)
                        .foregroundStyle(item.axis.color)
                        .frame(width: 18)

                    Text(item.axis.name)
                        .font(.subheadline)
                        .frame(width: 56, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.axis.color.opacity(0.12))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.axis.gradient)
                                .frame(width: geo.size.width * CGFloat(item.average / 100.0))
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)

                    Text(String(format: "%.0f", item.average))
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(item.axis.color)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - カレンダーヒートマップ

    private var calendarHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CP ヒートマップ（直近 90 日）")
                .font(.headline)

            CPCalendarHeatmapView(entries: viewModel.calendarData)
        }
        .padding()
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Empty Placeholder

    private func emptyPlaceholder(_ message: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(Color.vcSecondaryLabel)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.vcSecondaryLabel)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - StatSummaryCard

struct StatSummaryCard: View {
    let title: String
    let value: String
    let unit:  String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Color.vcSecondaryLabel)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.vcSecondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Calendar Heatmap
// GitHub の Contribution Graph と同スタイル。CPの強度で色を変化させる。

struct CPCalendarHeatmapView: View {

    let entries: [CalendarEntry]

    private let calendar = Calendar.current

    // date → CP のマップ
    private var cpMap: [Date: Int] {
        Dictionary(uniqueKeysWithValues: entries.map {
            (calendar.startOfDay(for: $0.date), $0.cp)
        })
    }

    // 直近90日を7日列×13週のグリッドに変換
    private var weeks: [[Date?]] {
        let today   = calendar.startOfDay(for: Date())
        var start   = calendar.date(byAdding: .day, value: -89, to: today)!

        // 月曜始まりに揃える
        let weekday   = (calendar.component(.weekday, from: start) + 5) % 7  // Mon=0
        start = calendar.date(byAdding: .day, value: -weekday, to: start)!

        var weeks: [[Date?]] = []
        var week:  [Date?]   = []
        var cur = start

        while cur <= today {
            week.append(cur)
            if week.count == 7 {
                weeks.append(week)
                week = []
            }
            cur = calendar.date(byAdding: .day, value: 1, to: cur)!
        }
        if !week.isEmpty {
            while week.count < 7 { week.append(nil) }
            weeks.append(week)
        }
        return weeks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 曜日ラベル（月〜日）
            HStack(spacing: 3) {
                Color.clear.frame(width: 20)  // 月ラベルのためのスペース
                ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.vcSecondaryLabel)
                        .frame(maxWidth: .infinity)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 3) {
                    ForEach(weeks.indices, id: \.self) { wIdx in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { dIdx in
                                if let date = weeks[wIdx][dIdx] {
                                    let isFuture = date > calendar.startOfDay(for: Date())
                                    let cp = cpMap[date] ?? 0
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(isFuture
                                              ? Color.vcSecondaryLabel.opacity(0.08)
                                              : heatColor(cp: cp))
                                        .frame(width: 12, height: 12)
                                } else {
                                    Color.clear.frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
            }

            // 凡例
            HStack(spacing: 4) {
                Text("少ない")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.vcSecondaryLabel)
                ForEach([0, 125, 250, 375, 500], id: \.self) { cp in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(cp: cp))
                        .frame(width: 10, height: 10)
                }
                Text("500 CP")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
            .padding(.top, 4)
        }
    }

    // CP 量を金色グラデーション強度にマッピング
    private func heatColor(cp: Int) -> Color {
        guard cp > 0 else { return Color.vcSecondaryLabel.opacity(0.15) }
        let t = min(Double(cp) / 500.0, 1.0)
        return Color.vcCP.opacity(0.15 + t * 0.85)
    }
}
