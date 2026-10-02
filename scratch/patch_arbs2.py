import json

files = {
    'en': {'invoiceAddress': 'Invoice Address', 'companyTp': 'TP (Taxe Prof.)'},
    'fr': {'invoiceAddress': 'Adresse (Factures)', 'companyTp': 'TP'},
    'ar': {'invoiceAddress': 'عنوان الفاتورة', 'companyTp': 'ضريبة المهنية'},
    'es': {'invoiceAddress': 'Dirección (Facturas)', 'companyTp': 'TP'},
}

for lang, new_keys in files.items():
    path = f'lib/src/localization/arb/app_{lang}.arb'
    with open(path, 'r') as f:
        data = json.load(f)
    
    for k, v in new_keys.items():
        if k not in data:
            data[k] = v
            
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

print("Updated arbs")
