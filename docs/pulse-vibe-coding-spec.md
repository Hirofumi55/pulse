# Pulse — Vibe Coding 指示書

macOS メニューバー型システムモニター **Pulse** の実装指示書です。Codex はこの文書を
本リポジトリにおける唯一の真実の源として扱い、この文書にないことは事前承認を得てから
実装します。

## 0. このドキュメントの読み方

| セクション | 重要度 | 内容 |
|----------|------|------|
| §1-3 | 必読 | プロジェクト概要、絶対禁止事項、事前承認フロー |
| §4-6 | 必読 | 技術スタック、プロジェクト構造、AGENTS.md |
| §7-13 | 実装時参照 | Phase 別タスク分解、実装ガイド |
| §14-16 | 完了前確認 | テスト、CI/CD、リリース、検証 |

作業開始前に §1〜§6 を全文読み込みます。タスク実装中は対応する §7〜§13 を参照します。

## 1. プロジェクトサマリ

| 項目 | 内容 |
|------|------|
| アプリ名 | **Pulse** |
| 説明 | Modern system monitor for Apple Silicon |
| ターゲット | macOS 14 Sonoma 以降、Apple Silicon (arm64) のみ |
| 言語 | Swift 6.0+、UI 日本語のみ(i18n 対応構造) |
| ライセンス | MIT |
| バンドル ID | `com.hirofumi.pulse` |
| GitHub リポジトリ | `hirofumi/pulse` / `hirofumi/homebrew-tap` |
| 配布 | Homebrew Cask + Sparkle 2.x によるアプリ内アップデート |
| 開発期間目標 | Phase 1: 4週間 |

### 1.1 コアバリュー

1. **軽量**: アイドル時メモリ 50MB 以下、CPU 使用率 1% 以下
2. **美しい**: SwiftUI ネイティブの質感、SF Pro/Mono、適切な余白
3. **Apple Silicon ネイティブ**: P-core/E-core/GPU/ANE を意識した設計
4. **プライバシーファースト**: テレメトリなし、ネットワーク通信はアップデート確認のみ

## 2. 絶対禁止事項

### 2.1 アーキテクチャ

- Intel Mac 対応コード(SMC 経由の温度取得等)を書かない
- Electron / Tauri / React Native を使わない
- サードパーティの UI ライブラリ(Sparkle 以外)を追加しない
- ネットワーク通信をアップデート確認以外の用途で実装しない
- ユーザーの個人情報・利用統計・テレメトリを送信しない

### 2.2 セキュリティ・プライバシー

- プライベート API(`_C` プレフィックス、ヘッダー未公開 API)に依存しない
  - `IOHID` / `IOReport` / `host_processor_info` 等の公開 Mach API は許可
- root 権限を要求しない
- ユーザーディレクトリ外のファイルを読み書きしない
- Keychain にデータを書き込まない
- ハードコードされた API キー・トークンを含めない

### 2.3 配布

- Apple Developer 証明書での署名処理を実装しない
- App Store 提出関連のコードを書かない(`SKStoreReviewController` 等)
- Sparkle 以外の自作アップデーターを実装しない

### 2.4 コード品質

- `print()` をプロダクションコードに残さない。必ず `Logger` を使う
- `try!` / `as!` / 強制アンラップ `!` を使わない。明確な理由がある場合のみコメント付きで許可
- `@unchecked Sendable` を安易に使わない
- メインスレッドをブロックしない。必ず async/await + Task を使う
- 1 ファイル 500 行を超えない。超える場合は分割する

## 3. 事前承認フロー

### 3.1 必ず確認が必要な事項

| カテゴリ | 例 |
|---------|-----|
| 依存追加 | Sparkle 以外の SPM パッケージを追加する場合 |
| API 選定 | 複数の実装方法があり、判断に迷う場合 |
| 仕様逸脱 | 本書の要件と異なる実装になる場合 |
| 大規模リファクタ | ディレクトリ構造を変える場合、3 ファイル以上の同時変更 |
| 破壊的変更 | 既存の公開 API シグネチャを変える場合 |
| プライベート API | プライベート API に頼らざるを得ないケース |

### 3.2 確認時のフォーマット

```text
【事前承認依頼】
状況: <何をしようとしているか>
選択肢:
  A. <選択肢A>(メリット/デメリット)
  B. <選択肢B>(メリット/デメリット)
推奨: <Codexの推奨>
影響範囲: <変更されるファイル数、リスク>
```

### 3.3 確認不要

- バグ修正
- リント警告の解消
- コメント・ドキュメントの追加
- テストの追加
- 本書に明記された仕様の実装

## 4. 技術スタック

### 4.1 言語・ランタイム

```text
Swift: 6.0+
macOS Deployment Target: 14.0
Xcode: 16.0+
Architecture: arm64 only
```

