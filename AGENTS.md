# AGENTS.md — Pulse プロジェクトルール

このファイルは Codex などの AI コーディングエージェントが本リポジトリで作業する際に
従うべきルールをまとめたものです。完全な仕様は `docs/pulse-vibe-coding-spec.md`
を参照してください。

## プロジェクト概要

- **名称**: Pulse
- **対象環境**: macOS 14 Sonoma 以降、Apple Silicon のみ
- **言語**: Swift 6
- **UI言語**: 日本語のみ(i18n対応構造で実装)
- **ライセンス**: MIT
- **仕様の原典**: `docs/pulse-vibe-coding-spec.md`

## ビルド・テストコマンド

```bash
# ビルド(Debug)
xcodebuild -scheme Pulse -configuration Debug build

# テスト実行
xcodebuild test -scheme Pulse -destination 'platform=macOS,arch=arm64'

# Lint チェック
swiftlint --strict
swift-format lint --recursive Pulse/ --strict

# フォーマット適用
swift-format format --in-place --recursive Pulse/

# Release ビルド(リリース時)
xcodebuild -scheme Pulse -configuration Release \
  -archivePath build/Pulse.xcarchive archive
```

## 絶対遵守ルール(違反厳禁)

1. Intel Mac 向けのコード(SMC 経由の温度取得など)を一切書かない
2. Sparkle のアップデート確認以外のネットワーク通信を実装しない
3. プライベート API は事前承認なしに使用しない
4. `try!` / `as!` / 強制アンラップ `!` を使わない(やむを得ない場合は理由をコメントで明記)
5. メインスレッドをブロックしない。必ず async/await を使う
6. Sparkle 以外の SPM 依存を事前承認なしに追加しない
7. `print()` を使わない。`os` フレームワークの `Logger` を使う
8. シークレット・APIキー・`.env` ファイルをコミットしない
9. 1ファイル500行を超えない
10. 仕様書 §3.1 に記載された事前承認フローを必ず守る

## スタイルルール

- Swift 6 の strict concurrency モードを有効化
- 状態を持つ Sampler は `actor` を優先
- 参照セマンティクスが不要なら `class` より `struct` を優先
- ViewModel は `@Observable`(Observation フレームワーク)を使う
- 公開 API には必ず `///` 形式のドキュメントコメントを付与
- 全 Sampler 実装は `Sampler` プロトコルに準拠
- 識別子・定数名は英語、コメント・コミットメッセージは日本語

## 事前承認が必要な作業

以下に該当する作業は、実装前に必ずユーザーへ確認すること。

- SPM 依存を新規追加する場合
- ディレクトリ構造を変更する場合
- 公開 API シグネチャを変更する場合
- プライベート API を使用する場合
- 3ファイル以上を同時に変更するリファクタ

## コミット前の検証

すべてのコミット前に以下のコマンドをすべて成功させること。

```bash
swiftlint --strict && \
swift-format lint --recursive Pulse/ --strict && \
xcodebuild test -scheme Pulse -destination 'platform=macOS,arch=arm64' -quiet
```

3つのコマンドがすべて成功しない限り、コミットしてはならない。

## ロギング

`os` フレームワークの `Logger` を使うこと。

```swift
import os

private let logger = Logger(subsystem: "com.hirofumi.pulse", category: "Sampler")
logger.debug("サンプル取得: \(snapshot)")
logger.error("CPU統計の読み取りに失敗: \(error)")
```

`print()` の使用は禁止。

## コミットメッセージ規約

[Conventional Commits](https://www.conventionalcommits.org/ja/v1.0.0/) を採用する。
プレフィックスは英語、本文は日本語で記述する。

```
feat: メニューバーにディスクI/O表示を追加
fix: ネットワーク速度の計算で初回サンプル時にクラッシュする不具合を修正
docs: README にトラブルシューティングを追記
refactor: MetricsCoordinator のサンプリングループを TaskGroup ベースに変更
test: CPUSampler のテストを追加
chore: SwiftLint を 0.55 に更新
```

## ブランチ戦略

- `main`: 常にリリース可能な状態を保つ
- `feat/*`, `fix/*`, `docs/*`: 機能・修正・ドキュメントごとに作成
- PR 経由でのみ `main` にマージ(直接 push 禁止)
