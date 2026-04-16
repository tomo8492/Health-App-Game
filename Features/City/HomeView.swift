// HomeView.swift
// Features/City/
// SCR-001: ホーム画面（街ビュー）
//
// カイロソフト風 HUD デザイン（参考画像1）:
//   ┌──────────────────────────────────────────────────┐
//   │  Y1 春  ⛅ 3  ☀  ★10  [軸別 CP アイコン]    │ ← topBar
//   ├──────────────────────────────────────────────────┤
//   │                                                  │
//   │              CITY VIEW（SpriteKit）              │
//   │                                                  │
//   ├──────────────────────────────────────────────────┤
//   │ [建物名]        Lv.3    人気 45  CP +30 / 日    │ ← buildingInfoBar
//   ├──────────────────────────────────────────────────┤
//   │  [切替]                          [メニュー ▶]  │ ← bottomBar
//   └──────────────────────────────────────────────────┘
//
// CLAUDE.md Key Rule 9: CitySceneCoordinator 経由のみで SpriteKit と通信

import SwiftUI
import SpriteKit

struct HomeView: View {

    @Environment(AppState.self)             private var appState
    @Environment(CitySceneCoordinator.self) private var coordinator
    @State private var showPremiumStore  = false
    @State private var showCityManagement = false
    @State private var cachedScene: CityScene?
    @State private var cpBadgePulse:  Bool = false  // CP バッジパルス（totalCP 増加時）
    @State private var weatherIconPulse: Bool = false
    @State private var showMinimap: Bool = true

