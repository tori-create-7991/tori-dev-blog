# 0005. feed コレクションの下書きファイル命名と画像アセットの置き場所

Status: Accepted

## Context

00_my_env の `text-sns-writer`（X + Bluesky の短文下書き）と `image-sns-writer`
（図解画像の下書き、投稿先は Instagram）を、`blog-post-writer` と同様に
`tori-dev-blog` の `content/feed/drafts/`（[0004](0004-content-draft-directory-convention.md)）
に書き込むようにしたい。`feed` コレクションのスキーマは1ファイル=1投稿・
`platform` は単一値（`x` | `bluesky` | `instagram`）という設計のため、
「X スレッド + Bluesky 単発」を1ファイルにまとめていた旧 life-os 形式のままでは
プラットフォームごとに分けて表示できない。また `content/` 配下は静的アセットとして
配信されないため、Instagram 用の画像をそのまま置いても `/feed` ページに表示できない。

## Decision

**ファイル命名**: `content/feed/drafts/<slug>-<platform>.md`（`platform` は
`x` / `bluesky` / `instagram`）。1プラットフォーム1ファイルとし、X スレッドは
本文に採番リストとしてそのまま入れる（スレッドをフィード上で分割表示はしない）。

**画像アセット（Instagram）**: 本文で表示する画像は `public/feed/<slug>.png` に置き、
本文から `![](/feed/<slug>.png)` で参照する。図解のソース（編集用の
`diagram.html`）を残す場合は `content/feed/drafts/<slug>-instagram.diagram.html`
のように `.md` 以外の拡張子で同じ `drafts/` 直下に置く（`feed/*.md` グロブに
マッチしないため自動的にコレクションから除外される）。

**公開**: 実際に投稿した後、`sourceUrl` を frontmatter に追記して
`content/feed/` へ `git mv` する。

## Consequences

**良い面:**
- `blog-post-writer` と同じ「drafts/ に置く → 見直す → git mv で公開」の
  流れを feed にもそのまま適用でき、運用が一貫する
- 画像もテキストも「1ファイル (+ 画像1枚)」の単純な構成に収まる

**悪い面:**
- Instagram 画像は `public/feed/<slug>.png` に置いた時点で直リンク経由なら
  ドラフト段階でも参照可能になる（サイト上のどこからもリンクされないので
  実害は小さい想定だが、`.md` が `drafts/` にある間は「未公開」ではなく
  「未リンク」でしかない点に注意）
- X スレッドを1ファイルの本文にまとめる方式なので、フィード上でスレッドの
  各投稿を個別カードとして見せたくなった場合は別途対応が要る
