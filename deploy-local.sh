#!/bin/bash

# 로컬 빌드 및 준비 스크립트
# 깃허브에서 코드를 가져와 로컬에서 빌드하고 GCP 배포를 위한 준비를 합니다.

# 오류 발생 시 스크립트 중단
set -e

# 로그 함수
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 환경 설정
setup_env() {
  log "환경 설정 중..."
  
  # 로컬 환경
  LOCAL_BASE_PATH="/Users/roklee/NewSum"
  LOCAL_FRONTEND_REPO_PATH="$LOCAL_BASE_PATH/17-newsum-fe"
  LOCAL_BACKEND_REPO_PATH="$LOCAL_BASE_PATH/17-newsum-be"
  LOCAL_AI_REPO_PATH="$LOCAL_BASE_PATH/17-newsum-ai"
  
  # Git 저장소 정보
  FRONTEND_REPO="https://github.com/roklee/17-newsum-fe.git"
  BACKEND_REPO="https://github.com/roklee/17-newsum-be.git"
  AI_REPO="https://github.com/roklee/17-newsum-ai.git"
  
  log "환경 설정 완료!"
}

# 코드 가져오기
clone_repos() {
  log "코드 가져오기 시작..."
  
  # 프론트엔드
  log "프론트엔드 코드 가져오기 중..."
  if [ -d "$LOCAL_FRONTEND_REPO_PATH" ]; then
    cd "$LOCAL_FRONTEND_REPO_PATH"
    git pull origin main
  else
    git clone "$FRONTEND_REPO" "$LOCAL_FRONTEND_REPO_PATH"
  fi
  
  # 백엔드
  log "백엔드 코드 가져오기 중..."
  if [ -d "$LOCAL_BACKEND_REPO_PATH" ]; then
    cd "$LOCAL_BACKEND_REPO_PATH"
    git pull origin main
  else
    git clone "$BACKEND_REPO" "$LOCAL_BACKEND_REPO_PATH"
  fi
  
  # AI
  log "AI 코드 가져오기 중..."
  if [ -d "$LOCAL_AI_REPO_PATH" ]; then
    cd "$LOCAL_AI_REPO_PATH"
    git pull origin main
  else
    git clone "$AI_REPO" "$LOCAL_AI_REPO_PATH"
  fi
  
  log "코드 가져오기 완료!"
}

# 프론트엔드 빌드
build_frontend() {
  log "프론트엔드 빌드 시작..."
  
  cd "$LOCAL_FRONTEND_REPO_PATH"
  npm install
  npm run build
  
  # 빌드 결과를 백엔드 static 디렉토리로 복사
  log "프론트엔드 빌드 결과물 복사 중..."
  mkdir -p "$LOCAL_BACKEND_REPO_PATH/src/main/resources/static"
  cp -r "$LOCAL_FRONTEND_REPO_PATH/dist"/* "$LOCAL_BACKEND_REPO_PATH/src/main/resources/static/"
  
  log "프론트엔드 빌드 완료!"
}

# 백엔드 빌드
build_backend() {
  log "백엔드 빌드 시작..."
  
  cd "$LOCAL_BACKEND_REPO_PATH"
  ./gradlew clean build -x test
  
  log "백엔드 빌드 완료!"
}

# 메인 실행 함수
main() {
  log "로컬 빌드 시작..."
  
  # 환경 설정
  setup_env
  
  # 코드 가져오기
  clone_repos
  
  # 프론트엔드 빌드
  build_frontend
  
  # 백엔드 빌드
  build_backend
  
  log "로컬 빌드 완료!"
}

# 스크립트 실행
main "$@"
