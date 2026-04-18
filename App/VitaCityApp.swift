// VitaCityApp.swift
// App/
//
// エントリポイント・DI コンテナ
// CLAUDE.md Key Rule 11: CloudKit は cloudKitDatabase: .none で明示的に無効化

import SwiftUI
import SwiftData
import WidgetKit
import VitaCityCore

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

    @State private var selectedTab:        AppTab = .home
    @State private var achievementEngine   = AchievementEngine()
    @State private var cityCoordinator     = CitySceneCoordinator()   // ★ RootView で一元管理
    @State private var loginBonusService   = LoginBonusService()
    @State private var pendingAchievement: Achievement? = nil
    @State private var showPremiumStore:   Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム SCR-001（SpriteKit 街ビュー）
            NavigationStack { HomeView() }
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)

            // 記録ダッシュボード SCR-002
            NavigationStack {
                RecordDashboardView(streakManager: makeStreakManager())
            }
            .tabItem { Label("記録", systemImage: "pencil.and.list.clipboard") }
            .tag(AppTab.record)

            // 統計 SCR-003（Swift Charts）
            NavigationStack {
                StatisticsView(repository: makeDailyRecordRepository())
            }
            .tabItem { Label("統計", systemImage: "chart.bar.fill") }
            .tag(AppTab.statistics)

            // 街管理
            NavigationStack { CityManagementView() }
                .tabItem { Label("街管理", systemImage: "building.2.fill") }
                .tag(AppTab.city)

            // 実績（Phase 4）
            NavigationStack { AchievementsView() }
                .tabItem { Label("実績", systemImage: "trophy.fill") }
                .tag(AppTab.achievements)
                .environment(achievementEngine)
        }
        .tint(Color.vcCP)
        // CitySceneCoordinator を全タブから参照可能にする（CLAUDE.md Key Rule 9）
        .environment(cityCoordinator)
        .achievementBanner($pendingAchievement)
        // ログインボーナスオーバーレイ（新しい日の初回起動時に表示）
        .loginBonusOverlay($loginBonusService.pendingBonus)
        .sheet(isPresented: $showPremiumStore) {
            PremiumStoreView().environment(appState)
        }
        .task { await setupApp() }
        // 今日の CP 変化を街ビューへ同期（todayCP と totalCP を分離管理）
        .onChange(of: appState.todayTotalCP) { _, newCP in
            cityCoordinator.syncTodayCP(newCP)
            Task { await checkAchievements() }
        }
        // 歩数変化を街の NPC 数へ同期
        .onChange(of: appState.todaySteps) { _, steps in
            cityCoordinator.updateStepCount(steps)
        }
        // 飲酒数変化を街のペナルティ建物へ同期（CLAUDE.md Key Rule 2: B029/B030）
        .onChange(of: appState.todayDrinkCount) { _, count in
            cityCoordinator.syncAlcohol(drinkCount: count)
        }
        // プレミアム解放を街へ反映
        .onChange(of: appState.isPremium) { _, premium in
            if premium { cityCoordinator.unlockPremium() }
        }
    }

    // MARK: - DI

    private func makeStreakManager() -> StreakManager {
        StreakManager(repository: DailyRecordRepository(modelContext: modelContext))
    }

    private func makeDailyRecordRepository() -> DailyRecordRepository {
        DailyRecordRepository(modelContext: modelContext)
    }

    // MARK: - App 起動時の処理 ★ 全修正済み

    private func setupApp() async {
        let streakMgr = makeStreakManager()
        let hkService = HealthKitService()

        // 1. HealthKit 認可
        if hkService.isAvailable {
            try? await hkService.requestAuthorization()
            appState.isHealthKitAuthorized = true
        }

        // 2. 今日の DailyRecord を取得して AppState に設定 ★
        await appState.refreshTodayRecord(streakManager: streakMgr)

        // 3. 歩数取得（バックグラウンド監視も開始）
        let steps = (try? await hkService.fetchTodaySteps()) ?? 0
        appState.todaySteps = steps
        hkService.startStepCountObserver { steps in appState.todaySteps = steps }

        // 4. 睡眠データ（CLAUDE.md Key Rule 7: 朝の起動時のみ・前夜分）★
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12, let record = appState.todayRecord, record.sleepCP == 0 {
            let sleepHours = (try? await hkService.fetchLastNightSleep()) ?? 0
            if sleepHours > 0 {
                let sleepCP = CPPointCalculator.sleepCP(hours: sleepHours)
                try? await streakMgr.updateCP(for: record, axis: .sleep, cp: sleepCP)
                await appState.refreshTodayRecord(streakManager: streakMgr)
            }
        }

        // 5. 旧データアーカイブ（無料版: 90日超）★
        try? await streakMgr.archiveOldRecords(isPremium: appState.isPremium)

        // 6. 起動時の街ビュー同期（cumulative CP を DB から計算して初期化）
        let repo = makeDailyRecordRepository()
        let cumulativeCP  = (try? await repo.cumulativeCPTotal())  ?? appState.todayTotalCP
        // 前日 CP を取得: 朝の天気ベースライン計算に使用
        // （ストリーク×10 + 前日CP×30% を上限150として天気の底上げに使用）
        let previousDayCP = (try? await repo.previousDayCPTotal()) ?? 0
        cityCoordinator.initCumulativeCP(
            cumulative:    cumulativeCP,
            today:         appState.todayTotalCP,
            streak:        appState.todayStreak,
            previousDayCP: previousDayCP
        )
        cityCoordinator.updateTimeOfDay(Calendar.current.component(.hour, from: Date()))

        // 7. ログインボーナス判定（日付が変わった初回起動のみ）
        if let bonus = loginBonusService.checkAndAwardDailyBonus() {
            cityCoordinator.awardLoginBonus(amount: bonus.totalCP)
        }

        // 8. 通知スケジュール
        await NotificationService.shared.scheduleDailyReminder()

        // 9. 実績チェック
        await checkAchievements()
    }

    // MARK: - 実績チェック + ウィジェット更新

    private func checkAchievements() async {
        let repo = makeDailyRecordRepository()
        guard let allRecords = try? await repo.recentRecords(limit: 365) else { return }
        let streak = appState.todayStreak

        achievementEngine.checkAchievements(
            totalCP:     cityCoordinator.totalCP,   // 累計 CP（マイルストーン実績に使用）
            streak:      streak,
            npcCount:    cityCoordinator.npcCount,
            todayRecord: appState.todayRecord,
            allRecords:  allRecords
        )
        if let unlocked = achievementEngine.recentlyUnlocked {
            pendingAchievement = unlocked
            achievementEngine.recentlyUnlocked = nil
        }
        let record = appState.todayRecord
        WidgetDataStore.save(
            totalCP:     record?.totalCP     ?? 0,
            exerciseCP:  record?.exerciseCP  ?? 0,
            dietCP:      record?.dietCP      ?? 0,
            alcoholCP:   record?.alcoholCP   ?? 0,
            sleepCP:     record?.sleepCP     ?? 0,
            lifestyleCP: record?.lifestyleCP ?? 0,
            streak:      streak,
            isPremium:   appState.isPremium
        )
    }
}

// MARK: - Tab 定義

enum AppTab: Hashable {
    case home, record, statistics, city, achievements
}

