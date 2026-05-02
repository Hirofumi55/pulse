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

## 仕様

実装判断の原典は [pulse-vibe-coding-spec.md](pulse-vibe-coding-spec.md) です。
仕様から外れる変更は、実装前に事前承認を取ってください。
