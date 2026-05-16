# Clinical Trial Pipeline & R&D Success Analysis

![Python](https://img.shields.io/badge/Python-3.8+-blue?logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-SQLite-lightblue?logo=sqlite&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-orange?logo=tableau&logoColor=white)
![Domain](https://img.shields.io/badge/Domain-Life%20Sciences%20%26%20Pharma-green)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

---

## The Problem

Drug development is expensive and mostly fails. A Phase 3 trial can cost north of $300M — and roughly half don't make it to approval. Biotech companies and their investors need to know which therapeutic areas give the best odds, where trials tend to collapse, and how enrollment size affects outcomes.

This project maps those questions using real clinical trial data, framed as a biotech R&D investment advisory.

---

## Dataset

| Detail | Info |
|---|---|
| Source | [ClinicalTrials.gov — Kaggle](https://www.kaggle.com/datasets/prasad22/healthcare-dataset) |
| Records | 400,000+ trials |
| Coverage | Phase 1 through Phase 4 |
| Period | 2000 – 2023 |
| Fields | Phase, status, sponsor, condition, enrollment, dates |

---

## Tools

| Layer | Tools |
|---|---|
| Cleaning & EDA | Python (Pandas, NumPy, Seaborn, Matplotlib) |
| Analysis | SQL (SQLite) — 8 queries |
| Dashboard | Tableau |
| Presentation | PowerPoint — 3-slide advisory deck |

---

## What the Analysis Covers

### Python
- Loads and cleans 400K+ trial records
- Standardises phase labels (Phase 1/2/3/4) and status (Completed / Active / Terminated)
- Maps 9 therapeutic categories from free-text condition fields
- Generates 6-chart dashboard saved as PNG

### SQL (8 Queries)

| Query | Question answered |
|---|---|
| Q1 | Trial volume and completion rate by phase |
| Q2 | Therapeutic area — trial count and Phase 3 success rate |
| Q3 | Pipeline funnel — Phase 1 to Phase 4 progression rates |
| Q4 | Sponsor concentration — top 15 by trial volume |
| Q5 | Enrollment size by therapeutic area |
| Q6 | Termination rate by area and phase — risk flags |
| Q7 | Year-over-year trial starts trend (2000–2023) |
| Q8 | Rare disease vs common disease risk comparison |

---

## Key Findings

- The pipeline narrows sharply between Phase 2 and Phase 3 — that is where most R&D investment is lost
- Oncology leads in trial volume but has a below-average Phase 3 success rate
- Rare Disease trials carry higher termination risk despite orphan drug incentives
- Enrollment size inversely correlates with termination rate in Phase 3 trials
- Trial starts grew steadily from 2000 to 2019, with a dip post-2020

---

## Repository Structure

```
pharma-clinical-trial-pipeline-analysis/
│
├── clinical_trials_analysis.py    # Python EDA + cleaning + visualisation
├── clinical_trials_analysis.sql   # 8 SQL queries for pipeline analysis
├── clinical_trials_dashboard.png  # 6-chart output (generated on run)
├── clinical_trials_analysis.db    # SQLite database (generated on run)
└── README.md
```

---

## How to Run

```bash
# Install dependencies
pip install pandas matplotlib seaborn

# Download dataset from Kaggle
# https://www.kaggle.com/datasets/prasad22/healthcare-dataset
# Rename file to: clinical_trials.csv

# Run analysis
python clinical_trials_analysis.py
```

---

## Author

**Rachit Bhatt**
MBA — Finance & Business Analytics | Delhi Technological University
[LinkedIn](https://www.linkedin.com/in/rachitbhatt16) · [GitHub](https://github.com/rachitbhatt16)

---

## License

Uses publicly available data from ClinicalTrials.gov via Kaggle. For educational and portfolio purposes only.
