# SQL Server Data Warehouse Project

A SQL Server/T-SQL project demonstrating a layered data-warehouse workflow, transformation scripts, analytical views, and data-quality checks.

## Project Overview

The repository is organized around the **Bronze → Silver → Gold** warehouse pattern:

- **Bronze:** landing/staging structures and initial data loading.
- **Silver:** cleaned and standardized data structures and transformations.
- **Gold:** business-facing views for customer, product, and sales analysis.

> Scope note: This README describes the repository structure and SQL assets. Run the scripts in SQL Server and validate the resulting objects/data before treating the workflow as production-ready.

## Repository Structure

```text
.
├── Docs/                         # Project documentation
├── datasets/                     # Input datasets (if included)
├── scripts/
│   ├── bronze/                   # Bronze-layer DDL and load procedure
│   ├── Silver/                   # Silver-layer DDL and load procedure
│   └── Gold/                     # Gold-layer analytical views
├── tests/                        # SQL data-quality checks
├── LICENSE
└── README.md
```

## Technology Stack

- Microsoft SQL Server
- T-SQL
- SQL DDL and stored procedures
- Layered data warehousing
- SQL-based data validation

## Main SQL Assets

- Bronze layer: `ddl.bronze.sql`, `proc_load_bronze.sql`
- Silver layer: `ddl_Silver.sql`, `proc_load_silver.sql`
- Gold layer: `DDL_Gold.sql`
- Quality checks: `quality_checks_Silver.sql`

File names preserve the repository's current casing.

## Data Flow

```text
Source datasets
      |
      v
  Bronze layer
(raw / landing data)
      |
      v
  Silver layer
(cleaning / standardization)
      |
      v
   Gold layer
(customer, product,
 and sales views)
      |
      v
Analytical queries / reporting
```

## How to Explore

1. Read the materials in `Docs/`.
2. Inspect the available files in `datasets/`.
3. Review the Bronze, Silver, and Gold SQL scripts in sequence.
4. Review `tests/quality_checks_Silver.sql` and execute checks against the intended database.
5. Validate object names, row counts, and query results in SQL Server Management Studio or another SQL Server client.

## Current Limitations / Next Improvements

- Add a documented SQL Server version and database setup instructions.
- Document the exact source files, expected schemas, and execution order.
- Include representative query outputs or screenshots after running the scripts.
- Record data-quality check outcomes and sample row counts.
- Add automated test execution where practical.

## Author

**Shiva Sai Goud Mallarapu**  
GitHub: [Shivasai-mallarapu](https://github.com/Shivasai-mallarapu)
