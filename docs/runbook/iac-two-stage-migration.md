# 2 段構成の IaC への移行 runbook（2026-10、1 回だけ）

旧構成（Terraform 1 つ、CI がすべて apply、共有 WIF Pool、GitHub Secrets）から、
bootstrap / app の 2 段構成（[ADR 0006](../adr/0006-two-stage-terraform.md)）へ本番を移す手順。

- 本番を変えるコマンドはすべて人が実行する。各手順の「確認」を満たさなければ先へ進まない。
- **手順 5 で PR をマージするまで、main と preview ブランチに push しない。** 手順 3 以降は旧 CI の権限が外れるので、旧 workflow は失敗する。
- **手順 3 以降は前に進むだけで、旧構成には戻さない。** 手順 3 で state が google provider 8 系の形式になり、旧 SA・API・旧 Provider が state から外れるので、旧コードに戻しても動かない。手順 3 以降で失敗したら、その場で直して先へ進む（forward fix）。そのための控えを手順 3 の前に取る。
- 作業は移行 PR のブランチを checkout したリポジトリのルートで行う。
- 公開リポジトリなので、控えたファイル（`.migration-backup/`）はコミットしない（`.gitignore` 済み）。

## 0. 準備

```bash
git switch <移行 PR のブランチ>
mise exec -- terraform version            # Terraform v1.15.x であること（CI と同じ）
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token --account=ryo.tonegawa.7991@gmail.com)"  # 1 時間で切れる。切れたら再実行
export GITHUB_TOKEN="$(gh auth token)"
export CF_ISSUER_ACCOUNT=ryo.tonegawa.7991@gmail.com   # 発行用トークンを読むアカウント
mkdir -p .migration-backup
```

`scripts/with-cloudflare-token.sh` は、tori-dev-secrets の `cloudflare-tori-dev-deploy-token` を発行用トークンとして使う。
実行のたびに有効期限 1 時間のトークンを発行し、終わったら削除する。

**事前確認**:

```bash
# tfstate バケットが公開されていない（手順 2 で公開アクセス防止を有効にする前の確認）
# 取得に失敗したら OK と出さずに止める
policy=$(gcloud storage buckets get-iam-policy gs://tori-develop-tfstate --account=ryo.tonegawa.7991@gmail.com --format=json) \
  || { echo "IAM ポリシーを取得できません。止める"; false; }
grep -E 'allUsers|allAuthenticatedUsers' <<<"$policy" && echo "公開設定あり。止める" || echo "OK: 公開設定なし"

# 旧サイト（default site）に付いている独自ドメイン（手順 4・7 で旧 TXT と旧サイトを止めるため）
curl -sf -H "Authorization: Bearer $GOOGLE_OAUTH_ACCESS_TOKEN" \
  "https://firebasehosting.googleapis.com/v1beta1/projects/tori-develop/sites/tori-develop/customDomains" \
  | jq -e '[.customDomains[]?.name]' || echo "取得に失敗。止める"

# tfstate バケット全体の控え（このバケットには他リポジトリの state もあり、手順 2 で世代管理を有効にする前に取る）
gcloud storage cp -r gs://tori-develop-tfstate .migration-backup/tfstate-bucket --account=ryo.tonegawa.7991@gmail.com
```

旧サイトのドメイン一覧は `[]`（空）であることを期待する。何か出たら、手順 4 の旧 TXT の削除と手順 7 の旧サイト停止はしないで報告する。

tfstate バケット `tori-develop-tfstate` は名刺サイトなど他リポジトリの state と共用している。手順 2 で入れる世代管理と古い世代の削除ルールは、
バケット全体（他リポジトリの state も）に効く。他リポジトリの Terraform がこのバケット自体（`google_storage_bucket`）を管理していないことを確認しておく
（2026-10 時点では、どのリポジトリもバケットを管理していない。作ったのは旧 `setup_gcp.sh`）。

## 1. Cloudflare の ID を調べて tfvars に書く

ゾーン ID は Cloudflare ダッシュボードの tori-dev.com の Overview（右側の API 欄）にある。秘密ではない。
`terraform/bootstrap/terraform.tfvars` の `cloudflare_zone_id` に書いてから、レコードの一覧を出して控える。

```bash
scripts/with-cloudflare-token.sh -- sh -c '
  ZONE=$(sed -nE "s/^ *cloudflare_zone_id *= *\"([0-9a-f]{32})\".*/\1/p" terraform/bootstrap/terraform.tfvars)
  printf "header = \"Authorization: Bearer %s\"\n" "$CLOUDFLARE_API_TOKEN" \
    | curl -s --config - "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?per_page=100"' \
  > .migration-backup/dns-records.json
jq -r '.result[] | [.id, .type, .name, .content, (.proxied|tostring)] | @tsv' .migration-backup/dns-records.json
```

