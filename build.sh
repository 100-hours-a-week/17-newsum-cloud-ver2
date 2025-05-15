#!/bin/bash

# 로컬 빌드 자동화 스크립트
# 프론트엔드, 백엔드, AI 코드를 로컬에서 빌드합니다.

# 오류 발생 시 스크립트 중단
set -e

# 로그 함수
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Discord 알림 함수
send_discord_alert() {
  local message="$1"
  local status="$2"
  
  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    log "Discord Webhook URL이 설정되지 않았습니다."
    return
  fi
  
  local color
  if [ "$status" = "success" ]; then
    color="3066993"  # 초록색
  else
    color="15158332"  # 빨간색
  fi
  
  local payload=$(cat <<EOF
{
  "username": "Build Bot",
  "avatar_url": "https://raw.githubusercontent.com/vitejs/vite/HEAD/docs/public/logo.svg",
  "embeds": [
    {
      "title": "Build Status",
      "description": "$message",
      "color": $color,
      "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    }
  ]
}
EOF
)

  curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL"
}

# 설정 변수
# 로컬 환경
LOCAL_FRONTEND_REPO_PATH="/Users/roklee/NewSum/17-newsum-fe"
LOCAL_BACKEND_REPO_PATH="/Users/roklee/NewSum/17-newsum-be"
LOCAL_AI_REPO_PATH="/Users/roklee/NewSum/17-newsum-ai"
STATIC_DIR="$LOCAL_BACKEND_REPO_PATH/src/main/resources/static"


# Discord 알림 설정
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1372125501753135155/je6c4gGIF5WJg_HGmEKeh6hvRhT6v-FDzMcz3QgeSyaTnzcYQEfs0V8kWeEgqs8FD8zA"

# 1. 프론트엔드 빌드
build_frontend() {
  log "프론트엔드 빌드 시작..."
  cd "$LOCAL_FRONTEND_REPO_PATH"
  
  # git에서 최신 코드 가져오기
  git fetch origin dev
  git merge origin/dev --no-edit
  
  # 의존성 설치
  npm install
  
  # 빌드 (Vite 사용)
  npm run build
  
  # 빌드된 파일을 백엔드의 static 디렉토리로 복사
  mkdir -p "$STATIC_DIR"
  cp -r dist/* "$STATIC_DIR/"
  
  log "프론트엔드 빌드 및 static 디렉토리 복사 완료!"
}

# 2. 백엔드 빌드
build_backend() {
  log "백엔드 빌드 시작..."
  cd "$LOCAL_BACKEND_REPO_PATH"
  
  # git에서 최신 코드 가져오기
  git fetch origin dev
  git merge origin/dev --no-edit
  
  # Gradle을 사용한 빌드
  ./gradlew clean build -x test
  
  log "백엔드 빌드 완료!"
}

# 3. AI 코드 빌드
build_ai() {
  log "AI 코드 빌드 시작..."
  cd "$LOCAL_AI_REPO_PATH"
  
  # git에서 최신 코드 가져오기
  git fetch origin dev
  git merge origin/dev --no-edit
  
  # 가상환경 설정 및 패키지 설치
  if [ ! -d "venv" ]; then
    python3 -m venv venv
  fi
  source venv/bin/activate
  pip install -r requirements.txt
  
  # 가상 환경 생성 및 활성화
  if [ ! -d "venv" ]; then
    python3 -m venv venv
  fi
  source venv/bin/activate
  
  # 의존성 설치
  pip install -r requirements.txt
  
  log "AI 코드 빌드 완료!"
}

# 전체 빌드 함수
build_all() {
  log "전체 빌드 시작..."
  
  # 프론트엔드 빌드
  build_frontend
  
  # 백엔드 빌드
  build_backend
  
  # AI 빌드
  build_ai
  
  log "전체 빌드 완료!"
}

# 메인 실행 함수
main() {
  # 전체 빌드 실행
  if build_all; then
    send_discord_alert "Build completed successfully!" "success"
  else
    send_discord_alert "Build failed!" "error"
    exit 1
  fi
}

# 스크립트 진입점
main "$@"
