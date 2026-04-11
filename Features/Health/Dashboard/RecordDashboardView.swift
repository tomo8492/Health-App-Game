// RecordDashboardView.swift
// Features/Health/Dashboard/
// SCR-002: 記録ダッシュボード

import SwiftUI

// MARK: - ViewModel

@Observable
final class RecordDashboardViewModel {

    var todayRecord:  DailyRecord?
    var streak:       Int    = 0
    var isLoading:    Bool   = false
    var errorMessage: String? = nil

    let streakManager: StreakManager

    init(streakManager: StreakManager) {
        self.streakManager = streakManager
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todayRecord = try await streakManager.todayRecord()
            streak      = try await streakManager.currentStreak()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cp(for axis: CPAxis) -> Int { axis.cp(from: todayRecord) }

    var totalCP: Int { todayRecord?.totalCP ?? 0 }

    var completedAxes: Int {
        CPAxis.allCases.filter { $0.isRecorded(in: todayRecord) }.count
    }

    var isAllComplete: Bool { completedAxes == 5 }
}

// MARK: - View

struct RecordDashboardView: View {

    @State var viewModel: RecordDashboardViewModel
    @State private var activeSheet: CPAxis? = nil
    @Environment(AppState.self) private var appState  // ★ 保存後に AppState を同期

    init(streakManager: StreakManager) {
        _viewModel = State(wrappedValue: RecordDashboardViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ─── ヘッダー（日付 + ストリーク）───
                headerSection

                // ─── 5軸リング ───
                ringSection

                // ─── クイック記録ボタン ───
                quickRecordSection

                // ─── 直近7日バー ───
                weeklyBarSection
            }
            .padding()
        }
        .navigationTitle("今日の記録")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $activeSheet) { axis in
            recordSheet(for: axis)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.month().day().weekday()))
                    .font(.subheadline)
                    .foregroundStyle(Color.vcSecondaryLabel)
                Text("今日の健康記録")
                    .font(.title2.weight(.bold))
            }
            Spacer()
            StreakBadgeView(streak: viewModel.streak)
        }
    }

    private var ringSection: some View {
        VStack(spacing: 16) {
            CPFiveRingsView(record: viewModel.todayRecord, size: 240)
                .padding(.vertical, 8)

            // 5軸 CP サマリー
            HStack(spacing: 0) {
                ForEach(CPAxis.allCases, id: \.self) { axis in
                    VStack(spacing: 4) {
                        Image(systemName: axis.icon)
                            .font(.caption)
                            .foregroundStyle(axis.color)
                        Text("\(viewModel.cp(for: axis))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vcLabel)
                            .contentTransition(.numericText())
                        Text(axis.shortName)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 14))

            if viewModel.isAllComplete {
                Label("本日全軸記録完了！", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vcCP)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.5), value: viewModel.todayRecord?.totalCP)
    }

    private var quickRecordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイック記録")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CPAxis.allCases, id: \.self) { axis in
                    QuickRecordButton(
                        axis:      axis,
                        cp:        viewModel.cp(for: axis),
                        isRecorded: axis.isRecorded(in: viewModel.todayRecord)
                    ) {
                        activeSheet = axis
                    }
                }
            }
        }
    }

    private var weeklyBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日の軸別 CP")
                    .font(.headline)
                Spacer()
                Text("統計タブで詳細を確認")
                    .font(.caption2)
                    .foregroundStyle(Color.vcSecondaryLabel)
            }
            // 今日の5軸 CP バー
            VStack(spacing: 8) {
                ForEach(CPAxis.allCases, id: \.self) { axis in
                    let cp = viewModel.cp(for: axis)
                    HStack(spacing: 10) {
                        Image(systemName: axis.icon)
                            .font(.caption)
                            .foregroundStyle(axis.color)
                            .frame(width: 16)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(axis.color.opacity(0.12))
                                Capsule().fill(axis.color)
                                    .frame(width: geo.size.width * CGFloat(cp) / 100.0)
                            }
                            .frame(height: 6)
                        }
                        .frame(height: 6)
                        Text("\(cp)")
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .foregroundStyle(axis.color)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Record Sheet

    @ViewBuilder
    private func recordSheet(for axis: CPAxis) -> some View {
        NavigationStack {
            if let record = viewModel.todayRecord {
                let binding = Binding(
                    get: { record },
                    set: { viewModel.todayRecord = $0 }
                )
                switch axis {
                case .exercise:
                    ExerciseRecordView(record: binding, streakManager: viewModel.streakManager)
                case .diet:
                    DietRecordView(record: binding, streakManager: viewModel.streakManager)
                case .alcohol:
                    AlcoholRecordView(record: binding, streakManager: viewModel.streakManager)
                case .sleep:
                    SleepRecordView(record: binding, streakManager: viewModel.streakManager)
                case .lifestyle:
                    LifestyleRecordView(record: binding, streakManager: viewModel.streakManager)
                }
            } else {
                ProgressView().task { await viewModel.load() }
            }
        }
        .onDisappear {
            Task {
                await viewModel.load()
                // 記録保存後に AppState を更新 → RootView の onChange → 街・実績・ウィジェット反映 ★
                appState.todayRecord  = viewModel.todayRecord
                appState.todayTotalCP = viewModel.totalCP
                appState.todayStreak  = viewModel.streak
            }
        }
    }
}

// MARK: - QuickRecordButton

private struct QuickRecordButton: View {
    let axis:       CPAxis
    let cp:         Int
    let isRecorded: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CPSmallRingView(axis: axis, cp: cp, size: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(axis.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vcLabel)
                    Text(isRecorded ? "\(cp) CP 記録済み" : "タップして記録")
                        .font(.caption)
                        .foregroundStyle(isRecorded ? axis.color : Color.vcSecondaryLabel)
                }
                Spacer()

                Image(systemName: isRecorded ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isRecorded ? axis.color : Color.vcSecondaryLabel)
                    .font(.caption)
            }
            .padding(12)
            .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

