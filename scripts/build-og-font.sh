#!/usr/bin/env bash
# OG 画像レンダリング用の日本語フォント(サブセット)を作り直す。
#
# nuxt-og-image は Takumi レンダラに実フォントファイルを渡す必要がある。
# Noto Sans JP のフル可変 TTF は 9.6MB あり、そのままリポジトリに置けないので
# 「使用頻度上位3000漢字 + かな + 記号 + 実コンテンツに出る全文字」に絞る。
#
# 記事タイトルに珍しい漢字を使って豆腐(□)が出たら、このスクリプトを再実行する。
# 必要: python3, fonttools (pip install fonttools), curl
set -euo pipefail
cd "$(dirname "$0")/.."
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Noto Sans JP (Variable) を取得"
curl -sS -L --fail \
  "https://github.com/notofonts/noto-cjk/raw/main/Sans/Variable/TTF/Subset/NotoSansJP-VF.ttf" \
  -o "$WORK/NotoSansJP-VF.ttf"

echo "==> 漢字頻度表を取得"
curl -sS -L --fail \
  "https://raw.githubusercontent.com/scriptin/topokanji/master/data/kanji-frequency/wikipedia.json" \
  -o "$WORK/freq.json"

echo "==> 対象文字を収集"
WORK="$WORK" python3 - <<'PY'
import json, os, pathlib
work = os.environ["WORK"]
chars = {chr(c) for c in range(0x20, 0x7f)}
for a, b in [(0x3000, 0x30ff), (0xff01, 0xff60), (0xffe0, 0xffe6),
             (0x2010, 0x2027), (0x2030, 0x205e), (0x2190, 0x2193),
             (0x25a0, 0x25cf), (0x2605, 0x2606)]:
    chars |= {chr(c) for c in range(a, b + 1)}
freq = json.load(open(f"{work}/freq.json"))
kanji = [r[0] for r in freq if len(r[0]) == 1 and 0x4e00 <= ord(r[0]) <= 0x9fff]
chars |= set(kanji[:3000])
root = pathlib.Path(".")
for p in list(root.glob("content/**/*.md")) + [root / "siteConfig.ts"]:
    try: chars |= set(p.read_text(encoding="utf-8"))
    except Exception: pass
chars = {c for c in chars if ord(c) > 0x1f and ord(c) != 0x7f}
pathlib.Path(f"{work}/chars.txt").write_text("".join(sorted(chars)), encoding="utf-8")
print(f"    対象文字数: {len(chars)}")
PY

echo "==> wght 軸を 400-700 に制限"
WORK="$WORK" python3 - <<'PY'
import os
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
work = os.environ["WORK"]
f = TTFont(f"{work}/NotoSansJP-VF.ttf")
instancer.instantiateVariableFont(f, {"wght": (400, 700)}).save(f"{work}/limited.ttf")
PY

echo "==> サブセット化"
python3 -m fontTools.subset "$WORK/limited.ttf" \
  --text-file="$WORK/chars.txt" \
  --output-file=scripts/fonts/NotoSansJP-og.ttf \
  --layout-features='kern,palt,vert,vrt2' \
  --notdef-glyph --notdef-outline --recommended-glyphs \
  --drop-tables+=DSIG,LTSH,hdmx,VDMX,PCLT \
  --no-hinting

# このフォントは OG 画像のビルド時生成にだけ使う。
# public/ に置くと配信対象になってしまうため scripts/fonts/ に置く。
ls -lh scripts/fonts/NotoSansJP-og.ttf
echo "==> 完了"
