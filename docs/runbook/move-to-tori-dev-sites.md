# GCP プロジェクトを tori-dev-sites へ移す runbook（2026-11、1 回だけ）

ブログを `tori-develop` から、サイト専用の新プロジェクト `tori-dev-sites` へ移す手順（[ADR 0007](../adr/0007-move-to-tori-dev-sites.md)）。
名刺サイト（01_self-digital-business-card）も同じプロジェクトへ移る。名刺の手順は名刺のリポジトリにあり、この手順の 3 が終わってから始める。

- 本番を変えるコマンドはすべて人が実行する。各手順の「確認」を満たさなければ先へ進まない。
- **手順 3 から手順 4 のマージまで、main に push しない**（Dependabot の PR もマージしない）。手順 3 で GitHub Variables が新プロジェクトを指すが、
  main のコードはまだ旧プロジェクト用なので、main の CI は失敗する。`terraform`・`deploy` を手動実行（workflow_dispatch）もしない。
  この間に月曜の定期ズレ検知が動くと失敗するが、apply はしないので無視してよい。
- 手順 5 の切替までは、tori-dev.com は旧サイト `tori-develop-blog` から配信され続ける。手順 5 より前ならいつでも中止できる（戻し方は各手順）。
- tori-develop の旧 state（`gs://tori-develop-tfstate/terraform/tori-dev-blog/`）には触らない。**旧 state で terraform を実行しない**（本番の DNS と GitHub 設定を旧値に戻してしまう）。
- 作業は移行 PR のブランチを checkout したリポジトリのルートで行う。

## 0. 準備

```bash
setopt interactive_comments   # zsh で行末の # をコメントとして扱う（この手順のコマンドは行末にコメントがある）
git switch feat/move-to-tori-dev-sites
mise exec -- terraform version            # Terraform v1.15.x であること（CI と同じ）
ACC=--account=ryo.tonegawa.7991@gmail.com
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token $ACC)"  # 1 時間で切れる。切れたら再実行
export GITHUB_TOKEN="$(gh auth token)"
export CF_ISSUER_ACCOUNT=ryo.tonegawa.7991@gmail.com   # scripts/with-cloudflare-token.sh 用
NEW=tori-dev-sites
BUCKET=tori-dev-sites-tori-dev-blog-tfstate
# Firebase Hosting の REST API を呼ぶ関数（課金先プロジェクトの指定が無いと 403 になる）
fh() { curl -sf -H "Authorization: Bearer $GOOGLE_OAUTH_ACCESS_TOKEN" -H "X-Goog-User-Project: $1" \
  "https://firebasehosting.googleapis.com/v1beta1/$2" "${@:3}"; }
```

## 1. プロジェクトを作る

```bash
gcloud projects create $NEW --name="tori-dev sites" $ACC
gcloud billing accounts list $ACC                       # 使う請求先アカウントの ID を選ぶ
gcloud billing projects link $NEW --billing-account=<請求先アカウント ID> $ACC
# bootstrap が API を有効化する前に要る 3 つ（新しいプロジェクトでは既に有効なこともある）
gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com storage.googleapis.com --project=$NEW $ACC
```

- `tori-dev-sites` が使えない（既に使われている）と言われたら止める。ID を変えるならこの PR の `project_id` とバケット名を書き換える。
- 任意: 請求先アカウントに予算アラート（例: 月 100 円）を付ける。Hosting と state は無料枠に収まる想定。

**確認**: `gcloud billing projects describe $NEW $ACC --format='value(billingEnabled)'` が `True`。

## 2. state バケットを作る

```bash
gcloud storage buckets create gs://$BUCKET --project=$NEW --location=us-central1 \
  --uniform-bucket-level-access --public-access-prevention $ACC
```

バージョン管理と古い世代の削除ルールは手順 3 の apply で入る（bootstrap が import して管理する）。

戻し方: `gcloud storage buckets delete gs://$BUCKET $ACC`。

## 3. bootstrap を plan → apply

新しいバケットで state を新しく始める（`-reconfigure`。旧 state は移さない）。

```bash
mise exec -- terraform -chdir=terraform/bootstrap init -backend-config=backend.hcl -reconfigure
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -out=tfplan
```

**確認**（plan の中身）:

- `0 to destroy`。
- import: バケット 1・GitHub Variables 11・Environment 2・deployment policy 1・ruleset 1・Cloudflare 2。
- 新規: API 8・`google_firebase_project.default`・Pool `tori-dev-blog-pool`・Provider `github-actions`・SA 3 個とその IAM・`terraform_data.private_vulnerability_reporting`。
- GitHub Variables は値だけ変わる（`GCP_PROJECT_ID` が `tori-dev-sites`、`PROD_SITE_ID` が `tori-dev-sites-blog`、`TF_STATE_PREFIX_APP` が `terraform/tori-dev-blog/app` など）。`PROD_SITE_URL` は `https://tori-dev.com` のまま。
- Cloudflare の 2 レコードは**変わらない**（A は `199.36.158.100`、TXT は `hosting-site=tori-develop-blog` のまま。`comment` の差分だけなら可）。TXT が変わる plan なら止める（`dns_ownership_site_id` が効いていない）。
- バケットは update だけ（`versioning` と `lifecycle_rule` が足される。既定値の属性の差分も出てよい）。destroy・replace・`location` の変更が出たら止める。

