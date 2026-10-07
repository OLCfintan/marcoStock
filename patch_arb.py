import json
import sys

def update_arb(file, updates):
    with open(file, 'r') as f:
        data = json.load(f)
    
    for k, v in updates.items():
        data[k] = v
        
    with open(file, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

en = {
  "ok": "OK",
  "insufficientStockFor": "Insufficient stock for \"{product}\".\nAvailable: {available}\nRequested: {requested}",
  "@insufficientStockFor": {
    "placeholders": {
      "product": {"type": "String"},
      "available": {"type": "String"},
      "requested": {"type": "String"}
    }
  }
}

fr = {
  "ok": "OK",
  "insufficientStockFor": "Stock insuffisant pour \"{product}\".\nDisponible: {available}\nDemandé: {requested}"
}

es = {
  "ok": "OK",
  "insufficientStockFor": "Stock insuficiente para \"{product}\".\nDisponible: {available}\nSolicitado: {requested}"
}

ar = {
  "ok": "حسنا",
  "insufficientStockFor": "مخزون غير كاف لـ \"{product}\".\nالمتاح: {available}\nالمطلوب: {requested}"
}

update_arb('lib/src/localization/arb/app_en.arb', en)
update_arb('lib/src/localization/arb/app_fr.arb', fr)
update_arb('lib/src/localization/arb/app_es.arb', es)
update_arb('lib/src/localization/arb/app_ar.arb', ar)
