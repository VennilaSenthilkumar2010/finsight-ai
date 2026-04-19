# FinSight AI 🚀
### Real-time Market Intelligence Pipeline — Azure Databricks · Mosaic AI · Power BI

![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![Databricks](https://img.shields.io/badge/Databricks-Mosaic%20AI-red?logo=databricks)
![Azure](https://img.shields.io/badge/Azure-ADLS%20Gen2%20%7C%20ADF%20%7C%20DevOps-0078D4?logo=microsoftazure)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-Medallion%20Architecture-00ADD8)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What is FinSight AI?

FinSight AI is a **production-grade, plug-and-play data engineering project** that ingests real-time stock and cryptocurrency market data, runs it through a full **Medallion ETL pipeline** (Bronze → Silver → Gold), and applies three AI/ML models using **Databricks Mosaic AI**:

| AI Module | Model | Output |
|---|---|---|
| 🚨 Anomaly Detection | Isolation Forest | Price spike / crash flags |
| 📈 Trend Prediction | XGBoost Classifier | Next-hour bullish / bearish signal |
| 🧠 Sentiment Analysis | LLM (GPT-4o-mini) | News-driven trading signal |

Results are served via a **FastAPI REST endpoint** and visualised in a **real-time Power BI dashboard**.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  INGESTION   Polygon.io · CoinGecko · NewsAPI               │
│              via Azure Data Factory (scheduled triggers)     │
└────────────────────────┬────────────────────────────────────┘
                         │ raw JSON / CSV
┌────────────────────────▼────────────────────────────────────┐
│  BRONZE      ADLS Gen2 · Delta Lake · schema-on-read        │
│              watermark table · incremental load              │
└────────────────────────┬────────────────────────────────────┘
                         │ PySpark ETL · Databricks
┌────────────────────────▼────────────────────────────────────┐
│  SILVER      dedup · null handling · type casting           │
│              outlier removal · Delta UPSERT (MERGE)          │
└────────────────────────┬────────────────────────────────────┘
                         │ feature engineering · PySpark
┌────────────────────────▼────────────────────────────────────┐
│  GOLD        RSI · MACD · Bollinger Bands · Z-scores        │
│              Mosaic AI Feature Store · news embeddings       │
└──────┬───────────────────────────────────────┬──────────────┘
       │ Mosaic AI                             │
┌──────▼──────────┐ ┌──────────────────┐ ┌────▼─────────────┐
│ Anomaly         │ │ Trend Prediction │ │ Sentiment LLM    │
│ Isolation Forest│ │ XGBoost + AutoML │ │ GPT-4o-mini      │
│ MLflow tracking │ │ MLflow tracking  │ │ FAISS vector DB  │
└──────┬──────────┘ └────────┬─────────┘ └────┬─────────────┘
       └────────────────┬────┘                 │
                        │ REST · Docker        │
          ┌─────────────▼──────────────────────▼──────────────┐
          │  FastAPI  /predict · /anomalies · /sentiment       │
          │  Power BI DirectQuery Dashboard (real-time)        │
          └────────────────────────────────────────────────────┘
                        │
          ┌─────────────▼──────────────────────────────────────┐
          │  CI/CD  GitHub Actions · Azure DevOps · Docker     │
          └────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
finsight-ai/
├── ingestion/                  # Data source connectors
│   ├── polygon/                # Polygon.io (stocks, OHLCV, trades)
│   ├── coingecko/              # CoinGecko (crypto prices)
│   └── newsapi/                # NewsAPI (financial news headlines)
│
├── etl/                        # Medallion pipeline notebooks
│   ├── bronze/                 # Raw ingestion → Delta Bronze
│   ├── silver/                 # Cleansing → Delta Silver
│   └── gold/                   # Feature engineering → Delta Gold
│
├── ai/                         # Mosaic AI model modules
│   ├── anomaly/                # Isolation Forest — price spike detection
│   ├── trend/                  # XGBoost — next-hour direction prediction
│   └── sentiment/              # LLM — news sentiment → trading signal
│
├── serving/                    # FastAPI REST layer
│   ├── api/                    # Route handlers
│   └── schemas/                # Pydantic request/response models
│
├── infrastructure/             # IaC
│   ├── terraform/              # Azure resource provisioning
│   └── arm/                    # ARM templates (alternative)
│
├── pipelines/
│   └── adf/                    # Azure Data Factory pipeline JSON exports
│
├── notebooks/                  # Databricks notebooks (exploratory)
├── tests/
│   ├── unit/                   # pytest unit tests
│   └── integration/            # end-to-end pipeline tests
│
├── config/                     # Environment configs
├── docs/                       # Architecture diagrams, wiki
├── scripts/                    # Utility scripts (bootstrap, seed data)
│
├── .env.example                # Environment variable template
├── .gitignore
├── .pre-commit-config.yaml     # Code quality hooks
├── pyproject.toml              # Project metadata + tool config
├── requirements.txt            # Production dependencies
├── requirements-dev.txt        # Dev + test dependencies
├── docker-compose.yml          # Local dev stack
└── Makefile                    # Common dev commands
```

---

## Quickstart

### 1. Clone and setup
```bash
git clone https://github.com/YOUR_USERNAME/finsight-ai.git
cd finsight-ai
cp .env.example .env          # Fill in your API keys and Azure credentials
make install                  # Install dependencies + pre-commit hooks
```

### 2. Run ingestion locally (no Azure needed)
```bash
make ingest-local             # Pulls data from APIs → local Delta files
```

### 3. Run the full ETL pipeline locally
```bash
make etl-local                # Bronze → Silver → Gold on local Spark
```

### 4. Start the API
```bash
make api                      # FastAPI server at http://localhost:8000
# Docs at http://localhost:8000/docs
```

### 5. Deploy to Azure
```bash
make infra-up                 # Terraform: provision ADLS, Databricks, ADF
make deploy                   # CI/CD: push notebooks + Docker image
```

---

## API Reference

| Endpoint | Method | Description |
|---|---|---|
| `/predict/{ticker}` | GET | Next-hour bullish/bearish signal |
| `/anomalies/{ticker}` | GET | Recent price anomaly flags |
| `/sentiment/{ticker}` | GET | News sentiment score + signal |
| `/health` | GET | Service health check |

---

## Data Sources

| Source | Data | Refresh | Free Tier |
|---|---|---|---|
| [Polygon.io](https://polygon.io) | Stocks OHLCV, trades, quotes | 1 min delay | ✅ 5 API calls/min |
| [CoinGecko](https://coingecko.com/api) | Crypto prices, market cap | Real-time | ✅ 30 calls/min |
| [NewsAPI](https://newsapi.org) | Financial news headlines | Hourly | ✅ 100 calls/day |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Cloud | Azure (ADLS Gen2, Databricks, ADF, Key Vault, Container Apps) |
| Storage | Delta Lake (Medallion: Bronze / Silver / Gold) |
| Processing | Apache Spark (PySpark), Databricks |
| AI/ML | Mosaic AI, MLflow, XGBoost, Isolation Forest, OpenAI GPT-4o-mini |
| Vector Store | FAISS |
| API | FastAPI, Uvicorn, Docker |
| BI | Power BI (DirectQuery) |
| CI/CD | GitHub Actions, Azure DevOps |
| IaC | Terraform |

---

## Milestones

- [x] Step 1 — Project scaffold & documentation
- [ ] Step 2 — Azure infrastructure (Terraform)
- [ ] Step 3 — Bronze ingestion pipeline (ADF + Python)
- [ ] Step 4 — Silver ETL (PySpark — cleansing)
- [ ] Step 5 — Gold feature engineering (Mosaic AI Feature Store)
- [ ] Step 6 — AI model layer (Anomaly + Trend + Sentiment)
- [ ] Step 7 — FastAPI serving layer (Docker)
- [ ] Step 8 — Power BI dashboard + CI/CD

---

## Contributing

Pull requests welcome. Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) and ensure `make lint` passes before submitting.

---

## License

MIT © Vennila Senthilkumar
