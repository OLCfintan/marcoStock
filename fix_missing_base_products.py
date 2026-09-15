import sqlite3
import uuid
import re

def extract_family_name(name):
    s = name.lower()
    s = re.sub(r'\b\d+(?:\.\d+)?\s*(?:ml|l|kg|g|mg|cl|dl|m3|cm|mm|m)\b', '', s)
    s = re.sub(r'[^a-z0-9\s-]', '', s)
    s = s.replace('-', ' ')
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def get_base_unit(unit):
    u = unit.lower().strip()
    if u in ['g', 'mg', 'kg']: return 'KG'
    if u in ['ml', 'cl', 'dl', 'l']: return 'L'
    if u in ['m3']: return 'M3'
    return unit.upper()

def main():
    conn = sqlite3.connect('marcoStock_clean.sqlite') # I'll copy the live DB and modify it
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM products WHERE is_active = 1")
    columns = [description[0] for description in cursor.description]
    products = [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    # group by family
    families = {}
    for p in products:
        fam = extract_family_name(p['name'])
        if fam not in families:
            families[fam] = []
        families[fam].append(p)
        
    for fam, prods in families.items():
        # check if it has a unitSize == 1
        has_base = any(str(p['unit_size']) == '1' for p in prods)
        if not has_base:
            # take the first product as template
            t = prods[0]
            default_unit = get_base_unit(t['unit'])
            
            # calculate base price
            t_price = float(t['selling_price'])
            t_size = float(t['unit_size'])
            base_price = (t_price / t_size) if t_size > 0 else 0
            
            t_purch = float(t['purchase_price'])
            base_purch = (t_purch / t_size) if t_size > 0 else 0
            
            new_id = str(uuid.uuid4())
            new_name = f"{fam.upper()} 1{default_unit}"
            new_ref = str(t['reference'])[:6] + '-BASE'
            
            cursor.execute("""
                INSERT INTO products (
                    id, name, reference, unit, unit_size, packaging_type, units_per_box, 
                    purchase_price, selling_price, tier2_price, tier3_price, minimum_stock, 
                    base_minimum_stock, magazin_minimum_stock, image_path, is_active, 
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                new_id, new_name, new_ref, default_unit, '1', 'Vrac', 1, 
                str(round(base_purch, 2)), str(round(base_price, 2)), None, None, '0', 
                '0', '0', t['image_path'], 1, t['created_at'], t['updated_at']
            ))
            print(f"Created base product for family: {fam} -> {new_name}")
            
    conn.commit()
    conn.close()

if __name__ == '__main__':
    # copy DB
    import shutil
    shutil.copy('/home/limbo/Documents/markogroup_erp.sqlite', 'marcoStock_clean.sqlite')
    main()
    shutil.copy('marcoStock_clean.sqlite', '/home/limbo/Documents/markogroup_erp.sqlite')
