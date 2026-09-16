import sqlite3
import os

def get_si_unit(unit):
    u = unit.lower().strip()
    if u in ['ml', 'cl', 'dl', 'l']: return 'l'
    if u in ['mg', 'g', 'kg', 't']: return 'kg'
    if u == 'm3': return 'm3'
    return u

def get_base_value(unit):
    u = unit.lower().strip()
    if u in ['t', 'm3']: return 1000.0
    if u in ['kg', 'l']: return 1.0
    if u in ['g', 'ml']: return 0.001
    if u == 'mg': return 0.000001
    if u == 'cl': return 0.01
    if u == 'dl': return 0.1
    return 1.0

db_path = os.path.expanduser('~/.local/share/marko_group/app.db')
if not os.path.exists(db_path):
    db_path = os.path.expanduser('~/Documents/markogroup_erp.sqlite')

if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    
    cur.execute("SELECT product_id, location_id, quantity FROM stock_balances")
    balances = cur.fetchall()
    
    for product_id, location_id, quantity_str in balances:
        try:
            quantity = float(quantity_str)
        except:
            continue
            
        cur.execute("SELECT unit_size, unit FROM products WHERE id = ?", (product_id,))
        prod = cur.fetchone()
        if not prod: continue
        
        unit_size = float(prod[0])
        unit = prod[1]
        
        # Convert old representation (multiples of base unit size) to absolute SI unit
        # old_representation = raw_magnitude / unitSize
        # new_representation = raw_magnitude
        # So we just multiply by unitSize! And then convert to SI unit.
        
        # Actually, the old code returned:
        # return (convertedMagnitude / baseProduct.unitSize)
        # Where convertedMagnitude was already converted to baseProduct's unit.
        # Wait, if baseProduct is 900mL, convertedMagnitude was in mL!
        # So it divided by 900 to get "number of 900mL bottles".
        # So quantity = (mL / 900).
        # To get Liters, we do: quantity * 900 = mL. Then mL * 0.001 = Liters.
        
        si_unit = get_si_unit(unit)
        factor = get_base_value(unit) / get_base_value(si_unit)
        
        new_quantity = quantity * unit_size * factor
        
        cur.execute("UPDATE stock_balances SET quantity = ? WHERE product_id = ? AND location_id = ?",
                   (str(new_quantity), product_id, location_id))
                   
    # Also update stock_movements!
    cur.execute("SELECT id, product_id, quantity FROM stock_movements")
    movements = cur.fetchall()
    
    for movement_id, product_id, quantity_str in movements:
        try:
            quantity = float(quantity_str)
        except:
            continue
            
        cur.execute("SELECT unit_size, unit FROM products WHERE id = ?", (product_id,))
        prod = cur.fetchone()
        if not prod: continue
        
        unit_size = float(prod[0])
        unit = prod[1]
        
        si_unit = get_si_unit(unit)
        factor = get_base_value(unit) / get_base_value(si_unit)
        
        new_quantity = quantity * unit_size * factor
        
        cur.execute("UPDATE stock_movements SET quantity = ? WHERE id = ?",
                   (str(new_quantity), movement_id))
                   
    conn.commit()
    print("Migrated database stock to absolute SI units!")
