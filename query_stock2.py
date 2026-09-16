import sqlite3
import os

db_path = os.path.expanduser('~/.local/share/marko_group/app.db')
if not os.path.exists(db_path):
    db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')

conn = sqlite3.connect(db_path)
cur = conn.cursor()
cur.execute("SELECT product_id, source_location_id, target_location_id, quantity, reason FROM stock_movements")
for r in cur.fetchall():
    print(r)
