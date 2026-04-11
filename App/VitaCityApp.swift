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

    @State private var appState    = AppState()
    @State private var adService   = AdService()
    @State private var isLaunching = true     // ローンチアニメーション制御

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(appState)
                    .environment(adService)
                    .modelContainer(modelContainer)

                if isLaunching {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isLaunching = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - RootView（タブナビゲーション）

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self)  private var appState
    @State private var selectedTab:        AppTab = .home
    @State private var achievementEngine   = AchievementEngine()
    @State private var notificationService = NotificationService()
    @State private var pendingAchievement: Achievement? = nil
    @State private var showPremiumStore:   Bool = false
    @Environment(AdService.self) private var adService

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム SCR-001（SpriteKit 街ビュー）
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("ホーム", systemImage: "house.fill") }
            .tag(AppTab.home)

            // 記録ダッシュボード SCR-002
            NavigationStack {
                RecordDashboardView(streakManager: makeStreakManager())
            }
            .tabItem { Label("記録", systemImage: "pencil.and.list.clipboard") }
            .tag(AppTab.record)
            .environment(notificationService)

            // 統計 SCR-003（Swift Charts）
            NavigationStack {
                StatisticsView(repository: makeDailyRecordRepository())
            }
            .tabItem { Label("統計", systemImage: "chart.bar.fill") }
            .tag(AppTab.statistics)

            // 街管理
            NavigationStack {
                CityManagementView()
            }
            .tabItem { Label("街管理", systemImage: "building.2.fill") }
            .tag(AppTab.city)
            .environment(adService)

            // 実績 SCR（Phase 4）
            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("実績", systemImage: "trophy.fill")
            }
            .tag(AppTab.achievements)
            .environment(achievementEngine)
        }
        .tint(Color.vcCP)
        .achievementBanner($pendingAchievement)
        .sheet(isPresented: $showPremiumStore) {
            PremiumStoreView()
                .environment(appState)
        }
        .task { await setupApp() }
        .onChange(of: appState.todayTotalCP) { _, _ in
            Task { await checkAchievements() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            BuildingTextureGenerator.clearCache()
        }
    }

    // MARK: - DI

    private func makeStreakManager() -> StreakManager {
        StreakManager(repository: DailyRecordRepository(modelContext: modelContext))
    }

    private func makeDailyRecordRepository() -> DailyRecordRepository {
        DailyRecordRepository(modelContext: modelContext)
    }

    // MARK: - App 起動時の処理

    private func setupApp() async {
        // 今日の記録を AppState に反映（todayRecord が nil のまま CP が 0 になるのを防ぐ）
        await appState.refreshTodayRecord(using: makeStreakManager())

        // 広告 SDK 初期化（プレミアム未購入時のみ実質動作）
        await adService.initialize()

        // 通知許可リクエスト + 毎日リマインダーを登録
        await notificationService.requestAuthorization()
        notificationService.scheduleDailyReminder(hour: 20)
        notificationService.clearBadge()

        let hkService = HealthKitService()
        if hkService.isAvailable {
            try? await hkService.requestAuthorization()
            appState.isHealthKitAuthorized = true
        }
        let steps = (try? await hkService.fetchTodaySteps()) ?? 0
        appState.todaySteps = steps
        hkService.startStepCountObserver { steps in
            appState.todaySteps = steps
        }
        await checkAchievements()
    }

    // MARK: - 実績チェック + ウィジェット更新

    private func checkAchievements() async {
        let repo = makeDailyRecordRepository()
        guard let allRecords = try? await repo.recentRecords(limit: 365) else { return }
        let streak = (try? await repo.currentStreak()) ?? 0

        achievementEngine.checkAchievements(
            totalCP:     appState.todayTotalCP,
            streak:      streak,
            npcCount:    0,     // CitySceneCoordinator から取得（Phase 2 連携）
            todayRecord: appState.todayRecord,
            allRecords:  allRecords
        )
        // 実績解放バナー + 通知
        if let unlocked = achievementEngine.recentlyUnlocked {
            pendingAchievement = unlocked
            notificationService.sendAchievementNotification(
                title:       unlocked.title,
                description: unlocked.description,
                icon:        unlocked.icon
            )
            achievementEngine.recentlyUnlocked = nil
        }
        // ストリークマイルストーン通知
        notificationService.sendStreakNotification(streak: streak)

        // CP マイルストーン通知
        notificationService.sendCPMilestoneNotification(totalCP: appState.todayTotalCP)

        // ウィジェット更新
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

