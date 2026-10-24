# 2 段構成の IaC への移行 runbook（2026-10、1 回だけ）

旧構成（Terraform 1 つ、CI がすべて apply、共有 WIF Pool、GitHub Secrets）から、
bootstrap / app の 2 段構成（[ADR 0006](../adr/0006-two-stage-terraform.md)）へ本番を移す手順。

- 本番を変えるコマンドはすべて人が実行する。各手順の「確認」を満たさなければ先へ進まない。
- **手順 5 で PR をマージするまで、main に push しない。** 手順 3 以降は旧 CI の権限が外れるので、main の旧 workflow は失敗する。
- 作業は移行 PR のブランチを checkout したリポジトリのルートで行う。

## 0. 準備

```bash
git switch <移行 PR のブランチ>
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token --account=ryo.tonegawa.7991@gmail.com)"  # 1 時間で切れる。切れたら再実行
export GITHUB_TOKEN="$(gh auth token)"
export CF_ISSUER_ACCOUNT=ryo.tonegawa.7991@gmail.com   # 発行用トークンを読むアカウント
```

`scripts/with-cloudflare-token.sh` は、tori-dev-secrets の `cloudflare-tori-dev-deploy-token` を発行用トークンとして使う。
実行のたびに有効期限 1 時間のトークンを発行し、終わったら削除する。

## 1. Cloudflare の ID を調べて tfvars に書く

ゾーン ID は Cloudflare ダッシュボードの tori-dev.com の Overview（右側の API 欄）にある。秘密ではない。
`terraform/bootstrap/terraform.tfvars` の `cloudflare_zone_id` に書いてから、レコードの一覧を出す。

```bash
scripts/with-cloudflare-token.sh -- sh -c '
  ZONE=$(sed -nE "s/^ *cloudflare_zone_id *= *\"([0-9a-f]{32})\".*/\1/p" terraform/bootstrap/terraform.tfvars)
  printf "header = \"Authorization: Bearer %s\"\n" "$CLOUDFLARE_API_TOKEN" \
    | curl -s --config - "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?per_page=100" \
    | jq -r ".result[] | [.id, .type, .name, .content, (.proxied|tostring)] | @tsv"'
```

一覧から次の ID を控える。

| レコード | 使い道 |
|---|---|
| `A tori-dev.com 199.36.158.100` | tfvars の `existing.dns_apex_a_record_id`（import） |
| `TXT tori-dev.com hosting-site=tori-develop-blog` | tfvars の `existing.dns_ownership_txt_record_id`（import） |
| `CNAME preview.tori-dev.com` | 手順 4 で削除 |
| `TXT tori-dev.com hosting-site=tori-develop`（旧サイト用） | 手順 4 で削除 |

tfvars の `TODO_` をすべて埋めたら、変更をコミットして PR に push する（ID は秘密ではない）。

**確認**: `grep -n TODO_ terraform/bootstrap/terraform.tfvars` が何も出さない。

## 2. bootstrap を plan → apply

```bash
mise exec -- terraform -chdir=terraform/bootstrap init -backend-config=backend.hcl
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -out=tfplan
```

**確認**（どちらも plan ファイルから数える）:

```bash
cd terraform/bootstrap
# 削除が 0 件
mise exec -- terraform show -json tfplan | jq '[.resource_changes[] | select(.change.actions | index("delete"))] | length'
# import が 11 件（tfstate バケット 1、API 8、DNS 2）
mise exec -- terraform show -json tfplan | jq '[.resource_changes[] | select(.change.importing != null)] | length'
cd ../..
```

- tfstate バケットは import と同時に「バージョニング有効・公開アクセス防止」の変更（update）が入る。作り直し（replace）になっていたら止める（`tf_state_bucket_location` の値が実際と違う）。
- DNS の 2 件は import のみで変更なし（update が出たら content の書き方の差。plan の差分を見て tfvars か定義を直す）。
- 新規作成されるもの: Pool・Provider・SA 3 つ・IAM・GitHub の Variables 12 件・Environment 2 つ・ruleset・非公開の脆弱性報告。

```bash
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply tfplan
```

**確認**:

```bash
gh variable list -R tori-create-7991/tori-dev-blog          # WIF_PROVIDER など 12 件
gh api repos/tori-create-7991/tori-dev-blog/rulesets --jq '.[].name'   # main
```

**戻し方**: 新しい Pool・SA・Variables は旧構成と並存しているので、旧 CI には影響しない。
問題があれば `terraform -chdir=terraform/bootstrap destroy` の前に、tfstate バケットと DNS を
`terraform state rm` で外してから destroy する（バケットは `prevent_destroy` で守られている）。

## 3. app の state から Cloudflare を外して plan → apply

app stack は Cloudflare provider を持たなくなったので、state に残るレコード 2 件を先に外す
（実レコードは手順 2 で bootstrap が import 済み、または手順 4 で削除する）。

```bash
mise exec -- terraform -chdir=terraform/app init -backend-config=backend.hcl -reconfigure
mise exec -- terraform -chdir=terraform/app state list | grep cloudflare
#   cloudflare_record.firebase_hosting_ownership[0]
#   cloudflare_record.firebase_hosting_preview[0]
mise exec -- terraform -chdir=terraform/app state rm \
  'cloudflare_record.firebase_hosting_ownership[0]' \
  'cloudflare_record.firebase_hosting_preview[0]'
mise exec -- terraform -chdir=terraform/app plan -out=tfplan
```

