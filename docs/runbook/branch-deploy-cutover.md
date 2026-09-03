# ブランチ別デプロイへの切替 runbook

`main` → 本番 `tori-dev.com` / `preview` → 検証 `preview.tori-dev.com` の構成へ移行する手順。

DNS とカスタムドメインの付け替えを伴うため、**順序を守ること**。各段階で検証コマンドを実行し、失敗したらその場でロールバックする。

## 移行前後の状態

| | 移行前 | 移行後 |
|---|---|---|
| `tori-dev.com` | default site `tori-develop`（旧 Nuxt2） | `tori-develop-blog`（新 Nuxt3, main） |
| `preview.tori-dev.com` | `tori-develop-blog`（新 Nuxt3） | `tori-develop-preview`（新 Nuxt3, preview, noindex） |
| 旧 Nuxt2 | `tori-dev.com` で配信 | `tori-develop.web.app` に残置（ドメイン紐付けのみ解除） |
| apex の A レコード | 手動 `199.36.158.100` | **変更しない**（`manage_apex_dns = false`） |
| apex の所有権 TXT | `hosting-site=<site_id>` | Terraform 管理（`cloudflare_record.firebase_hosting_ownership`）。旧サイト用の TXT は手動削除が要る |

## 前提

- 人のゲートは **PR のマージ**。Environment の required reviewers は使わない
  （`main` への push はレビュー済みの変更しか入らないため）
- `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ZONE_ID` が GitHub Secrets に登録済み
- Cloudflare の該当ゾーンで、apex レコードが **DNS-only（グレークラウド）** であること

## 手順

### 1. GitHub Variables を設定する（human）

**CI の Terraform Apply はブランチに関係なく同じ変数セットを渡す。**
そのため `CUSTOM_DOMAIN` を先に本番ドメインにすると、preview ブランチを push した時点で
apex の切替まで同時に走ってしまう。プレビュー検証を先に通すため、**この段階では設定しない**。

```bash
# CUSTOM_DOMAIN は未定義にする（CI 側で '' に解決され、apex は据え置き）
gh variable delete CUSTOM_DOMAIN

gh variable set PREVIEW_CUSTOM_DOMAIN --body "preview.tori-dev.com"
gh variable set PREVIEW_SITE_SUFFIX --body "preview"
gh variable set ENABLE_PREVIEW_SITE --body "true"
gh variable list
```

> `gh variable set --body ""` は "object is missing required key: value" で拒否される。
> 空にしたい場合は `gh variable delete` を使う。

本番ドメインは手順 4 の直前に設定する。

### 2. apex の A レコードは触らない。ただし所有権 TXT は必ず要る

`tori-dev.com` の A レコード `199.36.158.100` は **Firebase Hosting の共通 IP** で、
Firebase は IP ではなく `Host` ヘッダでサイトを振り分ける（実測: レスポンスに
`vary: x-fh-requested-host`）。したがって **A レコードは変更しなくてよい**。

A → CNAME への置き換えはタイプ変更のため destroy→create になり、一時的に名前解決が
落ちる。利点がないので `manage_apex_dns = false`（既定）のままにする。

**ただし A レコードを触らないことと「DNS を触らない」ことは違う。**
Firebase は apex をどのサイトが持つかを `hosting-site=<site_id>` の TXT レコードで
判定する。これを直さないとカスタムドメインは `OWNERSHIP_MISMATCH` のまま配信に
切り替わらない。さらに新旧2本が並ぶと `OWNERSHIP_CONFLICT` になる
（`CD_CONFLICTING_CLAIMS`: "There must be at most one TXT record with the
`hosting-site=` prefix on the domain."）。

- 追加する TXT は `cloudflare_record.firebase_hosting_ownership` として Terraform 管理下にある
- **旧サイト用の TXT（`hosting-site=tori-develop`）は Terraform 導入前の手動レコードで、
  record id が分からず import できない。Cloudflare API かダッシュボードで手動削除する**

