#!/bin/bash

# 로그 파일 경로
LOG_DIR="./logs"
# 데이터 디렉토리 경로
DATA_DIR="$HOME/data/db"

# PM2 프로세스 이름 설정
PM2_MONGODB_NAME="mongo-server"
PM2_REDIS_NAME="redis-server"

# 명령어 인자 확인
if [ $# -eq 0 ]; then
  echo "사용법: ./run-db.sh {start|stop|restart|status}"
  exit 1
fi

# 시스템 상태 체크 함수
check_system_status() {
  echo "시스템 상태를 확인합니다..."
  
  # MongoDB 포트 (27017) 확인
  if lsof -i:27017 >/dev/null 2>&1; then
    echo "경고: MongoDB 포트(27017)가 이미 사용 중입니다."
  fi
  
  # Redis 포트 (6379) 확인
  if lsof -i:6379 >/dev/null 2>&1; then
    echo "경고: Redis 포트(6379)가 이미 사용 중입니다."
  fi
  
  # 디스크 공간 확인
  DISK_SPACE=$(df -h "$DATA_DIR" | awk 'NR==2 {print $4}')
  echo "사용 가능한 디스크 공간: $DISK_SPACE"
}

# 서비스 시작 함수
start_services() {
  echo "MongoDB 및 Redis 서비스를 시작합니다..."
  
  check_system_status

  # 데이터 디렉토리 확인 및 생성
  if [ ! -d "$DATA_DIR" ]; then
    echo "데이터 디렉토리가 존재하지 않습니다. 생성합니다: $DATA_DIR"
    mkdir -p "$DATA_DIR"
    chmod 755 "$DATA_DIR"
  fi

  # 로그 디렉토리 생성
  mkdir -p $LOG_DIR

  # MongoDB 시작
  if ! pm2 list | grep -q "$PM2_MONGODB_NAME"; then
    echo "MongoDB를 시작합니다..."
    pm2 start mongod --name "$PM2_MONGODB_NAME" -- \
      --dbpath "$DATA_DIR" \
      --bind_ip 0.0.0.0 \
      --logpath "$LOG_DIR/mongodb.log" \
      --logappend
  else
    echo "MongoDB가 이미 실행 중입니다."
  fi

  # Redis 시작
  if ! pm2 list | grep -q "$PM2_REDIS_NAME"; then
    echo "Redis를 시작합니다..."
    pm2 start redis-server --name "$PM2_REDIS_NAME" -- \
      --bind 0.0.0.0 \
      --loglevel notice \
      --dir "$LOG_DIR" \
      --daemonize no
  else
    echo "Redis가 이미 실행 중입니다."
  fi

  echo "MongoDB 및 Redis가 시작되었습니다."
}

# 서비스 중지 함수
stop_services() {
  echo "MongoDB 및 Redis 서비스를 중지합니다..."
  
  for service in "$PM2_MONGODB_NAME" "$PM2_REDIS_NAME"; do
    if pm2 list | grep -q "$service"; then
      echo "$service 중지 중..."
      pm2 stop "$service"
      pm2 delete "$service"
    fi
  done

  echo "MongoDB 및 Redis가 중지되었습니다."
}

# 서비스 재시작 함수
restart_services() {
  echo "MongoDB 및 Redis 서비스를 재시작합니다..."
  
  pm2 restart "$PM2_MONGODB_NAME"
  pm2 restart "$PM2_REDIS_NAME"
  
  echo "MongoDB 및 Redis가 재시작되었습니다."
}

# 서비스 상태 확인 함수
status_services() {
  echo "MongoDB 및 Redis 상태를 확인합니다..."
  pm2 list
  
  echo "\n포트 사용 현황:"
  echo "MongoDB (27017):" $(lsof -i:27017 | grep LISTEN || echo "미사용")
  echo "Redis (6379):" $(lsof -i:6379 | grep LISTEN || echo "미사용")
}

# 명령어 처리
case "$1" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  restart)
    restart_services
    ;;
  status)
    status_services
    ;;
  *)
    echo "사용법: ./run-db.sh {start|stop|restart|status}"
    exit 1
    ;;
esac