### 4.2 依存パッケージ

| パッケージ | バージョン | 用途 |
|-----------|----------|-----|
| Sparkle | `2.6.4` 以上 | アプリ内アップデート |

それ以外の外部依存は追加しません。

### 4.3 Apple 純正フレームワーク

| フレームワーク | 用途 |
|--------------|------|
| AppKit | NSStatusItem, NSPopover, NSVisualEffectView |
| SwiftUI | 詳細画面・設定画面 |
| Charts | 時系列グラフ(macOS 14+) |
| Combine / Observation | リアクティブな状態管理 |
| Foundation | 基本機能 |
| os.log (Logger) | ロギング |
| IOKit | ディスク I/O、センサー |
| Darwin (Mach) | CPU、メモリ統計 |

### 4.4 開発ツール

| ツール | 設定 |
|------|------|
| SwiftLint | `.swiftlint.yml` 配置、CI 統合 |
| swift-format | `.swift-format` 配置、CI 統合 |
| Swift Testing | テストフレームワーク(Xcode 16+) |

## 5. プロジェクト構造

```text
pulse/
├── Pulse.xcodeproj/
├── Pulse/
│   ├── App/
│   ├── Presentation/
│   ├── Application/
│   ├── Domain/
│   ├── Infrastructure/
│   ├── Resources/
│   └── Utilities/
├── PulseTests/
├── PulseUITests/
├── .github/workflows/
├── scripts/
├── docs/
├── .swiftlint.yml
├── .swift-format
├── .gitignore
├── AGENTS.md
├── README.md
├── LICENSE
└── CHANGELOG.md
```

詳細なディレクトリ・ファイル名は初回依頼の §5 に従います。Swift ファイルは PascalCase、
型は PascalCase、関数・変数は camelCase、グローバル定数は禁止します。

### 5.1 Swift ファイル冒頭テンプレート

```swift
//
//  <FileName>.swift
//  Pulse
//
//  Created by Pulse Project. Licensed under MIT.
//

import Foundation
```

## 6. プロジェクトドキュメント

リポジトリルートに `AGENTS.md`、`README.md`、`LICENSE`、`CHANGELOG.md` を配置します。
`docs/` 配下に `CONTRIBUTING.md`、`ARCHITECTURE.md`、この仕様書を配置します。
ドキュメント・コミットメッセージ・PR タイトル・PR 本文は日本語を基本とします。

`AGENTS.md` と `README.md` は初回依頼 §6.1 / §6.2 の内容を配置済みの原文として扱います。

## 7. Phase 1 タスク分解

各タスクの Definition of Done を満たしてから次へ進みます。

### Task 1: プロジェクトセットアップ

目的: ビルド可能な空の macOS アプリを作成します。

手順:

1. macOS App テンプレート相当の `Pulse.xcodeproj` を作成
2. Deployment Target を macOS 14.0 に設定
3. Architecture を arm64 のみに設定
4. `Info.plist` に `LSUIElement = YES` を追加
5. `.swiftlint.yml`, `.swift-format`, `.gitignore` を配置
6. `AGENTS.md` を §6.1 の内容で配置
7. `README.md` を §6.2 の内容で配置し、`docs/images/hero.png` を置く
8. MIT `LICENSE`、日本語の `CHANGELOG.md` を配置
9. この仕様書を `docs/pulse-vibe-coding-spec.md` に配置
10. Sparkle 2.6.4 以上を SPM で追加

DoD:

- `xcodebuild build` がエラーなく完了する
- `swiftlint` が警告ゼロ
- アプリ起動時に Dock に表示されない
- Sparkle がリンクされている
- `AGENTS.md`、`README.md`、仕様書、`LICENSE`、`CHANGELOG.md` が配置されている

### Task 2: ドメインモデル定義

`Domain/Models/` に `MetricsSnapshot`、`CPUMetrics`、`MemoryMetrics`、`DiskMetrics`、
`VolumeInfo`、`NetworkMetrics`、`InterfaceInfo`、`DisplayItem` を定義します。全モデルは
`Sendable` と `Equatable` に準拠し、公開 API には `///` コメントを付けます。

### Task 3: Sampler プロトコルと CPU Sampler

`Sampler` は `Sendable` で、`func sample() async throws -> Output` を提供します。
`CPUSampler` は `actor` とし、`host_statistics(HOST_CPU_LOAD_INFO)` と
`host_processor_info(PROCESSOR_CPU_LOAD_INFO)` を使います。CPU 使用率は前回サンプルとの差分から
計算し、初回サンプルは `0.0` を返します。

### Task 4: Memory Sampler

