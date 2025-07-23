#!/usr/bin/env bash
# -----------------------------------------------------------
# pull-branch-into.sh ─ 모든 stayfor* 저장소에서
#                       origin/<source> → <target> fast‑forward 머지
#
# 사용법) ./pull-branch-into.sh <source-branch> <target-branch>
#         인자 생략 시 기본값: source=develop, target=main
#
#   1) target 브랜치를 checkout(없으면 생성 & track)
#   2) origin/<source> 를 fetch
#   3) fast‑forward 가능하면 merge (--ff-only)
#      불가능(충돌)하면 실패로 기록
#   4) push는 하지 않음 (로컬에만 반영)
# -----------------------------------------------------------
set -euo pipefail

SOURCE_BRANCH="${1:-develop}"
TARGET_BRANCH="${2:-main}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

UPDATED=()
SKIPPED=()
FAILED=()

echo "─── ${SOURCE_BRANCH} → '${TARGET_BRANCH}' fast‑forward 머지 시작 ───"

for repo in "${REPOS[@]}"; do
  path="$ROOT_DIR/$repo"

  if [[ ! -d "$path/.git" ]]; then
    echo "⚠️  스킵: $repo (git 저장소 아님)"
    continue
  fi

  echo "▶▶ $repo"
  git -C "$path" fetch origin "$SOURCE_BRANCH" "$TARGET_BRANCH" --prune || {
    echo "❌ fetch 실패"; FAILED+=("$repo"); echo; continue
  }

  # source 브랜치 존재?
  if ! git -C "$path" show-ref --quiet "refs/remotes/origin/${SOURCE_BRANCH}"; then
    echo "⚠️  origin/${SOURCE_BRANCH} 없음 (스킵)"
    SKIPPED+=("$repo"); echo; continue
  fi

  # target 브랜치 checkout (없으면 새로 만들기)
  if git -C "$path" show-ref --quiet "refs/heads/${TARGET_BRANCH}"; then
    git -C "$path" checkout "$TARGET_BRANCH"
  else
    git -C "$path" checkout -b "$TARGET_BRANCH" --track "origin/${TARGET_BRANCH}" || {
      echo "⚠️  '${TARGET_BRANCH}' 브랜치 생성 실패 (스킵)"
      FAILED+=("$repo"); echo; continue
    }
  fi

  # fast‑forward 머지
  if git -C "$path" merge --ff-only "origin/${SOURCE_BRANCH}"; then
    echo "✅ 업데이트 완료 (${SOURCE_BRANCH} → ${TARGET_BRANCH})"
    UPDATED+=("$repo")
  else
    echo "❌ fast‑forward 불가(충돌 또는 분기점 다름) → 수동 처리 필요"
    FAILED+=("$repo")
  fi
  echo
done

echo "─── 요약 ───"
[[ ${#UPDATED[@]} -gt 0 ]] && { echo "✅ 업데이트 완료:"; printf ' - %s\n' "${UPDATED[@]}"; }
[[ ${#SKIPPED[@]}  -gt 0 ]] && { echo "⏩ 스킵:";          printf ' - %s\n' "${SKIPPED[@]}"; }
[[ ${#FAILED[@]}   -gt 0 ]] && { echo "❌ 실패/충돌:";     printf ' - %s\n' "${FAILED[@]}"; exit 1; }
