// CityManagementView.swift
// Features/City/
// 街管理タブ: 建設可能な建物一覧・街のステータスサマリー
// CLAUDE.md Key Rule 4: 建設可能 28 種 + 自動生成 2 種

import SwiftUI

// MARK: - CityManagementView

struct CityManagementView: View {

    @Environment(AppState.self) private var appState
    @State private var selectedAxis: CPAxis? = nil
    @State private var selectedBuilding: BuildingCatalogEntry? = nil

    private var filteredBuildings: [BuildingCatalogEntry] {
        guard let axis = selectedAxis else { return BuildingCatalog.all }
        return BuildingCatalog.all.filter { $0.axis == axis }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cityStatusCard
                    .padding(.horizontal)

                axisFilterRow
                    .padding(.horizontal)

                buildingGrid
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("街管理")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedBuilding) { entry in
            BuildingCatalogDetailSheet(entry: entry)
        }
    }

    // MARK: - 街ステータスカード

    private var cityStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VITA CITY")
                        .font(.title2.bold())
                    Text("建物 28 種 + 自動生成 2 種")
                        .font(.caption)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.vcCP)
                        Text("\(appState.todayTotalCP) CP")
                            .font(.title3.bold())
                            .foregroundStyle(Color.vcCP)
                    }
                    Text("今日の合計")
                        .font(.caption2)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
            }

            Divider()

            // マップ拡張進捗（CLAUDE.md Key Rule 6）
            MapExpansionProgressView()
        }
        .padding()
        .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 軸フィルター

    private var axisFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "すべて",
                    icon:  "square.grid.2x2",
                    color: .vcCP,
                    isSelected: selectedAxis == nil
                ) { selectedAxis = nil }

                ForEach(CPAxis.allCases, id: \.self) { axis in
                    FilterChip(
                        label:      axis.shortName,
                        icon:       axis.icon,
                        color:      axis.color,
                        isSelected: selectedAxis == axis
                    ) { selectedAxis = selectedAxis == axis ? nil : axis }
                }
            }
        }
    }

    // MARK: - 建物グリッド

    private var buildingGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(filteredBuildings) { entry in
                BuildingCatalogCard(entry: entry) {
                    selectedBuilding = entry
                }
            }
        }
    }
}

// MARK: - MapExpansionProgressView

private struct MapExpansionProgressView: View {

    // マップ拡張コスト（CLAUDE.md Key Rule 6）
    private let thresholds: [(label: String, cp: Int)] = [
        ("20×20", 0),
        ("30×30", 5_000),
        ("40×40", 15_000),
        ("50×50", 30_000),
    ]

    // 累計 CP で判定（todayTotalCP は今日分のみで正しくない）
    @Environment(CitySceneCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("マップ拡張")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("累計 \(coordinator.totalCP) CP")
                    .font(.caption2)
                    .foregroundStyle(Color.vcSecondaryLabel)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 0) {
                ForEach(thresholds.indices, id: \.self) { i in
                    let t = thresholds[i]
                    VStack(spacing: 4) {
                        Circle()
                            .fill(coordinator.totalCP >= t.cp ? Color.vcCP : Color.vcSecondaryLabel.opacity(0.3))
                            .frame(width: 10, height: 10)
                        Text(t.label)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }
                    if i < thresholds.count - 1 {
                        Rectangle()
                            .fill(Color.vcSecondaryLabel.opacity(0.2))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 14)
                    }
                }
            }
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let label:      String
    let icon:       String
    let color:      Color
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .white : color)
            .background(
                isSelected ? color : color.opacity(0.12),
                in: Capsule()
            )
        }
    }
}

// MARK: - BuildingCatalogCard

private struct BuildingCatalogCard: View {
    let entry:  BuildingCatalogEntry
    let action: () -> Void