**確認**: 削除されるのが次の 11 件だけであること。

```bash
cd terraform/app
mise exec -- terraform show -json tfplan \
  | jq -r '.resource_changes[] | select(.change.actions | index("delete")) | .address'
cd ../..
```

| 削除されるもの | 件数 | 理由 |
|---|---|---|
| `google_artifact_registry_repository.app` | 1 | Cloud Run の名残。イメージ 0 件 |
| `google_project_iam_member.github_actions[...]` | 8 | 旧 CI 用 SA の強い権限を剥奪 |
| `google_storage_bucket_iam_member.github_actions_tfstate` | 1 | 旧 CI 用 SA のバケット全体への storage.admin |
| `google_firebase_hosting_custom_domain.preview[0]` | 1 | preview.tori-dev.com を廃止 |

ほかに、state から外すだけ（"will no longer be managed"）のものが 11 件（API 8、旧 SA、旧 Provider、旧 binding）と、
`google_firebase_hosting_site.preview[0]` → `google_firebase_hosting_site.preview` の移動（moved）が出る。
google provider を 5 系から 8 系に上げたことによる update が出た場合は、内容を読んで問題ないか判断する。

```bash
mise exec -- terraform -chdir=terraform/app apply tfplan
```

**戻し方**: 剥奪した権限は、旧構成のコード（main の `terraform/iam.tf`）で `gcloud projects add-iam-policy-binding`
すれば戻る。検証用ドメインは Firebase Console から付け直せる（DNS は手順 4 まで残っている）。

## 4. 使わなくなった DNS を消す

手順 1 で控えた 2 件（preview の CNAME と旧サイト用の TXT）を削除する。

```bash
scripts/with-cloudflare-token.sh -- sh -c '
  ZONE=$(sed -nE "s/^ *cloudflare_zone_id *= *\"([0-9a-f]{32})\".*/\1/p" terraform/bootstrap/terraform.tfvars)
  for ID in <preview CNAME の ID> <旧 TXT の ID>; do
    printf "header = \"Authorization: Bearer %s\"\n" "$CLOUDFLARE_API_TOKEN" \
      | curl -s --config - -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/$ID" \
      | jq -c "{success, id: .result.id}"
  done'
```

**確認**: 手順 1 の一覧コマンドを再実行し、2 件が消え、apex A と所有権 TXT が残っている。

## 5. PR の CI を通してマージ

手順 2 で Variables と SA ができたので、PR のチェックを再実行する。

```bash
gh pr checks <PR 番号> -R tori-create-7991/tori-dev-blog
gh run rerun <失敗した run の ID> -R tori-create-7991/tori-dev-blog
```

**確認**:
- `build` と `plan` が成功。plan のコメントが「差分なし」（手順 3 で apply 済みのため）。
- PR にプレビュー URL のコメントが付き、開ける。レスポンスに `x-robots-tag: noindex` と `content-security-policy` が付いている。

マージする。

## 6. main の CI を確認

```bash
gh run list -R tori-create-7991/tori-dev-blog --branch main --limit 3
```

**確認**: `terraform`（apply は "No changes"）と `deploy` が成功。`curl -sI https://tori-dev.com/` に `content-security-policy` と `x-frame-options` が出る。

## 7. 後片付け

新構成で main の CI が通ったことを確認してから行う。

```bash
# 旧 WIF Provider（共有 Pool github-pool 内）と旧 CI 用 SA。Provider は 30 日以内なら undelete できる
gcloud iam workload-identity-pools providers delete tori-dev-blog-provider \
  --workload-identity-pool=github-pool --location=global --project=tori-develop --account=ryo.tonegawa.7991@gmail.com
gcloud iam service-accounts delete github-actions-tori-blog@tori-develop.iam.gserviceaccount.com \
  --project=tori-develop --account=ryo.tonegawa.7991@gmail.com

# 旧 GitHub Secrets 7 件と旧 Variables 4 件
for s in CLOUDFLARE_API_TOKEN CLOUDFLARE_ZONE_ID GCP_PROJECT_ID GCP_SA_EMAIL GCP_TF_STATE_BUCKET INDEXNOW_KEY WIF_PROVIDER; do
  gh secret delete "$s" -R tori-create-7991/tori-dev-blog
done
for v in CUSTOM_DOMAIN ENABLE_PREVIEW_SITE PREVIEW_CUSTOM_DOMAIN PREVIEW_SITE_SUFFIX; do
  gh variable delete "$v" -R tori-create-7991/tori-dev-blog
done

# preview ブランチ
git push origin --delete preview

# 旧 Nuxt2 サイト（default site）の配信を止める。サイト自体は削除できない
npx firebase hosting:disable --site tori-develop --project tori-develop
```

`github-pool` 自体は名刺サイト（`01_self-digital-business-card`）の state が持っているので、ここでは触らない。
3 つのリポジトリが抜けたあと、名刺サイト側で削除する。

## 8. 最終確認

```bash
gh secret list -R tori-create-7991/tori-dev-blog                                   # 何も出ない
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -detailed-exitcode   # exit 0
mise exec -- terraform -chdir=terraform/app plan -detailed-exitcode                # exit 0
curl -sI https://tori-dev.com/ | grep -iE 'content-security-policy|x-frame-options'
curl -sI https://tori-develop.web.app/ | head -1                                   # 旧サイトは 404
```
