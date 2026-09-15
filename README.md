# The Kansas Data Science Education Atlas

## Table of Contents

- [Overview](#overview)
- [Key Findings](#key-findings)
- [Research Questions](#research-questions)
- [Data Sources](#data-sources)
- [Datasets](#datasets)
- [Spatial Analyses](#spatial-analyses)
- [Policy Recommendations](#policy-recommendations)
- [Quick Start](#quick-start)
- [Tech Stack](#tech-stack)
- [API Documentation](#api-documentation)
- [Recognitions](#recognitions)
- [Acknowledgements](#acknowledgements)
- [Helpful Links](#helpful-links)
- [Citation](#citation)

## Overview

This research project addresses geographic inequities in Data Science (DS) and Artificial Intelligence (AI) education access across Kansas. Using publicly available datasets, geospatial analysis, and machine learning classification, the study reveals that 88 of 105 counties lack any DS/AI academic offerings, with programs concentrated in counties hosting four-year universities (Lawrence, Manhattan, Wichita).

## Key Findings

- Educational infrastructure (presence of four-year colleges) has the strongest association to DS/AI program availability
- Economic indicators (e.g., median income, poverty rate) show minimal correlation
- Digital infrastructure is adequate statewide (e.g., avg broadband index: 0.79) but doesn't drive program creation
- Random Forest (ML model) achieved ~91% accuracy

## Research Questions

- *RQ1:* How do population density and demographics correlate with DS/AI educational offerings, and what are the implications for educational equity?
- *RQ2:* How does K-12 school distribution compare to DS/AI program availability, and where are the critical gaps in the educational pipeline?
- *RQ3:* To what extent do online DS programs reduce geographic inequality, and how is this limited by digital infrastructure?
- *RQ4:* Is there a correlation between county-level economic strength and DS/AI program density?

## Data Sources

- *NCES Common Core of Data (CCD):* K-12 school locations and counts
- *NCES IPEDS:* College and university information
- *IPUMS NHGIS:* Census demographic and economic data (ACS 2019-2023)
- *FCC Broadband Map:* Fixed broadband coverage metrics
- *US Census Bureau:* County centroid lat/long coordinates
- *Manual Collection:* DS/AI course inventory (AI-assisted web scraping via Claude & ChatGPT)

Refer to the [Methodology Process](docs/ATLAS_Methodology.md) for more information regarding data collection and ML experiment steps.

## Datasets

The project integrates 7 interconnected datasets derived from multiple authoritative sources:

| Dataset   | Description                                                       | Records | Features |
|-----------|-------------------------------------------------------------------|---------|----------|
| Dataset 1 | Educational institution locations with demographic data           | 1426    | 11       |
| Dataset 2 | Institution counts aggregated by County-City-ZIP                  | 506     | 14       |
| Dataset 3 | DS/AI course and program inventory                                | 176     | 9        |
| Dataset 4 | College-level program impact scores with coordinates              | 78      | 10       |
| Dataset 5 | County-level digital access metrics                               | 106     | 9        |
| Dataset 6 | Socioeconomic indicators and program impact                       | 106     | 11       |
| Dataset 7 | Comprehensive ML-ready integration (Datasets 1-6)                 | 106     | 32       |

## Spatial Analyses

The reproducible R workflow in [`spatial-analysis/`](spatial-analysis/) contains
two county-level analyses:

1. **Access shadows:** multiscale physical accessibility and a joint
   physical/digital access screen.
2. **Expansion-site optimization:** population-reach and equity-priority
   sequences for one to five hypothetical learning hubs.

The repository tracks source code and tests. Rendered HTML and generated
pipeline artifacts are intentionally excluded and can be regenerated locally.

## Policy Recommendations

1. *Immediate Expansion:* Target the 4 False Positive counties (counties predicted to have programs but lacking them) as high-leverage opportunities
2. *Regional Hub Development:* Establish DS/AI centers serving northwest, southwest, and central Kansas clusters
3. *Faculty Fellowship Program:* Incentivize DS/AI specialists to teach in underserved counties
4. *2+2 Articulation Agreements:* Create community college → university transfer pathways for DS/AI degrees
5. *Hybrid Certificate Programs:* Leverage existing broadband with mobile/hybrid delivery combining online instruction and periodic in-person sessions

---

## Quick Start

```bash
git clone https://github.com/2shakilrafi/The-Kansas-Data-Science-Education-Atlas.git
cd The-Kansas-Data-Science-Education-Atlas
```

**Terminal 1 — Frontend:**
```bash
npm install && npm run dev
```

**Terminal 2 — Backend:**
```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Tech Stack

- **Frontend:** React, TypeScript, Tailwind CSS, Vite
- **Backend:** FastAPI (Python), PostgreSQL
- **Mapping:** Leaflet.js
- **Testing:** Vitest, Pytest
- **Deployment:** Render (frontend & backend)
- **Database:** Google BigQuery
- **Data Processing:** Python (custom scripts), SQL
- **ML Platform:** WEKA 3.8
- **Visualization:** R, Microsoft Power BI Desktop
- **Writing:** Microsoft Word, Overleaf

## API Documentation

- [API Reference](docs/API.md)

---

## Recognitions

- Winner of $1,500 Spring 2026 Undergraduate Research Scholarship (College of Arts & Sciences, Kansas State University)
- Presented at MINK-WIC Conference 2025 (Missouri, Iowa, Nebraska, Kansas)
- Research paper accepted into American Society for Engineering Education (ASEE) 2026 Annual Conference & Exposition
- Presented as speaker at Kansas Data Science Conference 2026

## Acknowledgements

- National Science Foundation (NSF), Grant No. 2148878
- College of Arts & Sciences — Kansas State University

---

## Helpful Links
- [KSDCon Presentation Demo](https://youtu.be/KVLEbQzL_g8)
- [ASEE Presentation Demo](https://youtu.be/tEcJ6soxCTc)
- [Research Paper](docs/Research%20Paper%20-%20ASEE%20-%20Final%20-%20Overleaf.pdf) — accepted into ASEE 2026 Annual Conference & Exposition
- [Public Dashboard](https://atlas-frontend-44fq.onrender.com/)
- [Dashboard Deployment Guide](docs/Render_Deployment_Guide.pdf)

## Citation

If you use this project, please cite:

> Chandramouli, S. S. (2026). The Kansas Data Science Education Atlas. Kansas State University. [GitHub Repository](https://github.com/csrisurya/The-Kansas-Data-Science-Education-Atlas)
