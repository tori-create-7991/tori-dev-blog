# ベースイメージとしてNode.js 20のAlpineバージョンを使用
FROM node:22-alpine AS base

# 依存関係のインストールステージ
FROM base AS deps
# Alpine Linuxでnpmパッケージの互換性を確保するために必要なパッケージをインストール
RUN apk add --no-cache libc6-compat
WORKDIR /app

# package.jsonと各種ロックファイルをコピー
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# ローカルプラグインをコピー
# COPY eslint-plugin-custom-rules ./eslint-plugin-custom-rules

# 存在するロックファイルに応じて適切なパッケージマネージャーを使用してインストール
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# ビルドステージ
FROM base AS builder
WORKDIR /app
# 必要なビルドツールをインストール
RUN apk add --no-cache python3 make g++ sqlite-dev
# 依存関係をdepsステージからコピー
COPY --from=deps /app/node_modules ./node_modules
# ソースコードをコピー
COPY . .

# 環境変数を設定
# ENV NODE_ENV=production

# better-sqlite3を再ビルド
RUN npm rebuild better-sqlite3

# アプリケーションのビルド
RUN npm run generate

# 本番環境用のステージ
FROM nginx:alpine AS runner
WORKDIR /usr/share/nginx/html

# 環境変数を設定
ENV NODE_ENV=production

# 静的ファイルをコピー
COPY --from=builder /app/.output/public/. .

# nginx設定ファイルをコピー
COPY nginx.conf /etc/nginx/conf.d/default.conf

# ポート8080を公開
EXPOSE 8080

# アプリケーションの起動コマンド
CMD ["nginx", "-g", "daemon off;"]
