# Inventory and Demand Analysis Dashboard — Project Scope

## Objective

Analyse daily retail sales and stock-on-hand data to identify demand trends, stockout exposure, slow-moving and excess inventory, store-level inventory imbalances, and opportunities to improve replenishment decisions.

## Stakeholders

- Inventory Manager
- Supply Chain Manager
- Procurement Manager
- Store Operations Manager
- Category Manager

## Key Business Questions

1. How is product demand changing over time?
2. Which stores, categories, and SKUs generate the greatest demand?
3. Which products experience frequent or prolonged stockouts?
4. Which products have excess inventory relative to demand?
5. Which products are slow-moving or non-moving?
6. How many days of stock cover are available?
7. Which stores or products should be prioritised for replenishment?
8. Where could inventory be reallocated between stores?
9. How variable and predictable is demand by product?
10. Where might stock unavailability be suppressing observed sales?

## Planned KPIs

- Units sold
- Average daily demand
- Current stock on hand
- Average stock on hand
- Stockout days
- Stockout rate
- Days of stock cover
- Sell-through rate
- Inventory turnover proxy
- Slow-moving SKUs
- Non-moving SKUs
- At-risk SKUs
- Excess-stock SKUs
- Reorder candidates

Final KPI definitions will depend on the available fields and will document any assumptions.

## Dataset

Retail Transactions and Stocks Data, published through Mendeley Data under a CC BY 4.0 licence.

Source: https://data.mendeley.com/datasets/27x8mjm8k4/1

Expected files:

- `retail_sales_ml_apl.csv`
- `retail_inventory_ml_apl.csv`

The dataset contains daily sales and stock-on-hand records across 40 retail stores, 2,326 SKUs, and a four-level product hierarchy.

## Tools

- Power Query for repeatable data cleaning and transformation
- PostgreSQL and SQL for storage, validation, and operational analysis
- Python for exploratory analysis, ABC–XYZ classification, demand forecasting, and inventory recommendations
- Power BI and DAX for semantic modelling and interactive dashboards
- Git and GitHub for version control and portfolio presentation

## Python Analysis

Python will be used after SQL validation for:

1. Exploratory demand analysis
2. ABC classification by demand contribution
3. XYZ classification by demand variability
4. Baseline moving-average forecasts
5. Forecast evaluation using MAE, RMSE, WAPE, and bias
6. Stockout and potential lost-demand analysis where supported
7. Replenishment recommendations with clearly documented assumptions

## Planned Dashboard Pages

1. Inventory Overview
2. Product and Category Analysis
3. Store and Replenishment Analysis
4. Demand Trends and Forecasting

## Limitations and Controls

- Financial inventory value will not be calculated without a reliable unit-cost field.
- Reorder points and safety stock will not be presented as factual unless lead-time and service-level inputs are available.
- Any assumed lead times or service levels will be labelled as scenario assumptions.
- Observed sales will not automatically be treated as true demand during stockout periods.
- Forecasts will be evaluated against a baseline and reported with error metrics.
