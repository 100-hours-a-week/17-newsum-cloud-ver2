#!/bin/bash

# 로컬 빌드 자동화 스크립트
# 프론트엔드, 백엔드, AI 코드를 로컬에서 빌드합니다.

# 오류 발생 시 스크립트 중단
set -e

# 설정 변수
# vm 환경
VM_NewSum_PATH="/home/guswp1128/newsum"
VM_FRONTEND_REPO_PATH="$VM_NewSum_PATH/17-newsum-fe"
VM_BACKEND_REPO_PATH="$VM_NewSum_PATH/17-newsum-be"
VM_AI_REPO_PATH="$VM_NewSum_PATH/17-newsum-ai"
STATIC_DIR="$VM_BACKEND_REPO_PATH/src/main/resources/static"

# git 저장소 URL
GIT_REPO_URL_FE="https://github.com/100-hours-a-week/17-newsum-fe.git"
GIT_REPO_URL_BE="https://github.com/100-hours-a-week/17-newsum-be.git"
GIT_REPO_URL_AI="https://github.com/100-hours-a-week/17-newsum-ai.git"

# Discord 알림 설정
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1371857343523983390/a3-Kh3fEgVv83q64xCrCFYDklcBHJZ7kqK_NK9EBeHAXyI6zJjk3oON59N2wWJwbFJ9R"

# 로그 함수
log() {
  local message="$1"
  local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "$timestamp - $message"
  echo "$timestamp - $message" >> "$VM_BACKEND_REPO_PATH/build.log"
}

