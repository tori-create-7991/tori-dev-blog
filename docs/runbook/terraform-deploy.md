# Runbook: Terraform とデプロイの運用

2 段構成（[ADR 0006](../adr/0006-two-stage-terraform.md)）になってからの日常の運用手順。
ゼロから構築する手順は [docs/setup/fork.md](../setup/fork.md)、2026-10 の移行は
[iac-two-stage-migration.md](iac-two-stage-migration.md)。

## 何がどこで動くか

| | 中身 | 誰がいつ apply するか |
|---|---|---|
| `terraform/bootstrap/` | API、tfstate バケット、WIF Pool・Provider、CI 用 SA と権限、Cloudflare DNS、GitHub の Variables・Environment・ruleset | 人がローカルで、変えるときだけ |
| `terraform/app/` | Firebase Hosting の本番・検証サイト、本番の独自ドメイン | CI が main への push で（`terraform.yml`） |
| サイトの中身 | Nuxt のビルド結果 | CI が main への push で、`terraform.yml` の apply が成功したあと本番へ（`deploy.yml`）。PR ごとにプレビューへ（`pr-preview.yml`） |

CI は GitHub Secrets を使わない。値はすべて bootstrap が登録する Variables から読む。

| CI 用 SA | 使える条件 | 権限 |
|---|---|---|
| `gha-tori-dev-blog-deployer` | Environment `production` のジョブ（main ブランチだけが使える） | Hosting の管理、app stack の state の読み書き |
| `gha-tori-dev-blog-preview` | PR | Hosting の管理（プレビューチャネルへの配信に使う） |
| `gha-tori-dev-blog-planner` | このリポジトリの全ワークフロー | 読み取り、app stack の state の読み取り |

## 共通の準備（ローカルで Terraform を実行するとき）

```bash
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token --account=ryo.tonegawa.7991@gmail.com)"
export GITHUB_TOKEN="$(gh auth token)"                   # bootstrap のみ
export CF_ISSUER_ACCOUNT=ryo.tonegawa.7991@gmail.com      # bootstrap で DNS を扱うとき
```

apply は main を最新にしてから実行する。PR のブランチから apply すると、main にない状態が本番に入る。

## app を変える（Hosting・ドメイン）

1. `terraform/app/` を変えて PR を出す。CI が plan を PR にコメントする。
2. plan を確認してマージする。CI が apply する。

ローカルで plan だけ見たいとき:

```bash
mise exec -- terraform -chdir=terraform/app init -backend-config=backend.hcl
mise exec -- terraform -chdir=terraform/app plan
```

## bootstrap を変える（権限・DNS・GitHub 設定）

1. `terraform/bootstrap/` を変え、ローカルで plan を実行して結果を PR の本文に貼る。
2. マージしたら main を最新にして apply する。

```bash
git switch main && git pull
mise exec -- terraform -chdir=terraform/bootstrap init -backend-config=backend.hcl
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -out=tfplan
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply tfplan
```

`scripts/with-cloudflare-token.sh` は、tori-dev-secrets の発行用トークン（`cloudflare-tori-dev-deploy-token`、
User API Tokens: Edit 権限）を使って、tori-dev.com だけを編集できる有効期限 1 時間のトークンを発行し、
コマンドが終わったら削除する。DNS に触れない変更でも、bootstrap の plan には Cloudflare の読み取りが入るので使う。

## チェックが失敗したとき

| 失敗 | 対応 |
|---|---|
| PR の `plan` | plan の出力（PR のコメントか Actions のログ）を見る。認証エラーなら Variables と SA の binding を bootstrap の plan で確認 |
| PR の `build` | ビルドのログを見る。`check-drafts` の失敗は下書きがビルドに混ざっている（ADR 0004） |
| 毎週の `drift` | 本番の Hosting 設定がコードとずれている。Console での手作業を探し、コードに取り込むか main から apply して戻す |
| main の `deploy` の疎通確認 | Firebase Console のリリース履歴から前のバージョンに戻す（DNS は触らない） |

## 定期的にやること

- **月に 1 回、bootstrap の plan を実行する**（上の手順の plan まで）。CI のズレ検知は app（Hosting）だけを見ていて、DNS・SA・GitHub 設定のズレには気づけない。差分が出たら原因を調べ、コードに取り込むか apply で戻す。
- **失敗の通知はメール**。GitHub Actions の失敗は、ワークフローを最後に編集した人（スケジュール実行は cron を最後に変えた人）にメールで届く。週 1 回の `drift` の失敗もここで気づく。公開リポジトリで 60 日間コミットが無いとスケジュール実行が止まるので、そのときは Actions 画面から有効にし直す。

## フォークと Dependabot の PR

GCP に認証できないので、plan とプレビューは動かずビルドの確認だけになる。
`terraform/` に触れない PR では、必須チェック `plan` は成功扱いになる。`terraform/` に触れる PR（Dependabot の provider 更新など）では
`plan` が失敗するので、ローカルで plan を確認してから、管理者として保護を無視してマージする（`gh pr merge <番号> --merge --admin`）。

## 受け入れているリスク（既知の制約）

| 制約 | 理由・対策 |
|---|---|
| 発行用の Cloudflare トークン（User API Tokens: Edit）は、実質 Cloudflare アカウント全体の権限を持つ | 短命トークンを作るための元の鍵として必要。tori-dev-secrets の Secret Manager で保管し、読めるのは自分のアカウントだけにする |
| preview SA でも本番サイトへ配信できる | Hosting の権限はプロジェクト単位でしか付けられない。使えるのはこのリポジトリからの PR だけで、PR を作れるのは書き込み権限のある人だけ |
| deployer SA は app stack の state の古い世代も消せる | ロックファイルの削除に同じ権限が要るため分けられない。古い世代は 10 世代または 90 日まで残る |
| CSP に `'unsafe-inline'`・`'unsafe-eval'` が残っている | Nuxt の静的出力がインラインスクリプトを使うため。外すのは別タスク |
| HSTS に `includeSubDomains` を付けている | tori-dev.com のサブドメインはすべて HTTPS で配信する前提。HTTPS でないサブドメインを作るときは外す |

## 過去の事故（再発防止の理由）

> **2026-07-22: state の prefix の衝突**。GCS backend の prefix が `terraform/blog` という汎用名で、同じバケットを
> 使っていた旧 Nuxt3 ブログ（`012_nuxt-07_nuxt3_toriblog`）の state と衝突した。apply が旧リポジトリの
> SA の権限・WIF Provider・Artifact Registry を壊した。→ prefix にはリポジトリ名をフルで含める（命名ルール
> `gcp-ci-identity-naming`）。CI 用 SA の tfstate の権限は IAM Condition で app stack の state だけに絞っている。

> **2026-07-23: Variables の登録漏れで本番が消えた**。`CUSTOM_DOMAIN` が未登録で空文字になり、
> 「独自ドメインなし」と判定されて preview.tori-dev.com の DNS とカスタムドメインが destroy された。
> → Variables は bootstrap が Terraform で登録する。空文字が「リソースを消す」方向に倒れる変数は、
> CI からは渡さず tfvars に置く（app stack は CI から変数を受け取らない）。
