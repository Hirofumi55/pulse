# CONTRIBUTING

Pulse への貢献ありがとうございます。

## 開発環境

- macOS 14 Sonoma 以降
- Apple Silicon Mac
- Xcode 16.0 以降
- Swift 6.0 以降
- SwiftLint
- swift-format

## セットアップ

```bash
git clone https://github.com/Hirofumi55/pulse.git
cd pulse
open Pulse.xcodeproj
```

## 検証

コミット前に以下を実行してください。

```bash
swiftlint --strict
swift-format lint --recursive Pulse/ --strict
xcodebuild test -scheme Pulse -destination 'platform=macOS,arch=arm64' -quiet
```

## バージョン更新

アプリの表示バージョンは Xcode project の `MARKETING_VERSION`、Sparkle が比較に使う
ビルド番号は `CURRENT_PROJECT_VERSION` で管理します。`Pulse/App/Info.plist` は
これらの build setting を参照するため、直接編集しません。

```bash
# 表示バージョンを 0.1.1 に更新し、ビルド番号を現在値から +1 する
scripts/bump-version.sh 0.1.1

# ビルド番号を明示する場合
scripts/bump-version.sh 0.1.1 2
```

バージョン番号は Semantic Versioning に従います。

- `PATCH`: バグ修正、アクセシビリティ改善、CI 修正
- `MINOR`: 新機能追加、Phase 単位の機能追加
- `MAJOR`: 破壊的変更、大きな UI/仕様変更

## 仕様

実装判断の原典は [pulse-vibe-coding-spec.md](pulse-vibe-coding-spec.md) です。
仕様から外れる変更は、実装前に事前承認を取ってください。