# Discord 알림 함수
send_discord_alert() {
  local title="$1"
  local description="$2"
  local color="$3"
  
  local payload=$(cat <<EOF
{
  "username": "VM Deploy Bot",
  "avatar_url": "https://raw.githubusercontent.com/vitejs/vite/HEAD/docs/public/logo.svg",
  "embeds": [
    {
      "title": "$title",
      "description": "$description",
      "color": $color,
      "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    }
  ]
}
EOF
)

  curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL"
}

# 시스템 리소스 모니터링 함수
monitor_resources() {
  local title="$1"
  
  # CPU 사용량
  local cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
  
  # 메모리 사용량
  local mem=$(free | grep Mem | awk '{print $3/$2 * 100.0 "%"}')
  
  # 디스크 사용량
  local disk=$(df -h / | awk 'NR==2 {print $5}')
  
  log "$title 리소스 사용량:"
  log "CPU: $cpu"
  log "메모리: $mem"
  log "디스크: $disk"
  
  # Discord 알림
  local payload=$(cat <<EOF
{
  "username": "VM Resource Monitor",
  "avatar_url": "https://raw.githubusercontent.com/vitejs/vite/HEAD/docs/public/logo.svg",
  "embeds": [
    {
      "title": "$title 리소스 사용량",
      "fields": [
        {"name": "CPU", "value": "$cpu", "inline": true},
        {"name": "메모리", "value": "$mem", "inline": true},
        {"name": "디스크", "value": "$disk", "inline": true}
      ],
      "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    }
  ]
}
EOF
)
  
  curl -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL"
}

# 1. 프론트엔드 빌드
build_fe() {
  log "프론트엔드 빌드 시작..."
  
  # 빌드 전 리소스 사용량 확인
  monitor_resources "프론트엔드 빌드 전"

  # 프론트엔드 코드 가져오기
  cd "$VM_NewSum_PATH"
  
  # 디렉토리가 이미 존재하면 pull만, 없으면 clone
  if [ -d "17-newsum-fe/.git" ]; then
    cd "17-newsum-fe"
    log "프론트엔드 저장소 업데이트 중..."
    git pull origin dev
    
    # 변경사항이 없으면 빌드 건너뛰기
    if [ "$?" -eq 0 ]; then
      log "프론트엔드 저장소에 변경사항이 없습니다. 빌드를 건너뜁니다."
      return 0
    fi
  else
    log "프론트엔드 저장소 클론 중..."
    git clone "$GIT_REPO_URL_FE"
  fi
  
  # 프론트엔드 디렉토리로 이동
  cd "$VM_NewSum_PATH/17-newsum-fe"

  # 의존성 설치
  log "프론트엔드 의존성 설치 중..."
  npm install
  
  # 빌드 (Vite 사용)
  log "프론트엔드 빌드 중..."
  npm run build
  
  # 빌드된 파일을 백엔드의 static 디렉토리로 복사
  log "프론트엔드 빌드 파일 복사 중..."
  mkdir -p "$STATIC_DIR"
  cp -r "$VM_FRONTEND_REPO_PATH/dist"/* "$STATIC_DIR/"
  
  # 빌드 후 리소스 사용량 확인
  monitor_resources "프론트엔드 빌드 후"
  
  log "프론트엔드 빌드 완료!"
}

# 2. 백엔드 빌드
build_be() {
  log "백엔드 빌드 시작..."
  
  # 빌드 전 리소스 사용량 확인
  monitor_resources "백엔드 빌드 전"

  # 백엔드 코드 가져오기
  cd "$VM_NewSum_PATH"
  
  # 디렉토리가 이미 존재하면 pull만, 없으면 clone
  if [ -d "17-newsum-be/.git" ]; then
    cd "17-newsum-be"
    log "백엔드 저장소 업데이트 중..."
    git pull origin dev
    
    # 변경사항이 없으면 빌드 건너뛰기
    if [ "$?" -eq 0 ]; then
      log "백엔드 저장소에 변경사항이 없습니다. 빌드를 건너뜁니다."
      return 0
    fi
  else
    log "백엔드 저장소 클론 중..."
    git clone "$GIT_REPO_URL_BE"
  fi
  
  # 백엔드 디렉토리로 이동
  cd "$VM_NewSum_PATH/17-newsum-be"

  # 빌드
  ./gradlew clean build -x test
  
  # 빌드 후 리소스 사용량 확인
  monitor_resources "백엔드 빌드 후"
  
  log "백엔드 빌드 완료!"
}

# 3. AI 코드 빌드
build_ai() {
  log "AI 코드 빌드 시작..."
  
  # 빌드 전 리소스 사용량 확인
  monitor_resources "AI 빌드 전"

  # AI 코드 가져오기
  cd "$VM_NewSum_PATH"
  
  # 디렉토리가 이미 존재하면 pull만, 없으면 clone
  if [ -d "17-newsum-ai/.git" ]; then
    cd "17-newsum-ai"
    log "AI 저장소 업데이트 중..."
    git pull origin dev
    
    # 변경사항이 없으면 빌드 건너뛰기
    if [ "$?" -eq 0 ]; then
      log "AI 저장소에 변경사항이 없습니다. 빌드를 건너뜁니다."
      return 0
    fi
  else
    log "AI 저장소 클론 중..."
    git clone "$GIT_REPO_URL_AI"
  fi
  
  # AI 디렉토리로 이동
  cd "$VM_NewSum_PATH/17-newsum-ai"

  # 가상 환경 생성 및 활성화
  if [ ! -d "$VM_AI_REPO_PATH/venv" ]; then
    sudo apt update
    sudo apt install python3-venv -y
    log "AI 가상 환경 생성 중..."
    python3 -m venv venv
    source venv/bin/activate
    log "AI 가상 환경 생성 완료"
  fi
  
  pip install --upgrade pip
  
  # requirements.txt 확인
  if [ ! -f "$VM_NewSum_PATH/17-newsum-ai/requirements.txt" ]; then
    log "오류: requirements.txt 파일이 없습니다."
    send_discord_alert "AI 빌드 실패" "requirements.txt 파일이 없습니다." 15158332
    exit 1
  fi
  
  # 의존성 설치
  log "AI 의존성 설치 중..."
  pip install -r "$VM_NewSum_PATH/17-newsum-ai/requirements.txt"
  
  # 빌드 후 리소스 사용량 확인
  monitor_resources "AI 빌드 후"
  
  log "AI 코드 빌드 완료!"
}

# 각 서비스 빌드 체크 함수
check_fe_build() {
  log "프론트엔드 빌드 상태 확인 중..."
  
  # 프론트엔드 디렉토리가 존재하는지 확인
  if [ ! -d "$VM_FRONTEND_REPO_PATH" ]; then
    log "프론트엔드 빌드 상태: 미빌드"
    return 1
  fi
  
  # 빌드된 파일이 있는지 확인
  if [ ! -d "$VM_FRONTEND_REPO_PATH/dist" ]; then
    log "프론트엔드 빌드 상태: 실패"
    return 1
  fi
  
  # 빌드된 파일이 정상적인지 확인
  if [ ! -f "$VM_FRONTEND_REPO_PATH/dist/index.html" ]; then
    log "프론트엔드 빌드 상태: 실패"
    return 1
  fi
  
  log "프론트엔드 빌드 상태: 성공"
  return 0
}

check_be_build() {
  log "백엔드 빌드 상태 확인 중..."
  
  # 백엔드 디렉토리가 존재하는지 확인
  if [ ! -d "$VM_BACKEND_REPO_PATH" ]; then
    log "백엔드 빌드 상태: 미빌드"
    return 1
  fi
  
  # 빌드된 파일이 있는지 확인
  if [ ! -f "$VM_BACKEND_REPO_PATH/build/libs/*.jar" ]; then
    log "백엔드 빌드 상태: 실패"
    return 1
  fi
  
  log "백엔드 빌드 상태: 성공"
  return 0
}

check_ai_build() {
  log "AI 빌드 상태 확인 중..."
  
  # AI 디렉토리가 존재하는지 확인
  if [ ! -d "$VM_AI_REPO_PATH" ]; then
    log "AI 빌드 상태: 미빌드"
    return 1
  fi
  
  # 가상 환경이 있는지 확인
  if [ ! -d "$VM_AI_REPO_PATH/venv" ]; then
    log "AI 빌드 상태: 실패"
    return 1
  fi
  
  # 의존성 설치가 완료되었는지 확인
  if [ ! -f "$VM_AI_REPO_PATH/requirements.txt" ]; then
    log "AI 빌드 상태: 실패"
    return 1
  fi
  
  log "AI 빌드 상태: 성공"
  return 0
}

check_all_build() {
  log "전체 빌드 상태 확인 중..."
  
  if ! check_fe_build; then
    send_discord_alert "빌드 상태 확인" "프론트엔드 빌드가 실패했습니다." 15158332
    return 1
  fi
  
  if ! check_be_build; then
    send_discord_alert "빌드 상태 확인" "백엔드 빌드가 실패했습니다." 15158332
    return 1
  fi
  
  if ! check_ai_build; then
    send_discord_alert "빌드 상태 확인" "AI 빌드가 실패했습니다." 15158332
    return 1
  fi
  
  send_discord_alert "빌드 상태 확인" "모든 서비스 빌드가 성공했습니다." 3066993
  return 0
}

# 전체 빌드 함수
build_all() {
  log "전체 빌드 시작..."
  
  # 빌드 전 전체 리소스 사용량 확인
  monitor_resources "전체 빌드 전"
  
  # 프론트엔드 빌드
  if ! build_fe; then
    send_discord_alert "빌드 실패" "프론트엔드 빌드 실패" 15158332
    exit 1
  fi
  
  # 백엔드 빌드
  if ! build_be; then
    send_discord_alert "빌드 실패" "백엔드 빌드 실패" 15158332
    exit 1
  fi
  
  # AI 빌드
  if ! build_ai; then
    send_discord_alert "빌드 실패" "AI 빌드 실패" 15158332
    exit 1
  fi
  
  # 빌드 후 전체 리소스 사용량 확인
  monitor_resources "전체 빌드 후"
  
  log "전체 빌드 완료!"
  send_discord_alert "빌드 성공" "모든 서비스 빌드가 성공적으로 완료되었습니다." 3066993
}

# 메인 실행 함수
main() {
  # 인자가 없으면 전체 빌드
  if [ $# -eq 0 ]; then
    if build_all; then
      send_discord_alert "빌드 성공" "모든 서비스 빌드가 성공적으로 완료되었습니다." 3066993
    else
      send_discord_alert "빌드 실패" "빌드 과정에서 오류가 발생했습니다." 15158332
      exit 1
    fi
    return
  fi

  # 각 인자에 대해 빌드 실행
  for arg in "$@"; do
    case "$arg" in
      "fe")
        if build_fe; then
          send_discord_alert "프론트엔드 빌드 성공" "프론트엔드 빌드가 성공적으로 완료되었습니다." 3066993
        else
          send_discord_alert "프론트엔드 빌드 실패" "프론트엔드 빌드 실패" 15158332
          exit 1
        fi
        ;;
      "be")
        if build_be; then
          send_discord_alert "백엔드 빌드 성공" "백엔드 빌드가 성공적으로 완료되었습니다." 3066993
        else
          send_discord_alert "백엔드 빌드 실패" "백엔드 빌드 실패" 15158332
          exit 1
        fi
        ;;
      "ai")
        if build_ai; then
          send_discord_alert "AI 빌드 성공" "AI 빌드가 성공적으로 완료되었습니다." 3066993
        else
          send_discord_alert "AI 빌드 실패" "AI 빌드 실패" 15158332
          exit 1
        fi
        ;;
      "all")
        if build_all; then
          send_discord_alert "빌드 성공" "모든 서비스 빌드가 성공적으로 완료되었습니다." 3066993
        else
          send_discord_alert "빌드 실패" "빌드 과정에서 오류가 발생했습니다." 15158332
          exit 1
        fi
        ;;
      "check")
        if check_all_build; then
          log "모든 서비스 빌드 상태가 정상입니다."
        else
          log "빌드 상태에 문제가 있습니다."
          exit 1
        fi
        ;;
      *)
        echo "사용 방법:"
        echo "  $0 [fe|be|ai|all|check]"
        echo "  fe: 프론트엔드만 빌드"
        echo "  be: 백엔드만 빌드"
        echo "  ai: AI 코드만 빌드"
        echo "  all: 모든 서비스 빌드 (기본)"
        echo "  check: 빌드 상태 확인"
        exit 1
        ;;
    esac
  done
}

# 스크립트 진입점
main "$@"
