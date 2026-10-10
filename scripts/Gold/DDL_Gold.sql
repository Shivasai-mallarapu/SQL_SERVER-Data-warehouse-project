/*===============================================
DDL Script: Create Gold Views
===================================================================================
Script Purpose: This script creates views for the Gold layer in the data warehouse.

The Gold layer represents the final dimension and fact tables (Star Schema)
====================================================================================
Each view performs transformations and combines data from the Silver layer to produce a clean,
enriched, and business-ready dataset.
====================================================================================
Usage: - These views can be queried directly for analytics and reporting.
*/

------------------------------------
--Creating Gold Layer
------------------------------------
CREATE VIEW gold.dim_customer AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	CASE WHEN ci.cst_gndr!= 'n/a' THEN ci.cst_gndr --CRM is the Master for gender Info
		ELSE COALESCE(ca.gen,'n/a')
	END AS Gender,
	ci.cst_marital_status AS martical_status,
	la.cntry AS country,
	ca.bdate AS DateOfBrith,
	ci.cst_create_date AS create_date
from Silver.crm_cust_info  ci		
LEFT JOIN Silver.erp_CUST_AZ12 ca
ON ci.cst_key=ca.cid 
LEFT JOIN Silver.erp_Loc_A101 la
ON ci.cst_key=la.cid
==============================================================
CREATE VIEW Gold.Dim_Products AS
	SELECT
	ROW_NUMBER() OVER(ORDER BY prd_start_dt,prd_key ) AS Product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.cat_id AS catagory_id,
	pn.prd_nm AS Product_name,
	pc.cat AS catagory,
	pc.subcat AS subcatagory,
	pc.maintenance,
	pn.prd_cost AS Poduct_cost,
	pn.prd_line AS Product_line,
	pn.prd_start_dt AS Starting_date
	FROM Silver.crm_prd_info pn
	LEFT JOIN Silver.erp_PX_CAT_G1V2 pc
	ON pn.cat_id = pc.id
	WHERE prd_end_dt IS NULL --Filter out all historical data
============================================================
	CREATE VIEW Gold.fact_sales AS 
	SELECT 
	sd.sls_ord_num,
	pr.product_number,
	cu.customer_id,
	sd.sls_order_dt,
	sd.sls_ship_dt,
	sd.sls_due_dt,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price,
	sd.dwh_create_date
	FROM Silver.crm_sales_details sd
	LEFT JOIN Gold.dim_customer CU ON sd.sls_cust_id =cu.customer_id
	LEFT JOIN Gold.Dim_Products pr ON sd.sls_prd_key = pr.product_number

