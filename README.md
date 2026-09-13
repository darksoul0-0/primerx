# PrimeRx — Commercial Analytics Case Study 💊📊

A pharma commercial-analytics deep dive built around lab-alert data, prescription sales, and HCP-account affiliations — answering the questions a pharma sales-ops or market-access team actually asks: *which doctors matter, are alerts converting into prescriptions, and where are we losing share to competitors?*

---

## 🧭 Overview

`PrimeRx` simulates a real-world commercial analytics workflow for a pharmaceutical brand (`DRG001`) competing against rivals like `Rivalex` (`DRG002`). Using diagnostic **lab alerts** as a leading indicator of patient need, the analysis tracks whether those alerts translate into **prescription volume** for our drug — and segments HCPs (Healthcare Providers) and accounts by responsiveness.

The project moves through three layers:

1. **SQL** — cleaning, joining, and modeling raw alert/sales/affiliation data in MySQL
2. **Python** — exploratory analysis and validation (`PrimeRx_pyCode.ipynb`)
3. **Excel / PowerPoint** — a stakeholder-ready workbook and case-outcome deck translating the SQL output into business recommendations

---

## 🗂️ Repository Structure

| File | Description |
|---|---|
| `updated_primerx.sql` | Core SQL analysis — 15+ queries covering HCP ranking, conversion, lift, and segmentation |
| `PrimeRx_pyCode.ipynb` | Python notebook for exploration and cross-checking the SQL results |
| `PrimeRx Datasets.xlsx` | Multi-sheet workbook with the finished analysis and step-by-step instructions per business question |
| `alerts.csv` | Lab alert records per HCP (alert date, lab result) |
| `sales.csv` | Prescription-level sales data (drug, volume, date, HCP) |
| `affliation.csv` | HCP ↔ Account affiliation mapping |
| `medical case_outcome.pptx` | Slide deck summarizing findings and recommendations |
| `README.md` | You are here |

---

## ❓ Business Questions Answered

- **Doctor prioritization** — which HCPs generate the most alerts, and do the highest-volume prescribers overlap with the highest-alert doctors?
- **Alert → prescription conversion** — after a doctor's first positive lab alert, do they start prescribing our drug within 30 days? Who doesn't convert?
- **Competitive share** — among the highest-alert doctors, what's our drug's share of prescription volume vs. competitors, and who's the top competing drug?
- **Account-level performance** — which accounts have the lowest alert-to-prescription conversion, and what's our volume per active doctor by account?
- **Pre/post lift analysis** — comparing prescription volume 90 days before vs. 90 days after a doctor's first positive alert
- **HCP segmentation** — classifying doctors into **New Starters**, **Growers**, and **Non-Responders** based on lift, with incremental volume by segment

---

## 🛠️ Tech Stack

- **SQL (MySQL)** — window functions (`RANK() OVER`), CTEs, conditional aggregation, date-based cohort logic
- **Python** (Jupyter/pandas) — supporting exploratory analysis
- **Excel** — final deliverable workbook with reproducible steps
- **PowerPoint** — executive-facing case outcome summary

---

## 🚀 Getting Started

1. Load `alerts.csv`, `sales.csv`, and `affliation.csv` into a MySQL schema named `primerx`
2. Run `updated_primerx.sql` top to bottom — each block is a standalone, commented query
3. Open `PrimeRx_pyCode.ipynb` to explore the same data in Python
4. Reference `PrimeRx Datasets.xlsx` for the finished analysis and `medical case_outcome.pptx` for the narrative summary

---

## 📌 Notes

This is a self-directed analytics case study built for practice in translating raw transactional/clinical-style data into commercial decisions — the kind of HCP targeting and lift analysis used in pharma sales operations and market access teams.
