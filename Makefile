.PHONY: install lint test api ingest-local etl-local infra-up infra-down deploy clean help

# ─────────────────────────────────────────────
# FinSight AI — Developer Commands
# Usage: make <target>
# ─────────────────────────────────────────────

help:
	@echo ""
	@echo "FinSight AI — Available Commands"
	@echo "──────────────────────────────────"
	@echo "  make install        Install deps + pre-commit hooks"
	@echo "  make lint           Run ruff + mypy"
	@echo "  make test           Run full test suite with coverage"
	@echo "  make api            Start FastAPI server (localhost:8000)"
	@echo "  make ingest-local   Pull market data locally (no Azure)"
	@echo "  make etl-local      Run Bronze→Silver→Gold locally"
	@echo "  make infra-up       Terraform: provision Azure resources"
	@echo "  make infra-down     Terraform: destroy Azure resources"
	@echo "  make deploy         Push notebooks + Docker image to Azure"
	@echo "  make clean          Remove cache, coverage, tmp files"
	@echo ""

# ── Setup ─────────────────────────────────────
install:
	pip install -r requirements-dev.txt
	pre-commit install
	@echo "✅ Dependencies installed and pre-commit hooks set up"

# ── Code Quality ──────────────────────────────
lint:
	ruff check . --fix
	ruff format .
	mypy . --ignore-missing-imports
	@echo "✅ Lint passed"

# ── Tests ─────────────────────────────────────
test:
	pytest tests/ -v --cov=. --cov-report=term-missing --cov-report=xml
	@echo "✅ Tests complete"

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

# ── API ───────────────────────────────────────
api:
	uvicorn serving.api.main:app --host 0.0.0.0 --port 8000 --reload

api-docker:
	docker-compose up --build api

# ── Local Pipeline ────────────────────────────
ingest-local:
	python scripts/run_ingestion_local.py

etl-local:
	python scripts/run_etl_local.py

# ── Infrastructure ────────────────────────────
infra-up:
	cd infrastructure/terraform && terraform init && terraform apply -auto-approve

infra-down:
	cd infrastructure/terraform && terraform destroy -auto-approve

# ── Deploy ────────────────────────────────────
deploy:
	@echo "Deploying notebooks to Databricks..."
	databricks workspace import_dir notebooks /finsight-ai/notebooks --overwrite
	@echo "Building and pushing Docker image..."
	docker build -t finsightai-api:latest .
	docker tag finsightai-api:latest YOUR_ACR.azurecr.io/finsightai-api:latest
	docker push YOUR_ACR.azurecr.io/finsightai-api:latest
	@echo "✅ Deploy complete"

# ── Clean ─────────────────────────────────────
clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name "htmlcov" -exec rm -rf {} +
	find . -name "coverage.xml" -delete
	find . -name ".coverage" -delete
	@echo "✅ Cleaned"
