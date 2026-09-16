import json

files = {
    'en': 'lib/src/localization/arb/app_en.arb',
    'fr': 'lib/src/localization/arb/app_fr.arb',
    'ar': 'lib/src/localization/arb/app_ar.arb',
    'es': 'lib/src/localization/arb/app_es.arb'
}

data = {
    'en': {
        'pdfTotalDebt': 'Total Debt',
        'pdfRemainingInInvoice': 'Remaining in this Invoice',
        'pdfRemainingInBon': 'Remaining in this Delivery Note'
    },
    'fr': {
        'pdfTotalDebt': 'Crédit total',
        'pdfRemainingInInvoice': 'Reste sur cette facture',
        'pdfRemainingInBon': 'Reste sur ce bon de livraison'
    },
    'ar': {
        'pdfTotalDebt': 'مجموع الديون',
        'pdfRemainingInInvoice': 'المتبقي في هذه الفاتورة',
        'pdfRemainingInBon': 'المتبقي في هذا البون'
    },
    'es': {
        'pdfTotalDebt': 'Deuda total',
        'pdfRemainingInInvoice': 'Restante en esta factura',
        'pdfRemainingInBon': 'Restante en este albarán'
    }
}

for lang, filepath in files.items():
    with open(filepath, 'r') as f:
        content = json.load(f)
        
    for k, v in data[lang].items():
        content[k] = v
        
    with open(filepath, 'w') as f:
        json.dump(content, f, indent=2, ensure_ascii=False)
        
print("ARBs updated.")