`host_statistics64(HOST_VM_INFO64)` と `vm.swapusage` を使い、App/Wired/Compressed/Cache/Free、
Swap、Pressure を取得します。`usageRatio` は Activity Monitor 準拠で
`app + wired + compressed` を総物理メモリで割ります。

### Task 5: Disk Sampler

ボリューム一覧は `FileManager.default.mountedVolumeURLs`、容量は URL resource values、
I/O は IOKit `IOBlockStorageDriver` の `Statistics` を使います。速度は前回との差分/経過時間です。

### Task 6: Network Sampler

`getifaddrs` と `sysctl(NET_RT_IFLIST2)` を使い、`if_data64.ifi_ibytes` /
`ifi_obytes` から速度を計算します。`lo0`、`awdl`、`llw` などの仮想インターフェースは除外します。

### Task 7: MetricsCoordinator

`@Observable @MainActor final class MetricsCoordinator` とし、CPU/Memory/Disk/Network sampler を
並列に呼び出します。履歴は 300 件(5分@1Hz)まで保持し、`start()` / `stop()` /
`updateInterval(_:)` を提供します。

### Task 8: PreferencesStore

`@Observable final class PreferencesStore` とし、`UserDefaults` をバックエンドにします。
デフォルトは `displayedItems = [.cpuUsage, .memoryUsage, .networkSpeed]`、
`samplingIntervalSeconds = 1.0` です。

### Task 9: MenuBarController

`NSStatusItem` を設定に応じて動的に作成・削除します。左クリックでポップオーバー、右クリックで
設定/一時停止/終了メニューを表示します。表示フォーマットは SF Mono 11pt です。

### Task 10: ポップオーバー UI

`NSPopover` + SwiftUI。サイズは 380×480pt。タブは 概要 / CPU / メモリ / ストレージ / ネットワーク。
背景は `.ultraThinMaterial`。チャートは Swift Charts を使います。

### Task 11: 設定画面

macOS 14+ の `Settings` シーンを使います。タブは 一般 / 表示 / 更新 / 単位 / 情報。
全設定は即時反映し、リセット機能と Bundle からのバージョン取得を実装します。

### Task 12: Sparkle 統合

`SUFeedURL`、`SUPublicEDKey`、`SUEnableInstallerLauncherService`、
`SUEnableAutomaticChecks`、`SUScheduledCheckInterval` を `Info.plist` に設定します。
設定画面から手動確認でき、自動確認は 24 時間に 1 回です。EdDSA 署名検証を有効にします。

### Task 13: ロギング

`Utilities/Logger+Pulse.swift` に `LogCategory` と `Logger(category:)` を定義します。
プロジェクト内に `print()` を残しません。

### Task 14: テスト

各 Sampler のスモークテスト、`MetricsCoordinator`、`PreferencesStore`、`Formatter+Bytes`、
`DisplayItem.isAvailableInPhase1` をテストします。Swift Testing を使います。

### Task 15: アプリアイコン

AppIcon.appiconset の枠を用意し、プレースホルダー画像を配置します。最終アイコンはデザイナーが
差し替える前提です。

## 8. リソース取得 実装ガイド

CPU 使用率は累積 tick の差分で計算します。`USER`、`SYSTEM`、`IDLE`、`NICE` の差分を合計し、
`(user + system + nice) / totalTicks` を総使用率とします。コア毎の使用率は `host_processor_info`
を使い、取得した `processor_info_array_t` は `vm_deallocate` で解放します。

メモリプレッシャーは `host_statistics64(HOST_VM_INFO64)` の `compressor_page_count` と `pageouts`
から推定します。代替として `DISPATCH_SOURCE_TYPE_MEMORYPRESSURE` の購読を検討できます。

ネットワーク速度は `sysctl` の `NET_RT_IFLIST2` から interface 統計を取得し、カウンタリセット時は
差分を 0 として保護します。

ディスク I/O は IOKit の `IOServiceMatching("IOBlockStorageDriver")` から `Statistics` 辞書を読み、
`Bytes (Read)` と `Bytes (Write)` を合算します。

## 9. Sparkle 統合詳細

SPM URL は `https://github.com/sparkle-project/Sparkle`、バージョンは 2.6.4 以上です。
EdDSA キーは Sparkle 同梱の `generate_keys` で生成し、公開鍵を `SUPublicEDKey` に埋め込みます。
秘密鍵は安全に保管し、リリース時の署名にだけ使います。

appcast は `scripts/generate-appcast.sh` で `generate_appcast` を呼び出し、GitHub Pages の
`https://hirofumi.github.io/pulse/appcast.xml` で公開します。

## 10. UI/UX 実装ガイド

