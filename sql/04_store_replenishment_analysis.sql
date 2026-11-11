CREATE OR REPLACE VIEW inventory.product_store_metrics AS
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

        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Sale')
            AS gross_units_sold,

        ABS(
            SUM(quantity_sold)
                FILTER (WHERE transaction_type = 'Return')
        ) AS returned_units,

        SUM(quantity_sold) AS net_units_sold,
        SUM(sales_amount) AS net_sales,
        SUM(gross_profit) AS gross_profit

    FROM inventory.sales_clean
    GROUP BY product_store_key
),
combined_data AS (
    SELECT
        i.product_store_key,
        i.product_no,
        i.product_description,
        i.product_division,
        i.product_category,
        i.product_subcategory,
        i.product_segment,
        i.supplier,
        i.store_id,
        i.store_type,
        i.sales_channel,
        i.end_date AS inventory_date,
        i.stock_status,
        i.availability_status,
        i.quantity_on_hand,
        i.stock_cost_value,
        i.stock_selling_value,
        i.unit_cost_price,
        i.unit_selling_price,

        COALESCE(d.gross_units_sold, 0)
            AS gross_units_sold,

        COALESCE(d.returned_units, 0)
            AS returned_units,

        COALESCE(d.net_units_sold, 0)
            AS net_units_sold,

        COALESCE(d.net_sales, 0)
            AS net_sales,

        COALESCE(d.gross_profit, 0)
            AS gross_profit,

        COALESCE(d.net_units_sold, 0)::NUMERIC
            / p.analysis_days AS average_daily_demand

    FROM inventory.latest_inventory AS i
    LEFT JOIN product_store_demand AS d
        ON i.product_store_key = d.product_store_key
    CROSS JOIN sales_period AS p
)
SELECT
    *,
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

FROM combined_data;

SELECT COUNT(*) AS product_store_metrics_rows
FROM inventory.product_store_metrics;

SELECT COUNT(*)
FROM inventory.latest_inventory;

--Replenishment status summary
SELECT
    replenishment_status,
    COUNT(*) AS product_store_records,
    COUNT(DISTINCT product_no) AS products,
    COUNT(DISTINCT store_id) AS stores,
    SUM(quantity_on_hand) AS units_on_hand,
    ROUND(SUM(stock_cost_value), 2) AS stock_cost_value,
    ROUND(SUM(net_sales), 2) AS net_sales
FROM inventory.product_store_metrics
GROUP BY replenishment_status
ORDER BY
    CASE replenishment_status
        WHEN 'Urgent Replenishment' THEN 1
        WHEN 'Replenish Soon' THEN 2
        WHEN 'Possible Excess Stock' THEN 3
        WHEN 'Non-Moving Stock' THEN 4
        ELSE 5
    END;

--Urgent replenishment priorities
SELECT
    product_no,
    product_description,
    product_category,
    supplier,
    store_id,
    quantity_on_hand,
    net_units_sold,
    ROUND(average_daily_demand, 4)
        AS average_daily_demand,
    estimated_days_of_supply,
    ROUND(net_sales, 2) AS net_sales,
    replenishment_status
FROM inventory.product_store_metrics
WHERE replenishment_status IN (
    'Urgent Replenishment',
    'Replenish Soon'
)
ORDER BY
    CASE replenishment_status
        WHEN 'Urgent Replenishment' THEN 1
        ELSE 2
    END,
    average_daily_demand DESC;

--Possible excess and non-moving inventory
SELECT
    product_no,
    product_description,
    product_category,
    supplier,
    store_id,
    quantity_on_hand,
    ROUND(stock_cost_value, 2) AS stock_cost_value,
    net_units_sold,
    estimated_days_of_supply,
    replenishment_status
FROM inventory.product_store_metrics
WHERE replenishment_status IN (
    'Possible Excess Stock',
    'Non-Moving Stock'
)
ORDER BY stock_cost_value DESC;

--Identify store-transfer opportunities
--This finds the same product in a store needing stock and another store with possible excess stock.
WITH stores_needing_stock AS (
    SELECT
        product_no,
        product_description,
        product_category,
        store_id AS destination_store,
        quantity_on_hand AS destination_stock,
        average_daily_demand AS destination_daily_demand,
        replenishment_status AS destination_status
    FROM inventory.product_store_metrics
    WHERE replenishment_status IN (
        'Urgent Replenishment',
        'Replenish Soon'
    )
),
stores_with_excess AS (
    SELECT
        product_no,
        store_id AS source_store,
        quantity_on_hand AS source_stock,
        average_daily_demand AS source_daily_demand,
        estimated_days_of_supply AS source_days_of_supply,
        stock_cost_value AS source_stock_cost_value,
        replenishment_status AS source_status
    FROM inventory.product_store_metrics
    WHERE replenishment_status IN (
        'Possible Excess Stock',
        'Non-Moving Stock'
    )
),
transfer_candidates AS (
    SELECT
        n.product_no,
        n.product_description,
        n.product_category,
        e.source_store,
        e.source_stock,
        e.source_days_of_supply,
        n.destination_store,
        n.destination_stock,
        ROUND(n.destination_daily_demand, 4)
            AS destination_daily_demand,
        n.destination_status,
        e.source_status,

        ROW_NUMBER() OVER (
            PARTITION BY
                n.product_no,
                n.destination_store
            ORDER BY
                e.source_stock DESC,
                e.source_stock_cost_value DESC
        ) AS source_rank

    FROM stores_needing_stock AS n
    JOIN stores_with_excess AS e
        ON n.product_no = e.product_no
       AND n.destination_store <> e.source_store
)
SELECT
    product_no,
    product_description,
    product_category,
    source_store,
    source_stock,
    source_days_of_supply,
    destination_store,
    destination_stock,
    destination_daily_demand,
    destination_status,
    source_status
FROM transfer_candidates
WHERE source_rank = 1
ORDER BY
    CASE destination_status
        WHEN 'Urgent Replenishment' THEN 1
        ELSE 2
    END,
    destination_daily_demand DESC;
    
--Supplier exposure
SELECT
    supplier,
    COUNT(DISTINCT product_no) AS supplied_products,

    COUNT(*) FILTER (
        WHERE replenishment_status = 'Urgent Replenishment'
    ) AS urgent_replenishment_records,

    COUNT(*) FILTER (
        WHERE replenishment_status = 'Replenish Soon'
    ) AS replenish_soon_records,

    COUNT(*) FILTER (
        WHERE replenishment_status = 'Possible Excess Stock'
    ) AS possible_excess_records,

    ROUND(SUM(stock_cost_value), 2)
        AS inventory_cost_value,

    ROUND(SUM(net_sales), 2)
        AS net_sales

FROM inventory.product_store_metrics
GROUP BY supplier
ORDER BY urgent_replenishment_records DESC,
         replenish_soon_records DESC;

SELECT *
FROM inventory.product_store_metrics
ORDER BY product_no, store_id;