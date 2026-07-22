# Design Doc: 疎結合リポジトリ間の連携（GitHub Actions cross-repo trigger + Notion共有DB）

## Context and Scope

tori-dev-blog / article-relay / text-sns-relay は意図的に疎結合（コード非依存、
それぞれ単独動作可能）に保っている。しかし現状は連携が完全に手動:

- blog の記事を Qiita/Zenn/note に流すには、article-relay を手動 CLI 実行
- text-sns-relay の投稿履歴は blog 側から見えない（`/tweets` ページ未実装）

本 Design Doc は、疎結合を壊さずに以下 2 つの連携を自動化する方式を定める。

## Goals / Non-Goals

### Goals

- **連携ポイント1**: blog に記事 push → 自動で article-relay がクロスポスト実行
- **連携ポイント2**: text-sns-relay の投稿履歴 → Notion DB 経由で blog の
  `/tweets` ページに反映
- **疎結合の維持**: どちらの連携も「実行時のトリガー/データ受け渡し」のみ。
  git submodule・npm パッケージ import のようなビルド時コード結合は行わない

### Non-Goals

- article-relay / text-sns-relay の内部実装変更（既存の zero-runtime-deps
  方針は維持）
- 実際の GitHub Secrets 投入・Notion DB 作成の実行（本 Doc は設計とコード
  準備まで。認証情報系はユーザー実行）
- blog → text-sns-relay 方向の連携（例: blogの記事をトリガーにSNS投稿）は
  スコープ外。今回は text-sns-relay → blog の片方向のみ

## Design / System Context

### 連携ポイント1: blog → article-relay（GitHub Actions cross-repo trigger）

```
tori-dev-blog (push to main)
  │
  ▼
GitHub Actions: detect-cross-post.yml
  1. git diff で変更された content/posts/*.md を検出
  2. 各ファイルの frontmatter を読み、cross_post: {qiita/zenn/note: true} を確認
  3. 該当ファイルごとに article-relay へ repository_dispatch を送信
     POST /repos/tori-create-7991/article-relay/dispatches
     event_type: "cross-post"
     client_payload: { file_path, content (base64), repo, sha }
        │
        ▼
article-relay (repository_dispatch: cross-post)
  1. client_payload から記事内容を復元し一時ファイルに書き出し
  2. npm run cross -- <tmpfile>
  3. 投稿結果（成功/失敗）を tori-dev-blog へ commit-back はしない
     （frontmatterのURL書き戻しは今回スコープ外。手動運用時と同じ制約）
```

**認証**: tori-dev-blog に Fine-grained PAT（`article-relay` repo への
`contents:read` は不要、`actions: write` のみで dispatch 可）を Secret
`ARTICLE_RELAY_DISPATCH_TOKEN` として設定。

**Zenn連携の制約**: 現状 `ZENN_REPO_PATH` はローカルクローン済みディレクトリを
前提にしている。CI環境ではその場で `git clone` する必要があるため、
`lib/zenn-git.ts` に「未クローンならclone、既存ならpull」のロジックを追加する。

### 連携ポイント2: text-sns-relay → Notion → blog（共有DB経由）

```
text-sns-relay (投稿成功時)
  │
  ▼
lib/history.ts の appendHistory() 拡張
  - 既存: data/history.json への追記（変更なし）
  - 追加: Notion DB へも1レコード追加（NOTION_TOKEN, NOTION_TWEETS_DB_ID）
        │
        ▼
Notion DB「つぶやきログ」
  プロパティ: Text, Platforms(multi-select: X/Bluesky/Threads),
             URL(X), URL(Bluesky), URL(Threads), PostedAt
        │
        ▼ (blog ビルド時)
tori-dev-blog: scripts/getTweetsFromNotion.ts（新規）
  1. Notion DB を query
  2. content/tweets/*.md（または JSON）として書き出し
  3. pages/tweets.vue が一覧表示
```

**認証**: text-sns-relay に `NOTION_TOKEN`, `NOTION_TWEETS_DB_ID` を追加。
blog 側の `scripts/getTweetsFromNotion.ts` も同じ Notion DB を参照するため
同じ `NOTION_TOKEN`（または read-only 版）を GitHub Secrets に設定。

## Alternatives Considered

- **git submodule**: ビルド時の強依存になり疎結合の意図に反するため却下
- **npm パッケージ化**: article-relay のコアロジックを配布・import する形。
  コード結合が生じるため却下（実行時トリガーのみに限定する方針と矛盾）
- **手動同期（JSONファイルをrepo間でcommit）**: 運用が煩雑（都度手動コピー）
  なため、連携ポイント2ではNotion一元化を優先

## Risks / Concerns

| リスク | 対処 |
|---|---|
| PAT の権限が広すぎる漏洩時の被害 | Fine-grained PAT で article-relay 1リポジトリ・`actions:write`のみに限定 |
| repository_dispatch の client_payload サイズ上限（約64KB） | 通常のブログ記事本文は収まる想定。超過時はfile_pathのみ渡しgit経由で本文取得する方式に切替可能（今回は簡易実装で先に進める） |
| Zenn連携をCI化する際、毎回git cloneでCI時間増 | 許容範囲（記事投稿は高頻度でないため） |
| Notion API rate limit | 投稿頻度が低いツールのため実害小 |

## Success Metrics

- [ ] blog に `cross_post: {qiita: true}` を持つ記事をpush → article-relayの
      workflowが自動起動し実際にQiita投稿されることを確認
- [ ] text-sns-relayで投稿 → Notion DBに1レコード追加されることを確認
- [ ] blogのビルドで `/tweets` ページにNotionのレコードが反映されることを確認
