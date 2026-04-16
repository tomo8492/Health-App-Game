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
    @State private var ringPulseTrigger: Int = 0      // CP リング光のパルス（CP増加時）
    @State private var celebrate: Bool = false        // 全軸完了の祝福
    @State private var lastTotalCP: Int = 0
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
            ZStack {
                // 光のパルス（CP 増加時）
                Circle()
                    .stroke(Color.vcCP.opacity(ringPulseTrigger > 0 ? 0.0 : 0.0), lineWidth: 0)
                    .frame(width: 240, height: 240)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.vcCP.opacity(0.0), lineWidth: 4)
                        .frame(width: 240, height: 240)
                        .modifier(PulseEffect(
                            id: ringPulseTrigger,
                            delay: Double(i) * 0.12,
                            color: Color.vcCP
                        ))
                }
                CPFiveRingsView(record: viewModel.todayRecord, size: 240)
                    .padding(.vertical, 8)
            }

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
                ZStack {
                    // 紙吹雪風の背景パルス
                    if celebrate {
                        ConfettiView()
                            .frame(height: 60)
                            .transition(.opacity)
                    }
                    Label("本日全軸記録完了！🎉", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.vcCP)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.vcCP.opacity(0.20), Color.vcCP.opacity(0.05)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .scaleEffect(celebrate ? 1.06 : 1.0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.55), value: celebrate)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.5), value: viewModel.todayRecord?.totalCP)
        .onChange(of: viewModel.totalCP) { old, new in
            // CP が増えたら光のパルスを発生 + ハプティック
            if new > old {
                ringPulseTrigger += 1
                HapticEngine.tapLight()
            }
            // 全軸完了したら祝福アニメーション + サクセスハプティック
            if viewModel.isAllComplete && !celebrate {
                celebrate = true
                HapticEngine.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    celebrate = false
                }
            }
            lastTotalCP = new
        }
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
                appState.todayRecord     = viewModel.todayRecord
                appState.todayTotalCP    = viewModel.totalCP
                appState.todayStreak     = viewModel.streak
                // 飲酒数を同期 → B029/B030 ペナルティ建物トリガー（CLAUDE.md Key Rule 2）
                appState.todayDrinkCount = viewModel.todayRecord?.alcoholLogs.last?.drinkCount ?? -1
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

    @State private var pressed: Bool = false

    var body: some View {
        Button {
            // 触覚フィードバック → アクション
            HapticEngine.tapLight()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { pressed = false }
            }
            action()
        } label: {
            HStack(spacing: 12) {
                CPSmallRingView(axis: axis, cp: cp, size: 52)
                    .shadow(color: pressed ? axis.color.opacity(0.6) : .clear, radius: 8)

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
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.vcSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(axis.color.opacity(pressed ? 0.7 : 0), lineWidth: 1.4)
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PulseEffect (CP リング外側の光のパルス)

private struct PulseEffect: ViewModifier {
    let id: Int          // 変化するたびにアニメーションをトリガーする
    let delay: Double
    let color: Color

    @State private var scale: CGFloat = 0.95
    @State private var opacity: Double = 0.0

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 3)
                    .scaleEffect(scale)
                    .opacity(opacity)
            )
            .onChange(of: id) { _, _ in
                // 即座にリセット → アニメーション
                scale = 0.95
                opacity = 0.85
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    scale = 1.25
                    opacity = 0.0
                }
            }
    }
}

// MARK: - ConfettiView (全軸完了時の紙吹雪)

private struct ConfettiView: View {
    private let pieces = (0..<22).map { _ in ConfettiPiece.random() }
    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<pieces.count, id: \.self) { i in
                let p = pieces[i]
                Rectangle()
                    .fill(p.color)
                    .frame(width: 5, height: 8)
                    .rotationEffect(.degrees(animate ? p.endRotation : 0))
                    .offset(
                        x: animate ? p.endX : 0,
                        y: animate ? p.endY : -20
                    )
                    .opacity(animate ? 0.0 : 1.0)
                    .animation(
                        .easeOut(duration: p.duration).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }

    private struct ConfettiPiece {
        let color: Color
        let endX: CGFloat
        let endY: CGFloat
        let endRotation: Double
        let duration: Double
        let delay: Double

        static func random() -> ConfettiPiece {
            let palette: [Color] = [.vcExercise, .vcDiet, .vcAlcohol, .vcSleep, .vcLifestyle, .vcCP]
            return ConfettiPiece(
                color: palette.randomElement() ?? .vcCP,
                endX: CGFloat.random(in: -120...120),
                endY: CGFloat.random(in: 30...80),
                endRotation: Double.random(in: -180...180),
                duration: Double.random(in: 1.4...2.2),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}

