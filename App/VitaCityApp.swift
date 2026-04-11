// VitaCityApp.swift
// App/
//
// エントリポイント・DI コンテナ
// CLAUDE.md Key Rule 11: CloudKit は cloudKitDatabase: .none で明示的に無効化

import SwiftUI
import SwiftData

@main
struct VitaCityApp: App {

    // MARK: - SwiftData コンテナ

    let modelContainer: ModelContainer = {
        let schema = Schema([
            DailyRecord.self,
            ExerciseLog.self,
            DietLog.self,
            AlcoholLog.self,
            SleepLog.self,
            LifestyleLog.self,
        ])
        // CloudKit は将来実装。今は .none で明示的に無効化（CLAUDE.md Key Rule 11）
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData ModelContainer 初期化失敗: \(error)")
        }
    }()

    // MARK: - App 全体の状態（Single Source of Truth）

    @State private var appState = AppState()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - RootView（タブナビゲーション）

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self)  private var appState
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム（Phase 2 で街ビューに置き換え）
            NavigationStack {
                HomePlaceholderView()
            }
            .tabItem { Label("ホーム", systemImage: "house.fill") }
            .tag(AppTab.home)

            // 記録ダッシュボード SCR-002
            NavigationStack {
                RecordDashboardView(streakManager: makeStreakManager())
            }
            .tabItem { Label("記録", systemImage: "pencil.and.list.clipboard") }
            .tag(AppTab.record)

            // 統計（Phase 3 実装）
            NavigationStack {
                StatisticsPlaceholderView()
            }
            .tabItem { Label("統計", systemImage: "chart.bar.fill") }
            .tag(AppTab.statistics)

            // 街管理（Phase 2 実装）
            NavigationStack {
                CityPlaceholderView()
            }
            .tabItem { Label("街管理", systemImage: "building.2.fill") }
            .tag(AppTab.city)

            // 実績（Phase 4 実装）
            NavigationStack {
                AchievementsPlaceholderView()
            }
            .tabItem { Label("実績", systemImage: "trophy.fill") }
            .tag(AppTab.achievements)
        }
        .tint(Color.vcCP)
        .task { await setupApp() }
    }

    // MARK: - DI

    private func makeStreakManager() -> StreakManager {
        StreakManager(repository: DailyRecordRepository(modelContext: modelContext))
    }

    // MARK: - App 起動時の処理

    private func setupApp() async {
        // HealthKit 認可
        let hkService = HealthKitService()
        if hkService.isAvailable {
            try? await hkService.requestAuthorization()
            appState.isHealthKitAuthorized = true
        }
        // 今日の歩数取得
        let steps = (try? await hkService.fetchTodaySteps()) ?? 0
        appState.todaySteps = steps
        // HealthKit バックグラウンド監視
        hkService.startStepCountObserver { steps in
            appState.todaySteps = steps
        }
    }
}

// MARK: - Tab 定義

enum AppTab: Hashable {
    case home, record, statistics, city, achievements
}

// MARK: - Placeholder Views (各 Phase で実装予定)

struct HomePlaceholderView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.vcCP)
            Text("VITA CITY").font(.largeTitle.bold())
            Text("Phase 2 で街ビューが表示されます")
                .foregroundStyle(Color.vcSecondaryLabel)
            Text("今日の歩数: \(appState.todaySteps)")
                .font(.subheadline)
        }
        .navigationTitle("VITA CITY")
    }
}

struct StatisticsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("統計 (Phase 3)", systemImage: "chart.bar.fill",
            description: Text("Swift Charts による統計グラフは Phase 3 で実装予定"))
    }
}

struct CityPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("街管理 (Phase 2)", systemImage: "building.2.fill",
            description: Text("SpriteKit による街ビューは Phase 2 で実装予定"))
    }
}

struct AchievementsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("実績 (Phase 4)", systemImage: "trophy.fill",
            description: Text("実績・バッジシステムは Phase 4 で実装予定"))
    }
}