```bash
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply tfplan
```

**確認**:

```bash
gh variable list -R tori-create-7991/tori-dev-blog          # 新プロジェクトの値になっている
fh $NEW projects/$NEW/sites | jq '[.sites[]?.name]'   # Firebase が有効（default site だけ、または空）
curl -s https://tori-dev.com/ -o /dev/null -w '%{http_code}\n'                       # 200（旧サイトから配信）
```

戻し方: Variables を旧値に戻せば旧構成に戻る。旧 state の `terraform/bootstrap` の値（`gh variable set` で 11 個）を入れ直す。
旧 SA と旧 Pool は手順 6 まで残っているので、それで旧 CI がまた動く。

ここから先は名刺サイトの移行を始めてよい（Firebase と API が有効になったため）。

## 4. PR の CI を通してマージ

```bash
gh run rerun --failed <plan を含む run の ID>   # Variables が新しくなったので新プロジェクトの plan になる
gh pr checks                                 # plan が成功、build はプレビュー配信だけ失敗
```

- plan は `google_firebase_hosting_site.blog`・`.preview`・`google_firebase_hosting_custom_domain.blog[0]` の 3 つの作成だけ。
- 必須チェック `build`（pr-preview.yml）は**失敗する**。プレビュー配信先の検証サイト `tori-dev-sites-preview` がマージ後の apply まで無いため。
  ビルド自体の成功をログで確かめ、`plan` が通っていれば、管理者として保護を無視してマージする（`gh pr merge --admin --merge`）。

マージすると main で次が順に動く: terraform（app を apply してサイトと独自ドメインを作る）→ deploy（新サイトへ配信）。

**確認**:

```bash
gh run list -R tori-create-7991/tori-dev-blog --branch main --limit 3
curl -s https://tori-dev-sites-blog.web.app/ -o /dev/null -w '%{http_code}\n'      # 200
curl -s https://tori-dev.com/ -o /dev/null -w '%{http_code}\n'                     # 200（まだ旧サイト）
fh $NEW projects/$NEW/sites/tori-dev-sites-blog/customDomains/tori-dev.com | jq '{ownershipState, hostState, cert: .cert.state, requiredDnsUpdates}'
```

- deploy の「Verify deployment」は tori-dev.com を見るので、この時点では旧サイトを確かめているだけ。新サイトは上の `web.app` で確かめる。
- 新サイトの独自ドメインは、所有権 TXT がまだ旧サイトを向いているので `OWNERSHIP_MISMATCH` などになる。これで正しい。
- 新サイトの中身が tori-dev.com と同じであることを、いくつかのページで見比べる。

**app の apply が独自ドメインの作成で失敗したら**（旧サイトに付いているせいで作れない場合。独自ドメインが app の state に**載っていない**ときだけ。載っていれば `custom_domain` は変えずに原因を直す。`prevent_destroy` があるので消す plan は止まる）: `terraform/app/terraform.tfvars` の
`custom_domain` を `""` にする PR を出してマージし、サイトと配信だけ先に済ませる。独自ドメインは手順 5 の 2 の apply のあとに、`custom_domain` を戻す PR をマージして作る。

## 5. 独自ドメインを新サイトへ切り替える

**2 の apply から 3 で新サイトが有効になるまでの間、独自ドメインが表示されない・証明書エラーになる時間がありうる**（数分〜最悪 24 時間。
Firebase は 1 つのドメインを 1 サイトにしか持たせず、DNS の向き先は 1 つしか書けないため）。混まない時間に、結果を見ていられるときに行う。
長引いたら下の「戻し方」で旧サイトに戻す。

ここで tori-dev.com の配信元が変わる。

1. 証明書を先に用意する（任意。HTTPS が使えない時間を短くする）。手順 4 の `requiredDnsUpdates` に `_acme-challenge.tori-dev.com` の TXT があれば、
   Cloudflare のダッシュボードで手で足す（DNS only）。このレコードは Terraform では管理しない（一時的なもの）。

2. 所有権 TXT を新サイトへ向ける。`terraform/bootstrap/terraform.tfvars` の `dns_ownership_site_id` の行（とその上のコメント）を消すコミットを作り、PR にする。そのブランチで:

   ```bash
   scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -out=tfplan
   # 確認: cloudflare_dns_record.ownership_txt[0] の content が hosting-site=tori-dev-sites-blog に変わる 1 件だけ
   scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply tfplan
   ```

