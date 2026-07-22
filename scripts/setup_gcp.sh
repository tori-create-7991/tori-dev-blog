#!/bin/bash
set -e

# ===================================================================
#   GCP Initial Setup Script (tori-dev-blog)
# ===================================================================
#
# 冪等性: 新規プロジェクトでも既存プロジェクトでも安全に実行可能
#   - 新規: すべてのリソースをゼロから作成
#   - 更新: 既存リソースをインポートしてから terraform apply
#
# 使い方:
#   ローカル:      bash scripts/setup_gcp.sh
#   Cloud Shell:  git clone <repo> && cd <repo> && bash scripts/setup_gcp.sh
#
# 環境変数で事前設定も可能:
#   export PROJECT_ID="my-project"
#   export GH_REPO="user/repo"
#   export CUSTOM_DOMAIN="blog.example.com"  # 省略可
#   export CLOUDFLARE_API_TOKEN="xxx"  # 省略時はGCP Secret Managerから自動取得
#   export CLOUDFLARE_ZONE_ID="xxx"    # 省略時はCloudflare API から自動導出
#   export SECRET_PROJECT="tori-dev-secrets"              # Cloudflareトークン保管先GCPプロジェクト
#   export CLOUDFLARE_DNS_TOKEN_SECRET="cloudflare-tori-dev-dns-token"  # secret名
#
# CUSTOM_DOMAIN設定時、CLOUDFLARE_API_TOKENは
#   gcloud secrets versions access latest \
#     --secret=cloudflare-tori-dev-dns-token --project=tori-dev-secrets
# で自動取得する（実行アカウントに secretmanager.secretAccessor 権限が必要）。
# ===================================================================

REGION="asia-northeast1"
POOL_NAME="github-pool"
PROVIDER_NAME="tori-dev-blog-provider"
SA_NAME="github-actions-tori-blog"

echo "==================================================="
echo "   GCP Initial Setup Script (tori-dev-blog)"
echo "==================================================="
echo ""
echo "冪等スクリプト: 新規作成でも更新でも安全に実行できます。"
echo ""

# -------------------------------------------------------------------
# 0. 前提条件チェック
# -------------------------------------------------------------------
echo "=== 前提条件チェック ==="
HAS_ERROR=false

if ! command -v gcloud &>/dev/null; then
  echo "  [ERROR] gcloud CLI が見つかりません"
  echo "    → https://cloud.google.com/sdk/docs/install"
  HAS_ERROR=true
else
  echo "  gcloud CLI ✓ ($(gcloud --version 2>&1 | head -1))"
fi

if ! command -v terraform &>/dev/null; then
  echo "  [ERROR] terraform が見つかりません"
  echo "    → https://developer.hashicorp.com/terraform/install"
  HAS_ERROR=true
else
  echo "  terraform ✓ ($(terraform --version 2>&1 | head -1))"
fi

if [ "$HAS_ERROR" = true ]; then
  echo ""
  echo "必要なツールをインストールしてから再実行してください。"
  exit 1
fi

# gcloud認証・アカウント選択
# 複数Googleアカウントを使い分ける場合の対応:
#   gcloud config configurations create tori-blog
#   gcloud config configurations activate tori-blog
#   gcloud auth login
#   → 以降 GCP_CONFIG=tori-blog bash scripts/setup_gcp.sh で切替不要
if [ -n "$GCP_CONFIG" ]; then
  echo "  gcloud configuration: $GCP_CONFIG を使用"
  gcloud config configurations activate "$GCP_CONFIG" 2>/dev/null || {
    echo "  [ERROR] configuration '$GCP_CONFIG' が見つかりません"
    echo "    作成方法: gcloud config configurations create $GCP_CONFIG && gcloud auth login"
    exit 1
  }
fi

GCLOUD_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -z "$GCLOUD_ACCOUNT" ]; then
  echo "  [WARN] gcloud未認証 → ブラウザでログインします..."
  gcloud auth login
  GCLOUD_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
fi
echo "  gcloud認証 ✓ ($GCLOUD_ACCOUNT)"

# 認証済みアカウント一覧を表示（別アカウントで実行したい場合のヒント）
OTHER_ACCOUNTS=$(gcloud auth list --format="value(account)" 2>/dev/null | grep -v "^${GCLOUD_ACCOUNT}$" || true)
if [ -n "$OTHER_ACCOUNTS" ]; then
  echo "  ヒント: 別アカウントで実行する場合:"
  echo "    gcloud config set account <email>"
  echo "    利用可能: $OTHER_ACCOUNTS"
