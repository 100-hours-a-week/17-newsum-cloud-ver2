#!/bin/bash

# SSL 키 스토어를 GCP VM으로 복사하는 스크립트

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
  
  # SSL 설정
  SSL_KEY_STORE_LOCAL="/Users/roklee/NewSum/17-newsum-cl/dev.new-sum.p12"
  SSL_KEY_STORE_REMOTE="/etc/ssl/private/dev.new-sum.p12"
  
  log "환경 설정 완료!"
}

# SSL 키 스토어 복사
copy_ssl() {
  log "SSL 키 스토어 복사 시작..."
  
  # SSL 키 스토어 파일이 존재하는지 확인
  if [ ! -f "$SSL_KEY_STORE_LOCAL" ]; then
    log "Error: SSL 키 스토어 파일이 존재하지 않습니다: $SSL_KEY_STORE_LOCAL"
    exit 1
  fi
  
  # SSL 키 스토어를 GCP VM으로 복사
  log "SSL 키 스토어 파일 전송 중..."
  scp "$SSL_KEY_STORE_LOCAL" "$GCP_VM_USER@$GCP_VM_IP:$SSL_KEY_STORE_REMOTE"
  
  # 권한 설정
  log "SSL 키 스토어 권한 설정 중..."
  ssh -i "~/.ssh/id_rsa" "$GCP_VM_USER@$GCP_VM_IP" << 'EOF'
    sudo chown root:root "$SSL_KEY_STORE_REMOTE"
    sudo chmod 600 "$SSL_KEY_STORE_REMOTE"
EOF

  log "SSL 키 스토어 복사 완료!"
}

# 메인 실행 함수
main() {
  log "SSL 키 스토어 복사 시작..."
  
  # 환경 설정
  setup_env
  
  # SSL 키 스토어 복사
  copy_ssl
  
  log "SSL 키 스토어 복사 완료!"
}

# 스크립트 실행
main "$@"
