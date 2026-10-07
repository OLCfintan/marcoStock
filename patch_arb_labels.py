import json

def update_arb(file, updates):
    with open(file, 'r') as f:
        data = json.load(f)
    
    for k, v in updates.items():
        data[k] = v
        
    with open(file, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

en = {
  "companyBranch": "Company Branch",
  "ice": "ICE"
}

fr = {
  "companyBranch": "Succursale de l'entreprise",
  "ice": "ICE"
}

es = {
  "companyBranch": "Sucursal de la empresa",
  "ice": "ICE"
}

ar = {
  "companyBranch": "فرع الشركة",
  "ice": "ICE"
}

update_arb('lib/src/localization/arb/app_en.arb', en)
update_arb('lib/src/localization/arb/app_fr.arb', fr)
update_arb('lib/src/localization/arb/app_es.arb', es)
update_arb('lib/src/localization/arb/app_ar.arb', ar)