    @Environment(CitySceneCoordinator.self) private var coordinator

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.axis.color.opacity(0.12))
                        .frame(height: 72)
                    Image(systemName: entry.axis.icon)
                        .font(.largeTitle)
                        .foregroundStyle(entry.axis.color)

                    // ステータスバッジ（右上）
                    VStack {
                        HStack {
                            Spacer()
                            buildStatusBadge
                        }
                        Spacer()
                    }
                    .padding(6)
                }

                VStack(spacing: 3) {
                    Text(entry.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(entry.axis.name + "軸")
                        .font(.caption2)
                        .foregroundStyle(entry.axis.color)
                    Text("必要 CP: \(entry.requiredCP)")
                        .font(.caption2)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
            }
            .padding(12)
            .background(Color.vcCardBackground, in: RoundedRectangle(cornerRadius: 16))
            .opacity(coordinator.builtBuildingIds.contains(entry.id) ? 0.65 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var buildStatusBadge: some View {
        if coordinator.builtBuildingIds.contains(entry.id) {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.green)
                .font(.system(size: 18))
        } else if coordinator.totalCP >= entry.requiredCP {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, entry.axis.color)
                .font(.system(size: 18))
        } else {
            Image(systemName: "lock.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.vcSecondaryLabel)
                .font(.system(size: 18))
        }
    }
}

// MARK: - BuildingCatalogDetailSheet

