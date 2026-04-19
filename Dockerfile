# ─────────────────────────────────────────────
# FinSight AI — FastAPI Docker Image
# Multi-stage build: lean production image
# ─────────────────────────────────────────────

# ── Stage 1: Build dependencies ───────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# ── Stage 2: Production image ─────────────────
FROM python:3.11-slim AS production

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY config/ ./config/
COPY serving/ ./serving/
COPY ai/ ./ai/
COPY etl/ ./etl/

# Non-root user for security
RUN useradd -m -u 1000 finsight && chown -R finsight:finsight /app
USER finsight

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "serving.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
