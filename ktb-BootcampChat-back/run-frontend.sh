#!/bin/bash

# 프론트엔드 설정
FRONTEND_DIR="./frontend"
LOG_DIR="./logs"
PM2_FRONTEND_NAME="frontend-server"

# 명령어 인자 확인
if [ $# -eq 0 ]; then
  echo "사용법: ./run-frontend.sh {start|stop|restart|status} [mode]"
  echo "mode 옵션: dev (기본값) | prod"
  exit 1
fi

# 실행 모드 설정 (기본값: dev)
MODE=${2:-dev}

# 로그 디렉토리 생성
mkdir -p $LOG_DIR

# 프론트엔드 시작 함수
start_frontend() {
  if ! pm2 list | grep -q "$PM2_FRONTEND_NAME"; then
    echo "프론트엔드 서버를 시작합니다... (모드: $MODE)"
    cd "$FRONTEND_DIR"
    if [ "$MODE" = "prod" ]; then
      echo "프론트엔드 프로덕션 빌드를 시작합니다..."
      npm run build
      pm2 start npm --name "$PM2_FRONTEND_NAME" \
        --log "$LOG_DIR/frontend.log" \
        --error "$LOG_DIR/frontend-error.log" \
        -- start
    else
      pm2 start npm --name "$PM2_FRONTEND_NAME" \
        --log "$LOG_DIR/frontend.log" \
        --error "$LOG_DIR/frontend-error.log" \
        -- run dev -- -p 3000
    fi
    cd ..
    echo "프론트엔드 서버가 시작되었습니다."
  else
    echo "프론트엔드 서버가 이미 실행 중입니다."
  fi
}

# 프론트엔드 중지 함수
stop_frontend() {
  if pm2 list | grep -q "$PM2_FRONTEND_NAME"; then
    echo "프론트엔드 서버를 중지합니다..."
    pm2 stop "$PM2_FRONTEND_NAME"
    pm2 delete "$PM2_FRONTEND_NAME"
    echo "프론트엔드 서버가 중지되었습니다."
  else
    echo "프론트엔드 서버가 실행 중이지 않습니다."
  fi
}

# 프론트엔드 재시작 함수
restart_frontend() {
  if pm2 list | grep -q "$PM2_FRONTEND_NAME"; then
    echo "프론트엔드 서버를 재시작합니다... (모드: $MODE)"
    cd "$FRONTEND_DIR"
    if [ "$MODE" = "prod" ]; then
      echo "프론트엔드 프로덕션 빌드를 다시 시작합니다..."
      npm run build
    fi
    pm2 restart "$PM2_FRONTEND_NAME"
    cd ..
    echo "프론트엔드 서버가 재시작되었습니다."
  else
    echo "프론트엔드 서버가 실행 중이지 않습니다. 서버를 시작합니다..."
    start_frontend
  fi
}

# 프론트엔드 상태 확인 함수
status_frontend() {
  echo "프론트엔드 서버 상태를 확인합니다..."
  pm2 list | grep "$PM2_FRONTEND_NAME" && echo "프론트엔드 서버가 실행 중입니다." || echo "프론트엔드 서버가 실행 중이지 않습니다."
  echo "\n포트 사용 현황:"
  echo "Frontend (3000):" $(lsof -i:3000 | grep LISTEN || echo "미사용")
}

# 명령어 처리
case "$1" in
  start)
    start_frontend
    ;;
  stop)
    stop_frontend
    ;;
  restart)
    restart_frontend
    ;;
  status)
    status_frontend
    ;;
  *)
    echo "사용법: ./run-frontend.sh {start|stop|restart|status} [mode]"
    echo "mode 옵션: dev (기본값) | prod"
    exit 1
    ;;
esac
