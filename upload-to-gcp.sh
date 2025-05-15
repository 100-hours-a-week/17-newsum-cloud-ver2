#!/bin/bash

# GCP 배포 스크립트
# 로컬에서 빌드된 파일들을 GCP VM에 배포합니다.

# 오류 발생 시 스크립트 중단
set -e

# 로그 함수
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 환경 설정
setup_env() {
  log "환경 설정 중..."
  
  # GCP 환경
  GCP_VM_USER="${GCP_VM_USER:-rok}"
  GCP_VM_IP="${GCP_VM_IP:-34.22.76.15}"
  GCP_BASE_PATH="/home/deploy/newsum"
  GCP_BACKEND_PATH="$GCP_BASE_PATH/be"
  GCP_AI_PATH="$GCP_BASE_PATH/ai"
  
  # SSL 설정
  SSL_KEY_STORE="/etc/ssl/private/dev.new-sum.p12"
  SSL_KEY_STORE_PASSWORD="${SSL_KEY_STORE_PASSWORD:-your_secure_password}"
  
  # 로컬 환경
  LOCAL_BASE_PATH="/Users/roklee/NewSum"
  LOCAL_BACKEND_REPO_PATH="$LOCAL_BASE_PATH/17-newsum-be"
  LOCAL_AI_REPO_PATH="$LOCAL_BASE_PATH/17-newsum-ai"
  
  log "환경 설정 완료!"
}

# 파일 전송
upload_files() {
  log "파일 전송 시작..."
  
  # 백엔드 JAR 파일 전송
  log "백엔드 JAR 파일 전송 중..."
  scp "$LOCAL_BACKEND_REPO_PATH/build/libs/newsum-0.0.1-SNAPSHOT.jar" "$GCP_VM_USER@$GCP_VM_IP:$GCP_BACKEND_PATH/newsum.jar"
  
  # AI 소스코드 전송
  log "AI 소스코드 전송 중..."
  scp -r "$LOCAL_AI_REPO_PATH/app" "$LOCAL_AI_REPO_PATH/main.py" "$LOCAL_AI_REPO_PATH/requirements.txt" "$GCP_VM_USER@$GCP_VM_IP:$GCP_AI_PATH"
  
  log "파일 전송 완료!"
}

# 서비스 실행
start_services() {
  log "서비스 실행 중..."
  
  # 기존 프로세스 정리
  log "기존 프로세스 정리 중..."
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    sudo pkill -f "java -jar newsum.jar"
    sudo pkill -f "python3 main.py"
EOF

  # 백엔드 서비스 시작
  log "백엔드 서비스 시작 중..."
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    cd $GCP_BACKEND_PATH
    # logs 디렉토리 생성 및 권한 설정
    sudo mkdir -p logs
    sudo chmod 775 logs
    
    # 로그 파일 생성
    sudo sh -c 'echo "Starting backend service..." > logs/app.log'
    
    # 서비스 시작
    sudo -E sh -c 'nohup java -jar newsum.jar --server.port=8080 >> logs/app.log 2>&1 &' &
    
    # 서비스 상태 확인
    sleep 2
    echo "Backend service status:"
    ps aux | grep -i "java -jar newsum.jar"
EOF

  # AI 서비스 시작
  log "AI 서비스 시작 중..."
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    cd $GCP_AI_PATH
    # logs 디렉토리 생성 및 권한 설정
    sudo mkdir -p logs
    sudo chmod 775 logs
    
    # 로그 파일 생성
    sudo sh -c 'echo "Starting AI service..." > logs/app.log'
    
    # 서비스 시작
    sudo -E sh -c 'source venv/bin/activate && nohup python3 main.py >> logs/app.log 2>&1 &' &
    
    # 서비스 상태 확인
    sleep 2
    echo "AI service status:"
    ps aux | grep -i "python3 main.py"
EOF

  # 서비스 상태 확인 (최종 확인)
  log "서비스 상태 확인 중..."
  sleep 5  # 서비스가 시작될 시간 기다림
  
  # 백엔드 상태 확인
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    echo "Checking backend service status..."
    ps aux | grep -i "java -jar newsum.jar"
    
    echo "Checking backend logs..."
    tail -n 20 $GCP_BACKEND_PATH/logs/app.log
EOF

  # AI 상태 확인
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    echo "Checking AI service status..."
    ps aux | grep -i "python3 main.py"
    
    echo "Checking AI logs..."
    tail -n 20 $GCP_AI_PATH/logs/app.log
EOF

  log "서비스 상태 확인 완료!"
}

# 메인 실행 함수
main() {
  log "GCP 배포 시작..."
  
  # 환경 설정
  setup_env
  
  # 명령행 인자에 따라 다른 작업 수행
  if [ "$1" = "start_services" ]; then
    start_services
    exit 0
  fi
  
  # 파일 전송
  upload_files
  
  # 서비스 실행
  start_services
  
  log "GCP 배포 완료!"
}

# 스크립트 실행
if [ "$1" = "start_services" ]; then
  setup_env
  start_services
else
  main "$@"
fi
