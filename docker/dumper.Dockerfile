FROM ghcr.io/ukwhatn/psql-base:latest AS dumper

# Set mode
ENV DB_TOOL_MODE=dumper

# Install dumper dependencies
RUN poetry install --no-interaction --only dumper

# Copy dump script
COPY script/dump.py ./dump.py

# Set permissions
RUN chown -R nonroot:nonroot /app
RUN chown nonroot:nonroot /entrypoint.sh

# Switch to non-root user
USER nonroot

# Run entrypoint script
ENTRYPOINT ["/entrypoint.sh"]