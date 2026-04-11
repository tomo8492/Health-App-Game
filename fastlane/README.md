# Fastlane & CI/CD セットアップガイド

## 必要な GitHub Secrets

GitHub リポジトリの **Settings → Secrets and variables → Actions** に以下を登録してください。

| Secret 名 | 説明 | 取得元 |
|---|---|---|
| `APPLE_ID` | Apple Developer アカウントのメールアドレス | 自身の Apple ID |
| `ASC_API_KEY_ID` | App Store Connect API キーの ID | App Store Connect → ユーザーとアクセス → API キー |
| `ASC_API_ISSUER_ID` | App Store Connect API の Issuer ID | 同上 |
| `ASC_API_KEY` | App Store Connect API キー（.p8 ファイルの内容） | 同上 |
| `TEAM_ID` | Apple Developer Portal のチーム ID | Developer Portal → Membership |
| `MATCH_GIT_URL` | 証明書管理リポジトリの Git URL（プライベート推奨） | 新規プライベートリポジトリを作成 |
| `MATCH_PASSWORD` | fastlane match の暗号化パスワード | 自身で設定 |
| `SLACK_URL` | Slack Incoming Webhook URL（任意） | Slack App 設定 |

## ローカルでの初回セットアップ

```bash
# Bundler のインストール（Ruby が必要）
gem install bundler

# Gemfile を作成
cat > Gemfile << 'EOF'
source "https://rubygems.org"
gem "fastlane"
gem "cocoapods"
EOF

bundle install

# fastlane match の初期化（証明書リポジトリを初めて使う場合）
bundle exec fastlane match init

# 開発用証明書を生成・登録
bundle exec fastlane match development

# App Store 用証明書を生成・登録
bundle exec fastlane match appstore
```

## 利用可能なレーン

```bash
# ユニットテスト実行
bundle exec fastlane test

# SwiftLint チェック
bundle exec fastlane lint

# TestFlight に配信（証明書設定が必要）
bundle exec fastlane beta

# App Store に審査提出（証明書設定が必要）
bundle exec fastlane release

# パッチバージョンをインクリメント
bundle exec fastlane bump_version

# マイナーバージョンをインクリメント
bundle exec fastlane bump_version type:minor
```

## GitHub Actions ワークフロー

`.github/workflows/ci.yml` に定義されています。

| ジョブ | トリガー | 内容 |
|---|---|---|
| `test-core` | すべての push / PR | VitaCityCore Swift Package のユニットテスト |
| `test-ios` | すべての push / PR | iOS Simulator でのテスト |
| `lint` | すべての push / PR | SwiftLint チェック |
| `beta` | `main` ブランチへの push のみ | TestFlight 自動配信 |

## TestFlight 自動配信の有効化

1. GitHub リポジトリで **Environments** → `testflight` を作成
2. 必要に応じて **Required reviewers** で手動承認を設定
3. 上記の Secrets をすべて登録
4. `main` ブランチに push すると自動で TestFlight 配信されます
