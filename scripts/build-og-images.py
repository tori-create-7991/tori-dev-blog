#!/usr/bin/env python3
"""記事ごとの OG 画像(1200x630 PNG)をビルド前に生成する。

なぜ Python なのか:
    OG 画像は SNS 側がラスタ画像しか受け付けないため、CSS では代替できない。
    当初 nuxt-og-image + Takumi レンダラで組もうとしたが、
    日本語フォントをレンダラへ渡すには @nuxt/fonts 0.13+ が必要で、
    それを入れると @nuxt/ui 3.0.2 のビルドが壊れる（compiler-sfc の型解決エラー）。
    記事は十数本の規模なので、依存を増やさず Pillow で事前生成する。

色の決め方:
    composables/useEyecatch.ts と同じ FNV-1a ハッシュを記事パスに掛けて
    色相・パターンを決める。サイト内の CSS サムネイル(ArticleThumb.vue)と
    同じ見た目になる。

使い方:
    python3 scripts/build-og-images.py          # 変更があった記事だけ生成
    python3 scripts/build-og-images.py --force  # 全記事を再生成

必要: python3, Pillow (pip install Pillow)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import pathlib
import re
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover
    sys.exit("Pillow が必要です: pip install Pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
POSTS_DIR = ROOT / "content" / "posts"
OUT_DIR = ROOT / "public" / "og" / "posts"
STATE_FILE = ROOT / "public" / "og" / ".state.json"
FONT_PATH = ROOT / "scripts" / "fonts" / "NotoSansJP-og.ttf"

W, H = 1200, 630
BG = (18, 18, 18)  # #121212 サイト背景
ACCENT = (162, 168, 151)  # #A2A897
FG = (244, 244, 241)  # #F4F4F1 (17.00:1 on #121212)
MUTED = (160, 158, 151)


def fnv1a(text: str) -> int:
    """composables/useEyecatch.ts と同じハッシュ。色を一致させるため実装を揃える。"""
    h = 0x811C9DC5
    for ch in text:
        h ^= ord(ch) & 0xFFFFFFFF
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def seed_of(path: str) -> dict:
    h = fnv1a(path or "tori-dev")
    return {
        # 色相 63-99°, 彩度 7-15%, 明度 61-71%:
        # この範囲なら #121212 上で常に 7:1 以上（WCAG AAA）になる
        "hue": 63 + (h % 37),
        "sat": 7 + ((h >> 8) % 9),
        "lig": 61 + ((h >> 16) % 11),
        "angle": 120 + ((h >> 20) % 120),
        "pattern": (h >> 28) % 4,
    }


def hsl_to_rgb(hue: float, sat: float, lig: float) -> tuple[int, int, int]:
    s, l = sat / 100.0, lig / 100.0
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((hue / 60.0) % 2 - 1))
    m = l - c / 2
    r, g, b = {
        0: (c, x, 0.0), 1: (x, c, 0.0), 2: (0.0, c, x),
        3: (0.0, x, c), 4: (x, 0.0, c), 5: (c, 0.0, x),
    }[int(hue // 60) % 6]
    return tuple(int(round((v + m) * 255)) for v in (r, g, b))  # type: ignore[return-value]


def parse_frontmatter(md: str) -> dict:
    m = re.match(r"^---\n(.*?)\n---\n", md, re.S)
    if not m:
        return {}
    data: dict = {}
    key = None
    for line in m.group(1).splitlines():
        if re.match(r"^\s*-\s+", line) and key:
            data.setdefault(key, []).append(line.split("-", 1)[1].strip().strip("'\""))
            continue
        km = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if km:
            key, raw = km.group(1), km.group(2).strip()
            if raw:
                data[key] = raw.strip("'\"")
            else:
                data[key] = []
    return data


def load_font(size: int) -> ImageFont.FreeTypeFont:
    """サブセット済み Noto Sans JP を使う。無ければ OS のヒラギノにフォールバック。"""
    for candidate in (FONT_PATH, pathlib.Path("/System/Library/Fonts/Hiragino Sans GB.ttc")):
        if candidate.exists():
            try:
                return ImageFont.truetype(str(candidate), size, index=1 if candidate.suffix == ".ttc" else 0)
            except Exception:
                continue
    return ImageFont.load_default()


def gradient_layer(seed: dict) -> Image.Image:
    """低解像度で作って拡大し、帯(バンディング)の出ない滑らかなグラデーションにする。"""
    sw, sh = 120, 63
    small = Image.new("RGB", (sw, sh), BG)
    px = small.load()
    tint = hsl_to_rgb(seed["hue"], seed["sat"], seed["lig"])
    cx, cy, radius = 0.82, 0.08, 0.9
    for y in range(sh):
        for x in range(sw):
            nx, ny = x / sw, y / sh
            dist = math.hypot(nx - cx, (ny - cy) * 0.55) / radius
            a = 0.26 * max(0.0, 1.0 - dist) ** 2
            px[x, y] = tuple(int(BG[c] + (tint[c] - BG[c]) * a) for c in range(3))
    return small.resize((W, H), Image.BICUBIC)


def draw_pattern(img: Image.Image, seed: dict) -> None:
    """幾何パターン。ArticleThumb.vue の4種と対応させる。"""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    col = ACCENT + (34,)  # opacity ≒ 0.13
    p = seed["pattern"]
    if p == 1:
        for x in range(0, W, 36):
            d.line([(x, 0), (x, H)], fill=col, width=2)
        for y in range(0, H, 36):
            d.line([(0, y), (W, y)], fill=col, width=2)
    elif p == 2:
        for i in range(-H, W, 26):
            d.line([(i, 0), (i + H, H)], fill=col, width=2)
    elif p == 3:
        for i in range(0, W + H, 30):
            d.line([(i, 0), (i - H, H)], fill=col, width=2)
    else:
        for x in range(0, W, 40):
            d.line([(x, 0), (x, H)], fill=col, width=2)
        for y in range(0, H, 40):
            d.line([(0, y), (W, y)], fill=col, width=2)
    img.paste(Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB"), (0, 0))


def wrap_title(title: str, font: ImageFont.FreeTypeFont, max_width: int, max_lines: int) -> list[str]:
    """日本語は文字単位で折り返す（単語境界が無いため）。"""
    lines: list[str] = []
    cur = ""
    for ch in title:
        trial = cur + ch
        if font.getbbox(trial)[2] > max_width and cur:
            lines.append(cur)
            cur = ch
            if len(lines) == max_lines:
                break
        else:
            cur = trial
    if cur and len(lines) < max_lines:
        lines.append(cur)
    if len("".join(lines)) < len(title) and lines:
        lines[-1] = lines[-1][:-1] + "…"
    return lines


def render(title: str, category: str, date: str, path: str) -> Image.Image:
    seed = seed_of(path)
    img = gradient_layer(seed)
    draw_pattern(img, seed)
    d = ImageDraw.Draw(img)

    margin = 80
    # タイトルは文字数でサイズを段階化する（日本語は文字数≒表示幅）
    n = len(title)
    size = 72 if n <= 14 else 62 if n <= 24 else 50 if n <= 36 else 42
    title_font = load_font(size)
    lines = wrap_title(title, title_font, W - margin * 2, 3)

    d.text((margin, 74), category or "BLOG", font=load_font(26), fill=ACCENT)

    line_h = int(size * 1.45)
    block_h = line_h * len(lines)
    y = (H - block_h) // 2 - 10
    for line in lines:
        d.text((margin, y), line, font=title_font, fill=FG)
        y += line_h

    accent_rgb = hsl_to_rgb(seed["hue"], seed["sat"], seed["lig"])
    foot_y = H - 96
    d.rounded_rectangle([margin, foot_y + 14, margin + 64, foot_y + 18], radius=2, fill=accent_rgb)
    foot_font = load_font(24)
    x = margin + 92
    for part in [p for p in ["tori-dev.com", "利根川 諒", date] if p]:
        d.text((x, foot_y), part, font=foot_font, fill=ACCENT)
        x += foot_font.getbbox(part)[2] + 34
    return img


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="全記事を再生成する")
    args = ap.parse_args()

    if not POSTS_DIR.is_dir():
        sys.exit(f"記事ディレクトリが見つかりません: {POSTS_DIR}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    state = {}
    if STATE_FILE.exists() and not args.force:
        try:
            state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except Exception:
            state = {}

    new_state, generated, skipped = {}, 0, 0
    for md_path in sorted(POSTS_DIR.glob("*.md")):
        raw = md_path.read_text(encoding="utf-8")
        fm = parse_frontmatter(raw)
        title = fm.get("title") or md_path.stem
        if fm.get("image"):
            continue  # 記事が独自のアイキャッチを持つ場合は生成しない
        slug = md_path.stem.lower()
        route = f"/posts/{slug}"
        category = (fm.get("categories") or [""])[0] if isinstance(fm.get("categories"), list) else ""
        date = str(fm.get("date", ""))[:10]

        # タイトル・カテゴリ・日付・レンダラ設定が同じなら作り直さない
        sig = hashlib.sha1(f"{title}|{category}|{date}|{route}|v1".encode()).hexdigest()
        out = OUT_DIR / f"{slug}.png"
        new_state[slug] = sig
        if not args.force and out.exists() and state.get(slug) == sig:
            skipped += 1
            continue

        render(title, category, date, route).save(out, "PNG", optimize=True)
        generated += 1
        print(f"  generated {out.relative_to(ROOT)}  ({title[:28]})")

    STATE_FILE.write_text(json.dumps(new_state, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"OG images: {generated} generated, {skipped} unchanged -> {OUT_DIR.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
