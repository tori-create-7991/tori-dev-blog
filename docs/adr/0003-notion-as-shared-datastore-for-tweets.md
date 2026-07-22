# 0003. text-sns-relay → blog の連携に Notion を共有データストアとして使う

Status: Accepted

## Context

text-sns-relay（X/Bluesky/Threads投稿ツール）の送信履歴を、tori-dev-blogの
`/tweets`ページに表示したい。両リポジトリはローカルファイルシステムを共有
しておらず、それぞれ別のCI環境でビルド・実行される。

## Decision

**Notion DB を仲介**として使う。text-sns-relayは投稿成功時に
`lib/history.ts`のappendHistory()内でNotion DBへも1レコード追加する。
blogはビルド時（`scripts/getTweetsFromNotion.ts`、新規）にそのNotion DBを
queryし、`/tweets`ページ用のコンテンツを生成する。

## Consequences

**良い面:**
- 両リポジトリはNotion DBという共通の外部APIにのみ依存し、互いを直接
  参照しない（疎結合維持）
- 既存のblog側Notion連携パターン（`scripts/getNotiontoMd.ts`の記事取込と
  同型）を踏襲でき、実装の一貫性が高い
- Notion DB自体が人間にとっても閲覧・手動編集可能な履歴ビューアになる

**悪い面:**
- Notion APIのレート制限・障害時にblogのビルドが影響を受ける可能性
  （投稿頻度が低いため実害は小さい想定）
- text-sns-relayとblog双方に`NOTION_TOKEN`の配布が必要（同一トークンの
  スコープ管理が必要）
- Notion側のスキーマ変更が両リポジトリに影響する暗黙の結合点になる
  （DBスキーマ変更時は両リポジトリの同時更新が必要）
