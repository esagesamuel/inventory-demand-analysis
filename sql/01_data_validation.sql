-- =========================================================
-- Project: Inventory and Demand Analysis
-- Script: 01_data_validation.sql
-- Purpose: Validate the sales and inventory imports
-- =========================================================


-- 1. Imported row counts
SELECT
    (SELECT COUNT(*) FROM inventory.sales_clean)
        AS sales_rows,
    (SELECT COUNT(*) FROM inventory.inventory_clean)
        AS inventory_rows;


-- 2. Sales date range
SELECT
    MIN(transaction_date) AS earliest_sales_date,
    MAX(transaction_date) AS latest_sales_date,
    COUNT(DISTINCT transaction_date) AS sales_days
FROM inventory.sales_clean;


-- 3. Inventory date range
SELECT
    MIN(start_date) AS earliest_inventory_start,
    MAX(end_date) AS latest_inventory_end,
    COUNT(DISTINCT start_date) AS inventory_start_dates
FROM inventory.inventory_clean;


-- 4. Duplicate sales row IDs
SELECT
    sales_row_id,
    COUNT(*) AS duplicate_count
FROM inventory.sales_clean
GROUP BY sales_row_id
HAVING COUNT(*) > 1;


-- 5. Duplicate inventory row IDs
SELECT
    inventory_row_id,
    COUNT(*) AS duplicate_count
FROM inventory.inventory_clean
GROUP BY inventory_row_id
HAVING COUNT(*) > 1;


-- 6. Missing critical sales values
SELECT
    COUNT(*) FILTER (WHERE transaction_date IS NULL)
        AS missing_transaction_dates,
    COUNT(*) FILTER (WHERE product_no IS NULL OR TRIM(product_no) = '')
        AS missing_product_numbers,
    COUNT(*) FILTER (WHERE store_id IS NULL OR TRIM(store_id) = '')
        AS missing_store_ids,
    COUNT(*) FILTER (WHERE quantity_sold IS NULL)
        AS missing_quantities,
    COUNT(*) FILTER (WHERE sales_amount IS NULL)
        AS missing_sales_amounts
FROM inventory.sales_clean;


-- 7. Missing critical inventory values
SELECT
    COUNT(*) FILTER (WHERE start_date IS NULL)
        AS missing_start_dates,
    COUNT(*) FILTER (WHERE end_date IS NULL)
        AS missing_end_dates,
    COUNT(*) FILTER (WHERE product_no IS NULL OR TRIM(product_no) = '')
        AS missing_product_numbers,
    COUNT(*) FILTER (WHERE store_id IS NULL OR TRIM(store_id) = '')
        AS missing_store_ids,
    COUNT(*) FILTER (WHERE quantity_on_hand IS NULL)
        AS missing_stock_quantities
FROM inventory.inventory_clean;


-- 8. Invalid inventory periods
SELECT
    COUNT(*) AS invalid_inventory_periods
FROM inventory.inventory_clean
WHERE end_date < start_date
   OR inventory_period_days <= 0;


-- 9. Sales and return summary
SELECT
    transaction_type,
    COUNT(*) AS line_count,
    SUM(quantity_sold) AS net_quantity,
    ROUND(SUM(sales_amount), 2) AS sales_value,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM inventory.sales_clean
GROUP BY transaction_type
ORDER BY transaction_type;


-- 10. Inventory availability summary
SELECT
    availability_status,
    COUNT(*) AS record_count,
    SUM(quantity_on_hand) AS quantity_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS stock_cost_value,
    SUM(stockout_days) AS stockout_days
FROM inventory.inventory_clean
GROUP BY availability_status
ORDER BY availability_status;


-- 11. Distinct business entities
SELECT
    (SELECT COUNT(DISTINCT product_no)
     FROM inventory.sales_clean) AS sales_products,

    (SELECT COUNT(DISTINCT product_no)
     FROM inventory.inventory_clean) AS inventory_products,

    (SELECT COUNT(DISTINCT store_id)
     FROM inventory.sales_clean) AS sales_stores,

    (SELECT COUNT(DISTINCT store_id)
     FROM inventory.inventory_clean) AS inventory_stores;


-- 12. Products in sales but missing from inventory
SELECT COUNT(*) AS sales_products_missing_from_inventory
FROM (
    SELECT DISTINCT product_no
    FROM inventory.sales_clean

    EXCEPT

    SELECT DISTINCT product_no
    FROM inventory.inventory_clean
) AS missing_products;


-- 13. Products in inventory but missing from sales
SELECT COUNT(*) AS inventory_products_without_sales
FROM (
    SELECT DISTINCT product_no
    FROM inventory.inventory_clean

    EXCEPT

    SELECT DISTINCT product_no
    FROM inventory.sales_clean
) AS missing_products;


-- 14. Product-store keys in sales but missing from inventory
SELECT COUNT(*) AS sales_keys_missing_from_inventory
FROM (
    SELECT DISTINCT product_store_key
    FROM inventory.sales_clean
    WHERE product_store_key IS NOT NULL

    EXCEPT

    SELECT DISTINCT product_store_key
    FROM inventory.inventory_clean
    WHERE product_store_key IS NOT NULL
) AS missing_keys;


-- 15. Product-store keys in inventory but missing from sales
SELECT COUNT(*) AS inventory_keys_without_sales
FROM (
    SELECT DISTINCT product_store_key
    FROM inventory.inventory_clean
    WHERE product_store_key IS NOT NULL

    EXCEPT

    SELECT DISTINCT product_store_key
    FROM inventory.sales_clean
    WHERE product_store_key IS NOT NULL
) AS missing_keys;