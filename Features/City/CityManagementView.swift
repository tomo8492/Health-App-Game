// CityManagementView.swift
// Features/City/
// 街管理タブ: 建設可能な建物一覧・街のステータスサマリー
// CLAUDE.md Key Rule 4: 建設可能 28 種 + 自動生成 2 種

import SwiftUI

// MARK: - CityManagementView

struct CityManagementView: View {

    @Environment(AppState.self)              private var appState
    @Environment(CitySceneCoordinator.self)  private var coordinator
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
                    HStack(spacing: 6) {
                        Text("VITA CITY")
                            .font(.title2.bold())
                        // 街レベルバッジ
                        Text("Lv.\(coordinator.cityLevel)")
                            .font(.caption.bold())
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .foregroundStyle(.white)
                            .background(Color.vcCP, in: Capsule())
                    }
                    Text("\(coordinator.builtBuildingIds.count)/28 建設済み")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(coordinator.builtBuildingIds.count >= 28 ? Color.vcCP : Color.vcSecondaryLabel)
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

            // 建物コレクション進捗
            BuildingCollectionProgressView()

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

// MARK: - BuildingCollectionProgressView

private struct BuildingCollectionProgressView: View {

    @Environment(CitySceneCoordinator.self) private var coordinator

    private var builtCount: Int { coordinator.builtBuildingIds.count }
    private var totalCount: Int { 28 }
    private var progress: Double { Double(builtCount) / Double(totalCount) }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label("建物コレクション", systemImage: "building.2.fill")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(builtCount)/\(totalCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(builtCount >= totalCount ? Color.vcCP : Color.vcSecondaryLabel)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vcSecondaryLabel.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.vcCP.opacity(0.8), Color.vcCP],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // 軸別の建設状況（小さなドットで表現）
            HStack(spacing: 12) {
                ForEach(CPAxis.allCases, id: \.self) { axis in
                    let axisBuildings = BuildingCatalog.all.filter { $0.axis == axis }
                    let axisBuilt = axisBuildings.filter { coordinator.builtBuildingIds.contains($0.id) }.count
                    HStack(spacing: 3) {
                        Circle()
                            .fill(axis.color)
                            .frame(width: 6, height: 6)
                        Text("\(axisBuilt)/\(axisBuildings.count)")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.vcSecondaryLabel)
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

                    // ロア（フレーバーテキスト）
                    if !entry.lore.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                                .foregroundStyle(entry.axis.color.opacity(0.6))
                                .font(.caption)
                            Text(entry.lore)
                                .font(.caption)
                                .foregroundStyle(Color.vcSecondaryLabel)
                                .italic()
                        }
                        .padding(12)
                        .background(entry.axis.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    }

                    // 建物ボーナス表示
                    buildingBonusView

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

    // MARK: - 建物ボーナス表示

    @ViewBuilder
    private var buildingBonusView: some View {
        let bonus = BuildingBonusCalculator.bonus(for: entry.axis, builtIds: [entry.id])
        if bonus > 0 {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(entry.axis.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text("建物ボーナス")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vcSecondaryLabel)
                    Text(entry.axis.name + "軸 +\(bonus) CP")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(entry.axis.color)
                }
                Spacer()
                Text(coordinator.builtBuildingIds.contains(entry.id) ? "有効中" : "建設で有効")
                    .font(.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .foregroundStyle(coordinator.builtBuildingIds.contains(entry.id) ? .white : entry.axis.color)
                    .background(
                        coordinator.builtBuildingIds.contains(entry.id)
                            ? entry.axis.color
                            : entry.axis.color.opacity(0.12),
                        in: Capsule()
                    )
            }
            .padding(12)
            .background(entry.axis.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
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
    let lore:        String   // フレーバーテキスト（建物にまつわる物語）
}

enum BuildingCatalog {
    static let all: [BuildingCatalogEntry] = [
        // 運動軸（Exercise） B001〜B006
        .init(id: "B001", name: "トレーニングジム", axis: .exercise, requiredCP: 200,
              description: "筋トレ設備を完備したジム。体力 UP の拠点。",
              lore: "かつて小さな倉庫だったこの場所を、ある住民が仲間と一緒にジムに改装した。「毎日少しずつでいい」がモットー。"),
        .init(id: "B002", name: "スポーツスタジアム", axis: .exercise, requiredCP: 1_000,
              description: "街のランドマーク。大会やイベントが開催される。",
              lore: "年に一度の VITA CUP が開かれる聖地。住民たちの歓声が街に活力を届ける。"),
        .init(id: "B003", name: "公園・ランニングコース", axis: .exercise, requiredCP: 500,
              description: "ウォーキング・ジョギングが楽しめる緑地。",
              lore: "朝日が差し込む並木道は、住民の散歩コース。ベンチには「1歩が世界を変える」と刻まれている。"),
        .init(id: "B004", name: "プール", axis: .exercise, requiredCP: 2_000,
              description: "水泳・アクアビクスができる施設。",
              lore: "水の抵抗は優しい負荷。ここでは年配の方からキッズまで、水しぶきの笑顔が絶えない。"),
        .init(id: "B005", name: "ヨガスタジオ", axis: .exercise, requiredCP: 800,
              description: "マインドフルネスと柔軟性を高める場所。",
              lore: "「呼吸に集中して」——師範の穏やかな声が響く。ここでは心も体もほぐれていく。"),
        .init(id: "B006", name: "自転車ステーション", axis: .exercise, requiredCP: 1_500,
              description: "シェアサイクルの拠点。街の移動を活性化。",
              lore: "排気ガスゼロの移動革命。風を切って走る爽快感が、住民をまた自転車に乗せる。"),

        // 食事軸（Diet） B007〜B012
        .init(id: "B007", name: "オーガニックカフェ", axis: .diet, requiredCP: 300,
              description: "地産地消の健康食を提供。地元農家と連携。",
              lore: "店主は元料理人。「食材の力を信じて」と語る彼女の料理は、どれも素材の味が生きている。"),
        .init(id: "B008", name: "ファーマーズマーケット", axis: .diet, requiredCP: 700,
              description: "週末に開かれる新鮮野菜の直売所。",
              lore: "土曜の朝が一番賑わう。農家さんの笑顔と、色とりどりの野菜が並ぶ光景は街の風物詩。"),
        .init(id: "B009", name: "ヘルシーレストラン", axis: .diet, requiredCP: 1_200,
              description: "栄養バランスを計算したコース料理を提供。",
              lore: "管理栄養士監修のメニューは週替わり。「美味しくて健康」を証明し続ける名店。"),
        .init(id: "B010", name: "料理教室", axis: .diet, requiredCP: 2_500,
              description: "家庭料理の腕を磨ける文化施設。",
              lore: "「自分で作れば何を食べているか分かる」——ここで学んだ住民の食卓が変わっていく。"),
        .init(id: "B011", name: "サラダバー", axis: .diet, requiredCP: 400,
              description: "30種の野菜が揃うセルフサービスの食堂。",
              lore: "好きな野菜を好きなだけ。カラフルな一皿を組み立てる楽しさが、野菜嫌いも変える。"),
        .init(id: "B012", name: "ジューススタンド", axis: .diet, requiredCP: 150,
              description: "フレッシュスムージーとコールドプレスジュース。",
              lore: "忙しい朝でもビタミン補給。店先の黒板メニューは毎朝、旬の果物で書き換えられる。"),

        // 飲酒軸（Alcohol）→ 中央広場に寄与（CLAUDE.md Key Rule 2） B013〜B016
        .init(id: "B013", name: "瞑想センター", axis: .alcohol, requiredCP: 1_800,
              description: "飲酒ゼロをサポートするマインドフルネス施設。",
              lore: "静寂の中で自分と向き合う場所。「飲まなくても楽しい夜がある」と気づいた人たちの拠り所。"),
        .init(id: "B014", name: "ハーブティーショップ", axis: .alcohol, requiredCP: 600,
              description: "ノンアルコールドリンクの専門店。",
              lore: "カモミールの香りに包まれた小さなお店。一杯のお茶が、お酒の代わりにほっとさせてくれる。"),
        .init(id: "B015", name: "セルフケアスパ", axis: .alcohol, requiredCP: 3_000,
              description: "節制の褒美に。リラクゼーション施設。",
              lore: "頑張った自分へのご褒美は、お酒じゃなくてもいい。温かいお湯と静けさが心を癒す。"),
        .init(id: "B016", name: "コミュニティセンター", axis: .alcohol, requiredCP: 1_000,
              description: "ソーバーコミュニティの集会所。",
              lore: "同じ目標を持つ仲間と集まる場所。互いの経験を分かち合い、励まし合う温かい空間。"),

        // 睡眠軸（Sleep） B017〜B022
        .init(id: "B017", name: "睡眠クリニック", axis: .sleep, requiredCP: 2_000,
              description: "睡眠の質を科学的に改善する専門施設。",
              lore: "睡眠ポリグラフが夜の秘密を解き明かす。ここに通い始めてから、朝が変わったという声が続出。"),
        .init(id: "B018", name: "天文台", axis: .sleep, requiredCP: 4_000,
              description: "夜の美しさを感じながら良眠を誘う施設。",
              lore: "星空を見上げると、日常の悩みが小さく感じる。穏やかな夜が良い眠りの始まり。"),
        .init(id: "B019", name: "図書館", axis: .lifestyle, requiredCP: 1_500,
              description: "読書と学習の静寂な場所。",
              lore: "本の中には無数の人生がある。ページをめくるたびに、少しずつ自分の習慣も良い方に変わっていく。"),
        .init(id: "B020", name: "アロマテラピーショップ", axis: .sleep, requiredCP: 800,
              description: "快眠を促すアロマグッズの専門店。",
              lore: "ラベンダーの香りが漂う店内。「今夜はぐっすり眠れそう」と呟く客の笑顔が、店主の喜び。"),
        .init(id: "B021", name: "ムーンライトパーク", axis: .sleep, requiredCP: 1_200,
              description: "夕暮れ後に開放される静かな公園。",
              lore: "月明かりに照らされた小径を歩く。虫の声と風の音だけの贅沢な時間が、心を眠りへ誘う。"),
        .init(id: "B022", name: "布団・寝具専門店", axis: .sleep, requiredCP: 500,
              description: "高品質な睡眠環境を整える専門店。",
              lore: "「枕を変えたら人生が変わった」は大げさじゃない。良い睡眠は良い道具から始まる。"),

        // 生活習慣軸（Lifestyle） B023〜B028
        .init(id: "B023", name: "ウォーターサーバー広場", axis: .lifestyle, requiredCP: 200,
              description: "水分補給を習慣化するための公共の泉。",
              lore: "街の中心に湧く清水。住民が水筒を持って集まる風景は、VITA CITY の日常になった。"),
        .init(id: "B024", name: "メンタルヘルスクリニック", axis: .lifestyle, requiredCP: 3_500,
              description: "ストレスケアと心の健康をサポート。",
              lore: "体の健康だけじゃない。心が元気であることが、すべての土台。そう気づいた街が作った施設。"),
        .init(id: "B025", name: "市庁舎", axis: .lifestyle, requiredCP: 0,
              description: "街の中心。総合 CP が集まる行政の拠点。",
              lore: "VITA CITY の始まりの場所。ここから街が広がり、住民が集まり、物語が生まれた。"),
        .init(id: "B026", name: "習慣カレンダータワー", axis: .lifestyle, requiredCP: 2_500,
              description: "連続記録日数が刻まれる街のモニュメント。",
              lore: "塔の壁には住民の継続日数が刻まれている。「積み重ねが力になる」と塔が静かに語りかける。"),
        .init(id: "B027", name: "ウェルネスショップ", axis: .lifestyle, requiredCP: 700,
              description: "健康グッズ・サプリメントの専門店。",
              lore: "店主おすすめのビタミンサプリが人気。「まずは水をしっかり飲むことから」が口癖。"),
        .init(id: "B028", name: "公民館", axis: .lifestyle, requiredCP: 1_000,
              description: "地域コミュニティの集会・教室が開かれる場所。",
              lore: "料理教室、ストレッチ会、読書会——住民同士の繋がりが、健康な街を支える見えない力。"),
    ]
}
