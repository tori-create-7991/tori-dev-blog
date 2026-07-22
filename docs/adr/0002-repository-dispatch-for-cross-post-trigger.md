# 0002. blog → article-relay の連携に GitHub Actions repository_dispatch を使う

Status: Accepted

## Context

tori-dev-blog と article-relay は疎結合（コード非依存）を意図して分離した
別リポジトリ。blogに記事を追加した際、自動でarticle-relayによる
Qiita/Zenn/noteクロスポストを走らせたいが、以下のいずれかの方式が考えられた:

1. GitHub Actions `repository_dispatch` によるcross-repoトリガー
2. git submodule でarticle-relayからblogを参照
3. article-relayの中核をnpmパッケージ化してblogから直接import
4. 手動CLI運用のまま（自動化しない）

## Decision

**GitHub Actions `repository_dispatch`** を採用する。blogのpush時に変更された
記事ファイルを検出し、`POST /repos/{owner}/article-relay/dispatches` で
article-relay側のworkflowを起動、記事内容は`client_payload`で渡す。

## Consequences

**良い面:**
- 実行時のみの疎通。コードレベルの依存関係が発生しない（疎結合維持）
- 認証はFine-grained PAT 1つのみ、スコープをarticle-relayリポジトリの
  `actions:write`に限定できる
- 両リポジトリとも独立してcloneしても動作する（submoduleのような
  取得順序の制約がない）

**悪い面:**
- `client_payload`のサイズ上限（約64KB）を超える記事は本文を渡せない
  （超えた場合は別方式へのフォールバックが必要、今回は未対応）
- クロスポスト失敗時の通知経路が未整備（GitHub Actionsのログを見る必要が
  ある。Slack通知等は別タスク）
- PATの発行・失効管理が手動運用（GitHub Appへの置き換えは将来検討）
