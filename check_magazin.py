import sqlite3
import os

db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute("SELECT sb.quantity, p.name FROM stock_balances sb JOIN products p ON sb.product_id = p.id WHERE sb.location_id = 'MAGAZIN_01'")
rows = c.fetchall()
print(f"Count: {len(rows)}")
for row in rows:
    print(row)