一覧から次の ID を控える。

| レコード | 使い道 |
|---|---|
| `A tori-dev.com 199.36.158.100` | tfvars の `existing.dns_apex_a_record_id`（import） |
| `TXT tori-dev.com hosting-site=tori-develop-blog` | tfvars の `existing.dns_ownership_txt_record_id`（import） |
| `CNAME preview.tori-dev.com` | 手順 4 で削除 |
| `TXT tori-dev.com hosting-site=tori-develop`（旧サイト用） | 手順 4 で削除 |

tfvars の `TODO_` をすべて埋め、行末の `# TODO:` コメントも消してから、コミットして PR に push する（ID は秘密ではない）。
CI の `plan` チェックは `TODO_` が残っていると失敗する。埋めた後も、手順 2 で Variables と SA ができるまでは認証できずに失敗する（手順 5 で再実行するまで赤のままでよい）。

**確認**: `grep -n TODO_ terraform/*/terraform.tfvars` が何も出さない。

## 2. bootstrap を plan → apply

```bash
mise exec -- terraform -chdir=terraform/bootstrap init -backend-config=backend.hcl
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -out=tfplan
```

**確認**（plan ファイルから数える）:

```bash
cd terraform/bootstrap
mise exec -- terraform show -json tfplan > ../../.migration-backup/bootstrap-plan.json
cd ../..
P=.migration-backup/bootstrap-plan.json
# 削除・作り直しが 0 件
jq '[.resource_changes[] | select(.change.actions | index("delete"))] | length' $P
# import が 11 件（tfstate バケット 1、API 8、DNS 2）
jq '[.resource_changes[] | select(.change.importing != null)] | length' $P
# 既存リソースへの変更（update）は tfstate バケットの 1 件だけ
jq -r '.resource_changes[] | select(.change.actions == ["update"]) | .address' $P
# 変更の全体（create は新しく作るもの。delete・replace が 1 件も無いこと）
jq -r '.resource_changes[] | select(.change.actions != ["no-op"]) | "\(.change.actions|join(",")) \(.address)"' $P | sort | uniq -c | sort -rn | head -50
```

- tfstate バケットの update は「公開アクセス防止」「バージョニング有効」「古い世代の削除ルール」の追加だけであること。作り直し（replace）になっていたら止める（`tf_state_bucket_location` が実際と違う）。
- DNS の 2 件は import だけで、update が出ないこと。出たら止めて差分を読み、`terraform/bootstrap/dns.tf` の `content`・`comment`・`ttl` を実際の値に合わせてから plan し直す（TXT の引用符の付け方の差がよくある）。apex の A は消えると名前解決が止まるので、少しでも怪しければ進まない。
- 新規作成されるもの: Pool・Provider・SA 3 つ・IAM・GitHub の Variables 11 件・Environment 2 つ・ruleset・非公開の脆弱性報告（ローカルの `gh` で設定する）。

```bash
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply tfplan
```

**確認**:

```bash
gh variable list -R tori-create-7991/tori-dev-blog --json name --jq '.[].name' | sort
#   DEPLOYER_SA GCP_PROJECT_ID INDEXNOW_KEY PLANNER_SA PREVIEW_SA PREVIEW_SITE_ID PROD_SITE_ID PROD_SITE_URL
#   TF_STATE_BUCKET TF_STATE_PREFIX_APP WIF_PROVIDER の 11 個（INDEXNOW_KEY は tfvars に値があるときだけ）があること。
#   旧 Variables 4 個（CUSTOM_DOMAIN など）も手順 7 まで残る
gh api repos/tori-create-7991/tori-dev-blog/rulesets --jq '.[].name'   # main
```

**戻し方**: 新しい Pool・SA・Variables は旧構成と並存しているので、旧 CI には影響しない。
問題があれば destroy はせず（バケットと DNS は `prevent_destroy` で守られている）、定義を直して再 apply する。
新しい Pool と Provider は、消すと 30 日間同じ ID を使えないので消さない。

## 3. app の state から Cloudflare を外して plan → apply

ここから先は前に進むだけ。先に控えを取る。

```bash
mise exec -- terraform -chdir=terraform/app init -backend-config=backend.hcl -reconfigure
mise exec -- terraform -chdir=terraform/app state pull > .migration-backup/app-state-before.json
gcloud projects get-iam-policy tori-develop --account=ryo.tonegawa.7991@gmail.com --format=json \
  > .migration-backup/project-iam-before.json
```

app stack は Cloudflare provider を持たなくなったので、state に残るレコード 2 件を外す
（実レコードは手順 2 で bootstrap が import 済み、または手順 4 で削除する）。

