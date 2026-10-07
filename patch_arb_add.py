import json

def update_arb(file, key, val):
    with open(file, 'r') as f:
        data = json.load(f)
    
    data[key] = val
        
    with open(file, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

update_arb('lib/src/localization/arb/app_en.arb', 'add', 'Add')
update_arb('lib/src/localization/arb/app_fr.arb', 'add', 'Ajouter')
update_arb('lib/src/localization/arb/app_es.arb', 'add', 'Agregar')
update_arb('lib/src/localization/arb/app_ar.arb', 'add', 'إضافة')

import sys
def remove_const(file, line_nums):
    with open(file, 'r') as f:
        lines = f.readlines()
    for i in line_nums:
        if 0 <= i < len(lines):
            lines[i] = lines[i].replace('const InputDecoration', 'InputDecoration')
            lines[i] = lines[i].replace('const TabBar', 'TabBar')
            lines[i] = lines[i].replace('const Tab(', 'Tab(')
    with open(file, 'w') as f:
        f.writelines(lines)

remove_const('lib/src/presentation/purchases/purchases_screen.dart', [804-1, 932-1, 933-1])
remove_const('lib/src/presentation/sales/pos_screen.dart', [493-1, 509-1, 525-1, 1828-1, 1829-1])

