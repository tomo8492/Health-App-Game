// LifestyleRecordView.swift
// Features/Health/Lifestyle/
// SCR-015

import SwiftUI
import VitaCityCore

// MARK: - ViewModel

@Observable
final class LifestyleRecordViewModel {
    var waterCups:       Int  = 0
    var stressLevel:     Int  = 3     // 1〜5
    var meditationDone:  Bool = false
    var readingDone:     Bool = false
    var detoxDone:       Bool = false

    var isSaving:  Bool    = false
    var saveError: String? = nil
    var savedCP:   Int?    = nil

    private let streakManager: StreakManager
    init(streakManager: StreakManager) { self.streakManager = streakManager }

    var habitsCompleted: Bool { meditationDone || readingDone || detoxDone }
    var previewCP: Int {
        CPPointCalculator.lifestyleCP(
            waterCups:       waterCups,
            stressLevel:     stressLevel,
            habitsCompleted: habitsCompleted
        )
    }

    var stressLabels: [String] { ["平穏", "少し", "普通", "高め", "強い"] }
    var stressMessage: String {
        switch stressLevel {
        case 1, 2: return "+40CP 低ストレス！"
        case 3:    return "+20CP 中ストレス"
        default:   return "ストレス管理が必要"
        }
    }

    @MainActor
    func save(to record: DailyRecord) async {
        isSaving = true; defer { isSaving = false }
        let cp = previewCP
        do {
            let log = LifestyleLog(
                date:           record.date,
                waterCups:      waterCups,
                stressLevel:    stressLevel,
                meditationDone: meditationDone,
                readingDone:    readingDone,
                detoxDone:      detoxDone
            )
            record.lifestyleLogs.append(log)
            try await streakManager.updateCP(for: record, axis: .lifestyle, cp: cp)
            savedCP = cp
        } catch { saveError = error.localizedDescription }
    }
}

// MARK: - View

struct LifestyleRecordView: View {
    @State   private var viewModel: LifestyleRecordViewModel
    @Binding var record: DailyRecord
    @Environment(\.dismiss) private var dismiss

    init(record: Binding<DailyRecord>, streakManager: StreakManager) {
        self._record    = record
        self._viewModel = State(wrappedValue: LifestyleRecordViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cpPreviewSection
                waterSection
                stressSection
                habitsSection
                VCSaveButton(title: "生活習慣を記録する", color: .vcLifestyle,
                             action: { Task { await viewModel.save(to: record) } },
                             isLoading: viewModel.isSaving)
            }
            .padding()
        }
        .navigationTitle("生活習慣")
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
                CPSingleRingView(progress: Double(viewModel.previewCP) / 100, color: .vcLifestyle, lineWidth: 18)
                    .frame(width: 140, height: 140)
                VStack(spacing: 2) {
                    Text("\(viewModel.previewCP)").font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcLifestyle).contentTransition(.numericText())
                    Text("CP").font(.caption.weight(.semibold)).foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.previewCP)
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    private var waterSection: some View {
        VCCard {
            WaterCupsView(cups: Binding(
                get:  { viewModel.waterCups },
                set:  { viewModel.waterCups = $0 }
            ))
        }
    }

    private var stressSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("ストレスレベル", systemImage: "brain.head.profile")
                        .font(.headline).foregroundStyle(Color.vcLifestyle)
                    Spacer()
                    Text(viewModel.stressMessage)
                        .font(.caption.weight(.semibold)).foregroundStyle(Color.vcLifestyle)
                }
                LabeledSlider(
                    title:  "レベル \(viewModel.stressLevel)",
                    value:  Binding(
                        get: { Double(viewModel.stressLevel) },
                        set: { viewModel.stressLevel = Int($0) }
                    ),
                    range:  1...5,
                    step:   1,
                    labels: viewModel.stressLabels,
                    color:  .vcLifestyle
                )
            }
        }
    }

    private var habitsSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("習慣チェック (+30CP)").font(.headline)
                HabitToggle(icon: "figure.mind.and.body", label: "瞑想・深呼吸",          isOn: $viewModel.meditationDone, color: .vcLifestyle)
                Divider()
                HabitToggle(icon: "book.fill",             label: "読書・学習",            isOn: $viewModel.readingDone,    color: .vcLifestyle)
                Divider()
                HabitToggle(icon: "iphone.slash",          label: "デジタルデトックス",    isOn: $viewModel.detoxDone,      color: .vcLifestyle)
            }
        }
    }
}

private struct HabitToggle: View {
    let icon:  String
    let label: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(label, systemImage: icon)
                .foregroundStyle(isOn ? color : Color.vcLabel)
        }
        .tint(color)
    }
}