```bash
# tori-dev-secrets(GCPプロジェクト) のトークンで、旧 TXT だけを内容一致で削除する
CF_TOKEN=$(gcloud secrets versions access latest --secret=cloudflare-tori-dev-dns-token \
  --project=tori-dev-secrets --account=ryo.tonegawa@tori-create.org)
CF_ZONE=$(curl -sS -H "Authorization: Bearer $CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones?name=tori-dev.com" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['result'][0]['id'])")
ID=$(curl -sS -H "Authorization: Bearer $CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records?type=TXT&name=tori-dev.com" \
  | python3 -c "import sys,json;[print(r['id']) for r in json.load(sys.stdin)['result'] \
      if r['content'].strip('\"')=='hosting-site=tori-develop']")
curl -sS -X DELETE -H "Authorization: Bearer $CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records/$ID"
```

#### 同一ドメインの付け替えについて

`preview.tori-dev.com` は現在 `tori-develop-blog`（`custom_domain` として）に紐付いている。
これを `tori-develop-preview`（`preview_custom_domain`）へ移す際、Firebase の
「1ドメイン = 1サイト」制約により、**先に旧側の紐付けを destroy しないと作成が失敗する**。

Terraform 側は `depends_on` で destroy → create の順序を固定してあるため、
通常は 1 回の apply で完了する。万一 `already in use` で失敗した場合は、
destroy だけは完了しているので **同じ apply をもう一度流せば通る**。

### 3-a. preview ブランチを作って先に検証環境を立てる（推奨）

本番を触る前に、プレビュー側だけで一連の流れを通す。

```bash
git switch -c preview
git push -u origin preview
```

CI が走り、承認後に:
- `tori-develop-preview` サイトが新規作成される
- `preview.tori-dev.com` が `tori-develop-blog` から **`tori-develop-preview` に付け替わる**
- プレビュー用ビルド（noindex）がデプロイされる

検証:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://preview.tori-dev.com/
curl -sS https://preview.tori-dev.com/robots.txt          # Disallow: / になっていること
curl -sS https://preview.tori-dev.com/ | grep -o 'name="robots"[^>]*'   # noindex, nofollow
dig +short preview.tori-dev.com                            # tori-develop-preview.web.app
```

> この時点で本番 `tori-dev.com` はまだ旧 Nuxt2 のまま。影響なし。

### 3-b. 旧サイトから apex の紐付けを外す（切替時に必須）

Firebase は「1ドメイン = 1サイト」の制約を持つ。`tori-dev.com` は現在
`tori-develop`（default site、旧 Nuxt2）に紐付いているため、
**新サイトに紐付ける前に旧側から外す**必要がある。

旧サイトは Terraform 管理外なので、API で外す:

```bash
TOKEN=$(gcloud auth print-access-token)
curl -X DELETE -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: tori-develop" \
  "https://firebasehosting.googleapis.com/v1beta1/projects/tori-develop/sites/tori-develop/customDomains/tori-dev.com"
