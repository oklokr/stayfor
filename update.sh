#!/usr/bin/env bash
# -----------------------------------------------------------
# update-all.sh  ─ stayfor* 각 저장소를 일괄 remote update + 필요시 pull
# -----------------------------------------------------------
set -euo pipefail

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

FAILED=()
UPDATED=()

echo "─── Git remote update & pull 시작 ───"

for repo in "${REPOS[@]}"; do
  path="$ROOT_DIR/$repo"
  if [[ -d "$path/.git" ]]; then
    echo "▶▶ $repo"
    
    if git -C "$path" remote update --prune; then
      # HEAD와 origin/main 차이 확인
      LOCAL=$(git -C "$path" rev-parse @)
      REMOTE=$(git -C "$path" rev-parse @{u})
      BASE=$(git -C "$path" merge-base @ @{u})

      if [[ "$LOCAL" == "$REMOTE" ]]; then
        echo "⏩ 최신 상태입니다"
      elif [[ "$LOCAL" == "$BASE" ]]; then
        echo "⬇️  변경사항 있음 → pulling..."
        if git -C "$path" pull --ff-only; then
          echo "✅ pull 완료: $repo"
          UPDATED+=("$repo")
        else
          echo "❌ pull 실패: $repo"
          FAILED+=("$repo")
        fi
      else
        echo "⚠️  local과 remote가 동기화되지 않음 (rebase 필요)"
        FAILED+=("$repo")
      fi

    else
      echo "❌ update 실패: $repo"
      FAILED+=("$repo")
    fi
    echo
  else
    echo "⚠️  스킵: $repo (git 저장소 아님)"
  fi
done

echo "─── 요약 ───"
if (( ${#FAILED[@]} )); then
  echo "❌ 실패한 저장소:"
  printf ' - %s\n' "${FAILED[@]}"
else
  echo "✅ 모든 저장소 업데이트 성공!"
fi

if (( ${#UPDATED[@]} )); then
  echo "📥 업데이트 받은 저장소:"
  printf ' - %s\n' "${UPDATED[@]}"
fi
