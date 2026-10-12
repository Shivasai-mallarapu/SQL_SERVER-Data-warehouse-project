/*
Silver-layer data-quality checks.

Run after Bronze and Silver load procedures. Each query returns rows that need
investigation; an empty result set means that specific check found no issues.
These checks are diagnostic and do not automatically stop a pipeline.
*/

-- 1. Customer records with missing business keys.
SELECT *
FROM Silver.crm_cust_info
WHERE cst_id IS NULL
   OR cst_key IS NULL;

-- 2. Duplicate customer IDs (expected to be unique after deduplication).
SELECT cst_id, COUNT(*) AS record_count
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- 3. Product records with missing identifiers.
SELECT *
FROM Silver.crm_prd_info
WHERE prd_id IS NULL
   OR prd_key IS NULL;

-- 4. Sales records with missing order/product/customer identifiers.
SELECT *
FROM Silver.crm_sales_details
WHERE sls_ord_num IS NULL
   OR sls_prd_key IS NULL
   OR sls_cust_id IS NULL;

-- 5. Sales values that may need business-rule review.
SELECT *
FROM Silver.crm_sales_details
WHERE sls_quantity < 0
   OR sls_sales < 0
   OR sls_price < 0;

-- 6. Date fields that could not be populated during transformation.
SELECT *
FROM Silver.crm_sales_details
WHERE sls_order_dt IS NULL
   OR sls_ship_dt IS NULL
   OR sls_due_dt IS NULL;
