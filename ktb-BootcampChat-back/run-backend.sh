#!/bin/bash

# 백엔드 설정
BACKEND_DIR="./backend"
LOG_DIR="./logs"
PM2_BACKEND_NAME="backend-server"

# 명령어 인자 확인
if [ $# -eq 0 ]; then
  echo "사용법: ./run-backend.sh {start|stop|restart|status} [mode]"
  echo "mode 옵션: dev (기본값) | prod"
  exit 1
fi

# 실행 모드 설정 (기본값: dev)
MODE=${2:-dev}

# 로그 디렉토리 생성
mkdir -p $LOG_DIR

# 백엔드 시작 함수
start_backend() {
  if ! pm2 list | grep -q "$PM2_BACKEND_NAME"; then
    echo "백엔드 서버를 시작합니다... (모드: $MODE)"
    cd "$BACKEND_DIR"
    NODE_ENV=$MODE pm2 start server.js --name "$PM2_BACKEND_NAME" \
      --log "$LOG_DIR/backend.log" \
      --error "$LOG_DIR/backend-error.log"
    cd ..
    echo "백엔드 서버가 시작되었습니다."
  else
    echo "백엔드 서버가 이미 실행 중입니다."
  fi
}

# 백엔드 중지 함수
stop_backend() {
  if pm2 list | grep -q "$PM2_BACKEND_NAME"; then
    echo "백엔드 서버를 중지합니다..."
    pm2 stop "$PM2_BACKEND_NAME"
    pm2 delete "$PM2_BACKEND_NAME"
    echo "백엔드 서버가 중지되었습니다."
  else
    echo "백엔드 서버가 실행 중이지 않습니다."
  fi
}

# 백엔드 재시작 함수
restart_backend() {
  if pm2 list | grep -q "$PM2_BACKEND_NAME"; then
    echo "백엔드 서버를 재시작합니다... (모드: $MODE)"
    cd "$BACKEND_DIR"
    NODE_ENV=$MODE pm2 restart "$PM2_BACKEND_NAME"
    cd ..
    echo "백엔드 서버가 재시작되었습니다."
  else
    echo "백엔드 서버가 실행 중이지 않습니다. 서버를 시작합니다..."
    start_backend
  fi
}

# 백엔드 상태 확인 함수
status_backend() {
  echo "백엔드 서버 상태를 확인합니다..."
  pm2 list | grep "$PM2_BACKEND_NAME" && echo "백엔드 서버가 실행 중입니다." || echo "백엔드 서버가 실행 중이지 않습니다."
  echo "\n포트 사용 현황:"
  echo "Backend (5000):" $(lsof -i:5000 | grep LISTEN || echo "미사용")
}

# 명령어 처리
case "$1" in
  start)
    start_backend
    ;;
  stop)
    stop_backend
    ;;
  restart)
    restart_backend
    ;;
  status)
    status_backend
    ;;
  *)
    echo "사용법: ./run-backend.sh {start|stop|restart|status} [mode]"
    echo "mode 옵션: dev (기본값) | prod"
    exit 1
    ;;
esac
