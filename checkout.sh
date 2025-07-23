#!/usr/bin/env bash
# -----------------------------------------------------------
# checkout-all.sh ─ stayfor* 각 저장소를 지정한 브랜치로 일괄 전환
#   사용법) ./checkout-all.sh <브랜치명>
#           인자를 생략하면 기본값은 main
# -----------------------------------------------------------
set -euo pipefail

# 전환할 브랜치 (기본값: main)
TARGET_BRANCH="${1:-main}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ▶ 필요하면 목록에 저장소 추가/제거
REPOS=(
  stayfor_api_gateway
  stayfor_bnb_service
  stayfor_config
  stayfor_config_server
  stayfor_eureka_server
  stayfor_front_service
  stayfor_message_service
  stayfor_user_service
)

SUCCESS=()
FAILED=()

echo "─── 모든 저장소를 '${TARGET_BRANCH}' 브랜치로 전환 ───"

for repo in "${REPOS[@]}"; do
  path="$ROOT_DIR/$repo"
  if [[ -d "$path/.git" ]]; then
    echo "▶▶ $repo"

    # 원격 정보 최신화
    git -C "$path" fetch --all --prune

    # 로컬 또는 원격에 브랜치가 존재하는지 확인
    if git -C "$path" show-ref --quiet "refs/heads/${TARGET_BRANCH}" \
       || git -C "$path" show-ref --quiet "refs/remotes/origin/${TARGET_BRANCH}"; then

      if git -C "$path" checkout "$TARGET_BRANCH"; then
        # checkout 성공 → fast‑forward pull 시도(있어도 되고 없어도 됨)
        git -C "$path" pull --ff-only || true
        echo "✅ 완료"
        SUCCESS+=("$repo")
      else
        echo "❌ checkout 실패"
        FAILED+=("$repo")
      fi
    else
      echo "⚠️  '${TARGET_BRANCH}' 브랜치가 없음 (스킵)"
      FAILED+=("$repo")
    fi
    echo
  else
    echo "⚠️  스킵: $repo (git 저장소 아님)"
  fi
done

echo "─── 요약 ───"
[[ ${#SUCCESS[@]} -gt 0 ]] && { echo "✅ 전환 성공:"; printf ' - %s\n' "${SUCCESS[@]}"; }
[[ ${#FAILED[@]}   -gt 0 ]] && { echo "❌ 실패/스킵:";  printf ' - %s\n' "${FAILED[@]}"; exit 1; }

