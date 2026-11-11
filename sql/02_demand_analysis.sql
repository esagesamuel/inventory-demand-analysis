SELECT
    MIN(transaction_date) AS start_date,
    MAX(transaction_date) AS end_date,
    COUNT(*) AS sales_lines,

    COUNT(DISTINCT product_no)
        AS products,

    COUNT(DISTINCT store_id)
        AS stores,

    SUM(quantity_sold)
        FILTER (WHERE transaction_type = 'Sale')
        AS gross_units_sold,

    ABS(
        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Return')
    ) AS returned_units,

    SUM(quantity_sold) AS net_units_sold,

    ROUND(
        SUM(sales_amount)
            FILTER (WHERE transaction_type = 'Sale'),
        2
    ) AS gross_sales,

    ROUND(
        ABS(
            SUM(sales_amount)
                FILTER (WHERE transaction_type = 'Return')
        ),
        2
    ) AS returned_sales_value,

    ROUND(SUM(sales_amount), 2)
        AS net_sales,

    ROUND(SUM(gross_profit), 2)
        AS net_gross_profit

FROM inventory.sales_clean;

--Monthly demand trend
SELECT
    sales_month_start,
    sales_year_month,
    SUM(quantity_sold)
        FILTER (WHERE transaction_type = 'Sale')
        AS gross_units_sold,

    ABS(
        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Return')
    ) AS returned_units,

    SUM(quantity_sold) AS net_units_sold,

    ROUND(
        SUM(sales_amount)
            FILTER (WHERE transaction_type = 'Sale'),
        2
    ) AS gross_sales,

    ROUND(SUM(sales_amount), 2)
        AS net_sales,

    ROUND(SUM(gross_profit), 2)
        AS gross_profit

FROM inventory.sales_clean
GROUP BY
    sales_month_start,
    sales_year_month,
    year_month_sort
ORDER BY year_month_sort;

--Monthly growth rates
WITH monthly_demand AS (
    SELECT
        sales_month_start,
        SUM(quantity_sold) AS net_units_sold,
        SUM(sales_amount) AS net_sales
    FROM inventory.sales_clean
    GROUP BY sales_month_start
),
monthly_comparison AS (
    SELECT
        sales_month_start,
        net_units_sold,
        net_sales,
        LAG(net_units_sold) OVER (
            ORDER BY sales_month_start
        ) AS previous_month_units,
        LAG(net_sales) OVER (
            ORDER BY sales_month_start
        ) AS previous_month_sales
    FROM monthly_demand
)
SELECT
    sales_month_start,
    net_units_sold,
    ROUND(net_sales, 2) AS net_sales,

    ROUND(
        100.0 * (net_units_sold - previous_month_units)
        / NULLIF(previous_month_units, 0),
        2
    ) AS unit_growth_pct,

    ROUND(
        100.0 * (net_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2
    ) AS sales_growth_pct

FROM monthly_comparison
ORDER BY sales_month_start;

--Demand by product
SELECT
    product_no,
    product_description,
    product_division,
    product_category,
    product_subcategory,
    product_segment,

    SUM(quantity_sold)
        FILTER (WHERE transaction_type = 'Sale')
        AS gross_units_sold,

    ABS(
        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Return')
    ) AS returned_units,

    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit

FROM inventory.sales_clean
GROUP BY
    product_no,
    product_description,
    product_division,
    product_category,
    product_subcategory,
    product_segment
ORDER BY net_units_sold DESC;

--Top 20 products by demand
SELECT
    product_no,
    product_description,
    product_category,
    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM inventory.sales_clean
GROUP BY
    product_no,
    product_description,
    product_category
HAVING SUM(quantity_sold) > 0
ORDER BY net_units_sold DESC
LIMIT 20;

--Bottom 20 products with sales activity
SELECT
    product_no,
    product_description,
    product_category,
    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM inventory.sales_clean
GROUP BY
    product_no,
    product_description,
    product_category
HAVING SUM(quantity_sold) > 0
ORDER BY net_units_sold
LIMIT 20;

--Category demand analysis
SELECT
    product_division,
    product_category,
    product_subcategory,
    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit,

    ROUND(
        100.0 * SUM(gross_profit)
        / NULLIF(SUM(sales_amount), 0),
        2
    ) AS gross_margin_pct

FROM inventory.sales_clean
GROUP BY
    product_division,
    product_category,
    product_subcategory
ORDER BY net_sales DESC;

--Store demand analysis
SELECT
    store_id,
    COUNT(DISTINCT product_no) AS products_sold,
    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit
FROM inventory.sales_clean
GROUP BY store_id
ORDER BY net_sales DESC;

--Sales channel analysis
SELECT
    sales_channel,
    SUM(quantity_sold) AS net_units_sold,
    ROUND(SUM(sales_amount), 2) AS net_sales,
    ROUND(SUM(gross_profit), 2) AS gross_profit,

    ROUND(
        100.0 * SUM(sales_amount)
        / NULLIF(
            SUM(SUM(sales_amount)) OVER (),
            0
        ),
        2
    ) AS sales_contribution_pct

FROM inventory.sales_clean
GROUP BY sales_channel
ORDER BY net_sales DESC;

--Return-rate analysis
SELECT
    product_category,

    SUM(quantity_sold)
        FILTER (WHERE transaction_type = 'Sale')
        AS units_sold,

    ABS(
        SUM(quantity_sold)
            FILTER (WHERE transaction_type = 'Return')
    ) AS units_returned,

    ROUND(
        100.0
        * ABS(
            SUM(quantity_sold)
                FILTER (WHERE transaction_type = 'Return')
        )
        / NULLIF(
            SUM(quantity_sold)
                FILTER (WHERE transaction_type = 'Sale'),
            0
        ),
        2
    ) AS return_rate_pct

FROM inventory.sales_clean
GROUP BY product_category
ORDER BY return_rate_pct DESC NULLS LAST;

