-- Sales indexes
CREATE INDEX IF NOT EXISTS idx_sales_transaction_date
    ON inventory.sales_clean (transaction_date);

CREATE INDEX IF NOT EXISTS idx_sales_product_no
    ON inventory.sales_clean (product_no);

CREATE INDEX IF NOT EXISTS idx_sales_store_id
    ON inventory.sales_clean (store_id);

CREATE INDEX IF NOT EXISTS idx_sales_product_store_key
    ON inventory.sales_clean (product_store_key);

CREATE INDEX IF NOT EXISTS idx_sales_transaction_type
    ON inventory.sales_clean (transaction_type);


-- Inventory indexes
CREATE INDEX IF NOT EXISTS idx_inventory_start_date
    ON inventory.inventory_clean (start_date);

CREATE INDEX IF NOT EXISTS idx_inventory_product_no
    ON inventory.inventory_clean (product_no);

CREATE INDEX IF NOT EXISTS idx_inventory_store_id
    ON inventory.inventory_clean (store_id);

CREATE INDEX IF NOT EXISTS idx_inventory_product_store_key
    ON inventory.inventory_clean (product_store_key);

CREATE INDEX IF NOT EXISTS idx_inventory_availability
    ON inventory.inventory_clean (availability_status);


ANALYZE inventory.sales_clean;
ANALYZE inventory.inventory_clean;