# Runbook: リポジトリ間連携（cross-post自動化 + つぶやき同期）のセットアップ

関連: `docs/design/cross-repo-loose-coupling.md`,
`docs/adr/0002-repository-dispatch-for-cross-post-trigger.md`,
`docs/adr/0003-notion-as-shared-datastore-for-tweets.md`

GCP/GitHub/Notionの認証情報はユーザー保有のため、本 runbook の手順は
ユーザー自身が実行する。

## 1. blog → article-relay 自動クロスポスト

### 1-1. Fine-grained PAT を発行

1. GitHub → Settings → Developer settings → Fine-grained tokens → Generate new token
2. Resource owner: `tori-create-7991`
3. Repository access: **Only select repositories** → `article-relay`
4. Permissions: **Actions: Read and write**（`repository_dispatch` 送信に必要）
5. 発行したトークンを控える

### 1-2. tori-dev-blog に Secret を設定

```bash
gh secret set ARTICLE_RELAY_DISPATCH_TOKEN --repo tori-create-7991/tori-dev-blog
# プロンプトでPATを貼り付け
```

### 1-3. article-relay に Qiita/Zenn の Secrets/Variables を設定

```bash
gh secret set QIITA_TOKEN --repo tori-create-7991/article-relay
gh secret set ZENN_REPO_URL --repo tori-create-7991/article-relay
# 例: https://x-access-token:<GitHub PAT>@github.com/you/zenn-content.git
gh variable set ZENN_BRANCH --repo tori-create-7991/article-relay --body "main"
gh variable set ZENN_AUTHOR_NAME --repo tori-create-7991/article-relay --body "あなたの名前"
gh variable set ZENN_AUTHOR_EMAIL --repo tori-create-7991/article-relay --body "you@example.com"
```

### 1-4. 動作確認

`content/posts/*.md` に `cross_post: { qiita: true }` を設定した記事を push
→ Actions タブで `detect-cross-post` → `article-relay` の
`cross-post-dispatch` が起動することを確認。

手動テストは article-relay 側で:

```bash
gh workflow run cross-post-dispatch.yml --repo tori-create-7991/article-relay \
  -f file_content_base64="$(base64 -i path/to/test.md)" \
  -f file_path="test.md"
```

## 2. text-sns-relay → blog つぶやき同期

### 2-1. Notion Integration 作成・DB接続

1. Notion → Settings → Connections → Develop or manage integrations →
   新規Integration作成、Internal Integration Tokenを控える
2. 対象DB「つぶやきログ」（`641e0e88-38b8-466a-98e4-d53aa4bd9432`）を開き、
   `...` メニュー → Connect to → 作成したIntegrationを選択

### 2-2. text-sns-relay に環境変数設定

ローカル `.env`:

```env
NOTION_TOKEN=ntn_...
NOTION_TWEETS_DB_ID=641e0e88-38b8-466a-98e4-d53aa4bd9432
```

### 2-3. tori-dev-blog に Secret 設定（ビルド時取得用）

```bash
gh secret set NOTION_TOKEN --repo tori-create-7991/tori-dev-blog
```

`NOTION_API_KEY`（記事取込用）と同じ値でよい。GitHub Actionsのビルド
ワークフロー（`firebase-hosting-deploy.yml`）の `.env` 生成ステップに
`NOTION_TWEETS_DB_ID` も含める必要がある（既存の `DOTENV` secret 全体を
更新するか、個別に追記）。

### 2-4. 動作確認

```bash
cd text-sns-relay
npm run post -- --platform x "テスト投稿"
```

→ Notion DB「つぶやきログ」に1レコード追加されることを確認。

```bash
cd tori-dev-blog
npm run get-tweets
npm run dev
# http://localhost:3000/tweets で表示確認
```
