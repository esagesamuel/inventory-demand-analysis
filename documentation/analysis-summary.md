# Inventory and Demand Analysis — Findings

## Executive Summary

This project analysed 125,751 sales records and 284,755 inventory records across 2,326 products and 40 stores. The analysis combined Power Query, PostgreSQL, SQL, Python and Power BI to evaluate sales demand, stock availability, ABC–XYZ product priorities, forecasting performance and replenishment opportunities.

The business generated **10,482,110.25 currency units in net sales**, **116,995 net units sold** and **4,634,359.16 in gross profit**, equivalent to a **44.21% gross margin**. The latest product-store snapshot contained **75,628 units on hand** with a cost value of **3,745,076.04** and a retail value of **7,404,355.15**. However, **9,109 of 60,968 product-store records were out of stock**, producing a current stockout rate of **14.94%**.

Product concentration and volatility are both material. Class A contained 928 products and contributed 79.99% of net sales, while the largest combined segment was AZ, with 583 high-value but volatile products. The forecasting proof of concept covered the top 20 Class A products. Its average WAPE was 84.83%, showing that the pilot forecasts require further refinement before operational deployment.

## Dataset Overview

- Sales records: **125,751**
- Inventory records: **284,755**
- Latest product-store snapshot records: **60,968**
- Sales and inventory activity period: **1 June 2025 to 24 April 2026**
- Distinct products: **2,326**
- Distinct stores: **40**
- Product-store combinations in the latest snapshot: **60,968**

## Sales and Demand Findings

- Gross sales: **11,215,681.26 currency units**
- Returned sales value: **733,571.01 currency units**
- Net sales: **10,482,110.25 currency units**
- Gross units sold: **124,542**
- Returned units: **7,547**
- Net units sold: **116,995**
- Unit return rate: **6.06%**
- Net gross profit: **4,634,359.16 currency units**
- Gross margin: **44.21%**
- Highest-sales month: **December 2025**, with **1,785,534.95** in net sales and **18,717** net units
- Highest-demand product: **PROD-100805**, with **1,170** net units and **102,481.99** in net sales
- Highest-revenue product: **PROD-140871**, with **104,027.50** in net sales and **915** net units
- Highest-revenue category: **Scholar Footwear Retro Legend**, with **1,920,958.56** in net sales
- Highest-revenue store: **STR-1006**, with **485,561.44** in net sales and **5,619** net units

December 2025 was the strongest demand period in the dataset. The concentration of revenue in a relatively small number of products supports differentiated inventory policies rather than applying the same replenishment rules to every SKU.

## Inventory Findings

- Current/open inventory records were active through **24 April 2026**.
- Units on hand: **75,628**
- Inventory cost value: **3,745,076.04 currency units**
- Inventory retail value: **7,404,355.15 currency units**
- Out-of-stock product-store records: **9,109**
- Current stockout rate: **14.94%**
- Urgent-replenishment records under the SQL classification: **8,085**
- Possible excess-stock records: **34,330**
- Non-moving inventory records: **13,290**
- Historical stockout-day rate for closed inventory periods: **9.47%**
- Highest historical stockout-risk store among closed periods: **STR-1080**, at **16.49%**
- Highest historical stockout-risk category among closed periods: **Scholar Footwear Retro Legend**, at **24.25%**

The simultaneous presence of 9,109 out-of-stock records, 34,330 possible excess records and 13,290 non-moving records indicates an allocation problem as well as a replenishment problem. Stock-transfer analysis should therefore be considered before automatically placing new purchase orders.

## ABC–XYZ Findings

| ABC class | Products | Product share | Net sales | Sales contribution |
|---|---:|---:|---:|---:|
| A | 928 | 39.90% | 8,384,530.49 | 79.99% |
| B | 601 | 25.84% | 1,572,385.46 | 15.00% |
| C | 797 | 34.26% | 525,194.30 | 5.01% |

Combined ABC–XYZ findings:

- AX products: **23**
- AY products: **322**
- AZ products: **583**
- BX products: **6**
- BY products: **173**
- BZ products: **422**
- CX products: **8**
- CY products: **332**
- CZ products: **457**
- Largest segment: **AZ**, with **583 products**
- Highest-value AZ product: **PROD-140871**, with **104,027.50** in net sales

The 583 AZ products are the most important monitoring group because they combine high financial contribution with volatile or intermittent demand. AX products are financially important but more predictable, making them stronger candidates for consistent service-level and reorder-point policies.

## Forecasting Findings

Forecasting was conducted as a proof of concept for the top 20 Class A products.