    var body: some View {
        ZStack(alignment: .top) {

            // ─── 全画面 SpriteKit 街ビュー ───
            GeometryReader { geo in
                SpriteView(
                    scene: makeScene(size: geo.size),
                    options: [.allowsTransparency]
                )
                .ignoresSafeArea()
            }

            // ─── UI オーバーレイ ───
            VStack(spacing: 0) {
                topBar
                Spacer()
                if coordinator.selectedBuilding != nil {
                    buildingInfoBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomBar
            }
            .animation(.spring(duration: 0.3), value: coordinator.selectedBuilding != nil)

            // ─── ミニマップ（右下、トグル可能） ───
            if showMinimap {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MinimapView(coordinator: coordinator)
                            .padding(.trailing, 12)
                            .padding(.bottom, coordinator.selectedBuilding == nil ? 56 : 110)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.4), value: coordinator.selectedBuilding != nil)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPremiumStore) {
            PremiumStoreView().environment(appState)
        }
        .sheet(isPresented: $showCityManagement) {
            NavigationStack { CityManagementView().environment(appState) }
        }
        .onChange(of: appState.todaySteps) { _, steps in
            coordinator.updateStepCount(steps)
        }
        .onChange(of: coordinator.totalCP) { _, cp in
            cachedScene?.updateHUDCP(cp)
            // CP バッジに弾むパルスを与える
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                cpBadgePulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    cpBadgePulse = false
                }
            }
        }
        .onChange(of: coordinator.currentWeather) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) { weatherIconPulse.toggle() }
        }
        .task {
            coordinator.updateTimeOfDay(Calendar.current.component(.hour, from: Date()))
        }
    }

    // MARK: - Make Scene

    private func makeScene(size: CGSize) -> CityScene {
        if let s = cachedScene { return s }
        let s = CityScene(size: size)
        s.scaleMode  = .resizeFill
        s.coordinator = coordinator
        cachedScene  = s
        return s
    }

    // MARK: - 上部ステータスバー（カイロソフト風）

    private var topBar: some View {
        HStack(spacing: 0) {
            // 年・季節
            yearSeasonBadge

            Spacer(minLength: 4)

            // 天気 + 住人数
            weatherBadge

            Spacer(minLength: 4)

            // ★ CP スコア
            cpBadge

            Spacer(minLength: 4)

            // 5軸 CP
            axisResourcesBar

            // プレミアムボタン
            if !appState.isPremium {
                premiumButton
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .padding(.top, safeAreaTopPadding)
    }

    private var yearSeasonBadge: some View {
        VStack(spacing: 1) {
            let year = max(1, coordinator.totalCP / 365 + 1)
            let season = currentSeason
            Text("Y\(year)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(season)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(seasonColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }

    private var weatherBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: weatherIcon)
                .font(.system(size: 12))
                .foregroundStyle(weatherIconColor)
                .symbolEffect(.bounce, value: weatherIconPulse)
            Text("\(coordinator.npcCount)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .contentTransition(.numericText())
            Image(systemName: "person.2.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }

    private var cpBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.vcCP)
                .scaleEffect(cpBadgePulse ? 1.45 : 1.0)
                .shadow(color: Color.vcCP.opacity(cpBadgePulse ? 0.85 : 0), radius: 6)
            Text("\(coordinator.totalCP)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vcCP)
                .contentTransition(.numericText())
                .scaleEffect(cpBadgePulse ? 1.18 : 1.0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Color.white.opacity(cpBadgePulse ? 0.30 : 0.15),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.vcCP.opacity(cpBadgePulse ? 0.85 : 0), lineWidth: 1.2)
        )
    }

    private var axisResourcesBar: some View {
        HStack(spacing: 5) {
            ForEach(CPAxis.allCases, id: \.self) { axis in
                VStack(spacing: 1) {
                    Image(systemName: axis.icon)
                        .font(.system(size: 8))
                        .foregroundStyle(axis.color)
                    Text("\(axis.cp(from: appState.todayRecord))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }

    private var premiumButton: some View {
        Button { showPremiumStore = true } label: {
            Image(systemName: "crown.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.vcCP)
                .padding(5)
                .background(Color.white.opacity(0.15), in: Circle())
        }
        .padding(.leading, 4)
    }

    // MARK: - 建物情報バー（タップ時表示）

    private var buildingInfoBar: some View {
        Group {
            if let building = coordinator.selectedBuilding {
                HStack(spacing: 0) {
                    // 建物名・軸
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        Label(building.axis.shortName + "軸", systemImage: building.axis.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(building.axis.color)
                    }
                    .frame(minWidth: 80, alignment: .leading)
                    .padding(.leading, 12)

                    Spacer()

                    // Lv
                    VStack(spacing: 2) {
                        Text("Lv.\(building.level)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.vcCP)
                    }

                    Spacer()

                    // 統計
                    HStack(spacing: 12) {
                        statItem(label: "人気", value: "\(building.level * 12 + 30)",
                                 icon: "heart.fill", color: .pink)
                        statItem(label: "地価", value: "\(building.level * 50)万",
                                 icon: "building.2.fill", color: .orange)
                        statItem(label: "CP", value: "+\(building.level * 8)/日",
                                 icon: "star.fill", color: .vcCP)
                    }
                    .padding(.trailing, 12)
                }
                .frame(height: 52)
                .background(
                    Color.black.opacity(0.72)
                        .overlay(
                            building.axis.color.opacity(0.18)
                        )
                )
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(building.axis.color.opacity(0.8)),
                    alignment: .top
                )
                .onTapGesture {
                    coordinator.selectedBuilding = nil
                }
            }
        }
    }

    private func statItem(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    // MARK: - 下部ナビゲーションバー（カイロソフト風）

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // 全体図ボタン（カメラをマップ中心・等倍にリセット）
            Button {
                coordinator.resetCamera()
            } label: {
                Text("全体図")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 64, height: 36)
                    .background(Color(UIColor(hex:"4A5568")))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }

            Spacer()

            // 天気メッセージ（中央）
            Text(weatherMessage)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineLimit(1)

            Spacer()

            // メニューボタン
            Button {
                showCityManagement = true
            } label: {
                HStack(spacing: 4) {
                    Text("メニュー")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.vcCP)
                }
                .frame(width: 90, height: 36)
                .background(Color(UIColor(hex:"2D6A4F")))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.vcCP.opacity(0.5), lineWidth: 0.5)
                )
            }
        }
        .frame(height: 36)
        .background(Color.black.opacity(0.75))
    }

    // MARK: - Helpers

    private var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return "春"
        case 6...8:  return "夏"
        case 9...11: return "秋"
        default:     return "冬"
        }
    }

    private var seasonColor: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:  return Color(UIColor(hex:"FFB6C1"))
        case 6...8:  return Color(UIColor(hex:"87CEEB"))
        case 9...11: return Color(UIColor(hex:"FFA500"))
        default:     return Color(UIColor(hex:"B0E0E6"))
        }
    }

    private var weatherIcon: String {
        switch coordinator.currentWeather {
        case .sunny:        return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy:       return "cloud.fill"
        case .rainy:        return "cloud.rain.fill"
        case .stormy:       return "cloud.bolt.rain.fill"
        }
    }

    private var weatherIconColor: Color {
        switch coordinator.currentWeather {
        case .sunny:        return .yellow
        case .partlyCloudy: return .orange
        case .cloudy:       return Color(UIColor(hex:"B0BEC5"))
        case .rainy:        return .cyan
        case .stormy:       return .purple
        }
    }

    private var weatherMessage: String {
        switch coordinator.currentWeather {
        case .sunny:        return "快晴！街は活気に満ちています"
        case .partlyCloudy: return "晴れ時々曇り。良い調子です"
        case .cloudy:       return "曇り空。記録を頑張りましょう"
        case .rainy:        return "雨模様。健康習慣を続けよう"
        case .stormy:       return "嵐。記録で街を守ろう！"
        }
    }

    private var safeAreaTopPadding: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 0
    }
}

