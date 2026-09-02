/**
 * 記事のパスから決定論的にアイキャッチの見た目を決める。
 *
 * - シードは path（タイトルを直しても見た目が変わらないようにするため）
 * - 色相はサイトのアクセント（セージ #A2A897 ≒ hsl(81 9% 63%)）の周辺に閉じ込める。
 *   明度の下限を 61% に置くことで、#121212 上での文字・罫線のコントラストが
 *   常に 7:1 以上（WCAG AAA）になる。
 */

export interface EyecatchSeed {
  hue: number
  sat: number
  lig: number
  angle: number
  pattern: number
}

// FNV-1a。文字列から安定した 32bit ハッシュを得る
const hash = (input: string) => {
  let h = 0x811c9dc5
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i)
    h = Math.imul(h, 0x01000193) >>> 0
  }
  return h >>> 0
}

export const useEyecatch = (seed: string): EyecatchSeed => {
  const h = hash(seed || 'tori-dev')
  return {
    // 63〜99°: セージ(81°)を中心に ±18°。彩度・明度と合わせて AAA を保証する範囲
    hue: 63 + (h % 37),
    // 7〜15%: これ以上上げると落ち着いたトーンから外れる
    sat: 7 + ((h >> 8) % 9),
    // 61〜71%: 61% が #121212 上で 7:1 を満たす下限
    lig: 61 + ((h >> 16) % 11),
    // 光の差す向き
    angle: 120 + ((h >> 20) % 120),
    // 幾何パターン 4 種
    pattern: (h >> 28) % 4,
  }
}
