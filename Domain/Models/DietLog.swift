// DietLog.swift
// Domain/Models

import Foundation
import SwiftData

/// 食事記録エンティティ
@Model
final class DietLog {

    var id: UUID = UUID()
    var date: Date
    var mealType: MealType
    var qualityRaw: String   // MealQuality を rawValue で保存（VitaCityCore 型を直接保存できないため）
    var hasProtein: Bool     = false
    var hasVegetable: Bool   = false
    var hasSnack: Bool       = false

    var quality: String {
        get { qualityRaw }
        set { qualityRaw = newValue }
    }

    init(
        date:         Date,
        mealType:     MealType,
        qualityRaw:   String = "normal",
        hasProtein:   Bool = false,
        hasVegetable: Bool = false,
        hasSnack:     Bool = false
    ) {
        self.date         = date
        self.mealType     = mealType
        self.qualityRaw   = qualityRaw
        self.hasProtein   = hasProtein
        self.hasVegetable = hasVegetable
        self.hasSnack     = hasSnack
    }
}

enum MealType: String, Codable {
    case breakfast = "breakfast"
    case lunch     = "lunch"
    case dinner    = "dinner"
}
