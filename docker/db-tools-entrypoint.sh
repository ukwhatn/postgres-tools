#!/bin/bash
set -e

# Validate database connection configuration
echo "Checking environment variables..."
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ERROR: POSTGRES_USER and POSTGRES_PASSWORD environment variables are required"
  exit 1
fi

echo "Checking database connection..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_isready -h ${POSTGRES_HOST:-localhost} -p ${POSTGRES_PORT:-5432} -U "$POSTGRES_USER" -d ${POSTGRES_DB:-main} -t 5
if [ $? -ne 0 ]; then
  echo "WARNING: Unable to connect to database. Commands will still run but may fail."
fi

if [ "$DB_TOOL_MODE" = "migrator" ]; then
  echo "Running migrator mode..."
  if [ "$1" = "generate" ] || [ "$1" = "revision" ]; then
    echo "Generating migration file: $2"
    shift
    exec alembic revision --autogenerate -m "$@"
  elif [ "$1" = "custom" ]; then
    echo "Running custom command: ${@:2}"
    exec "${@:2}"
  else
    echo "Running migrations..."
    exec alembic upgrade head
  fi
elif [ "$DB_TOOL_MODE" = "dumper" ]; then
  echo "Running dumper mode..."
  if [ "$1" = "custom" ]; then
    echo "Running custom command: ${@:2}"
    exec "${@:2}"
  else
    DUMPER_MODE=${DUMPER_MODE:-scheduled}
    echo "Dump mode: $DUMPER_MODE"
    exec python dump.py
  fi
else
  echo "Error: Unknown mode '$DB_TOOL_MODE'. Valid modes are 'migrator' or 'dumper'."
  exit 1
fi