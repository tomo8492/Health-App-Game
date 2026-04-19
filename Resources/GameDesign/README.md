# VITA CITY ゲームデザイン仕様書

> 建物・キャラクター・世界観の**統一デザイン方針**をまとめたドキュメント群。
> `Resources/Prompts/` が "PixelLab でどう描くか（How）" を扱うのに対し、
> ここでは "何を描くか・なぜそうするか（What / Why）" を定める。

---

## ドキュメント一覧

| ファイル | 内容 |
|---|---|
| [00_DesignOverview.md](./00_DesignOverview.md) | 世界観・アートディレクション 3 原則・色システム・アニメーション言語 |
| [01_BuildingDesign.md](./01_BuildingDesign.md) | 軸ごとの建築言語・Lv1〜5 成長ルール・全 30 建物のモチーフ |
| [02_CharacterDesign.md](./02_CharacterDesign.md) | NPC 5 種 + 特殊 2 種の人格・見た目・インタラクション設計 |

---

## 設計の階層関係

```
CLAUDE.md（プロジェクトルール）
    ↓
GameDesign/（世界観・何を作るか）
    ↓
Prompts/（PixelLab で どう 生成するか）
    ↓
Assets.xcassets（生成物）
    ↓
Features/City/（実装）
```

---

## コンセプト 1 行

> **「あなたの健康習慣が、穏やかで優しい島の街を育てる」**

- トーン: Cozy Wellness Town（居心地よい、ウェルネスの街）
- 参考: カイロソフト + Townscaper + どうぶつの森 + Stardew Valley
- ポリシー: 焦らせない・競わせない・煽らない
