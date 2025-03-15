FROM ghcr.io/ukwhatn/psql-base:latest AS migrator

# Set mode
ENV DB_TOOL_MODE=migrator

# Install migrator dependencies
RUN poetry install --no-interaction --only db

# Copy Alembic configuration
COPY alembic/alembic.ini ./alembic.ini
COPY alembic/env.py ./alembic/env.py
COPY alembic/script.py.mako ./alembic/script.py.mako

# Create and set permissions for versions directory
RUN mkdir -p /app/alembic/versions
RUN chown -R nonroot:nonroot /app
RUN chown nonroot:nonroot /entrypoint.sh

# Switch to non-root user
USER nonroot

# Mount versions directory
VOLUME ["/app/alembic/versions"]

# Run entrypoint script
ENTRYPOINT ["/entrypoint.sh"]