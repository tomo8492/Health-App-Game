// VitaCityApp.swift
// App/
//
// エントリポイント・DI設定
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
        // CLAUDE.md Key Rule 11: CloudKit は将来実装。今は .none で明示的に無効化
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData ModelContainer の初期化に失敗: \(error)")
        }
    }()

    // MARK: - App State（Single Source of Truth）

    @State private var appState = AppState()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - ContentView（仮）

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Text("VITA CITY - Phase 0")
            .font(.largeTitle)
    }
}
