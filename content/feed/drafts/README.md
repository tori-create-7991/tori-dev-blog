下書き置き場。ここに置いた `.md` はサイトに公開されない（`docs/adr/0004-content-draft-directory-convention.md` 参照）。
公開するときは `sourceUrl` を追記して親ディレクトリ（`content/feed/`）へ `git mv` する。

ファイル命名・画像アセットの置き場所は `docs/adr/0005-feed-draft-file-convention.md` 参照
（`<slug>-x.md` / `<slug>-bluesky.md` / `<slug>-instagram.md`、Instagram の画像は `public/feed/<slug>.png`）。
