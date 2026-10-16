# ==========================================
# Stage 1: Build & Dependency Resolution
# ==========================================
FROM python:3.10-slim AS builder

WORKDIR /app

# Install build tools and Poetry
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -U pip poetry

# Create isolated virtual environment for dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    VIRTUAL_ENV="/opt/venv"

# Copy dependency specifications
COPY poetry.lock pyproject.toml /app/

# Install production dependencies and Gunicorn into the virtualenv
RUN poetry config virtualenvs.create false \
    && poetry install --no-root --without dev \
    && pip install --no-cache-dir gunicorn

# ==========================================
# Stage 2: Final Minimal Runtime Image
# ==========================================
FROM python:3.10-slim AS runner

# Install only runtime system packages (no compiler, no dev tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the lightweight virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Activate the virtualenv for all subsequent runtime commands
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Copy application source code
COPY . /app/

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]