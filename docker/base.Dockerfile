FROM python:3.13.2-slim AS base

# 作業ディレクトリ設定
WORKDIR /app

# 環境変数設定
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# システム依存パッケージインストールと不要なキャッシュの削除
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libpq-dev gcc make curl gnupg lsb-release && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-17 && \
    pip install --no-cache-dir --upgrade pip poetry && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Poetryの設定
RUN poetry config virtualenvs.create false

# 依存関係ファイルをコピー
COPY pyproject.toml ./
COPY poetry.lock* ./

# エントリポイントスクリプト
COPY docker/db-tools-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 非rootユーザーを作成
RUN adduser --disabled-password --gecos "" nonroot