import sqlite3
import os

db_path = os.path.expanduser('~/.local/share/marko_group/app.db')
if not os.path.exists(db_path):
    db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')

if not os.path.exists(db_path):
    print("DB not found")
else:
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT count(*) FROM products")
    print(f"Products count: {cur.fetchone()[0]}")
    
    cur.execute("SELECT id, name, reference, is_active FROM products LIMIT 5")
    for r in cur.fetchall():
        print(r)