- Forecast horizon: **May–July 2026**
- Forecast periods: **3 months**
- Forecasted products: **20**
- Total forecast units: **2,502**
- Models evaluated: **Naive, three-month moving average and simple exponential smoothing**
- Selected models: **Naive for 9 products, moving average for 9 products and exponential smoothing for 2 products**
- Average best-model WAPE: **84.83%**
- Product-store forecast coverage: **800 of 60,968 records, or 1.31%**

The high average WAPE indicates that the existing monthly series are difficult to forecast accurately with the three baseline methods. The forecasts should therefore be treated as analytical estimates rather than production forecasts. The pilot is still useful because it establishes a repeatable evaluation framework and exposes which products require more sophisticated modelling or additional explanatory variables.

## Replenishment Findings

The Python recommendation output contained:

| Recommendation | Product-store records | Products | Stores | Suggested units | Estimated cost |
|---|---:|---:|---:|---:|---:|
| Urgent Replenishment | 143 | 15 | 39 | 519 | 1,193.08 |
| Place Replenishment Order | 303 | 20 | 40 | 655 | 31,210.98 |
| No Immediate Action | 229 | 20 | 40 | 18 | 819.88 |
| Review Excess Stock | 125 | 15 | 39 | 0 | 0.00 |
| No Forecast Available | 60,168 | 2,306 | 40 | 845 | 32,158.39 |

The two actionable order groups—Urgent Replenishment and Place Replenishment Order—represent **446 product-store records**, **1,174 suggested units** and an estimated cost of **32,404.06 currency units**. Recommendations labelled No Forecast Available should not be treated as forecast-supported purchase orders even where a preliminary quantity appears in the exported data.

## Recommendations

1. Prioritize the 143 urgent forecast-supported product-store records, beginning with Class A products and stores with the highest recent demand.
2. Review store-transfer opportunities before purchasing new stock because excess and non-moving inventory coexist with stockouts.
3. Closely monitor AZ products through shorter planning cycles, exception alerts and additional safety-stock review.
4. Maintain strong availability for AX products using consistent service-level and reorder-point rules.
5. Investigate the causes of the 14.94% current stockout rate, including allocation, replenishment timing, supplier performance and store-level assortment decisions.
6. Review the 34,330 possible excess and 13,290 non-moving records for transfer, markdown, promotion or assortment rationalization.
7. Improve forecasting using weekly demand where appropriate and test intermittent-demand methods, seasonal models, promotion features and store-level forecasts.
8. Expand forecast coverage only after validating model performance and replacing assumed replenishment parameters with approved operational inputs.

## Analytical Assumptions

- Returns were already recorded as negative quantities and values; their signs were not reversed during analysis.
- ABC classes used cumulative positive net-sales contribution: A approximately the first 80%, B the next 15% and C the remainder.
- XYZ classes used monthly demand coefficient of variation: X at or below 0.50, Y above 0.50 through 1.00, and Z above 1.00 or otherwise highly intermittent.
- Missing product-month combinations were filled with zero demand before calculating XYZ variability.
- Forecast model selection used the lowest WAPE, with MAE as a secondary criterion.
- Replenishment calculations assumed a 14-day lead time and 30-day target coverage.
- Service factors varied by ABC class.
- Product forecasts were allocated to stores according to their historical positive-demand share.
- Forecasting covered only the top 20 Class A products.
- Stock-transfer candidates did not account for distance, logistics cost, capacity or transfer lead time.

## Data-Quality Note

The inventory source contains **22,701 open-ended records with `9999-12-31` as the end-date sentinel**. This date represents an active record, not a literal operational horizon. These rows produce extremely large `inventory_period_days` and `stockout_days` values if included in duration-based calculations. Consequently, the reported **9.47% historical stockout-day rate** was calculated using closed inventory periods only. Current availability measures were calculated from the latest product-store snapshot instead.

Any dashboard measure that sums historical `inventory_period_days` or `stockout_days` should exclude the `9999-12-31` sentinel rows or cap them at the analysis date.

## Limitations

- The source currency was not explicitly confirmed, so financial findings are presented in currency units.
- Forecasts did not include promotions, holidays, price changes, supplier events or other external drivers.
- Supplier lead times, case-pack sizes, minimum order quantities and approved service levels were unavailable.
- The forecasting proof of concept covered only 20 products and achieved limited product-store coverage.
- The average forecast WAPE was high, so forecast-driven quantities require review.
- Replenishment recommendations are decision-support estimates, not automated purchase orders.
- The sell-through calculation is an analytical indicator because confirmed opening inventory for the complete sales period was unavailable.
