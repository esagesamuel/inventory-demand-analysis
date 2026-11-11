--Inventory period overview
SELECT
    MIN(start_date) AS earliest_start_date,
    MAX(end_date) AS latest_end_date,
    COUNT(*) AS inventory_records,
    COUNT(DISTINCT product_no) AS products,
    COUNT(DISTINCT store_id) AS stores,
    COUNT(DISTINCT product_store_key) AS product_store_combinations,
    SUM(stockout_days) AS recorded_stockout_days,
    ROUND(SUM(stock_cost_value), 2) AS historical_stock_cost_value
FROM inventory.inventory_clean;

CREATE OR REPLACE VIEW inventory.latest_inventory AS
WITH ranked_inventory AS (
    SELECT
        i.*,
        ROW_NUMBER() OVER (
            PARTITION BY product_store_key
            ORDER BY
                end_date DESC,
                start_date DESC,
                inventory_row_id DESC
        ) AS inventory_rank
    FROM inventory.inventory_clean AS i
)
SELECT
    inventory_row_id,
    start_date,
    end_date,
    inventory_year,
    inventory_quarter,
    inventory_month_number,
    inventory_month,
    inventory_week,
    inventory_day,
    inventory_month_start,
    inventory_week_start,
    inventory_year_month,
    inventory_year_month_sort,
    inventory_period_days,
    stock_status,
    availability_status,
    stockout_days,
    supplier,
    product_no,
    product_description,
    product_division,
    product_category,
    product_subcategory,
    product_segment,
    store_id,
    store_type,
    sales_channel,
    quantity_on_hand,
    stock_selling_value,
    stock_cost_value,
    unit_selling_price,
    unit_cost_price,
    product_store_key
FROM ranked_inventory
WHERE inventory_rank = 1;

select count(*) as latest_product_store_records
from inventory.latest_inventory

--Latest inventory KPIs
SELECT
    MAX(end_date) AS latest_inventory_date,
    COUNT(*) AS product_store_records,
    COUNT(DISTINCT product_no) AS products,
    COUNT(DISTINCT store_id) AS stores,
    SUM(quantity_on_hand) AS units_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS inventory_cost_value,
    ROUND(SUM(stock_selling_value), 2) AS inventory_retail_value,

    COUNT(*) FILTER (
        WHERE quantity_on_hand <= 0
    ) AS out_of_stock_product_store_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE quantity_on_hand <= 0
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS current_stockout_rate_pct

FROM inventory.latest_inventory;

--Inventory stock status
SELECT
    stock_status,
    COUNT(*) AS product_store_records,
    SUM(quantity_on_hand) AS units_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS inventory_cost_value,
    ROUND(SUM(stock_selling_value), 2) AS inventory_retail_value
FROM inventory.latest_inventory
GROUP BY stock_status
ORDER BY inventory_cost_value DESC;

--Inventory by category
SELECT
    product_division,
    product_category,
    product_subcategory,
    COUNT(DISTINCT product_no) AS products,
    SUM(quantity_on_hand) AS units_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS inventory_cost_value,
    ROUND(SUM(stock_selling_value), 2) AS inventory_retail_value,

    COUNT(*) FILTER (
        WHERE quantity_on_hand <= 0
    ) AS out_of_stock_records

FROM inventory.latest_inventory
GROUP BY
    product_division,
    product_category,
    product_subcategory
ORDER BY inventory_cost_value DESC;

--Inventory by store
SELECT
    store_id,
    store_type,
    COUNT(DISTINCT product_no) AS stocked_products,
    SUM(quantity_on_hand) AS units_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS inventory_cost_value,

    COUNT(*) FILTER (
        WHERE quantity_on_hand <= 0
    ) AS out_of_stock_products,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE quantity_on_hand <= 0
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS stockout_rate_pct

FROM inventory.latest_inventory
GROUP BY
    store_id,
    store_type
ORDER BY stockout_rate_pct DESC, inventory_cost_value DESC;

--Historical stockout exposure
--Calculates the proportion of observed inventory days recorded as out of stock
SELECT
    store_id,
    SUM(inventory_period_days) AS observed_inventory_days,
    SUM(stockout_days) AS stockout_days,

    ROUND(
        100.0 * SUM(stockout_days)
        / NULLIF(SUM(inventory_period_days), 0),
        2
    ) AS stockout_day_rate_pct

FROM inventory.inventory_clean
GROUP BY store_id
ORDER BY stockout_day_rate_pct DESC;

--Product level stockout exposure
SELECT
    product_no,
    product_description,
    product_category,
    SUM(inventory_period_days) AS observed_inventory_days,
    SUM(stockout_days) AS stockout_days,

    ROUND(
        100.0 * SUM(stockout_days)
        / NULLIF(SUM(inventory_period_days), 0),
        2
    ) AS stockout_day_rate_pct

FROM inventory.inventory_clean
GROUP BY
    product_no,
    product_description,
    product_category
HAVING SUM(stockout_days) > 0
ORDER BY stockout_days DESC, stockout_day_rate_pct DESC;