```bash
mise exec -- terraform -chdir=terraform/app state list | grep cloudflare
#   cloudflare_record.firebase_hosting_ownership[0]
#   cloudflare_record.firebase_hosting_preview[0]
mise exec -- terraform -chdir=terraform/app state rm \
  'cloudflare_record.firebase_hosting_ownership[0]' \
  'cloudflare_record.firebase_hosting_preview[0]'
mise exec -- terraform -chdir=terraform/app plan -out=tfplan
```

**確認**: 削除が次の 11 件だけで、変更（update）が 0 件であること。

```bash
cd terraform/app
mise exec -- terraform show -json tfplan > ../../.migration-backup/app-plan.json
cd ../..
P=.migration-backup/app-plan.json
jq -r '.resource_changes[] | select(.change.actions | index("delete")) | .address' $P
jq '[.resource_changes[] | select(.change.actions == ["update"])] | length' $P   # 0
# 変更の全体。delete 11 と forget 11 のほかに create・update・replace が無いこと
jq -r '.resource_changes[] | select(.change.actions != ["no-op"]) | "\(.change.actions|join(",")) \(.address)"' $P | sort
```

| 削除されるもの | 件数 | 理由 |
|---|---|---|
| `google_artifact_registry_repository.app` | 1 | Cloud Run の名残。イメージ 0 件 |
| `google_project_iam_member.github_actions[...]` | 8 | 旧 CI 用 SA の強い権限を剥奪 |
| `google_storage_bucket_iam_member.github_actions_tfstate` | 1 | 旧 CI 用 SA のバケット全体への storage.admin |
| `google_firebase_hosting_custom_domain.preview[0]` | 1 | preview.tori-dev.com を廃止 |

ほかに、state から外すだけ（"will no longer be managed"）のものが 11 件（API 8、旧 SA、旧 Provider、旧 binding）と、
`google_firebase_hosting_site.preview[0]` → `google_firebase_hosting_site.preview` の移動（moved）が出る。
2026-10-24 に本番 state の複製で同じ plan を確認済み（削除 11・state から外す 11・移動 1・変更 0）。

```bash
mise exec -- terraform -chdir=terraform/app apply tfplan
```

**途中で失敗したら**: plan と apply の出力を見て直し、もう一度 plan → apply する。旧構成に戻すときは、
`.migration-backup/app-state-before.json` を `terraform state push` し、外した 11 件を `terraform import` し直す必要がある
（旧コードは google provider 5 系なので、8 系で書かれた state を読めないことがある）。

## 4. 使わなくなった DNS を消す

手順 1 で控えた 2 件（preview の CNAME と旧サイト用の TXT）を削除する。手順 0 で旧サイトに独自ドメインが残っていた場合、旧 TXT は消さない。

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
消したレコードの中身は `.migration-backup/dns-records.json` にあるので、必要なら同じ内容で作り直せる。

## 5. PR の CI を通してマージ

手順 2 で Variables と SA ができたので、PR のチェックを再実行する。このときが新しい CI の初めての実地テストになる。

```bash
gh pr checks <PR 番号> -R tori-create-7991/tori-dev-blog
gh run rerun <失敗した run の ID> -R tori-create-7991/tori-dev-blog
```

**確認**:
- `build` と `plan` が成功。plan のコメントが「差分なし」（手順 3 で apply 済みのため）。これで planner SA の権限が足りていることも確かめられる。
- PR にプレビュー URL のコメントが付き、開ける。レスポンスに `x-robots-tag: noindex` と `content-security-policy` が付いている。

権限エラーで落ちたら、`terraform/bootstrap/service_accounts.tf` のロールを足して手順 2 と同じく bootstrap を apply し、再実行する。
チェックが通らないままマージが必要なときは、管理者として `gh pr merge <PR 番号> --merge --admin`。

## 6. main の CI を確認

```bash
gh run list -R tori-create-7991/tori-dev-blog --branch main --limit 3
```

**確認**:
- `terraform` の apply のログが "No changes" であること（変更が出ていたら、その内容がマージ前の plan と同じか確かめる）。
- `terraform` の完了後に `deploy` が動いて成功している。
- `curl -sI https://tori-dev.com/` に `content-security-policy`・`x-frame-options`・`referrer-policy` が出る。

deployer SA の権限が足りずに apply か配信が落ちたら、手順 5 と同じく bootstrap でロールを足し、`gh run rerun` する。

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
curl -sI https://tori-dev.com/ | grep -iE 'content-security-policy|x-frame-options|referrer-policy'
curl -sI https://tori-develop.web.app/ | head -1                                   # 旧サイトは 404
```

すべて確認できたら `.migration-backup/` を削除する。
