# 問い合わせフォーム（Google Forms）の管理

`/contact` に埋め込んでいる Google フォームの所在と設定。フォームは Google アカウント（Drive）の資産で、
GCP プロジェクトや Terraform には紐づかない。コードで持っているのは iframe の公開 ID だけ。

## 現行フォーム（2026-09-03 作成）

| 項目 | 値 |
|---|---|
| オーナー | `ryo.tonegawa.7991@gmail.com`（マイドライブ直下） |
| Drive ファイル ID（編集用） | `1LNUsv6ZZEH1nL6M5dasii0wBzsJ4fFqMfEVrbxHmjhQ` |
| 編集 URL | https://docs.google.com/forms/d/1LNUsv6ZZEH1nL6M5dasii0wBzsJ4fFqMfEVrbxHmjhQ/edit |
| 公開 ID（iframe 用） | `1FAIpQLSesrT3kzyqZm9txcsnnoUe68tHpzJrwLOiXnnJLidkKWbyl9g` |
| 参照箇所 | `content/sidecontent/contact.md` の `<iframe src=…/d/e/<公開ID>/viewform?embedded=true>` |

設問: お名前（任意）/ ご連絡先メールアドレス（任意）/ 問い合わせ内容（必須・段落）。

設定: メールアドレス収集なし（`emailCollectionType: DO_NOT_COLLECT`）、回答 1 回制限なし、公開・回答受付中。
**ログインなしで送信できること**が要件。「回答を 1 回に制限する」「メールアドレスを収集する=確認済み」の
どちらかを ON にすると回答者にログインを要求するようになるので触らない。

## 作成・変更の手順（gws CLI）

フォームの実体は Forms API で操作できる。既定プロファイル（`gws auth status` の user が 7991）で実行する。

```bash
# 空フォーム作成（Drive に作られる）
gws forms forms create --json '{"info":{"title":"問い合わせ","documentTitle":"tori-dev.com 問い合わせ"}}'

# 設問追加・説明文などは batchUpdate
gws forms forms batchUpdate --params '{"formId":"<FILE_ID>"}' --json '{"requests":[...]}'

# 公開して回答受付
gws forms forms setPublishSettings --params '{"formId":"<FILE_ID>"}' \
  --json '{"publishSettings":{"publishState":{"isPublished":true,"isAcceptingResponses":true}}}'

# 公開 ID（responderUri）の確認
gws forms forms get --params '{"formId":"<FILE_ID>"}' --format json | grep responderUri
```

「回答を 1 回に制限する」は Forms API に無い（新規フォームは既定 OFF）。変更が必要なら編集 UI の 設定 → 回答。

## 動作確認

シークレットウィンドウで https://tori-dev.com/contact を開き、ログインダイアログが出ずに送信できること。
CLI なら公開 URL の HTML に `accounts.google.com/Login` が含まれないことで判定できる。

## 旧フォーム

2026-09 以前に使っていた公開 ID `1FAIpQLSeHGhQpoV7JmCVTdEwt5RZPtNa0_R-X1dDpyqyLqWyisP8X1w` はオーナー不明
（7991 の Drive・共有アイテムに無い。旧サイト repo のコミット者 `rito.aither@gmail.com` が有力）。
「回答を 1 回に制限する」が ON でログイン必須になっていたため差し替えた。過去の回答はそのフォーム側に残る。
