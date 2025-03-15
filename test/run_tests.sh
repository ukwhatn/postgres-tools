#!/bin/bash
# PostgreSQL Tools テストスクリプト
# 
# マイグレーターとダンパーイメージの機能を検証するテストスクリプト
# Docker Compose環境が必要です

set -e  # エラー発生時に即終了

# 色付きの出力用関数
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
  echo -e "\n${CYAN}==== $1 ====${NC}"
}

# 環境をクリーンアップする関数
cleanup() {
  log_info "Cleaning up test environment..."
  docker compose -f "$(dirname "$0")/compose.yml" down -v
}

# エラー発生時のクリーンアップ
handle_error() {
  log_error "テスト失敗: $1"
  if [ "$KEEP_ENV" != "true" ]; then
    cleanup
  fi
  exit 1
}

# メイン処理開始
log_section "PostgreSQL Tools Testing"

# コマンドライン引数の処理
USE_LOCAL=false
KEEP_ENV=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --use-local) USE_LOCAL=true ;;
    --keep) KEEP_ENV=true ;;
    *) log_error "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# ローカルビルドイメージを使用する場合
if [ "$USE_LOCAL" = "true" ]; then
  log_info "Using locally built images"
  MIGRATOR_IMAGE="ghcr.io/ukwhatn/psql-migrator:latest"
  DUMPER_IMAGE="ghcr.io/ukwhatn/psql-dumper:latest"
  export MIGRATOR_IMAGE
  export DUMPER_IMAGE
fi

# 環境をクリーンアップして起動
log_info "Cleaning up previous test environment..."
docker compose -f "$(dirname "$0")/compose.yml" down -v || true

log_info "Starting test environment..."
docker compose -f "$(dirname "$0")/compose.yml" up -d

# サービスの準備ができるのを待つ
log_info "Waiting for services to be ready..."
sleep 5

# Postgresの準備確認
until docker exec test-postgres pg_isready -U postgres -d test; do
  log_info "PostgreSQL is not ready yet - sleeping for 2 seconds"
  sleep 2
done

# コンテナのログ確認
log_section "Services Status"
docker ps | grep "test-"

# ----- マイグレーターのテスト -----
log_section "Testing Migrator"

# マイグレーションが適用されたか確認
if docker exec test-postgres psql -U postgres -d test -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'test_table');" | grep -q 't'; then
  log_success "Migration successful: test_table created"
else
  handle_error "Migration failed: test_table not found"
fi

# ----- ダンパーのテスト -----
log_section "Testing Dumper"

# バケットを準備
log_info "Setting up MinIO bucket..."
docker exec test-mc mc alias set local http://minio:9000 minioadmin minioadmin
docker exec test-mc mc mb -p local/test-bucket
docker exec test-mc mc mb -p local/test-bucket/default

# テストデータの挿入
log_info "Inserting test data..."
docker exec test-postgres psql -U postgres -d test -c "INSERT INTO test_table (name) VALUES ('test1'), ('test2'), ('test3');"
docker exec test-postgres psql -U postgres -d test -c "SELECT * FROM test_table;" | tee /tmp/before_restore.txt

# バックアップ機能のテスト
log_info "Testing backup functionality..."
docker exec test-dumper python dump.py oneshot

# バックアップファイルの存在を確認
if docker exec test-mc mc ls local/test-bucket/default/ | grep -q "backup_"; then
  log_success "Backup created successfully"
else
  handle_error "Backup failed - no backup files found"
fi

# リストア機能のテスト
log_info "Testing restore functionality..."

# データベースをクリア
log_info "Clearing database for restore test..."
docker exec test-postgres psql -U postgres -d test -c "DELETE FROM test_table;"

# バックアップファイル名を取得
log_info "Finding backup file for restore..."
docker exec test-mc mc ls local/test-bucket/default/ > /tmp/backup_listing.txt
BACKUP_NAME=$(cat /tmp/backup_listing.txt | grep -v "STANDARD /" | grep "backup_.*\.sql" | head -1 | awk '{print $NF}')
log_info "Found backup file: $BACKUP_NAME"

if [ -z "$BACKUP_NAME" ]; then
  handle_error "Could not find any backup files"
fi

# リストアを実行
log_info "Restoring from backup: $BACKUP_NAME"
docker exec test-dumper python dump.py restore "default/$BACKUP_NAME"

# データを検証
log_info "Verifying restored data..."
docker exec test-postgres psql -U postgres -d test -c "SELECT * FROM test_table;" | tee /tmp/after_restore.txt

# 簡易的に行数でチェック
BEFORE_COUNT=$(grep -c "test" /tmp/before_restore.txt || true)
AFTER_COUNT=$(grep -c "test" /tmp/after_restore.txt || true)

if [ "$BEFORE_COUNT" -gt 0 ] && [ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ]; then
  log_success "Restore test passed. Before: $BEFORE_COUNT rows, After: $AFTER_COUNT rows"
else
  log_error "Restore test failed. Before: $BEFORE_COUNT rows, After: $AFTER_COUNT rows"
  diff /tmp/before_restore.txt /tmp/after_restore.txt || true
  handle_error "Data mismatch after restore"
fi

# すべてのテストが通過
log_section "All Tests Passed!"

# 環境をクリーンアップ（オプション）
if [ "$KEEP_ENV" != "true" ]; then
  cleanup
else
  log_info "Test environment is still running. Use the following command to stop it:"
  echo "docker compose -f $(realpath "$(dirname "$0")/compose.yml") down -v"
fi

exit 0