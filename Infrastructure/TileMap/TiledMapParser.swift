// TiledMapParser.swift
// Infrastructure/TileMap/
//
// CLAUDE.md Key Rule 5: SKTiled ライブラリを使用しない
// Tiled Map Editor の JSON 出力を自前でパースする軽量実装
// https://doc.mapeditor.org/en/stable/reference/json-map-format/

import Foundation
import SpriteKit

// MARK: - Tiled Map Data Model

struct TiledMap: Codable {
    let width:       Int
    let height:      Int
    let tileWidth:   Int
    let tileHeight:  Int
    let orientation: String       // "isometric"
    let layers:      [TiledLayer]
    let tilesets:    [TiledTileset]

    enum CodingKeys: String, CodingKey {
        case width, height, layers, tilesets, orientation
        case tileWidth  = "tilewidth"
        case tileHeight = "tileheight"
    }
}

struct TiledLayer: Codable {
    let name:    String
    let type:    String   // "tilelayer" or "objectgroup"
    let data:    [Int]?   // タイル GID 配列（tilelayer の場合）
    let width:   Int?
    let height:  Int?
    let visible: Bool
    let objects: [TiledObject]?

    enum CodingKeys: String, CodingKey {
        case name, type, data, width, height, visible, objects
    }
}

struct TiledObject: Codable {
    let id:         Int
    let name:       String
    let x:          Double
    let y:          Double
    let width:      Double
    let height:     Double
    let properties: [TiledProperty]?
}

struct TiledProperty: Codable {
    let name:  String
    let type:  String
    let value: AnyCodable
}

struct TiledTileset: Codable {
    let firstGid:  Int
    let source:    String?    // 外部 .tsj ファイル参照
    let name:      String?
    let tileWidth: Int?
    let tileHeight: Int?

    enum CodingKeys: String, CodingKey {
        case source, name
        case firstGid  = "firstgid"
        case tileWidth  = "tilewidth"
        case tileHeight = "tileheight"
    }
}

// MARK: - Parsed Tile

struct MapTile {
    let gridX:      Int
    let gridY:      Int
    let gid:        Int       // タイル番号（0 = 空）
    let isWalkable: Bool      // NPC 通行可フラグ（CLAUDE.md Key Rule 10）
    var screenPosition: CGPoint  // アイソメトリック座標に変換済み
}

// MARK: - TiledMapParser

final class TiledMapParser {

    // MARK: - Parse

    static func parse(named filename: String, bundle: Bundle = .main) throws -> ParsedMap {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw ParserError.fileNotFound(filename)
        }
        let data = try Data(contentsOf: url)
        let tiledMap = try JSONDecoder().decode(TiledMap.self, from: data)
        return buildParsedMap(from: tiledMap)
    }

    // MARK: - Build ParsedMap

    private static func buildParsedMap(from tiledMap: TiledMap) -> ParsedMap {
        let tw = CGFloat(tiledMap.tileWidth)
        let th = CGFloat(tiledMap.tileHeight)
        var tiles: [[MapTile]] = []

        // 地面レイヤーを取得
        let groundLayer = tiledMap.layers.first { $0.type == "tilelayer" && $0.name == "ground" }
                       ?? tiledMap.layers.first { $0.type == "tilelayer" }

        for row in 0..<tiledMap.height {
            var rowTiles: [MapTile] = []
            for col in 0..<tiledMap.width {
                let idx = row * tiledMap.width + col
                let gid = groundLayer?.data?[safe: idx] ?? 0
                // アイソメトリック座標変換
                let screenPos = isoToScreen(x: col, y: row, tileWidth: tw, tileHeight: th)
                let tile = MapTile(
                    gridX:          col,
                    gridY:          row,
                    gid:            gid,
                    isWalkable:     gid != 0,   // GID 0 = 空 = 通行不可
                    screenPosition: screenPos
                )
                rowTiles.append(tile)
            }
            tiles.append(rowTiles)
        }

        return ParsedMap(
            width:      tiledMap.width,
            height:     tiledMap.height,
            tileWidth:  tiledMap.tileWidth,
            tileHeight: tiledMap.tileHeight,
            tiles:      tiles
        )
    }

    // MARK: - アイソメトリック座標変換

    /// グリッド座標 (x, y) → スクリーン座標
    static func isoToScreen(x: Int, y: Int, tileWidth: CGFloat, tileHeight: CGFloat) -> CGPoint {
        let screenX = CGFloat(x - y) * (tileWidth / 2)
        let screenY = CGFloat(x + y) * (tileHeight / 2) * -1  // SpriteKit は Y 軸上向き
        return CGPoint(x: screenX, y: screenY)
    }

    /// スクリーン座標 → グリッド座標（タップ位置からタイルを特定するため）
    static func screenToIso(point: CGPoint, tileWidth: CGFloat, tileHeight: CGFloat) -> (x: Int, y: Int) {
        let tw2 = tileWidth  / 2
        let th2 = tileHeight / 2
        let gx = Int(( point.x / tw2 + (-point.y) / th2) / 2)
        let gy = Int((-point.x / tw2 + (-point.y) / th2) / 2)
        return (x: gx, y: gy)
    }

    // MARK: - Error

    enum ParserError: LocalizedError {
        case fileNotFound(String)
        var errorDescription: String? {
            switch self { case .fileNotFound(let name): return "Tiled JSON ファイルが見つかりません: \(name)" }
        }
    }
}

// MARK: - ParsedMap

struct ParsedMap {
    let width:      Int
    let height:     Int
    let tileWidth:  Int
    let tileHeight: Int
    let tiles:      [[MapTile]]

    func tile(at x: Int, y: Int) -> MapTile? {
        guard y >= 0 && y < tiles.count, x >= 0 && x < tiles[y].count else { return nil }
        return tiles[y][x]
    }

    func isWalkable(at x: Int, y: Int) -> Bool {
        tile(at: x, y: y)?.isWalkable ?? false
    }
}

// MARK: - Helpers

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// AnyCodable: TiledProperty の value 型対応
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int    = try? container.decode(Int.self)    { value = int; return }
        if let double = try? container.decode(Double.self) { value = double; return }
        if let bool   = try? container.decode(Bool.self)   { value = bool; return }
        if let str    = try? container.decode(String.self) { value = str; return }
        value = ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let v = value as? Int    { try container.encode(v) }
        else if let v = value as? Double  { try container.encode(v) }
        else if let v = value as? Bool    { try container.encode(v) }
        else if let v = value as? String  { try container.encode(v) }
    }
}
