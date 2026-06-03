# Philosophy Degree ROI Pipeline

## About
In this project, I built an Extract, Load, Transform (ELT) pipeline utilizing the modern data stack: Amazon S3, dbt and Snowflake, orchestrated via **GitHub Actions**. 

The pipeline ingests a raw individual-level microdata sample (2019-2023) from the American Community Survey (ACS) through a public API issued by the US Census Bureau.

Using dbt, the raw data is modeled into a **Star Schema**, decoupling descriptive categories from economic metrics, providing an analysis of the long-term career outcomes of individuals holding an undergraduate degree in philosophy.