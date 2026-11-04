# 0007. サイト専用の GCP プロジェクト tori-dev-sites へ移す

Status: Accepted（2026-11-04）。[0001](0001-reuse-gcp-project-new-hosting-site.md) を置き換える。

## Context

- ブログは [0001](0001-reuse-gcp-project-new-hosting-site.md) で既存プロジェクト `tori-develop` に同居させた。
- `tori-develop` には個人データ（ライフログ・家計の BigQuery データセット）がある。これらのデータセットは
  プロジェクトの閲覧者・編集者・オーナーに読み書きを許す既定の設定なので、プロジェクト単位のロールを持つ SA は個人データに届く。
  ブログの CI の planner SA は `roles/viewer` を持ち、このリポジトリのどの workflow からも使えた。
- 名刺サイト（01_self-digital-business-card）も同じプロジェクトにある。
- tfstate バケットは 1 つを複数リポジトリで共有し、このリポジトリの bootstrap がそのバケットを管理していた。

## Decision

1. ブログと名刺サイトを、サイトだけを置く新しいプロジェクト `tori-dev-sites` へ移す。2 つは同じプロジェクトに置く。
2. プロジェクト単位のもの（API と Firebase の有効化）は、このリポジトリの bootstrap だけが持つ。
   Firebase の有効化（`google_firebase_project`）は app から bootstrap へ移す（CI の SA には有効化の権限を渡さない）。
3. tfstate バケットは 1 リポジトリ 1 つ（`<project_id>-<repo_slug>-tfstate`）。各リポジトリの bootstrap が管理する。
4. planner SA は `roles/viewer` をやめ、`roles/firebase.viewer` だけにする。
5. 新しいバケットで state を新しく始める。GitHub の設定と Cloudflare のレコードは import で引き継ぐ。
6. 独自ドメインは、新サイトの準備ができてから所有権 TXT を切り替えて移す（手順は [move-to-tori-dev-sites.md](../runbook/move-to-tori-dev-sites.md)）。

## Consequences

**良い面:**
- サイトの CI の SA がどう使われても、個人データには届かない。
- バケットがリポジトリごとになり、他リポジトリの state を読めたり、他リポジトリの都合でバケットの設定が変わったりしない。
- プロジェクトの持ち主（API・Firebase）が 1 つに決まる。

**悪い面:**
- Hosting の権限はプロジェクト単位なので、ブログの CI は名刺サイトにも配信できる（逆も同じ）。どちらも同じ持ち主のサイトなので許容する。
- 名刺サイトはこのリポジトリの bootstrap が先に apply されていることを前提にする。
- 移行中、独自ドメインの証明書が新サイトで発行されるまで HTTPS が使えない時間がありうる。
- 旧サイトの ID（`tori-develop-blog` など）は削除後に再利用できない。
