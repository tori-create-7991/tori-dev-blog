下書き置き場。ここに置いた `.md` は git 管理外（`.gitignore`）で、サイトにも公開されない（`docs/adr/0004-content-draft-directory-convention.md` 参照）。
このリポジトリは公開なので、下書きを commit・push しない。
git 管理外なのでバックアップが無い。primary checkout で `git clean -x` を実行しない。

公開するときは親ディレクトリ（`content/posts/`）へ `mv` してから `git add` する。
