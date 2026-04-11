// HomeView.swift
// Features/City/
// SCR-001: ホーム画面（街ビュー）
//
// CLAUDE.md Key Rule 9: CitySceneCoordinator 経由でのみ SpriteKit と通信

import SwiftUI
import SpriteKit

struct HomeView: View {

    @Environment(AppState.self) private var appState
    @State private var coordinator = CitySceneCoordinator()
    @State private var showBuildingDetail = false
    @State private var showPremiumStore = false
    @State private var cachedScene: CityScene? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // ─── SpriteKit 街ビュー ───
                GeometryReader { geo in
                    SpriteView(
                        scene: makeScene(size: geo.size),
                        options: [.allowsTransparency]
                    )
                    .ignoresSafeArea()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ─── 下部オーバーレイ ───
                VStack {
                    // 上部: 日付・天気・CP
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer()

                    // 下部: 本日の CP サマリー
                    bottomSummary
                        .padding()
                }
            }

            // ─── バナー広告（プレミアム未購入時のみ・記録画面外）───
            // App Store 5.1.3: HealthKit データを広告に渡さない
            AdBannerView()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(item: $coordinator.selectedBuilding) { building in
            BuildingDetailSheet(building: building)
        }
        .sheet(isPresented: $showPremiumStore) {
            PremiumStoreView()
                .environment(appState)
        }
        .onChange(of: appState.todaySteps) { _, steps in
            coordinator.updateStepCount(steps)
        }
        .task {
            // 初回起動時の状態反映
            coordinator.updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
        }
    }

    // MARK: - Make Scene

    private func makeScene(size: CGSize) -> CityScene {
        if let existing = cachedScene { return existing }
        let scene         = CityScene(size: size)
        scene.scaleMode   = .aspectFill
        scene.coordinator = coordinator
        cachedScene       = scene
        return scene
    }

    // MARK: - 上部バー

    private var topBar: some View {
        HStack {
            // 日付・天気
            HStack(spacing: 6) {
                Image(systemName: weatherIcon)
                    .foregroundStyle(weatherColor)
                Text(Date().formatted(.dateTime.month().day()))
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            // プレミアムボタン（未購入時のみ）
            if !appState.isPremium {
                Button {
                    showPremiumStore = true
                } label: {
                    Image(systemName: "crown.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.vcCP)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }

            // CP 表示
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.vcCP)
                    .font(.caption)
                Text("\(coordinator.totalCP) CP")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vcCP)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    // MARK: - 下部サマリー

    private var bottomSummary: some View {
        VStack(spacing: 0) {
            // 天気メッセージ
            Text(weatherMessage)
                .font(.caption)
                .foregroundStyle(Color.vcSecondaryLabel)
                .padding(.bottom, 6)

            HStack(spacing: 8) {
                ForEach(CPAxis.allCases, id: \.self) { axis in
                    VStack(spacing: 3) {
                        Image(systemName: axis.icon)
                            .font(.caption)
                            .foregroundStyle(axis.color)
                        Text("\(axis.cp(from: appState.todayRecord))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(axis.cp(from: appState.todayRecord) > 0
                                             ? axis.color : Color.vcSecondaryLabel)
                        Text(axis.shortName)
                            .font(.system(size: 8))
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Weather helpers

    private var weatherIcon: String {
        switch coordinator.currentWeather {
        case .sunny:        return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy:       return "cloud.fill"
        case .rainy:        return "cloud.rain.fill"
        case .stormy:       return "cloud.bolt.rain.fill"
        }
    }

    private var weatherColor: Color {
        switch coordinator.currentWeather {
        case .sunny:        return .yellow
        case .partlyCloudy: return .orange
        case .cloudy:       return .gray
        case .rainy:        return .blue
        case .stormy:       return .purple
        }
    }

    private var weatherMessage: String {
        switch coordinator.currentWeather {
        case .sunny:        return "快晴！街は活気に満ちています"
        case .partlyCloudy: return "晴れ時々曇り。良い調子です"
        case .cloudy:       return "曇り空。記録を頑張りましょう"
        case .rainy:        return "雨が降っています。健康習慣を続けよう"
        case .stormy:       return "嵐。記録を積み重ねて街を守ろう！"
        }
    }
}

// MARK: - BuildingDetailSheet

struct BuildingDetailSheet: View {
    let building: BuildingInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 建物アイコン（仮）
                ZStack {
                    Circle()
                        .fill(building.axis.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: building.axis.icon)
                        .font(.largeTitle)
                        .foregroundStyle(building.axis.color)
                }

                Text(building.name)
                    .font(.title2.bold())

                HStack(spacing: 12) {
                    Label("\(building.axis.name)軸", systemImage: building.axis.icon)
                        .font(.subheadline)
                        .foregroundStyle(building.axis.color)
                    Divider().frame(height: 16)
                    Label("Lv.\(building.level)", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.vcCP)
                }

                Text(building.description)
                    .font(.body)
                    .foregroundStyle(Color.vcSecondaryLabel)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("建物詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
