# 0006. Terraform を bootstrap と app の 2 段に分け、CI に秘密を持たせない

Status: Accepted（2026-10-24）

## Context

このリポジトリは公開（MIT）で、フォークした人が自分の GCP と GitHub だけで同じ構成を作れるようにしたい。
2026-10 時点の構成には次の問題があった。

- Terraform は 1 つで、CI が main への push ごとに全部を apply していた。CI が自分の WIF・SA・IAM まで
  管理するため、CI 用 SA に `projectIamAdmin` などプロジェクト全体の強い権限が付いていた。
- WIF Pool `github-pool` を 3 つのリポジトリで共有し、Pool 自体は別リポジトリ（名刺サイト）の state が持っていた。
- PR を通さずに push できる `preview` ブランチからも、本番インフラを apply できた。
- CI が GitHub Secrets に Cloudflare の API トークンなど 7 件を持っていた。
- tfstate バケットの作成、WIF Pool、GitHub の Variables、apex の DNS などが手作業や初期構築スクリプトで作られ、
  コードで再現できなかった。

## Decision

1. **Terraform を 2 段に分ける。**
   - `terraform/bootstrap/`: 人がローカルで apply する。API、tfstate バケット、リポジトリ専用の WIF Pool と
     Provider、役割別の CI 用 SA と権限、Cloudflare の DNS、GitHub の Variables・Environment・ruleset。
   - `terraform/app/`: CI が main への push で apply する。Firebase Hosting のサイトと本番の独自ドメインだけ。
   - PR では CI が app の plan を実行して PR にコメントする。マージすれば apply されるので、コードと本番が食い違わない。
2. **WIF Pool はリポジトリごとに作る**（00_my_env の命名ルール `gcp-ci-identity-naming`）。Pool `tori-dev-blog-pool`、
   Provider `github-actions`、SA `gha-tori-dev-blog-<役割>`。Pool が専用なので、SA のなりすまし条件を
   `ref`（deployer は main のみ）や `event_name`（preview は PR のみ）だけで安全に絞れる。
3. **CI は秘密を 1 つも持たない。** GitHub Secrets は 0 件。DNS はほとんど変わらないので bootstrap に置き、
   apply するときだけ `scripts/with-cloudflare-token.sh` が有効期限 1 時間のトークンを発行して終わったら消す。
4. **PR ごとに Firebase Hosting のプレビューチャネルを出し、`preview` ブランチと preview.tori-dev.com を廃止する。**
5. **既存リソースは destroy せずに移す。** bootstrap へは `import`、app からは `removed { destroy = false }` と
   `terraform state rm`。意図して消すのは、空の Artifact Registry、旧 CI 用 SA の強い権限、検証用ドメインだけ。

## Alternatives

- **1 つの stack をローカルだけで apply し、CI は配信だけにする。** CI の権限は最小になり、仕組みも一番少ない。
  ただし「マージ後の apply 忘れ」でコードと本番が食い違いうる。エージェントが PR でインフラを変えて
  auto マージする運用では、「マージ＝適用」と「PR に plan が残る」ことの価値が大きいので採らなかった。
- **Cloudflare トークンを Secret Manager に置き、CI が実行時に読む。** CI が DNS を編集できるトークンを持ち、
  90 日ごとの更新と期限切れ検知も要る。DNS の変更頻度に見合わないので採らなかった。
- **共有 Pool を使い続ける。** Pool の変更が他リポジトリに波及し、Pool の持ち主が別リポジトリの state になる。

## Consequences

- フォークした人は、tfstate バケットを gcloud で 1 回作ったあと、bootstrap と app を 1 回ずつ apply すれば同じ構成になる（`docs/setup/fork.md`）。
- CI が持つ権限は「app stack の apply（Hosting だけ）と配信」と「読み取り」だけになる。
- フォークや Dependabot の PR では GCP に認証できないので plan が動かない。必須チェック `plan` は成功扱いにし、
  Terraform に関わる更新はマージ前にローカルで plan を確認する。
- DNS のズレは CI では検知しない。bootstrap をローカルで plan したときに確認する。
- 移行手順は `docs/runbook/iac-two-stage-migration.md`。
