# 3. multi-stageビルドの最適化
# ベースステージ（システム依存パッケージとツール）
FROM python:3.13.5-slim AS system-deps

# 環境変数設定
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# システム依存パッケージインストールと不要なキャッシュの削除
# --mount=type=cache を使ってapt-getのキャッシュを活用
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libpq-dev gcc make curl gnupg lsb-release && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-17 && \
    pip install --no-cache-dir --upgrade pip poetry

# エントリポイントスクリプト
COPY docker/db-tools-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 依存関係解決ステージ
FROM system-deps AS deps

# 作業ディレクトリ設定
WORKDIR /app

# Poetryの設定
RUN poetry config virtualenvs.create false

# 依存関係ファイルだけをコピー（キャッシュの効率化）
COPY pyproject.toml poetry.lock* ./

# 最終イメージ
FROM deps AS base

# クリーンアップ
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 非rootユーザーを作成
RUN adduser --disabled-password --gecos "" nonroot