// MARK: - MinimapView

/// 街全体を俯瞰する小型ミニマップ。
/// - 軸別建物色のドット表示
/// - 中央に市庁舎マーカー
/// - 右下に街レベルバッジ
private struct MinimapView: View {

    let coordinator: CitySceneCoordinator

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 背景タイル
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 96, height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                    )

                // ベース地面（緑のダイアモンド風背景）
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.45, green: 0.78, blue: 0.40),
                                     Color(red: 0.20, green: 0.50, blue: 0.18)],
                            center: .center, startRadius: 4, endRadius: 38
                        )
                    )
                    .frame(width: 72, height: 72)

                // 中央道路（十字）
                Rectangle().fill(Color.white.opacity(0.35)).frame(width: 70, height: 2)
                Rectangle().fill(Color.white.opacity(0.35)).frame(width: 2, height: 70)

                // 建設済み建物のドット（軸色）
                // Set をそのまま ForEach するとハッシュ順が毎回変わり SwiftUI の diff が無駄に走るので
                // 確定順序でソートして安定した再描画にする
                ForEach(coordinator.builtBuildingIds.sorted(), id: \.self) { id in
                    if let entry = BuildingCatalog.all.first(where: { $0.id == id }) {
                        Circle()
                            .fill(entry.axis.color)
                            .frame(width: 5, height: 5)
                            .offset(buildingOffset(for: id))
                    }
                }

                // 中央市庁舎マーカー
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.vcCP)
                    .shadow(color: Color.vcCP.opacity(0.7), radius: 2)

                // 街レベルバッジ（右下）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Lv.\(coordinator.cityLevel)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.vcCP)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.7), in: Capsule())
                    }
                }
                .frame(width: 90, height: 90)
            }

            Text("\(coordinator.builtBuildingIds.count) 棟")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    /// 軸ゾーンの相対オフセット（CityScene.findBestPosition と同方向）
    private func buildingOffset(for id: String) -> CGSize {
        guard let entry = BuildingCatalog.all.first(where: { $0.id == id }) else {
            return .zero
        }
        // ハッシュで個別ジッタを与える（重なり防止）
        let jitter = CGFloat((id.hashValue % 11) - 5)
        switch entry.axis {
        case .exercise:  return CGSize(width:  18 + jitter * 0.6, height: -16 + jitter * 0.4)
        case .diet:      return CGSize(width: -18 + jitter * 0.6, height: -16 + jitter * 0.4)
        case .alcohol:   return CGSize(width: -18 + jitter * 0.6, height:   8 + jitter * 0.4)
        case .sleep:     return CGSize(width: -18 + jitter * 0.6, height:  20 + jitter * 0.4)
        case .lifestyle: return CGSize(width:  16 + jitter * 0.6, height:  16 + jitter * 0.4)
        }
    }
}

