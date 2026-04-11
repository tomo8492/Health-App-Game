// AlcoholLog.swift
// Domain/Models

import Foundation
import SwiftData

/// 飲酒記録エンティティ
@Model
final class AlcoholLog {

    var id: UUID = UUID()
    var date: Date
    var drinkCount: Int     // ドリンク数（1ドリンク=ビール350ml等）
    var drinkType: DrinkType
    var startTime: Date?
    var endTime: Date?

    init(
        date:       Date,
        drinkCount: Int = 0,
        drinkType:  DrinkType = .beer,
        startTime:  Date? = nil,
        endTime:    Date? = nil
    ) {
        self.date       = date
        self.drinkCount = drinkCount
        self.drinkType  = drinkType
        self.startTime  = startTime
        self.endTime    = endTime
    }
}

enum DrinkType: String, Codable {
    case beer    = "beer"
    case wine    = "wine"
    case sake    = "sake"
    case whisky  = "whisky"
    case shochu  = "shochu"
    case other   = "other"
}
