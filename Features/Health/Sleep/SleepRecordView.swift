// SleepRecordView.swift
// Features/Health/Sleep/
// SCR-014

import SwiftUI
import VitaCityCore

// MARK: - ViewModel

@Observable
final class SleepRecordViewModel {
    var bedtime:  Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    var isFromHealthKit: Bool = false
    var manualComment: String = ""  // 良い/普通/悪い

    var isSaving:  Bool    = false
    var saveError: String? = nil
    var savedCP:   Int?    = nil

    private let streakManager: StreakManager
    init(streakManager: StreakManager) { self.streakManager = streakManager }

    var durationHours: Double {
        let diff = wakeTime.timeIntervalSince(bedtime)
        let adjusted = diff < 0 ? diff + 86400 : diff  // 翌日起床の場合
        return max(0, adjusted / 3600)
    }

    var durationText: String {
        let h = Int(durationHours)
        let m = Int((durationHours - Double(h)) * 60)
        return "\(h)時間 \(m)分"
    }

    var previewCP: Int { CPPointCalculator.sleepCP(hours: durationHours) }

    var sleepQualityMessage: String {
        switch previewCP {
        case 100: return "理想的な睡眠！"
        case 80:  return "少し長め"
        case 60:  return "もう少し眠れると良いです"
        default:  return "睡眠が短すぎます"
        }
    }

    @MainActor
    func save(to record: DailyRecord) async {
        isSaving = true; defer { isSaving = false }
        let cp = previewCP
        do {
            let log = SleepLog(
                date:            record.date,
                bedtime:         bedtime,
                wakeTime:        wakeTime,
                durationMinutes: Int(durationHours * 60),
                sleepScore:      cp,
                source:          isFromHealthKit ? .healthKit : .manual
            )
            record.sleepLogs.append(log)
            try await streakManager.updateCP(for: record, axis: .sleep, cp: cp)
            savedCP = cp
        } catch { saveError = error.localizedDescription }
    }

    func applyHealthKitSleep(hours: Double) {
        // HealthKit から取得した睡眠時間を反映
        let now = Date()
        wakeTime = now
        bedtime  = Calendar.current.date(byAdding: .hour, value: -Int(hours), to: now) ?? now
        isFromHealthKit = true
    }
}

// MARK: - View

struct SleepRecordView: View {
    @State   private var viewModel: SleepRecordViewModel
    @Binding var record: DailyRecord
    @Environment(\.dismiss) private var dismiss

    init(record: Binding<DailyRecord>, streakManager: StreakManager) {
        self._record    = record
        self._viewModel = State(wrappedValue: SleepRecordViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cpPreviewSection
                timePickerSection
                summarySection

                VCSaveButton(title: "睡眠を記録する", color: .vcSleep,
                             action: { Task { await viewModel.save(to: record) } },
                             isLoading: viewModel.isSaving)
            }
            .padding()
        }
        .navigationTitle("睡眠")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完了") { dismiss() } } }
        .onChange(of: viewModel.savedCP) { _, cp in if cp != nil { dismiss() } }
        .alert("保存エラー", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") { viewModel.saveError = nil }
        } message: { Text(viewModel.saveError ?? "") }
    }

    // MARK: - Sections

    private var cpPreviewSection: some View {
        VStack(spacing: 12) {
            ZStack {
                CPSingleRingView(progress: Double(viewModel.previewCP) / 100, color: .vcSleep, lineWidth: 18)
                    .frame(width: 140, height: 140)
                VStack(spacing: 2) {
                    Text("\(viewModel.previewCP)").font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcSleep).contentTransition(.numericText())
                    Text("CP").font(.caption.weight(.semibold)).foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.previewCP)

            Text(viewModel.durationText)
                .font(.title3.weight(.semibold)).foregroundStyle(Color.vcSleep)
            Text(viewModel.sleepQualityMessage)
                .font(.subheadline).foregroundStyle(Color.vcSecondaryLabel)

            if viewModel.isFromHealthKit {
                Label("Apple Health から自動取得", systemImage: "heart.fill")
                    .font(.caption).foregroundStyle(.pink)
            }
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    private var timePickerSection: some View {
        VCCard {
            VStack(spacing: 16) {
                HStack {
                    Label("就寝・起床時刻", systemImage: "moon.fill")
                        .font(.headline).foregroundStyle(Color.vcSleep)
                    Spacer()
                }
                DatePicker("就寝", selection: $viewModel.bedtime,  displayedComponents: .hourAndMinute)
                Divider()
                DatePicker("起床", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var summarySection: some View {
        VCCard {
            VStack(spacing: 12) {
                Text("睡眠の目安").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                ForEach([
                    ("7〜9時間", "100 CP", true),
                    ("9時間超",  "80 CP",  false),
                    ("6時間台",  "60 CP",  false),
                    ("5時間以下","20 CP",  false),
                ], id: \.0) { (range, cp, isIdeal) in
                    HStack {
                        Image(systemName: isIdeal ? "star.fill" : "circle")
                            .font(.caption).foregroundStyle(isIdeal ? Color.vcCP : Color.vcSecondaryLabel)
                        Text(range).font(.subheadline)
                        Spacer()
                        Text(cp).font(.subheadline.weight(.bold)).foregroundStyle(isIdeal ? Color.vcSleep : Color.vcSecondaryLabel)
                    }
                }
            }
        }
    }
}
