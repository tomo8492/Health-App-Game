// ExerciseRecordView.swift
// Features/Health/Exercise/
// SCR-011

import SwiftUI

struct ExerciseRecordView: View {
    @Environment(AppState.self)    private var appState
    @State private var viewModel:  ExerciseRecordViewModel
    @Binding  var record:          DailyRecord

    @Environment(\.dismiss) private var dismiss

    init(record: Binding<DailyRecord>, streakManager: StreakManager) {
        self._record   = record
        self._viewModel = State(wrappedValue: ExerciseRecordViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ─── CP プレビュー ───
                cpPreviewSection

                // ─── 歩数 ───
                stepsSection

                // ─── ワークアウト ───
                workoutSection

                // ─── 保存ボタン ───
                VCSaveButton(
                    title:     "運動を記録する",
                    color:     .vcExercise,
                    action:    { Task { await viewModel.save(to: record) } },
                    isLoading: viewModel.isSaving
                )
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("運動")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完了") { dismiss() }
            }
        }
        .onAppear {
            // HealthKit の歩数を自動反映
            viewModel.applyHealthKitSteps(appState.todaySteps)
        }
        .onChange(of: viewModel.savedCP) { _, cp in
            guard cp != nil else { return }
            dismiss()
        }
        .alert("保存エラー", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }

    // MARK: - CP プレビュー

    private var cpPreviewSection: some View {
        VStack(spacing: 12) {
            ZStack {
                CPSingleRingView(
                    progress: Double(viewModel.previewCP) / 100.0,
                    color: .vcExercise,
                    lineWidth: 18
                )
                .frame(width: 140, height: 140)

                VStack(spacing: 2) {
                    Text("\(viewModel.previewCP)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcExercise)
                        .contentTransition(.numericText())
                    Text("CP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.previewCP)

            if viewModel.isFromHealthKit {
                Label("HealthKit から自動取得", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color.pink)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 歩数セクション

    private var stepsSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("歩数", systemImage: "figure.walk")
                        .font(.headline)
                        .foregroundStyle(Color.vcExercise)
                    Spacer()
                    Text("\(viewModel.steps) 歩")
                        .font(.headline.monospacedDigit())
                }

                // 歩数バー
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vcExercise.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vcExercise)
                            .frame(width: geo.size.width * viewModel.stepsProgress, height: 8)
                            .animation(.spring(), value: viewModel.stepsProgress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("0")
                        .font(.caption)
                        .foregroundStyle(Color.vcSecondaryLabel)
                    Spacer()
                    Text("目標: 10,000 歩 = 60CP")
                        .font(.caption)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }

                // ステッパー
                Stepper(
                    "\(viewModel.steps) 歩",
                    value: Binding(
                        get: { viewModel.steps },
                        set: { viewModel.steps = $0; viewModel.isFromHealthKit = false }
                    ),
                    in: 0...50000,
                    step: 500
                )
                .labelsHidden()
            }
        }
    }

    // MARK: - ワークアウトセクション

    private var workoutSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("ワークアウト", systemImage: "dumbbell.fill")
                        .font(.headline)
                        .foregroundStyle(Color.vcExercise)
                    Spacer()
                    Text("\(viewModel.workoutMinutes) 分")
                        .font(.headline.monospacedDigit())
                }

                // 種別ピッカー
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([WorkoutType.running, .walking, .strength, .swimming, .yoga, .cycling, .other], id: \.self) { type in
                            WorkoutTypeChip(
                                type:       type,
                                isSelected: viewModel.selectedType == type
                            ) {
                                viewModel.selectedType = type
                            }
                        }
                    }
                }

                // 時間スライダー
                VStack(spacing: 4) {
                    HStack {
                        Text("時間")
                            .font(.subheadline)
                        Spacer()
                        Text(viewModel.workoutMinutes >= 30 ? "30分達成 ✓ +40CP" : "あと \(30 - viewModel.workoutMinutes) 分で +40CP")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(viewModel.workoutMinutes >= 30 ? Color.vcExercise : Color.vcSecondaryLabel)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.workoutMinutes) },
                            set: { viewModel.workoutMinutes = Int($0) }
                        ),
                        in: 0...120, step: 5
                    )
                    .tint(.vcExercise)
                }
            }
        }
    }
}

// MARK: - WorkoutType チップ

private struct WorkoutTypeChip: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var label: (icon: String, name: String) {
        switch type {
        case .running:  return ("figure.run", "ランニング")
        case .walking:  return ("figure.walk", "ウォーキング")
        case .strength: return ("dumbbell", "筋トレ")
        case .swimming: return ("figure.pool.swim", "水泳")
        case .yoga:     return ("figure.mind.and.body", "ヨガ")
        case .cycling:  return ("figure.outdoor.cycle", "サイクリング")
        case .other:    return ("sportscourt", "その他")
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: label.icon)
                    .font(.title3)
                Text(label.name)
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : Color.vcExercise)
            .background(isSelected ? Color.vcExercise : Color.vcExercise.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
