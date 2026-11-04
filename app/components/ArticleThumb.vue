<template>
  <!-- 装飾。記事タイトルは直下の見出しが持つので、スクリーンリーダーには渡さない -->
  <div
    aria-hidden="true"
    class="article-thumb relative w-full overflow-hidden rounded"
    :style="styleVars"
  >
    <div class="thumb-glow absolute inset-0"></div>
    <div class="thumb-pattern absolute inset-0" :data-pattern="seed.pattern"></div>
    <p class="thumb-title">{{ title }}</p>
    <span class="thumb-rule"></span>
  </div>
</template>

<script setup>
import { useEyecatch } from '~/composables/useEyecatch'

const props = defineProps({
  title: { type: String, required: true },
  // 見た目のシード。タイトルを直しても色が変わらないよう path を使う
  path: { type: String, required: true },
})

const seed = computed(() => useEyecatch(props.path))

const styleVars = computed(() => ({
  '--eye-h': String(seed.value.hue),
  '--eye-s': `${seed.value.sat}%`,
  '--eye-l': `${seed.value.lig}%`,
  '--eye-a': `${seed.value.angle}deg`,
  // 日本語は文字数がほぼ表示幅なので、文字数でサイズを段階化する
  '--eye-size':
    props.title.length <= 14 ? '1.375rem' : props.title.length <= 24 ? '1.15rem' : '1rem',
}))
</script>

<style scoped>
.article-thumb {
  /* 1200:630（OG 画像）と同じ比にして、カードと SNS カードの印象を揃える */
  aspect-ratio: 40 / 21;
  background-color: #121212;
  /* #4d4d4d は #121212 上で 3:1 を満たす。#333 だと 1.48:1 で境界として見えない */
  border: 1px solid #4d4d4d;
}

.thumb-glow {
  background:
    radial-gradient(
      120% 100% at 82% 8%,
      hsl(var(--eye-h) var(--eye-s) var(--eye-l) / 0.26) 0%,
      transparent 62%
    ),
    linear-gradient(var(--eye-a), hsl(var(--eye-h) var(--eye-s) var(--eye-l) / 0.12) 0%, transparent 70%);
}

/* パターンはすべて CSS グラデーション。追加アセットなし */
.thumb-pattern {
  opacity: 0.14;
}
.thumb-pattern[data-pattern='0'] {
  background-image:
    repeating-linear-gradient(0deg, #a2a897 0 1px, transparent 1px 24px),
    repeating-linear-gradient(90deg, #a2a897 0 1px, transparent 1px 24px);
}
.thumb-pattern[data-pattern='1'] {
  background-image: radial-gradient(#a2a897 1px, transparent 1.5px);
  background-size: 18px 18px;
}
.thumb-pattern[data-pattern='2'] {
  background-image: repeating-linear-gradient(45deg, #a2a897 0 1px, transparent 1px 14px);
}
.thumb-pattern[data-pattern='3'] {
  background-image: repeating-radial-gradient(circle at 88% 12%, #a2a897 0 1px, transparent 1px 22px);
}

.thumb-title {
  position: absolute;
  inset: auto 1.15rem 2rem 1.15rem;
  font-family: var(--font-display), 'Open Sans', sans-serif;
  font-size: var(--eye-size);
  font-weight: 700;
  line-height: 1.5;
  /* #F4F4F1 on #121212 = 17:1 */
  color: #f4f4f1;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  /* Chrome は文節で改行。未対応ブラウザは通常の日本語折り返しに落ちる */
  word-break: auto-phrase;
}

.thumb-rule {
  position: absolute;
  left: 1.15rem;
  bottom: 1.15rem;
  width: 3.25rem;
  height: 3px;
  border-radius: 2px;
  background: hsl(var(--eye-h) var(--eye-s) var(--eye-l));
}
</style>
