// AlcoholRecordView.swift
// Features/Health/Alcohol/
// SCR-013

import SwiftUI
import VitaCityCore

// MARK: - ViewModel

@Observable
final class AlcoholRecordViewModel {
    var drinkCount: Int       = 0
    var selectedType: DrinkType = .beer
    var startTime: Date       = Date()
    var endTime:   Date       = Date()
    var hasEndTime: Bool      = false

    var isSaving:  Bool    = false
    var saveError: String? = nil
    var savedCP:   Int?    = nil

    private let streakManager: StreakManager
    init(streakManager: StreakManager) { self.streakManager = streakManager }

    var previewCP: Int { CPPointCalculator.alcoholCP(drinkCount: drinkCount) }

    var statusMessage: String {
        switch drinkCount {
        case 0:     return "禁酒！最高の選択です"
        case 1...2: return "適量。健康的な楽しみ方"
        case 3...4: return "少し多めです"
        default:    return "過飲：健康に注意"
        }
    }

    var statusColor: Color {
        switch drinkCount {
        case 0:     return .vcExercise
        case 1...2: return .vcDiet
        case 3...4: return .vcDiet
        default:    return .vcLifestyle
        }
    }

    @MainActor
    func save(to record: DailyRecord) async {
        isSaving = true; defer { isSaving = false }
        let cp = previewCP
        do {
            let log = AlcoholLog(
                date:       record.date,
                drinkCount: drinkCount,
                drinkType:  selectedType,
                startTime:  drinkCount > 0 ? startTime : nil,
                endTime:    drinkCount > 0 && hasEndTime ? endTime : nil
            )
            record.alcoholLogs.append(log)
            try await streakManager.updateCP(for: record, axis: .alcohol, cp: cp)
            savedCP = cp
        } catch { saveError = error.localizedDescription }
    }
}

// MARK: - View

struct AlcoholRecordView: View {
    @State   private var viewModel: AlcoholRecordViewModel
    @Binding var record: DailyRecord
    @Environment(\.dismiss) private var dismiss

    init(record: Binding<DailyRecord>, streakManager: StreakManager) {
        self._record    = record
        self._viewModel = State(wrappedValue: AlcoholRecordViewModel(streakManager: streakManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // CP プレビュー
                cpPreviewSection

                // ドリンクカウンター
                drinkCountSection

                // 種別選択（飲む場合のみ）
                if viewModel.drinkCount > 0 {
                    drinkTypeSection
                    timeSection
                }

                VCSaveButton(title: "飲酒を記録する", color: .vcAlcohol,
                             action: { Task { await viewModel.save(to: record) } },
                             isLoading: viewModel.isSaving)
            }
            .padding()
        }
        .navigationTitle("飲酒")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完了") { dismiss() } } }
        .onChange(of: viewModel.savedCP) { _, cp in if cp != nil { dismiss() } }
        .alert("保存エラー", isPresented: .constant(viewModel.saveError != nil)) {
            Button("OK") { viewModel.saveError = nil }
        } message: { Text(viewModel.saveError ?? "") }
    }

    // MARK: - CP プレビュー

    private var cpPreviewSection: some View {
        VStack(spacing: 10) {
            ZStack {
                CPSingleRingView(progress: Double(viewModel.previewCP) / 100, color: .vcAlcohol, lineWidth: 18)
                    .frame(width: 140, height: 140)
                VStack(spacing: 2) {
                    Text("\(viewModel.previewCP)").font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcAlcohol).contentTransition(.numericText())
                    Text("CP").font(.caption.weight(.semibold)).foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.previewCP)
            Text(viewModel.statusMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewModel.statusColor)
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.vcSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - ドリンクカウンター

    private var drinkCountSection: some View {
        VCCard {
            VStack(spacing: 16) {
                HStack {
                    Label("ドリンク数", systemImage: "wineglass.fill")
                        .font(.headline).foregroundStyle(Color.vcAlcohol)
                    Spacer()
                    Text("1ドリンク = ビール350ml")
                        .font(.caption).foregroundStyle(Color.vcSecondaryLabel)
                }

                // カウンター
                HStack(spacing: 24) {
                    Button {
                        if viewModel.drinkCount > 0 { viewModel.drinkCount -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.largeTitle).foregroundStyle(viewModel.drinkCount > 0 ? Color.vcAlcohol : Color.vcSecondaryLabel)
                    }
                    .buttonStyle(.plain)

                    Text("\(viewModel.drinkCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vcLabel)
                        .frame(minWidth: 60)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: viewModel.drinkCount)

                    Button {
                        viewModel.drinkCount += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle).foregroundStyle(Color.vcAlcohol)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)

                // ドリンク可視化
                if viewModel.drinkCount > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<min(viewModel.drinkCount, 10), id: \.self) { _ in
                            Image(systemName: "wineglass.fill")
                                .foregroundStyle(Color.vcAlcohol)
                        }
                        if viewModel.drinkCount > 10 {
                            Text("+\(viewModel.drinkCount - 10)")
                                .font(.caption.bold()).foregroundStyle(Color.vcAlcohol)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - 種別

    private var drinkTypeSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("種類").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([DrinkType.beer, .wine, .sake, .whisky, .shochu, .other], id: \.self) { type in
                            let (icon, name) = drinkTypeInfo(type)
                            Button { viewModel.selectedType = type } label: {
                                Label(name, systemImage: icon)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .foregroundStyle(viewModel.selectedType == type ? .white : Color.vcAlcohol)
                                    .background(viewModel.selectedType == type ? Color.vcAlcohol : Color.vcAlcohol.opacity(0.12),
                                                in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 時刻

    private var timeSection: some View {
        VCCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("時刻（任意）").font(.headline)
                DatePicker("開始", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                Toggle("終了時刻を記録", isOn: $viewModel.hasEndTime).tint(Color.vcAlcohol)
                if viewModel.hasEndTime {
                    DatePicker("終了", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                }
            }
        }
    }

    private func drinkTypeInfo(_ type: DrinkType) -> (String, String) {
        switch type {
        case .beer:   return ("mug.fill", "ビール")
        case .wine:   return ("wineglass.fill", "ワイン")
        case .sake:   return ("fork.knife", "日本酒")
        case .whisky: return ("flame.fill", "ウイスキー")
        case .shochu: return ("sparkles", "焼酎")
        case .other:  return ("ellipsis.circle", "その他")
        }
    }
}
