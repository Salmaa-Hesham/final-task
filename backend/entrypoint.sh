#!/bin/bash
set -e

echo "Running Alembic database migrations..."
alembic upgrade head

echo "Starting Gunicorn server on port 8080..."
exec gunicorn --bind 0.0.0.0:8080 \
              --workers 2 \
              --timeout 120 \
              --access-logfile - \
              --error-logfile - \
              "realworld.app:app"
