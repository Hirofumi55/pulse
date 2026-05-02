# ARCHITECTURE

Pulse は Apple Silicon 専用の macOS メニューバー型システムモニターです。

## レイヤー

- `Presentation`: メニューバー、ポップオーバー、設定画面、共通 UI コンポーネント
- `Application`: ViewModel と UI 状態
- `Domain`: メトリクスモデル、ユースケース、プロトコル
- `Infrastructure`: Mach / IOKit / UserDefaults / Sparkle などの実装詳細
- `Utilities`: ロガー、フォーマッタなどの横断的な補助機能

## 原則

- SwiftUI と AppKit のネイティブ実装のみを使う
- サードパーティ UI ライブラリは使わない
- ネットワーク通信は Sparkle のアップデート確認に限定する
- Sampler は `Sampler` プロトコルへ準拠し、状態を持つ場合は `actor` を優先する
- UI は日本語のみで実装し、将来の i18n に備えて `Localizable.xcstrings` を使う