3. 新サイトの独自ドメインが有効になるのを待つ（数分〜最大 24 時間）。

   ```bash
   fh $NEW projects/$NEW/sites/tori-dev-sites-blog/customDomains/tori-dev.com | jq '{ownershipState, hostState, cert: .cert.state}'
   # 期待: OWNERSHIP_ACTIVE / HOST_ACTIVE / CERT_ACTIVE
   curl -sI https://tori-dev.com/ | head -1                                         # HTTP/2 200
   ```

   1 時間たっても `OWNERSHIP_ACTIVE` にならないときは、旧サイトの独自ドメインを先に消す（次の 4）。消してから新サイトが有効になるまでは
   tori-dev.com が表示されない（または証明書エラーになる）。

4. 旧サイトの独自ドメインを消す。

   ```bash
   fh tori-develop projects/tori-develop/sites/tori-develop-blog/customDomains/tori-dev.com -X DELETE | jq '.name'
   ```

   消したものは 30 日間戻せる（`.../customDomains/tori-dev.com:undelete` に POST）。

5. 1 で足した `_acme-challenge` の TXT を消す。手順 5 の 2 の PR をマージする（bootstrap は既に apply 済みなので、マージで変わるものは無い）。

戻し方（4 より前）: `dns_ownership_site_id = "tori-develop-blog"` を戻して apply すれば、TXT が旧サイトに戻る。

## 6. 後片付け（tori-develop。切替後 1 週間ほど問題が無ければ）

**terraform コマンドは使わない。** 旧 state にはまだ本番の DNS と GitHub 設定が載っている。

```bash
P="--project=tori-develop"
OLD=gha-tori-dev-blog

# 6-1. 旧 Hosting サイト（本番と検証）。サイト ID は二度と使えなくなる
fh tori-develop projects/tori-develop/sites/tori-develop-blog/customDomains | jq '[.customDomains[]?.name]'   # [] であること
for s in tori-develop-blog tori-develop-preview; do fh tori-develop projects/tori-develop/sites/$s -X DELETE >/dev/null && echo "deleted $s"; done

# 6-2. 旧 SA の project IAM（今ある分を読んで外す）
for role in deployer preview planner; do
  SA="$OLD-$role@tori-develop.iam.gserviceaccount.com"
  for R in $(gcloud projects get-iam-policy tori-develop $ACC --flatten='bindings[].members' \
      --filter="bindings.members=serviceAccount:$SA" --format='value(bindings.role)'); do
    gcloud projects remove-iam-policy-binding tori-develop --member="serviceAccount:$SA" --role="$R" --condition=None $ACC --quiet >/dev/null && echo "removed $SA $R"
  done
done

# 6-3. 旧 state バケットの条件付き IAM（deployer と planner の 2 件）
gcloud storage buckets get-iam-policy gs://tori-develop-tfstate $ACC --format=json \
  | jq '.bindings |= map(.members -= ["serviceAccount:'$OLD'-deployer@tori-develop.iam.gserviceaccount.com","serviceAccount:'$OLD'-planner@tori-develop.iam.gserviceaccount.com"] | select(.members | length > 0))' \
  > /tmp/tfstate-iam.json
cat /tmp/tfstate-iam.json        # storage.admin（人）と legacy の 3 件だけが残ること
gcloud storage buckets set-iam-policy gs://tori-develop-tfstate /tmp/tfstate-iam.json $ACC

# 6-4. 旧 SA と旧 Pool（どちらも 30 日間 undelete できる）
for role in deployer preview planner; do gcloud iam service-accounts delete "$OLD-$role@tori-develop.iam.gserviceaccount.com" $P $ACC --quiet; done
gcloud iam workload-identity-pools delete tori-dev-blog-pool --location=global $P $ACC --quiet

# 6-5. 旧 state（控えてから消す）
mkdir -p ~/Backups/tfstate/tori-dev-blog-tori-develop
gcloud storage cp -r gs://tori-develop-tfstate/terraform/tori-dev-blog ~/Backups/tfstate/tori-dev-blog-tori-develop/ $ACC
gcloud storage rm -r gs://tori-develop-tfstate/terraform/tori-dev-blog/ $ACC
```

バケット `tori-develop-tfstate` は名刺サイトの旧 state（`terraform/state/`）が残っている。名刺の移行と後片付けが終わって空になったら消す:
`gcloud storage buckets delete gs://tori-develop-tfstate $ACC`。

## 7. 最終確認

```bash
git fetch origin && git switch --detach origin/main   # worktree では main を switch できないため
scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap plan -detailed-exitcode   # exit 0
mise exec -- terraform -chdir=terraform/app init -backend-config=backend.hcl -reconfigure
mise exec -- terraform -chdir=terraform/app plan -detailed-exitcode                                            # exit 0
curl -s https://tori-dev.com/ -o /dev/null -w '%{http_code}\n'                                                 # 200
```

PR を 1 つ作り、プレビュー（`tori-dev-sites-preview--pr-<番号>-….web.app`）が出ることも確かめる。
