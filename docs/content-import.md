# 記事と画像の取り込み（任意の道具）

Notion のデータベースから記事を、Google Drive から画像や Markdown を取り込むスクリプト。
今の記事はリポジトリに直接書いているので普段は使わない。必要になったときだけ使う。

サイト本体とは依存を分けてあり（`tools/content-import/package.json`）、通常の `npm ci` ではインストールされない。
Dependabot の対象外なので、久しぶりに使うときは先に依存を更新する。

## 準備

```bash
cd tools/content-import
npm install
npm update   # 久しぶりに使うとき
```

リポジトリのルートに `.env` を作り、使うスクリプトの環境変数を書く（ひな形は `.env.example`）。

| スクリプト | 環境変数 |
|---|---|
| Notion → 記事 | `NOTION_API_KEY`、`NOTION_DATABASE_ID` |
| Google Drive → 画像・Markdown | `GCP_SA_KEY`（サービスアカウントの鍵 JSON）、`GDRIVE_MD_FOLDER_ID`、`GDRIVE_IMAGES_FOLDER_ID` |

`.env` はコミットしない（`.gitignore` 済み）。

## 実行

`tools/content-import` で実行する。スクリプトはリポジトリのルートに移動してから動くので、出力先はルートからの相対パスになる。

```bash
npm run get-notion       # Notion → content/posts/*.md（画像は public/images/）
npm run get-drive        # Google Drive のフォルダ → content/posts/・public/images/
npm run get-drive-file   # Google Drive の個別ファイル
```

取り込んだ記事は frontmatter が `content.config.ts` の `posts` スキーマに合っているか確認してからコミットする。
