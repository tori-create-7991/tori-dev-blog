下書き置き場。ここに置いた `.md` は git 管理外（`.gitignore`）で、サイトにも公開されない（`docs/adr/0004-content-draft-directory-convention.md` 参照）。
このリポジトリは公開なので、下書きを commit・push しない。

公開するときは `sourceUrl` を追記し、親ディレクトリ（`content/feed/`）へ `mv` してから `git add` する。

ファイル命名・画像アセットの置き場所は `docs/adr/0005-feed-draft-file-convention.md` 参照
（`<slug>-x.md` / `<slug>-bluesky.md` / `<slug>-instagram.md`、Instagram の画像は `public/feed/<slug>.png`）。
