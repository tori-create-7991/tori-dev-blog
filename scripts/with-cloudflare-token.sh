#!/usr/bin/env bash
# 有効期限 1 時間の Cloudflare API トークンを発行し、環境変数 CLOUDFLARE_API_TOKEN に入れて
# 後ろのコマンドを実行する。終わったら（失敗しても）トークンを削除する。
#
# 使い方:
#   scripts/with-cloudflare-token.sh -- terraform -chdir=terraform/bootstrap plan
#
# 発行用トークン（User API Tokens: Edit 権限を持つ長期トークン）は GCP の Secret Manager から読む。
#   CF_ISSUER_SECRET   secret 名            （既定 cloudflare-tori-dev-deploy-token）
#   CF_ISSUER_PROJECT  secret の GCP プロジェクト（既定 tori-dev-secrets）
#   CF_ISSUER_ACCOUNT  gcloud のアカウント    （任意。アクティブな設定と別のとき）
#   CF_ZONE_ID         対象ゾーン ID         （任意。無ければ terraform/bootstrap/terraform.tfvars から読む）
#   GCLOUD             gcloud の実行コマンド （任意。既定 gcloud）
#
# 発行するトークンの権限は、対象ゾーンの DNS Write（DNS:Edit）と Zone Read だけ。
# トークンの値は画面にもファイルにも出さない。curl にはヘッダを標準入力から渡し、
# コマンドライン引数（ps で見える）に載せない。
set -euo pipefail
set +x

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage 0
[[ "${1:-}" == "--" ]] && shift
[[ $# -gt 0 ]] || usage 2

CF_ISSUER_SECRET="${CF_ISSUER_SECRET:-cloudflare-tori-dev-deploy-token}"
CF_ISSUER_PROJECT="${CF_ISSUER_PROJECT:-tori-dev-secrets}"
CF_ISSUER_ACCOUNT="${CF_ISSUER_ACCOUNT:-}"
GCLOUD="${GCLOUD:-gcloud}"
API="https://api.cloudflare.com/client/v4"
TOKEN_PREFIX="tori-dev-blog-tf-"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

log() { printf '[with-cloudflare-token] %s\n' "$*" >&2; }
die() { log "エラー: $*"; exit 1; }

for cmd in curl jq "$GCLOUD"; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd が見つかりません"
done

# Cloudflare API を呼ぶ。$1=トークン、$2=メソッド、$3=パス、$4=本文（任意）。
# 応答の success が false なら失敗にする。
cf() {
  local token="$1" method="$2" path="$3" body="${4:-}" resp
  local args=(--silent --show-error --request "$method" --config -)
  [[ -n "$body" ]] && args+=(--header "Content-Type: application/json" --data "$body")
  resp="$(printf 'header = "Authorization: Bearer %s"\n' "$token" | curl "${args[@]}" "$API$path")" || return 1
  if [[ "$(jq -r '.success' <<<"$resp")" != "true" ]]; then
    log "Cloudflare API の失敗: $method $path: $(jq -c '[.errors[]?.message]' <<<"$resp")"
    return 1
  fi
  printf '%s' "$resp"
}

# 1. 発行用トークンを読む
gcloud_args=(secrets versions access latest --secret="$CF_ISSUER_SECRET" --project="$CF_ISSUER_PROJECT")
[[ -n "$CF_ISSUER_ACCOUNT" ]] && gcloud_args+=(--account="$CF_ISSUER_ACCOUNT")
ISSUER="$($GCLOUD "${gcloud_args[@]}" 2>/dev/null)" || die "発行用トークン $CF_ISSUER_PROJECT/$CF_ISSUER_SECRET を読めません"
[[ -n "$ISSUER" ]] || die "発行用トークンが空です"

# 2. 発行用トークンの権限を確認する（User API Tokens: Edit = "API Tokens Write"）
issuer_id="$(cf "$ISSUER" GET /user/tokens/verify | jq -r '.result.id')" || die "発行用トークンを確認できません"
if ! cf "$ISSUER" GET "/user/tokens/$issuer_id" \
  | jq -e '[.result.policies[]?.permission_groups[]?.name] | index("API Tokens Write")' >/dev/null; then
  die "発行用トークンに「User API Tokens: Edit」権限がありません"
fi

# 3. 前回の異常終了で残ったトークンを削除する
cf "$ISSUER" GET "/user/tokens?per_page=50" \
  | jq -r --arg p "$TOKEN_PREFIX" '.result[] | select(.name | startswith($p)) | .id' \
  | while read -r stale_id; do
      log "残っていたトークンを削除: $stale_id"
      cf "$ISSUER" DELETE "/user/tokens/$stale_id" >/dev/null || log "削除に失敗（続行）: $stale_id"
    done

# 4. ゾーン ID と権限グループ ID を調べる
if [[ -z "${CF_ZONE_ID:-}" ]]; then
  CF_ZONE_ID="$(sed -nE 's/^[[:space:]]*cloudflare_zone_id[[:space:]]*=[[:space:]]*"([0-9a-f]{32})".*/\1/p' \
    "$REPO_ROOT/terraform/bootstrap/terraform.tfvars" | head -1)"
fi
[[ "$CF_ZONE_ID" =~ ^[0-9a-f]{32}$ ]] || die "ゾーン ID が分かりません（CF_ZONE_ID か terraform.tfvars の cloudflare_zone_id）"

groups="$(cf "$ISSUER" GET /user/tokens/permission_groups)" || die "権限グループを取得できません"
dns_write="$(jq -r '.result[] | select(.name == "DNS Write") | .id' <<<"$groups" | head -1)"
zone_read="$(jq -r '.result[] | select(.name == "Zone Read") | .id' <<<"$groups" | head -1)"
[[ -n "$dns_write" && -n "$zone_read" ]] || die "権限グループ DNS Write / Zone Read が見つかりません"

# 5. 有効期限 1 時間のトークンを発行する
expires_on="$(date -u -v+1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+1 hour' '+%Y-%m-%dT%H:%M:%SZ')"
body="$(jq -nc \
  --arg name "${TOKEN_PREFIX}$(date -u '+%Y%m%dT%H%M%SZ')" \
  --arg zone "com.cloudflare.api.account.zone.$CF_ZONE_ID" \
  --arg dns "$dns_write" --arg zr "$zone_read" --arg exp "$expires_on" \
  '{name: $name, expires_on: $exp,
    policies: [{effect: "allow", resources: {($zone): "*"},
                permission_groups: [{id: $dns}, {id: $zr}]}]}')"
TEMP_ID=""
cleanup() {
  local rc=$?
  if [[ -n "${TEMP_ID:-}" ]]; then
    if cf "$ISSUER" DELETE "/user/tokens/$TEMP_ID" >/dev/null; then
      log "トークンを削除しました"
    else
      log "トークンの削除に失敗しました。次回の実行時に削除されます（有効期限は 1 時間）: $TEMP_ID"
    fi
  fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

created="$(cf "$ISSUER" POST /user/tokens "$body")" || die "トークンを発行できません"
TEMP_ID="$(jq -r '.result.id' <<<"$created")"
TEMP_TOKEN="$(jq -r '.result.value' <<<"$created")"
unset created


log "トークンを発行しました（期限 $expires_on）。コマンドを実行します: $1 ..."

# 6. コマンドを実行する。トークンは子プロセスの環境変数にだけ渡す。
CLOUDFLARE_API_TOKEN="$TEMP_TOKEN" "$@"
