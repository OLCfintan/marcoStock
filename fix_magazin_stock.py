import sqlite3
import os

db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')
conn = sqlite3.connect(db_path)
c = conn.cursor()

# Get the bad Magazin stock
c.execute("SELECT product_id, quantity FROM stock_balances WHERE location_id = 'MAGAZIN_01'")
rows = c.fetchall()

for row in rows:
    product_id, qty = row
    
    # 1. Add back to Base Warehouse
    c.execute("SELECT quantity FROM stock_balances WHERE location_id = 'BASE_WAREHOUSE_01' AND product_id = ?", (product_id,))
    base_res = c.fetchone()
    if base_res:
        new_base_qty = float(base_res[0]) + float(qty)
        c.execute("UPDATE stock_balances SET quantity = ? WHERE location_id = 'BASE_WAREHOUSE_01' AND product_id = ?", (str(new_base_qty), product_id))
    else:
        # Shouldn't happen but just in case
        c.execute("INSERT INTO stock_balances (product_id, location_id, quantity) VALUES (?, 'BASE_WAREHOUSE_01', ?)", (product_id, str(qty)))
        
    # 2. Delete from Magazin
    c.execute("DELETE FROM stock_balances WHERE location_id = 'MAGAZIN_01' AND product_id = ?", (product_id,))

conn.commit()
print("Restored corrupted Magazin stock back to Base Warehouse.")
