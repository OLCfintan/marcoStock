import json

def update_arb(file, updates):
    with open(file, 'r') as f:
        data = json.load(f)
    
    for k, v in updates.items():
        data[k] = v
        
    with open(file, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

en = {
  "autoInvoiceGenerator": "Auto Invoice Generator",
  "targetAmountHt": "Target Amount (HT)",
  "targetAmountTtc": "Target Amount (TTC)",
  "numberOfFamilies": "Number of Families (Categories)",
  "generate": "Generate",
  "cartNumber": "Cart {number}",
  "@cartNumber": {
    "placeholders": {
      "number": {"type": "String"}
    }
  },
  "cartTitle": "Cart",
  "purchaseCart": "Purchase Cart"
}

fr = {
  "autoInvoiceGenerator": "Générateur de Facture Auto",
  "targetAmountHt": "Montant Cible (HT)",
  "targetAmountTtc": "Montant Cible (TTC)",
  "numberOfFamilies": "Nombre de Familles (Catégories)",
  "generate": "Générer",
  "cartNumber": "Panier {number}",
  "cartTitle": "Panier",
  "purchaseCart": "Panier d'Achat"
}

es = {
  "autoInvoiceGenerator": "Generador Automático de Facturas",
  "targetAmountHt": "Monto Objetivo (HT)",
  "targetAmountTtc": "Monto Objetivo (TTC)",
  "numberOfFamilies": "Número de Familias (Categorías)",
  "generate": "Generar",
  "cartNumber": "Carrito {number}",
  "cartTitle": "Carrito",
  "purchaseCart": "Carrito de Compra"
}

ar = {
  "autoInvoiceGenerator": "مولد الفواتير التلقائي",
  "targetAmountHt": "المبلغ المستهدف (HT)",
  "targetAmountTtc": "المبلغ المستهدف (TTC)",
  "numberOfFamilies": "عدد العائلات (الفئات)",
  "generate": "توليد",
  "cartNumber": "سلة {number}",
  "cartTitle": "السلة",
  "purchaseCart": "سلة المشتريات"
}

update_arb('lib/src/localization/arb/app_en.arb', en)
update_arb('lib/src/localization/arb/app_fr.arb', fr)
update_arb('lib/src/localization/arb/app_es.arb', es)
update_arb('lib/src/localization/arb/app_ar.arb', ar)
