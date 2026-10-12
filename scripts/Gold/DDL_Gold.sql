/*
Gold-layer analytical views.

Prerequisites:
- Run the Bronze and Silver DDL/load scripts first.
- Ensure the Gold schema exists.
- Execute this script in SQL Server Management Studio or sqlcmd (GO batch separators are used).
*/

CREATE OR ALTER VIEW Gold.dim_customer
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ci.cst_marital_status AS marital_status,
    la.cntry AS country,
    ca.bdate AS date_of_birth,
    ci.cst_create_date AS create_date
FROM Silver.crm_cust_info AS ci
LEFT JOIN Silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN Silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO

CREATE OR ALTER VIEW Gold.dim_products
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.cat_id AS category_id,
    pn.prd_nm AS product_name,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS product_cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS starting_date
FROM Silver.crm_prd_info AS pn
LEFT JOIN Silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;
GO

CREATE OR ALTER VIEW Gold.fact_sales
AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_number,
    cu.customer_id,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS unit_price,
    sd.dwh_create_date
FROM Silver.crm_sales_details AS sd
LEFT JOIN Gold.dim_customer AS cu
    ON sd.sls_cust_id = cu.customer_id
LEFT JOIN Gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number;
GO