--Product store demand and inventory position
WITH sales_period AS (
    SELECT
        GREATEST(
            MAX(transaction_date) - MIN(transaction_date) + 1,
            1
        ) AS analysis_days
    FROM inventory.sales_clean
),
product_store_demand AS (
    SELECT
        product_store_key,
        SUM(quantity_sold) AS net_units_sold,
        ROUND(SUM(sales_amount), 2) AS net_sales,
        ROUND(SUM(gross_profit), 2) AS gross_profit
    FROM inventory.sales_clean
    GROUP BY product_store_key
)
SELECT
    i.product_store_key,
    i.product_no,
    i.product_description,
    i.product_category,
    i.store_id,
    i.quantity_on_hand,
    i.stock_cost_value,

    COALESCE(d.net_units_sold, 0)
        AS net_units_sold,

    COALESCE(d.net_sales, 0)
        AS net_sales,

    ROUND(
        COALESCE(d.net_units_sold, 0)::NUMERIC
        / p.analysis_days,
        4
    ) AS average_daily_demand,

    ROUND(
        i.quantity_on_hand
        / NULLIF(
            COALESCE(d.net_units_sold, 0)::NUMERIC
            / p.analysis_days,
            0
        ),
        2
    ) AS estimated_days_of_supply

FROM inventory.latest_inventory AS i
LEFT JOIN product_store_demand AS d
    ON i.product_store_key = d.product_store_key
CROSS JOIN sales_period AS p
ORDER BY estimated_days_of_supply NULLS LAST;

--Out of stock items with positive demand
WITH product_store_demand AS (
    SELECT
        product_store_key,
        SUM(quantity_sold) AS net_units_sold,
        ROUND(SUM(sales_amount), 2) AS net_sales
    FROM inventory.sales_clean
    GROUP BY product_store_key
)
SELECT
    i.product_no,
    i.product_description,
    i.product_category,
    i.store_id,
    i.quantity_on_hand,
    d.net_units_sold,
    d.net_sales
FROM inventory.latest_inventory AS i
JOIN product_store_demand AS d
    ON i.product_store_key = d.product_store_key
WHERE i.quantity_on_hand <= 0
  AND d.net_units_sold > 0
ORDER BY d.net_units_sold DESC;

--Inventory with no reocorded net demand
WITH product_store_demand AS (
    SELECT
        product_store_key,
        SUM(quantity_sold) AS net_units_sold,
        SUM(sales_amount) AS net_sales
    FROM inventory.sales_clean
    GROUP BY product_store_key
)
SELECT
    i.product_no,
    i.product_description,
    i.product_category,
    i.store_id,
    i.quantity_on_hand,
    ROUND(i.stock_cost_value, 2) AS stock_cost_value,
    COALESCE(d.net_units_sold, 0) AS net_units_sold
FROM inventory.latest_inventory AS i
LEFT JOIN product_store_demand AS d
    ON i.product_store_key = d.product_store_key
WHERE i.quantity_on_hand > 0
  AND COALESCE(d.net_units_sold, 0) <= 0
ORDER BY i.stock_cost_value DESC;

--Sell through indicator
WITH product_store_demand AS (
    SELECT
        product_store_key,
        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Sale')
            AS gross_units_sold
    FROM inventory.sales_clean
    GROUP BY product_store_key
)
SELECT
    i.product_no,
    i.product_description,
    i.product_category,
    i.store_id,
    COALESCE(d.gross_units_sold, 0) AS gross_units_sold,
    i.quantity_on_hand,

    ROUND(
        100.0 * COALESCE(d.gross_units_sold, 0)
        / NULLIF(
            COALESCE(d.gross_units_sold, 0)
            + GREATEST(i.quantity_on_hand, 0),
            0
        ),
        2
    ) AS sell_through_indicator_pct

FROM inventory.latest_inventory AS i
LEFT JOIN product_store_demand AS d
    ON i.product_store_key = d.product_store_key
ORDER BY sell_through_indicator_pct DESC NULLS LAST;

--Preliminary replenishment classification
WITH sales_period AS (
    SELECT
        GREATEST(
            MAX(transaction_date) - MIN(transaction_date) + 1,
            1
        ) AS analysis_days
    FROM inventory.sales_clean
),
product_store_demand AS (
    SELECT
        product_store_key,
        SUM(quantity_sold) AS net_units_sold
    FROM inventory.sales_clean
    GROUP BY product_store_key
),
inventory_demand AS (
    SELECT
        i.*,
        COALESCE(d.net_units_sold, 0) AS net_units_sold,

        COALESCE(d.net_units_sold, 0)::NUMERIC
        / p.analysis_days AS average_daily_demand

    FROM inventory.latest_inventory AS i
    LEFT JOIN product_store_demand AS d
        ON i.product_store_key = d.product_store_key
    CROSS JOIN sales_period AS p
)
SELECT
    product_no,
    product_description,
    product_category,
    store_id,
    quantity_on_hand,
    net_units_sold,
    ROUND(average_daily_demand, 4)
        AS average_daily_demand,

    ROUND(
        quantity_on_hand
        / NULLIF(average_daily_demand, 0),
        2
    ) AS estimated_days_of_supply,

    CASE
        WHEN quantity_on_hand <= 0
             AND net_units_sold > 0
            THEN 'Urgent Replenishment'

        WHEN average_daily_demand > 0
             AND quantity_on_hand / average_daily_demand < 14
            THEN 'Replenish Soon'

        WHEN average_daily_demand > 0
             AND quantity_on_hand / average_daily_demand > 90
            THEN 'Possible Excess Stock'

        WHEN quantity_on_hand > 0
             AND net_units_sold <= 0
            THEN 'Non-Moving Stock'

        ELSE 'Adequate Stock'
    END AS replenishment_status

FROM inventory_demand
ORDER BY
    CASE
        WHEN quantity_on_hand <= 0
             AND net_units_sold > 0 THEN 1
        WHEN average_daily_demand > 0
             AND quantity_on_hand / average_daily_demand < 14 THEN 2
        WHEN average_daily_demand > 0
             AND quantity_on_hand / average_daily_demand > 90 THEN 3
        WHEN quantity_on_hand > 0
             AND net_units_sold <= 0 THEN 4
        ELSE 5
    END,
    net_units_sold DESC;