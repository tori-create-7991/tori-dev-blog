# ブランチ別デプロイへの切替 runbook

`main` → 本番 `tori-dev.com` / `preview` → 検証 `preview.tori-dev.com` の構成へ移行する手順。

DNS とカスタムドメインの付け替えを伴うため、**順序を守ること**。各段階で検証コマンドを実行し、失敗したらその場でロールバックする。

## 移行前後の状態

| | 移行前 | 移行後 |
|---|---|---|
| `tori-dev.com` | default site `tori-develop`（旧 Nuxt2） | `tori-develop-blog`（新 Nuxt3, main） |
| `preview.tori-dev.com` | `tori-develop-blog`（新 Nuxt3） | `tori-develop-preview`（新 Nuxt3, preview, noindex） |
| 旧 Nuxt2 | `tori-dev.com` で配信 | `tori-develop.web.app` に残置（ドメイン紐付けのみ解除） |
| apex の DNS | 手動 A レコード `199.36.158.100` | Terraform 管理の CNAME（Cloudflare フラットニング） |

## 前提

- GitHub Environment `production` の required reviewers が設定済み（apply 前に人の承認が入る）
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

### 2. Cloudflare で apex の TTL を下げる（human・任意だが推奨）

apex を A → CNAME に変更する際、Terraform は「削除 → 作成」を行う。伝播待ちを短くするため、
事前に `tori-dev.com` の A レコードの TTL を 300 秒（5分）に下げ、**最低でも旧 TTL 分だけ待つ**。

> 現在の A レコードは Terraform 管理外。次の手順で Terraform が同名の CNAME を作ろうとすると
> **既存レコードと衝突してエラーになる可能性がある**。その場合は 3-b に進む。

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

### 3-b. apex レコードの衝突を解消する（human・必要時のみ）

手順 4 の apply で `cloudflare_record.firebase_hosting` の作成が
「record already exists」で失敗した場合、既存の手動 A レコードを Terraform に取り込むか、
削除してから apply し直す。

取り込む場合（レコード ID は Cloudflare ダッシュボードまたは API で確認）:

```bash
terraform -chdir=terraform import \
  'cloudflare_record.firebase_hosting[0]' "<zone_id>/<record_id>"
```

ただし A → CNAME はタイプ変更のため import しても差し替えになる。
**単純に既存 A レコードを削除してから apply する方が確実**（TTL を下げてあれば数分で収束）。

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

### 5. 旧 URL の 301 を入れる（別タスク）

旧 Nuxt2 の記事 URL は `/md/{slug}/`（旧 sitemap の `/post/*` は既に 404）。
`firebase.json` の `redirects` で `/md/*` `/post/*` → `/posts/*` を張る。
詳細は `.research_output/seo_aeo_layout_roadmap_20260822/notes_migration_measurement.md` の Q4。

これは本 runbook のスコープ外。**切替が安定してから**別 PR で入れる。

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