fi

# Terraform 認証: gcloud のアクセストークンを使用
# ADC は gcloud configurations と独立しており、別アカウントの認証が残ることがある。
# 確実に現在のアクティブアカウントの認証を使うため、gcloud のトークンを直接渡す。
export GOOGLE_OAUTH_ACCESS_TOKEN
GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token 2>/dev/null)
if [ -z "$GOOGLE_OAUTH_ACCESS_TOKEN" ]; then
  echo "  [ERROR] アクセストークンの取得に失敗しました"
  echo "    gcloud auth login を実行してください"
  exit 1
fi
echo "  Terraform認証 ✓ (gcloudトークンを使用)"
echo ""

echo "実行ステップ:"
echo "  1. 必要なAPIを有効化"
echo "  2. WIF Pool（共有）を確保 + blog専用Providerを作成"
echo "  3. Service Accountを作成しIAMロール付与"
echo "  4. Terraform state用バケットを作成"
echo "  5. terraform init → import → apply"
echo "  6. GitHub Secrets用の値を出力"
echo ""

# -------------------------------------------------------------------
# 1. Input (環境変数があればスキップ)
# -------------------------------------------------------------------
if [ -z "$PROJECT_ID" ]; then
  read -rp "Google Cloud Project ID: " PROJECT_ID
fi

if [ -z "$GH_REPO" ]; then
  read -rp "GitHub Repository (owner/repo): " GH_REPO
fi

if [ -z "$CUSTOM_DOMAIN" ]; then
  read -rp "カスタムドメイン (空Enter=なし): " CUSTOM_DOMAIN || CUSTOM_DOMAIN=""
fi

# Cloudflare はカスタムドメイン使用時のみ必須
# CLOUDFLARE_API_TOKEN は GCP Secret Manager (project: $SECRET_PROJECT,
# secret: cloudflare-tori-dev-dns-token) から自動取得する。
# CLOUDFLARE_ZONE_ID はトークンで Cloudflare API を叩いて自動導出する
# （zone_id自体は非秘匿情報のためSecret化不要）。
SECRET_PROJECT="${SECRET_PROJECT:-tori-dev-secrets}"
CLOUDFLARE_DNS_TOKEN_SECRET="${CLOUDFLARE_DNS_TOKEN_SECRET:-cloudflare-tori-dev-dns-token}"

