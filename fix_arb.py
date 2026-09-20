import json

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for key, val in data.items():
        if isinstance(val, str):
            data[key] = val.replace("Delivery Note", "BON").replace("Bon de livraison", "BON")
            
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

fix_file('lib/src/localization/arb/app_en.arb')
fix_file('lib/src/localization/arb/app_fr.arb')
fix_file('lib/src/localization/arb/app_ar.arb')
fix_file('lib/src/localization/arb/app_es.arb')
