# postgres-tools

[fastapi-template](https://github.com/ukwhatn/fastapi-template) および [pycord-template](https://github.com/ukwhatn/pycord-template) で使用するためのPostgreSQLツールイメージ

## イメージ

### psql-migrator

Alembicを使用したデータベースマイグレーション管理ツール。

**環境変数:**
- `POSTGRES_USER` (必須): データベースユーザー名
- `POSTGRES_PASSWORD` (必須): データベースパスワード
- `POSTGRES_HOST` (デフォルト: localhost): データベースホスト
- `POSTGRES_PORT` (デフォルト: 5432): データベースポート
- `POSTGRES_DB` (デフォルト: main): データベース名

**使用方法:**

```bash
# マイグレーションを実行
docker run --rm -v /path/to/versions:/app/alembic/versions \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db \
  ghcr.io/ukwhatn/psql-migrator:latest

# マイグレーションファイルを生成
docker run --rm -v /path/to/versions:/app/alembic/versions \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db \
  ghcr.io/ukwhatn/psql-migrator:latest generate "新しいテーブルの追加"

# カスタムコマンドを実行
docker run --rm -v /path/to/versions:/app/alembic/versions \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db \
  ghcr.io/ukwhatn/psql-migrator:latest custom alembic history
```

### psql-dumper

S3ストレージを使用したデータベースバックアップ作成・管理ツール。

**環境変数:**
- `POSTGRES_USER` (必須): データベースユーザー名
- `POSTGRES_PASSWORD` (必須): データベースパスワード
- `POSTGRES_HOST` (デフォルト: localhost): データベースホスト
- `POSTGRES_PORT` (デフォルト: 5432): データベースポート
- `POSTGRES_DB` (デフォルト: main): データベース名
- `SENTRY_DSN`: エラー報告用のSentry DSN
- `S3_ENDPOINT`: S3互換ストレージのエンドポイントURL
- `S3_ACCESS_KEY`: S3アクセスキー
- `S3_SECRET_KEY`: S3シークレットキー
- `S3_BUCKET` (デフォルト: test-bucket): S3バケット名
- `BACKUP_DIR` (デフォルト: default): バックアップ用のバケット内ディレクトリ
- `BACKUP_RETENTION_DAYS` (デフォルト: 30): バックアップを保持する日数
- `BACKUP_TIME` (デフォルト: 03:00): 日次バックアップの時間（24時間形式）
- `DUMPER_MODE` (デフォルト: scheduled): モード（scheduled または interactive）

**使用方法:**

```bash
# スケジュールされたバックアップを実行
docker run --rm \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db -e S3_ENDPOINT=https://s3.example.com \
  -e S3_ACCESS_KEY=key -e S3_SECRET_KEY=secret \
  -e S3_BUCKET=backups -e BACKUP_DIR=mydb \
  -e DUMPER_MODE=scheduled \
  ghcr.io/ukwhatn/psql-dumper:latest

# インタラクティブモードで実行
docker run -it --rm \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db -e S3_ENDPOINT=https://s3.example.com \
  -e S3_ACCESS_KEY=key -e S3_SECRET_KEY=secret \
  -e S3_BUCKET=backups -e BACKUP_DIR=mydb \
  -e DUMPER_MODE=interactive \
  ghcr.io/ukwhatn/psql-dumper:latest

# バックアップ作成を1回だけ実行
docker run --rm \
  -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password \
  -e POSTGRES_HOST=db -e S3_ENDPOINT=https://s3.example.com \
  -e S3_ACCESS_KEY=key -e S3_SECRET_KEY=secret \
  -e S3_BUCKET=backups -e BACKUP_DIR=mydb \
  ghcr.io/ukwhatn/psql-dumper:latest custom python dump.py oneshot
```

## Docker Compose での使用例

```yaml
services:
  db-migrator:
    container_name: project-db-migrator
    image: ghcr.io/ukwhatn/psql-migrator:latest
    volumes:
      - ./migrations/versions:/app/alembic/versions
    env_file:
      - ./envs/db.env
    environment:
      - POSTGRES_HOST=db
    restart: no
    depends_on:
      db:
        condition: service_healthy
    networks:
      - db

  db-dumper:
    container_name: project-db-dumper
    image: ghcr.io/ukwhatn/psql-dumper:latest
    env_file:
      - ./envs/db.env
      - ./envs/sentry.env
      - ./envs/aws-s3.env
    environment:
      - POSTGRES_HOST=db
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    networks:
      - db
```

### env ファイルの例

#### db.env
```
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=main
```

#### sentry.env
```
SENTRY_DSN=https://your-sentry-dsn
```

#### aws-s3.env
```
S3_ENDPOINT=https://s3.example.com
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_BUCKET=backups
BACKUP_DIR=project-db
BACKUP_RETENTION_DAYS=30
BACKUP_TIME=03:00
```

## 開発

### 必要条件

- Python 3.13+
- Poetry
- Docker（イメージのビルド用）
- Docker Compose V2

### セットアップ

```bash
# 依存関係のインストール
make install

# コードフォーマット
make format

# コードの静的解析
make lint

# セキュリティチェックの実行
make security
```

### ローカルでのイメージビルド

```bash
# ベースイメージをビルド
make build-base

# マイグレーターイメージをビルド
make build-migrator

# ダンパーイメージをビルド
make build-dumper

# すべてのイメージをビルド
make build-all

# 日付ベースのバージョンでイメージにタグ付け
make tag-images

# イメージをプッシュ（認証が必要）
make push-images
```

## CI/CD

このリポジトリはGitHub Actionsを使用して、関連ファイルが変更されるたびに自動的にDockerイメージをビルドしてプッシュします。Dependabotは依存関係を最新の状態に保つよう構成されています。