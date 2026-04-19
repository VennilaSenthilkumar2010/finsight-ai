# Contributing to FinSight AI

## Setup
```bash
git clone https://github.com/YOUR_USERNAME/finsight-ai.git
cd finsight-ai
cp .env.example .env
make install
```

## Branch strategy
- `main` — production, protected, CI/CD deploys from here
- `develop` — integration branch
- `feature/your-feature` — your work

## Before submitting a PR
```bash
make lint    # must pass
make test    # must pass with >80% coverage
```

## Commit message format
```
feat: add Polygon.io websocket ingestion
fix: handle null close price in silver ETL
docs: update architecture diagram
test: add unit tests for anomaly detector
```
