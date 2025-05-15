#!/bin/bash

# GCP VM 설정 스크립트
# GCP VM의 디렉토리 구조를 설정하고 필요한 권한을 부여합니다.

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
  
  log "환경 설정 완료!"
}

# GCP VM 설정
setup_gcp() {
  log "GCP VM 설정 시작..."
  
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    # 필요한 패키지 설치
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk python3-pip
    
    # 디렉토리 구조 생성 및 권한 설정
    sudo mkdir -p /home/deploy/newsum/{be,ai}
    sudo chown -R $USER:$USER /home/deploy/newsum
    sudo chmod -R 775 /home/deploy/newsum
    
    # 로그 디렉토리 생성 및 권한 설정
    sudo mkdir -p /home/deploy/newsum/be/logs /home/deploy/newsum/ai/logs
    sudo chown -R $USER:$USER /home/deploy/newsum/be/logs /home/deploy/newsum/ai/logs
    sudo chmod -R 775 /home/deploy/newsum/be/logs /home/deploy/newsum/ai/logs
    
    # SSL 키 스토어 설정
    sudo mkdir -p /etc/ssl/private
    sudo chown root:root /etc/ssl/private
    sudo chmod 700 /etc/ssl/private
    
    # Python 가상환경 설정
    cd /home/deploy/newsum/ai
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    deactivate
EOF

  log "GCP VM 설정 완료!"
}

# 메인 실행 함수
main() {
  log "GCP VM 설정 시작..."
  
  # 환경 설정
  setup_env
  
  # GCP VM 설정
  setup_gcp
  
  log "GCP VM 설정 완료!"
}

# 스크립트 실행
main "$@"
