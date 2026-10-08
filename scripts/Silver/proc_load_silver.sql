/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
--EXEC Silver.load_silver;

CREATE OR ALTER PROCEDURE Silver.load_silver
AS
BEGIN
	DECLARE @START_TIME DATETIME,@end_time DATETIME , @batch_start_time DATETIME,@batch_end_time DATETIME;
	BEGIN TRY 
		SET @batch_start_time=GETDATE();
		PRINT '============================================='
		PRINT 'Loading Silver Layer';
		PRINT '============================================='

		PRINT '============================================='
		PRINT 'Loading CRM Tables';
		PRINT '============================================='

		--Loading Silver.crm_cust_info
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table: Silver.crm_cust_info';
		TRUNCATE TABLE Silver.crm_cust_info;
		PRINT '>> Inserting Data Into: Silver.crm_cust_info';
		INSERT INTO Silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END AS cst_marital_status,
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END AS cst_gndr,
			cst_create_date
		FROM (
			SELECT *,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM Bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) t
		WHERE flag_last = 1;

		SET @end_time=GETDATE();
		PRINT'>>Load Duration'+CAST(DATEDIFF (SECOND,@start_time,@end_time) AS NVARCHAR) +'seconds'
		PRINT'------------------------------------------------------------------------------------'

		--Loading Silver.crm_prd_info
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table: Silver.crm_prd_info';
		TRUNCATE TABLE Silver.crm_prd_info;
		PRINT '>> Inserting Data Into: Silver.crm_prd_info';
		INSERT INTO Silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extract category ID
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,         -- Extract product key
			prd_nm,
			COALESCE(prd_cost, '0') AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'N/A'
			END AS prd_line, -- Map product line to description values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(
				DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt))
				AS DATE
			) AS prd_end_dt -- calculate end date as one day before the next start date
		FROM Bronze.crm_prd_info;
		SET @end_time=GETDATE();
		PRINT'>>Load Duration'+CAST(DATEDIFF (SECOND,@start_time,@end_time) AS NVARCHAR) +'seconds'
		PRINT'------------------------------------------------------------------------------------'

		--Loading Silver.crm_sales_details;
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table: Silver.crm_sales_details';
		TRUNCATE TABLE Silver.crm_sales_details;
		PRINT '>> Inserting Data Into: Silver.crm_sales_details';
		INSERT INTO Silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(CONVERT(varchar(20), sls_order_dt)) <> 8 THEN NULL
				ELSE TRY_CONVERT(date, CONVERT(varchar(8), sls_order_dt), 112)
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(CONVERT(varchar(20), sls_ship_dt)) <> 8 THEN NULL
				ELSE TRY_CONVERT(date, CONVERT(varchar(8), sls_ship_dt), 112)
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(CONVERT(varchar(20), sls_due_dt)) <> 8 THEN NULL
				ELSE TRY_CONVERT(date, CONVERT(varchar(8), sls_due_dt), 112)
			END AS sls_due_dt,
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE 
				WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS sls_price
		FROM Bronze.crm_sales_details;
		SET @end_time=GETDATE();
		PRINT'>>Load Duration'+CAST(DATEDIFF (SECOND,@start_time,@end_time) AS NVARCHAR) +'seconds'
		PRINT'------------------------------------------------------------------------------------'
		PRINT '>> Truncating Table: Silver.erp_CUST_AZ12';
		TRUNCATE TABLE Silver.erp_CUST_AZ12;

		--Loading Silver.erp_CUST_AZ12
		SET @start_time=GETDATE();
		PRINT '>> Inserting Data Into: Silver.erp_CUST_AZ12';
		INSERT INTO Silver.erp_CUST_AZ12(
			cid,
			bdate,
			gen
		)
		SELECT
			CASE 
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
				ELSE CID
			END AS cid,
			CASE 
				WHEN BDATE > GETDATE() THEN NULL
				ELSE BDATE
			END AS bdate,
			CASE 
				WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen
		FROM Bronze.erp_CUST_AZ12;

		PRINT '>> Truncating Table: Silver.erp_Loc_A101';
		TRUNCATE TABLE Silver.erp_Loc_A101;

		PRINT '>> Inserting Data Into: Silver.erp_Loc_A101';
		INSERT INTO Silver.erp_Loc_A101(
			cid,
			cntry
		)
		SELECT 
			REPLACE(CID, '-', '') AS cid,
			CASE 
				WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
				ELSE TRIM(CNTRY)
			END AS cntry
		FROM Bronze.erp_Loc_A101;
		SET @end_time=GETDATE();
		PRINT'>>Load Duration'+CAST(DATEDIFF (SECOND,@start_time,@end_time) AS NVARCHAR) +'seconds'
		PRINT'------------------------------------------------------------------------------------'

		--Loading Silver.erp_PX_CAT_G1V2;
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table: Silver.erp_PX_CAT_G1V2';
		TRUNCATE TABLE Silver.erp_PX_CAT_G1V2;
		PRINT '>> Inserting Data Into: Silver.erp_PX_CAT_G1V2';
		INSERT INTO Silver.erp_PX_CAT_G1V2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			ID,
			CAT,
			SUBCAT,
			MAINTENANCE
		FROM Bronze.erp_PX_CAT_G1V2;
		SET @end_time=GETDATE();
		PRINT'>>Load Duration'+CAST(DATEDIFF (SECOND,@start_time,@end_time) AS NVARCHAR) +'seconds'
		PRINT'------------------------------------------------------------------------------------'

		SET @batch_end_time=GETDATE();
		PRINT '====================================================================================================='
		PRINT 'Loading Silver Layers Is Completed';
		PRINT 'Total Load Duration'+CAST(DATEDIFF (SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) +'seconds'
		PRINT '====================================================================================================='
		END TRY
		BEGIN CATCH
			PRINT '================================================='
			PRINT 'ERROR OCCURED LOADING BRONZE LAYER'
			PRINT 'ERROR MESSAGE'+ERROR_MESSAGE();
			PRINT 'ERROR MESSAGE'+CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'ERROR MESSAGE'+CAST (ERROR_STATE () AS NVARCHAR);
			PRINT '================================================='
		END CATCH
END
