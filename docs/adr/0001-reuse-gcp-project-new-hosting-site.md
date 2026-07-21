# 0001. GCP project `tori-develop` を再利用し、新規 Firebase Hosting サイトとして分離する

Status: Accepted

## Context

新 Nuxt3 ブログ（tori-dev-blog）を Firebase Hosting にデプロイするにあたり、
以下の選択肢があった:

1. 新規 GCP project を作成し、そこに新サイトをホスティングする
2. 現行 tori-dev.com が稼働している既存 project `tori-develop` を再利用し、
   Firebase Hosting の multi-site 機能で**別サイト**として追加する

現行 tori-dev.com（Nuxt2/Vuetify）は project `tori-develop` の **default
Firebase Hosting サイト**で稼働中。ドメイン・課金・既存 IAM 設定がこの
project に紐づいている。

## Decision

GCP project `tori-develop` を再利用する。新 Nuxt3 サイトは Firebase Hosting
の multi-site 機能を用いて `${project_id}-${firebase_site_suffix}`
（デフォルト `tori-develop-blog`）という**別サイト ID**で作成する。

WIF (Workload Identity Federation) の Pool `github-pool` も既存のものを
共有継続する（business-card リポジトリ等と共用）。ただし Provider は
リポジトリ単位で分離し、`attribute_condition` で
`assertion.repository == "tori-create-7991/tori-dev-blog"` に限定した
新規 Provider（`tori-dev-blog-provider` 等）を作成する。

## Consequences

**良い面:**
- 既存の default サイト（旧 Nuxt2 ブログ）に一切影響を与えず、新サイトを
  独立してデプロイ・検証できる
- 課金・ドメイン管理・既存 IAM 資産をそのまま活かせる。新規 project 作成に
  伴う権限設定・請求先設定等のセットアップコストが発生しない
- WIF Pool 共有により、Pool 自体の管理（`scripts/setup_gcp.sh` での
  gcloud 手動確保）を再実行する必要がない

**悪い面:**
- 同一 project 内に新旧 2 つの Firebase Hosting サイトが並存する期間が
  生じる。カスタムドメイン tori-dev.com の切替タイミングを別途判断・実行
  する必要がある（本 ADR のスコープ外）
- WIF Pool が複数リポジトリで共有されるため、Pool 自体の設定変更は
  他リポジトリ（business-card 等）にも影響しうる。Provider 単位の分離で
  リスクは抑えているが、Pool 自体の削除・再設定は避ける必要がある
