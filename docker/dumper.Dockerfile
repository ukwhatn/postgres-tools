# ベースイメージからの依存関係インストールステージ
FROM ghcr.io/ukwhatn/psql-base:latest AS deps

# Set mode
ENV DB_TOOL_MODE=dumper

# キャッシュを効率的に利用して依存関係インストール
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/poetry \
    poetry install --no-interaction --only dumper

# 最終的なダンパーイメージ
FROM deps AS dumper

# Copy dump script
COPY script/dump.py ./dump.py

# 権限設定 - 複数のRUNコマンドを一つに結合して層を減らす
RUN chown -R nonroot:nonroot /app && \
    chown nonroot:nonroot /entrypoint.sh

# Switch to non-root user
USER nonroot

# Run entrypoint script
ENTRYPOINT ["/entrypoint.sh"]