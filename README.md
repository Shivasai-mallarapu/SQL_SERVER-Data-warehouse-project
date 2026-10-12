# SQL Server Data Warehouse Project

A SQL Server/T-SQL learning project for building a layered warehouse from CRM and ERP source data, transforming it for analytics, and defining Gold-layer views.

## Architecture

```text
CRM / ERP CSV files
       |
       v
Bronze — source-aligned landing tables
       |
       v
Silver — cleaned and standardized tables
       |
       v
Gold — customer and product dimensions,
       plus a sales fact view
       |
       v
Analytics and reporting queries
```

## Repository Structure

- `Docs/` — project documentation
- `datasets/` — source data location (verify that required CSV files are included)
- `scripts/bronze/` — Bronze DDL and load procedure
- `scripts/Silver/` — Silver DDL and transformation/load procedure
- `scripts/Gold/` — Gold analytical views
- `tests/quality_checks_Silver.sql` — diagnostic data-quality queries

## Technology

- Microsoft SQL Server
- T-SQL, DDL, stored procedures, `BULK INSERT`
- ETL transformations and dimensional modeling
- Data-quality checks

## Main Components

- **Bronze:** defines source-aligned CRM/ERP tables and loads CSV files.
- **Silver:** standardizes customer attributes, transforms source fields, and prepares data for analysis.
- **Gold:** defines customer and product dimensions and a sales fact view.
- **Quality checks:** returns rows that violate selected key, null, duplicate, or value checks.

## Setup and Execution

1. Use a SQL Server instance and a client such as SQL Server Management Studio.
2. Create the `Bronze`, `Silver`, and `Gold` schemas if they do not already exist.
3. Inspect the CSV file locations expected by `scripts/bronze/proc_load_bronze.sql` and change them to paths available on your machine.
4. Run the Bronze DDL script, then create and execute `Bronze.load_bronze`.
5. Run the Silver DDL script, then create and execute `Silver.load_silver`.
6. Run `scripts/Gold/DDL_Gold.sql` to create the analytical views.
7. Run `tests/quality_checks_Silver.sql` and inspect any returned rows.
8. Verify the views with sample SELECT queries before using them for reporting.

**Important:** the Bronze loader originally contained a machine-specific Windows path. Update all CSV paths before running it. This project has not been independently executed against your SQL Server instance from this review, so validate script execution and output locally.

## Known Follow-up Work

- Confirm the required CSV files are committed and document their source/licensing.
- Add schema creation/setup scripts and example analytical queries.
- Add expected row counts and documented validation results.
- Consider making the load procedures configurable rather than relying on local absolute paths.
- Run all scripts from a clean database and document any environment-specific prerequisites.

## Author

**Shiva Sai Goud Mallarapu**  
[GitHub profile](https://github.com/Shivasai-mallarapu)
