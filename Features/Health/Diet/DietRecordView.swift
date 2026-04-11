// DietRecordView.swift
// Features/Health/Diet/
// SCR-012

import SwiftUI
import VitaCityCore

struct DietRecordView: View {
    @State   private var viewModel: DietRecordViewModel
    @Binding var record: DailyRecord
    @Environment(\.dismiss) private var dismiss

    init(record: Binding<DailyRecord>, streakManager: StreakManager) {
        self._record    = record
        self._viewModel = State(wrappedValue: DietRecordViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // CP プレビュー
                cpPreviewSection

                // 3食評価
                mealsSection

                // オプション
                optionsSection

                // 保存
                VCSaveButton(
                    title:     "食事を記録する",
                    color:     .vcDiet,
                    action:    { Task { await viewModel.save(to: record) } },
                    isLoading: viewModel.isSaving
                )
            }
            .padding()
        }
        .navigationTitle("食事")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完了") { dismiss() } } }
        .onChange(of: viewModel.savedCP) { _, cp in if cp != nil { dismiss() } }
        .alert("保存エラー", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") { viewModel.saveError = nil }
        } message: { Text(viewModel.saveError ?? "") }
    }

    // MARK: - Sections

    private var cpPreviewSection: some View {
        VStack(spacing: 10) {
            ZStack {
                CPSingleRingView(progress: Double(viewModel.previewCP) / 100, color: .vcDiet, lineWidth: 18)
                    .frame(width: 140, height: 140)
                VStack(spacing: 2) {
                    Text("\(viewModel.previewCP)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Color.vcDiet)
                        .contentTransition(.numericText())
                    Text("CP").font(.caption.weight(.semibold)).foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.previewCP)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    private var mealsSection: some View {
        VCCard {
            VStack(spacing: 16) {
                Text("3食の評価").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                MealQualityRow(meal: "朝食", icon: "sun.horizon.fill",    quality: $viewModel.breakfastQuality)
                Divider()
                MealQualityRow(meal: "昼食", icon: "sun.max.fill",        quality: $viewModel.lunchQuality)
                Divider()
                MealQualityRow(meal: "夕食", icon: "moon.stars.fill",     quality: $viewModel.dinnerQuality)
            }
        }
    }

    private var optionsSection: some View {
        VCCard {
            VStack(spacing: 12) {
                Text("詳細（任意）").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                Toggle(isOn: $viewModel.hasSnack) {
                    Label("間食あり（-10CP）", systemImage: "cup.and.saucer.fill")
                        .foregroundStyle(viewModel.hasSnack ? Color.vcLifestyle : Color.vcLabel)
                }
                .tint(Color.vcDiet)
                Toggle(isOn: $viewModel.hasProtein) {
                    Label("タンパク質多め", systemImage: "fish.fill")
                }
                .tint(Color.vcDiet)
                Toggle(isOn: $viewModel.hasVegetable) {
                    Label("野菜摂取あり", systemImage: "leaf.fill")
                }
                .tint(Color.vcExercise)
            }
        }
    }
}

// MARK: - MealQualityRow

private struct MealQualityRow: View {
    let meal:   String
    let icon:   String
    @Binding var quality: MealQuality

    var body: some View {
        HStack {
            Label(meal, systemImage: icon)
                .font(.subheadline)
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                ForEach([MealQuality.bad, .normal, .allGood], id: \.rawStringValue) { q in
                    Button {
                        quality = q
                    } label: {
                        Text(q.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(quality == q ? .white : q.color)
                            .background(quality == q ? q.color : q.color.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