if [ -n "$CUSTOM_DOMAIN" ]; then
  if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "  Cloudflare API Token を GCP Secret Manager から取得中..."
    echo "    project: $SECRET_PROJECT / secret: $CLOUDFLARE_DNS_TOKEN_SECRET"
    if CLOUDFLARE_API_TOKEN=$(gcloud secrets versions access latest \
        --secret="$CLOUDFLARE_DNS_TOKEN_SECRET" \
        --project="$SECRET_PROJECT" 2>/dev/null) && [ -n "$CLOUDFLARE_API_TOKEN" ]; then
      echo "  Cloudflare API Token 取得 ✓"
    else
      echo "  [WARN] Secret Manager から取得できませんでした"
      echo "    （$SECRET_PROJECT への secretmanager.secretAccessor 権限、"
      echo "    または secret 名を確認してください）"
      read -rp "Cloudflare API Token (手動入力): " CLOUDFLARE_API_TOKEN
    fi
  fi

  if [ -z "$CLOUDFLARE_ZONE_ID" ] && [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    ZONE_APEX=$(echo "$CUSTOM_DOMAIN" | grep -oE '[^.]+\.[^.]+$')
    echo "  Cloudflare Zone ID を自動導出中... (zone: $ZONE_APEX)"
    ZONE_LOOKUP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${ZONE_APEX}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json")
    CLOUDFLARE_ZONE_ID=$(echo "$ZONE_LOOKUP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
      echo "  Cloudflare Zone ID 取得 ✓ ($CLOUDFLARE_ZONE_ID)"
    else
      echo "  [WARN] Zone ID の自動導出に失敗しました（トークンの権限 or ドメイン名を確認）"
      read -rp "Cloudflare Zone ID (手動入力): " CLOUDFLARE_ZONE_ID
    fi
  fi
else
  CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"
fi

# GitHub URLが渡された場合の正規化
GH_REPO=${GH_REPO#"https://github.com/"}
GH_REPO=${GH_REPO#"git@github.com:"}
GH_REPO=${GH_REPO%".git"}

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
BUCKET_NAME="${PROJECT_ID}-tfstate"

echo ""
echo "--- 設定内容 ---"
echo "  Project ID     : $PROJECT_ID"
echo "  GitHub Repo    : $GH_REPO"
echo "  SA Email       : $SA_EMAIL"
echo "  State Bucket   : $BUCKET_NAME"
echo "  Custom Domain  : ${CUSTOM_DOMAIN:-（なし）}"
echo "----------------"
echo ""

gcloud config set project "$PROJECT_ID"

# -------------------------------------------------------------------
# 2. Enable APIs (gcloud services enable は冪等)
# -------------------------------------------------------------------
echo "=== APIを有効化 ==="
APIS=(
  iam.googleapis.com
  iamcredentials.googleapis.com
  cloudresourcemanager.googleapis.com
  serviceusage.googleapis.com
  sts.googleapis.com
  firebase.googleapis.com
  firebasehosting.googleapis.com
  run.googleapis.com
  artifactregistry.googleapis.com
)
for api in "${APIS[@]}"; do
  echo "  有効化: $api"
  gcloud services enable "$api" --quiet
done
echo "APIの有効化完了"
echo ""

# -------------------------------------------------------------------
# 3. WIF Pool を確保（共有リソース: 他リポジトリと共用）
#    - 存在すればそのまま使用
#    - soft-delete状態なら undelete
#    - 存在しなければ作成
# -------------------------------------------------------------------
echo "=== WIF Pool ($POOL_NAME) を確保 ==="
POOL_EXISTS=false
if gcloud iam workload-identity-pools describe "$POOL_NAME" \
    --location=global --project="$PROJECT_ID" &>/dev/null; then
  POOL_EXISTS=true
  echo "  WIF Pool は既に存在します"
fi

if [ "$POOL_EXISTS" = false ]; then
  echo "  soft-delete状態からの復元を試行..."
  if gcloud iam workload-identity-pools undelete "$POOL_NAME" \
      --location=global --project="$PROJECT_ID" 2>/dev/null; then
    echo "  [復元] WIF Pool を undelete しました"
    POOL_EXISTS=true
  fi
fi

if [ "$POOL_EXISTS" = false ]; then
  echo "  WIF Pool を新規作成..."
  gcloud iam workload-identity-pools create "$POOL_NAME" \
    --location=global \
    --display-name="GitHub Actions Pool" \
    --project="$PROJECT_ID"
  echo "  [作成] WIF Pool を作成しました"
fi
echo ""

# -------------------------------------------------------------------
# 4. WIF Provider を確保（blog専用: tori-dev-blog-provider）
#    同様に 存在確認 → undelete → 新規作成
# -------------------------------------------------------------------
echo "=== WIF Provider ($PROVIDER_NAME) を確保 ==="
PROVIDER_EXISTS=false
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --workload-identity-pool="$POOL_NAME" \
    --location=global --project="$PROJECT_ID" &>/dev/null; then
  PROVIDER_EXISTS=true
  echo "  WIF Provider は既に存在します"
fi

if [ "$PROVIDER_EXISTS" = false ]; then
  echo "  soft-delete状態からの復元を試行..."
  if gcloud iam workload-identity-pools providers undelete "$PROVIDER_NAME" \
      --workload-identity-pool="$POOL_NAME" \
      --location=global --project="$PROJECT_ID" 2>/dev/null; then
    echo "  [復元] WIF Provider を undelete しました"
    PROVIDER_EXISTS=true
  fi
fi

if [ "$PROVIDER_EXISTS" = false ]; then
  echo "  WIF Provider を新規作成..."
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
    --workload-identity-pool="$POOL_NAME" \
    --location=global \
    --project="$PROJECT_ID" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
    --attribute-condition="assertion.repository == \"${GH_REPO}\""
  echo "  [作成] WIF Provider を作成しました"
fi
echo ""

# -------------------------------------------------------------------
# 5. Service Account を作成 + IAMロール付与
# -------------------------------------------------------------------
echo "=== Service Account ($SA_NAME) を確保 ==="
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
  echo "  Service Account は既に存在します"
else
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="GitHub Actions Blog Deploy" \
    --description="Service Account for tori-dev-blog GitHub Actions CI/CD" \
    --project="$PROJECT_ID"
  echo "  [作成] Service Account を作成しました"
fi

echo "  IAMロールを付与..."

# Terraform管理用ロール（SA自身が terraform apply を実行するために必要）
SA_ROLES=(
  "roles/firebase.admin"
  "roles/run.admin"
  "roles/artifactregistry.admin"
  "roles/iam.serviceAccountUser"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/storage.admin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/iam.workloadIdentityPoolAdmin"
  "roles/iam.serviceAccountAdmin"
)
for role in "${SA_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
  echo "    $role ✓"
done
echo ""

# -------------------------------------------------------------------
# 6. Terraform State Bucket
# -------------------------------------------------------------------
echo "=== Terraform State Bucket ($BUCKET_NAME) ==="
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
  echo "  バケットを新規作成..."
  gcloud storage buckets create "gs://$BUCKET_NAME" \
    --location="$REGION" \
    --uniform-bucket-level-access
  echo "  [作成] $BUCKET_NAME"
else
  echo "  バケットは既に存在します"
  gcloud storage buckets update "gs://$BUCKET_NAME" --uniform-bucket-level-access 2>/dev/null || true
  # UBLA有効化でACLが消える場合に備えてアクセス権を付与
  CURRENT_USER=$(gcloud config get-value account 2>/dev/null)
  if [ -n "$CURRENT_USER" ]; then
    gcloud storage buckets add-iam-policy-binding "gs://$BUCKET_NAME" \
      --member="user:$CURRENT_USER" --role="roles/storage.admin" --quiet >/dev/null 2>&1 || true
  fi
fi
echo ""

# -------------------------------------------------------------------
# 7. Terraform Init
# -------------------------------------------------------------------
echo "==================================================="
echo "   Terraform Init & Apply"
echo "==================================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT/terraform"

echo "=== terraform init ==="
# -reconfigure: バックエンド設定を毎回上書き（-migrate-stateは対話プロンプトが出る場合がある）
# -input=false: 非対話環境でのハング防止
terraform init -reconfigure -input=false -backend-config="bucket=${BUCKET_NAME}"
echo ""

# -------------------------------------------------------------------
# 8. Import pre-existing resources (冪等性の要)
# -------------------------------------------------------------------
echo "=== 既存リソースのインポート ==="

TF_VARS=(
  -var="project_id=${PROJECT_ID}"
  -var="github_repo=${GH_REPO}"
)

# オプション変数（指定時のみ追加）
if [ -n "$CUSTOM_DOMAIN" ]; then
  TF_VARS+=(-var="custom_domain=${CUSTOM_DOMAIN}")
fi
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  TF_VARS+=(-var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}")
fi
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  TF_VARS+=(-var="cloudflare_zone_id=${CLOUDFLARE_ZONE_ID}")
fi

import_if_missing() {
  local addr="$1" id="$2"
  if terraform state list 2>/dev/null | grep -qF "$addr"; then
    echo "  [skip] $addr (state内に存在)"
    return
  fi
  echo "  [import] $addr"
  local output
  if output=$(terraform import "${TF_VARS[@]}" "$addr" "$id" 2>&1); then
    echo "  [imported] $addr ✓"
  else
    echo "  [skip] $addr — 未存在 or インポート不可（apply で作成予定）"
    echo "$output" | tail -3 | sed 's/^/    /'
  fi
}

# --- WIF Pool はスクリプトの gcloud で確保済み（terraform管理外） ---

# --- WIF Provider ---
import_if_missing \
  "google_iam_workload_identity_pool_provider.github" \
  "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

# --- Service Account ---
import_if_missing \
  "google_service_account.github_actions" \
  "projects/${PROJECT_ID}/serviceAccounts/${SA_EMAIL}"

# --- Firebase Project ---
import_if_missing \
  "google_firebase_project.default" \
  "projects/${PROJECT_ID}"

# --- Firebase Hosting Site ---
import_if_missing \
  "google_firebase_hosting_site.blog" \
  "projects/${PROJECT_ID}/sites/${PROJECT_ID}-blog"

# --- Firebase Hosting Custom Domain (設定時のみ) ---
if [ -n "$CUSTOM_DOMAIN" ]; then
  import_if_missing \
    'google_firebase_hosting_custom_domain.blog[0]' \
    "projects/${PROJECT_ID}/sites/${PROJECT_ID}-blog/customDomains/${CUSTOM_DOMAIN}"
fi

# --- Google Project Services ---
import_if_missing \
  "google_project_service.firebase" \
  "${PROJECT_ID}/firebase.googleapis.com"

import_if_missing \
  "google_project_service.firebasehosting" \
  "${PROJECT_ID}/firebasehosting.googleapis.com"

import_if_missing \
  "google_project_service.iam" \
  "${PROJECT_ID}/iam.googleapis.com"

import_if_missing \
  "google_project_service.iamcredentials" \
  "${PROJECT_ID}/iamcredentials.googleapis.com"

import_if_missing \
  "google_project_service.cloudresourcemanager" \
  "${PROJECT_ID}/cloudresourcemanager.googleapis.com"

import_if_missing \
  "google_project_service.sts" \
  "${PROJECT_ID}/sts.googleapis.com"

import_if_missing \
  "google_project_service.run" \
  "${PROJECT_ID}/run.googleapis.com"

import_if_missing \
  "google_project_service.artifactregistry" \
  "${PROJECT_ID}/artifactregistry.googleapis.com"

# --- Artifact Registry Repository ---
import_if_missing \
  "google_artifact_registry_repository.app" \
  "projects/${PROJECT_ID}/locations/${REGION}/repositories/tori-dev-blog-images"

echo ""
echo "インポートフェーズ完了"
echo ""

# -------------------------------------------------------------------
# 9. Terraform Apply
# -------------------------------------------------------------------
echo "=== terraform apply ==="
terraform apply -auto-approve -input=false "${TF_VARS[@]}"

# -------------------------------------------------------------------
# 10. WIF → SA impersonation の安全ネット (gcloud は冪等)
# -------------------------------------------------------------------
WIF_POOL_FULL=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
  --location=global --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || true)
if [ -n "$WIF_POOL_FULL" ]; then
  echo ""
  echo "WIF impersonation binding を確認..."
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WIF_POOL_FULL}/attribute.repository/${GH_REPO}" \
    --condition=None \
    --quiet >/dev/null
  echo "  WIF → SA binding ✓"
fi

# -------------------------------------------------------------------
# 11. Output
# -------------------------------------------------------------------
WIF_PROVIDER_FULL=$(terraform output -raw wif_provider 2>/dev/null || echo "(terraform output 取得失敗)")
SA_EMAIL_OUTPUT=$(terraform output -raw sa_email 2>/dev/null || echo "$SA_EMAIL")

cd "$REPO_ROOT"

# -------------------------------------------------------------------
# 12. GitHub Secrets 登録 (gh CLI があれば自動、無ければ手動手順を表示)
# -------------------------------------------------------------------
echo ""
echo "==================================================="
echo "   セットアップ完了!"
echo "==================================================="
echo ""

declare -A GH_SECRETS=(
  [GCP_PROJECT_ID]="$PROJECT_ID"
  [GCP_TF_STATE_BUCKET]="$BUCKET_NAME"
  [WIF_PROVIDER]="$WIF_PROVIDER_FULL"
  [GCP_SA_EMAIL]="$SA_EMAIL_OUTPUT"
)
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  GH_SECRETS[CLOUDFLARE_API_TOKEN]="$CLOUDFLARE_API_TOKEN"
fi
if [ -n "$CLOUDFLARE_ZONE_ID" ]; then
  GH_SECRETS[CLOUDFLARE_ZONE_ID]="$CLOUDFLARE_ZONE_ID"
fi

if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "gh CLI 検出 → GitHub Secrets を自動登録..."
  for key in "${!GH_SECRETS[@]}"; do
    if gh secret set "$key" --repo "$GH_REPO" --body "${GH_SECRETS[$key]}" &>/dev/null; then
      echo "  [set] $key ✓"
    else
      echo "  [ERROR] $key の登録に失敗しました（--repo $GH_REPO への admin 権限を確認）"
    fi
  done
  echo ""
  echo "Cloudflare 用 Secret は、カスタムドメインを使う場合のみ手動で追加してください:"
  echo "  gh secret set CLOUDFLARE_API_TOKEN --repo $GH_REPO --body \"<token>\""
  echo "  gh secret set CLOUDFLARE_ZONE_ID --repo $GH_REPO --body \"<zone_id>\""
else
  echo "[WARN] gh CLI 未検出 or 未認証 → 手動で GitHub Repository Secrets に設定してください:"
  echo ""
  for key in "${!GH_SECRETS[@]}"; do
    echo "  $key : ${GH_SECRETS[$key]}"
  done
  echo ""
  echo "gh CLI を使う場合の一括登録コマンド例:"
  for key in "${!GH_SECRETS[@]}"; do
    echo "  gh secret set $key --repo $GH_REPO --body \"${GH_SECRETS[$key]}\""
  done
fi

echo ""
echo "以降は GitHub Actions (push to main) で"
echo "terraform apply が自動実行されます。"
echo ""