- セマンティックカラーを使う: `.primary`、`.secondary`、`.regularMaterial`、`.ultraThinMaterial`
- メニューバーは `.system(size: 11, weight: .regular, design: .monospaced)`
- ポップオーバー本文は 13pt、見出しは 17pt semibold
- 余白は 4 / 8 / 12 / 16 / 24 pt
- 値の変化は spring animation、タブ切替は opacity + move
- 固定色は避け、Asset Catalog の Any/Dark またはセマンティックカラーを使う

## 11. エラーハンドリング

`SamplerError` は `kernelCallFailed(name:code:)`、`sysctlFailed`、`ioKitFailed`、
`insufficientData`、`unexpectedFormat` を持つ `LocalizedError` とします。
Sampler エラー時は該当メトリクスのみ前回値を維持し、アプリ全体は停止しません。10 回以上連続
失敗した場合はメニューバーに `!` を表示します。

## 12. テスト要件

必須テスト:

- 各 Sampler を 2 回呼び出して有効値を返すこと
- `MetricsCoordinator.start()` 後に `latestSnapshot` が更新されること
- `MetricsCoordinator.stop()` でタスクが完全停止すること
- `PreferencesStore` の値が再起動後も保持されること
- `Formatter+Bytes` が 0、1KB、1MB、1GB、1TB で正しいこと
- `DisplayItem.isAvailableInPhase1` が温度/GPU に対して false であること

カバレッジ目標はドメインロジック 70% 以上です。

## 13. CI/CD 設定

CI は `macos-15`、Xcode 16.0、`swiftlint --strict`、`swift-format lint --recursive Pulse/ --strict`、
`xcodebuild test -scheme Pulse -destination 'platform=macOS,arch=arm64'` を実行します。

Release は `v*` tag push で Release build、ZIP 作成、Sparkle EdDSA 署名、GitHub Release への
アップロード、appcast 生成、Homebrew Cask 更新を行います。

必須 GitHub Secrets:

- `SPARKLE_PRIVATE_KEY`
- `TAP_REPO_TOKEN`

## 14. リリースプロセス

1. `CHANGELOG.md` を更新
2. `scripts/bump-version.sh 1.0.0` でバージョンを更新
   - `MARKETING_VERSION` を指定バージョンへ、`CURRENT_PROJECT_VERSION` を前回値 +1 へ更新する
3. コミット & プッシュ
4. `git tag v1.0.0 && git push --tags`
5. GitHub Actions でビルド・リリース・appcast 更新・Cask 更新
6. GitHub Releases でリリースノートを確認・編集

バージョニングは Semantic Versioning 2.0.0 に従います。

## 15. 完了前検証チェックリスト

機能:

- Dock に表示されない
- メニューバーに CPU / Memory / Network が表示される
- 各値が 1 秒ごとに更新される
- Activity Monitor と概ね一致する(±5%)
- 左クリックでポップオーバー、右クリックでコンテキストメニュー
- 5 タブが切り替わる
- 設定が即時反映され再起動後も保持される
- Sparkle の手動/自動アップデート確認が動作する
- ダーク/ライトモードに対応する

非機能:

- アイドル時メモリ使用量 < 50MB
- アイドル時 CPU 使用率 < 1%
- 起動時間 < 1 秒
- バイナリサイズ < 20MB
- ポップオーバー表示 < 100ms

品質:

- `swiftlint --strict` エラーゼロ
- `swift-format lint --strict` エラーゼロ
- 全テスト pass
- `print()` なし
- 強制アンラップは必要箇所のみコメント付き
- 全 Swift ファイル 500 行以下

## 16. 開発開始時の最初のアクション

1. 本書全体(特に §1〜§6)を読み込む
2. Task 1: プロジェクトセットアップから開始
3. 各タスクの DoD を満たしたら次へ
4. 不明点・判断に迷うことがあれば §3 の事前承認フローに従う
5. すべてのコミット前に AGENTS.md の Verification セクションを実行

## 17. 改訂履歴

| バージョン | 日付 | 変更内容 |
|----------|------|---------|
| 1.0 | 2026-05-02 | 初版 — Phase 1 仕様確定 |

## 付録 A: 用語集

| 用語 | 意味 |
|------|------|
| P-core | Performance core |
| E-core | Efficiency core |
| ANE | Apple Neural Engine |
| Mach | macOS のカーネル API 群 |
| IOKit | macOS の I/O ドライバアクセスフレームワーク |
| Sparkle | macOS 用のオープンソース自動アップデートフレームワーク |
| EdDSA | Edwards-curve Digital Signature Algorithm |
| Cask | Homebrew のアプリケーション配布形式 |

## 付録 B: 参考リンク

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Apple HIG: The Menu Bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Swift Charts Documentation](https://developer.apple.com/documentation/charts)
- [Mach Host Statistics](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/KernelProgramming/Mach/Mach.html)
- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