```

外すと `tori-dev.com` は一時的に 404 になる。次の手順 4 の apply で新サイトに
紐付くまでの数分間が実質的なダウンタイム。

> **実測での注意（2026-09 の切替時に踏んだもの）**
>
> 1. **認証は ADC ではなくユーザー認証を使う。**
>    `gcloud auth application-default print-access-token` は別アカウント
>    （`good-digital`）を掴んでいて 403 になる。`gcloud auth print-access-token`
>    （オーナー権限の `ryo.tonegawa.7991@gmail.com`）を使う。
>    `gcloud config configurations list` でアクティブ設定がずれていないかも見る。
> 2. **curl には `-f` を付けない。** 付けると HTTP エラーの本文が消えて原因が追えない。
>    逆にスクリプト内では `-f` が無いと 401 でも終了コード 0 で素通りするため、
>    ステータスを明示的に検査する。
> 3. **削除は論理削除。** レスポンスに `deleteTime` と 30 日後の `expireTime` が入る。
>    その間は旧サイト側に残骸として見える（`?showDeleted=true`）が、配信はしない。
> 4. **Firebase の DNS 探索結果はキャッシュされる。** TXT を直しても
>    `requiredDnsUpdates.checkTime` が数十分〜1時間更新されず
>    `OWNERSHIP_CONFLICT` のままになることがある。
>    `PATCH .../customDomains/<domain>?updateMask=certPreference` で
>    同じ値を書き戻すと reconcile が走って解消する。
> 5. **切替後の 404 は Fastly のエッジキャッシュを疑う。**
>    オリジンが切り替わっていても `cache-control: max-age=3600` で旧サイトの
>    応答が最大1時間残る。`?cb=$RANDOM` を付けて `x-cache: MISS` で確認する。

### 4. main にマージして本番を切り替える（human 承認）

まず本番ドメインを設定する:

```bash
gh variable set CUSTOM_DOMAIN --body "tori-dev.com"
```

PR をマージすると CI が走る。承認後:
- `tori-dev.com` が `tori-develop-blog` に紐付く
- apex の DNS が Terraform 管理の CNAME になる
- 本番用ビルド（index する）がデプロイされる

検証:

```bash
dig +short tori-dev.com
curl -sS -o /dev/null -w '%{http_code}\n' https://tori-dev.com/
curl -sS https://tori-dev.com/ | grep -o '<title>[^<]*</title>'    # 新サイトのタイトル
curl -sS https://tori-dev.com/robots.txt | head -3                 # Allow: / と Sitemap 行
curl -sS https://tori-dev.com/ | grep -c 'name="robots"'           # 0（noindex が無い）
curl -sS https://tori-dev.com/sitemap.xml | head -5                # tori-dev.com の絶対URL
```

**SSL のプロビジョニングに最大 24 時間かかる場合がある**（実際は数時間以内が多い）。
証明書が発行されるまで https が失敗することがあるので、その間は焦って戻さない。

### 5. 旧 URL の 301（実装済み・切替と同時に有効化される）

`firebase.json` の `redirects` に実装済み。切替時に自動で効く。

| 旧 | 新 |
|---|---|
| `/md/{slug}` `/md/{slug}/` `/post/{slug}` | `/posts/{slug}` |
| `/md/` `/md` | `/posts` |
| `/md/category/{name}` `/microcms/category/{name}` | `/category/{name}` |
| `/md/tag/{name}` `/microcms/tag/{name}` | `/tag/{name}` |

大文字混在の 2 本（`gas-checkRakutenPayEmailsAndLogDaily` / `nuxtLifeCycleMemo`）は
Nuxt Content が URL を小文字化するため、明示ルールを先頭に置いている。

Firebase Hosting エミュレータで実測済み: 全ケース **1 ホップで 200 に着地**、
新 URL がリダイレクトに巻き込まれないことも確認（無限ループなし）。

切替後の確認:

```bash
for p in /md/nuxt-blog/ /post/nuxt-blog /md/ /md/tag/nuxt \
         /md/gas-checkRakutenPayEmailsAndLogDaily/ /md/nuxtLifeCycleMemo; do
  curl -sS -m 20 -L -o /dev/null -w "$p hops=%{num_redirects} final=%{http_code}\n" "https://tori-dev.com$p"
done
# 期待: すべて hops=1 final=200
```

### 6. Search Console に新 sitemap を送る（human）

- ドメインプロパティ `tori-dev.com` で `https://tori-dev.com/sitemap.xml` を送信
- `preview.tori-dev.com` は **登録しない**（noindex なので送っても意味がない）

## ロールバック

| 段階 | 戻し方 |
|---|---|
| 手順 3（preview） | `gh variable set PREVIEW_CUSTOM_DOMAIN --body ""` して再 apply。または Firebase Console で `preview.tori-dev.com` を `tori-develop-blog` に戻す |
| 手順 4（本番切替） | `gh variable set CUSTOM_DOMAIN --body ""` → apply で apex の紐付けを解除し、Cloudflare で A レコード `199.36.158.100` を手動で戻す。旧サイトは default site に残っているので、ドメインを default site に付け直せば復旧する |
| デプロイ内容だけ戻したい | Firebase Console のリリース履歴から前バージョンにロールバック（DNS は触らない） |

## 中止条件

- 手順 4 の検証で `tori-dev.com` が 200 を返さない状態が 30 分以上続く
- SSL プロビジョニングが 24 時間を超える
- 意図せず `tori-dev.com` に noindex が出ている（`NUXT_PUBLIC_SITE_ENV` の判定ミス）

いずれもロールバック手順で戻し、原因を潰してから再実行する。

## 注意

- **Cloudflare のプロキシ（オレンジクラウド）を有効にしない。** Firebase Hosting の証明書検証が壊れやすく、
  加えて Cloudflare の AI Crawl Control が検索・AI クローラを遮断する事故につながる。
- Terraform state は本番・プレビュー両方を 1 つの state で管理している。
  どちらのブランチから apply しても同じリソース群を対象にするため、
  CI は両ブランチとも Environment `production`（承認ゲートあり）を通す。