struct BuildingCatalogDetailSheet: View {
    let entry: BuildingCatalogEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(CitySceneCoordinator.self) private var coordinator
    @State private var didBuild = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 建物アイコン
                    ZStack {
                        Circle()
                            .fill(entry.axis.color.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: entry.axis.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(entry.axis.color)
                    }
                    .padding(.top)

                    // 名前・ID
                    VStack(spacing: 4) {
                        Text(entry.name)
                            .font(.title2.bold())
                        Text(entry.id)
                            .font(.caption)
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }

                    // タグ
                    HStack(spacing: 12) {
                        Label(entry.axis.name + "軸", systemImage: entry.axis.icon)
                            .font(.subheadline)
                            .foregroundStyle(entry.axis.color)
                        Divider().frame(height: 16)
                        Label("必要 \(entry.requiredCP) CP", systemImage: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.vcCP)
                    }

                    // 説明
                    Text(entry.description)
                        .font(.body)
                        .foregroundStyle(Color.vcSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // 建設ボタン / ステータス
                    buildSection

                    Spacer()
                }
            }
            .navigationTitle("建物詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - 建設セクション

    @ViewBuilder
    private var buildSection: some View {
        VStack(spacing: 12) {
            if coordinator.builtBuildingIds.contains(entry.id) {
                // 建設済み
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("建設済み")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            } else if coordinator.totalCP >= entry.requiredCP {
                // 建設可能
                Button {
                    let success = coordinator.buildBuilding(entry)
                    if success {
                        didBuild = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: didBuild ? "checkmark" : "hammer.fill")
                        Text(didBuild ? "建設完了！" : "建設する")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(didBuild ? Color.green : entry.axis.color,
                                in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .disabled(didBuild)

            } else {
                // CP 不足（ロック）
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.vcSecondaryLabel)
                        Text("累計 \(entry.requiredCP) CP で解放")
                            .font(.subheadline)
                            .foregroundStyle(Color.vcSecondaryLabel)
                    }

                    // 進捗バー
                    let progress = min(1.0, Double(coordinator.totalCP) / Double(max(1, entry.requiredCP)))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.vcSecondaryLabel.opacity(0.15))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(entry.axis.color)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal)

                    Text("\(coordinator.totalCP) / \(entry.requiredCP) CP")
                        .font(.caption2)
                        .foregroundStyle(Color.vcSecondaryLabel)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Building Catalog（28 種建設可能）

struct BuildingCatalogEntry: Identifiable {
    let id:          String   // B001〜B028
    let name:        String
    let axis:        CPAxis
    let requiredCP:  Int      // 建設に必要な累計 CP
    let description: String
}

enum BuildingCatalog {
    static let all: [BuildingCatalogEntry] = [
        // 運動軸（Exercise） B001〜B006
        .init(id: "B001", name: "トレーニングジム",    axis: .exercise,  requiredCP:    200, description: "筋トレ設備を完備したジム。体力 UP の拠点。"),
        .init(id: "B002", name: "スポーツスタジアム",  axis: .exercise,  requiredCP:  1_000, description: "街のランドマーク。大会やイベントが開催される。"),
        .init(id: "B003", name: "公園・ランニングコース", axis: .exercise, requiredCP:    500, description: "ウォーキング・ジョギングが楽しめる緑地。"),
        .init(id: "B004", name: "プール",             axis: .exercise,  requiredCP:  2_000, description: "水泳・アクアビクスができる施設。"),
        .init(id: "B005", name: "ヨガスタジオ",        axis: .exercise,  requiredCP:    800, description: "マインドフルネスと柔軟性を高める場所。"),
        .init(id: "B006", name: "自転車ステーション",   axis: .exercise,  requiredCP:  1_500, description: "シェアサイクルの拠点。街の移動を活性化。"),

        // 食事軸（Diet） B007〜B012
        .init(id: "B007", name: "オーガニックカフェ",  axis: .diet,      requiredCP:    300, description: "地産地消の健康食を提供。地元農家と連携。"),
        .init(id: "B008", name: "ファーマーズマーケット", axis: .diet,    requiredCP:    700, description: "週末に開かれる新鮮野菜の直売所。"),
        .init(id: "B009", name: "ヘルシーレストラン",  axis: .diet,      requiredCP:  1_200, description: "栄養バランスを計算したコース料理を提供。"),
        .init(id: "B010", name: "料理教室",           axis: .diet,      requiredCP:  2_500, description: "家庭料理の腕を磨ける文化施設。"),
        .init(id: "B011", name: "サラダバー",          axis: .diet,      requiredCP:    400, description: "30種の野菜が揃うセルフサービスの食堂。"),
        .init(id: "B012", name: "ジューススタンド",    axis: .diet,      requiredCP:    150, description: "フレッシュスムージーとコールドプレスジュース。"),

        // 飲酒軸（Alcohol）→ 中央広場に寄与（CLAUDE.md Key Rule 2） B013〜B016
        .init(id: "B013", name: "瞑想センター",        axis: .alcohol,   requiredCP:  1_800, description: "飲酒ゼロをサポートするマインドフルネス施設。"),
        .init(id: "B014", name: "ハーブティーショップ", axis: .alcohol,  requiredCP:    600, description: "ノンアルコールドリンクの専門店。"),
        .init(id: "B015", name: "セルフケアスパ",      axis: .alcohol,   requiredCP:  3_000, description: "節制の褒美に。リラクゼーション施設。"),
        .init(id: "B016", name: "コミュニティセンター", axis: .alcohol,   requiredCP:  1_000, description: "ソーバーコミュニティの集会所。"),

        // 睡眠軸（Sleep） B017〜B022
        .init(id: "B017", name: "睡眠クリニック",      axis: .sleep,     requiredCP:  2_000, description: "睡眠の質を科学的に改善する専門施設。"),
        .init(id: "B018", name: "天文台",             axis: .sleep,      requiredCP:  4_000, description: "夜の美しさを感じながら良眠を誘う施設。"),
        .init(id: "B019", name: "図書館",             axis: .lifestyle,  requiredCP:  1_500, description: "読書と学習の静寂な場所（CLAUDE.md: 生活習慣軸）"),
        .init(id: "B020", name: "アロマテラピーショップ", axis: .sleep,   requiredCP:    800, description: "快眠を促すアロマグッズの専門店。"),
        .init(id: "B021", name: "ムーンライトパーク",  axis: .sleep,      requiredCP:  1_200, description: "夕暮れ後に開放される静かな公園。"),
        .init(id: "B022", name: "布団・寝具専門店",    axis: .sleep,      requiredCP:    500, description: "高品質な睡眠環境を整える専門店。"),

        // 生活習慣軸（Lifestyle） B023〜B028
        .init(id: "B023", name: "ウォーターサーバー広場", axis: .lifestyle, requiredCP:  200, description: "水分補給を習慣化するための公共の泉。"),
        .init(id: "B024", name: "メンタルヘルスクリニック", axis: .lifestyle, requiredCP: 3_500, description: "ストレスケアと心の健康をサポート。"),
        .init(id: "B025", name: "市庁舎",             axis: .lifestyle,   requiredCP:    0,  description: "街の中心。総合 CP が集まる行政の拠点。"),
        .init(id: "B026", name: "習慣カレンダータワー", axis: .lifestyle,  requiredCP:  2_500, description: "連続記録日数が刻まれる街のモニュメント。"),
        .init(id: "B027", name: "ウェルネスショップ",   axis: .lifestyle,  requiredCP:    700, description: "健康グッズ・サプリメントの専門店。"),
        .init(id: "B028", name: "公民館",             axis: .lifestyle,   requiredCP:  1_000, description: "地域コミュニティの集会・教室が開かれる場所。"),
    ]
}
