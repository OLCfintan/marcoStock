import json
import glob

files = {
    'en': {'modeDeReglement': 'Payment Method', 'letter': 'Letter/Draft'},
    'fr': {'modeDeReglement': 'Mode de Règlement', 'letter': 'Traite'},
    'ar': {'modeDeReglement': 'طريقة الدفع', 'letter': 'كمبيالة'},
    'es': {'modeDeReglement': 'Método de Pago', 'letter': 'Letra'},
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
