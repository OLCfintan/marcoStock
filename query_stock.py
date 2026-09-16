import sqlite3
import os

db_path = os.path.expanduser('~/.local/share/marko_group/app.db')
if not os.path.exists(db_path):
    db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')

if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT product_id, location_id, quantity FROM stock_balances")
    for r in cur.fetchall():
        print(r)
        
    print("Movements:")
    cur.execute("SELECT product_id, quantity, reason FROM stock_movements")
    for r in cur.fetchall():
        print(r)
