# ベースイメージからの依存関係インストールステージ
FROM ghcr.io/ukwhatn/psql-base:latest AS deps

# Set mode
ENV DB_TOOL_MODE=migrator

# キャッシュを効率的に利用して依存関係インストール
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/poetry \
    poetry install --no-interaction --only db

# 最終的なマイグレーターイメージ
FROM deps AS migrator

# Copy Alembic configuration
# マウントされるディレクトリ構造を維持するために一度に複数コピー
COPY alembic/alembic.ini ./alembic.ini
COPY alembic/env.py ./migrations/env.py
COPY alembic/script.py.mako ./migrations/script.py.mako

# Create and set permissions for versions directory
# 複数のRUNコマンドを一つに結合して層を減らす
RUN mkdir -p /app/versions && \
    chown -R nonroot:nonroot /app && \
    chown nonroot:nonroot /entrypoint.sh

# Switch to non-root user
USER nonroot

# Mount versions directory
VOLUME ["/app/versions"]

# Run entrypoint script
ENTRYPOINT ["/entrypoint.sh"]