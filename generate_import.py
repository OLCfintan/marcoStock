import re

# Raw text from the user
raw_data = """Diluant Marko 1er 1L	دوليو 1er	Diluant Marko 1er 1L	Diluant Marko 1er 1L
Diluant Marko 1er 650ml	دوليو 1er	Diluant Marko 1er 650ml	Diluant Marko 1er 650ml
Diluant Marko 1er 5L	دوليو 1er	Diluant Marko 1er 5L	Diluant Marko 1er 5L
Diluant Marko 1er 250ml	دوليو 1er	Diluant Marko 1er 250ml	Diluant Marko 1er 250ml
Diluant Marko 1er 0.5L	دوليو 1er	Diluant Marko 1er 0.5L	Diluant Marko 1er 0.5L
Diluant Marko 1er 2L	دوليو 1er	Diluant Marko 1er 2L	Diluant Marko 1er 2L
Diluant Marko 2eme 1L	دوليو 2eme	Diluant Marko 2eme 1L	Diluant Marko 2eme 1L
Diluant Marko 2eme 650ml	دوليو 2eme	Diluant Marko 2eme 650ml	Diluant Marko 2eme 650ml
Diluant Marko 2eme 5L	دوليو 2eme	Diluant Marko 2eme 5L	Diluant Marko 2eme 5L
Diluant Marko 2eme 250ml	دوليو 2eme	Diluant Marko 2eme 250ml	Diluant Marko 2eme 250ml
Diluant Marko 2eme 0.5L	دوليو 2eme	Diluant Marko 2eme 0.5L	Diluant Marko 2eme 0.5L
Diluant Marko 2eme 2L	دوليو 2eme	Diluant Marko 2eme 2L	Diluant Marko 2eme 2L
Diluant Marko MP 1L	دوليو MP	Diluant Marko MP 1L	Diluant Marko MP 1L
Diluant Marko MP 650ml	دوليو MP	Diluant Marko MP 650ml	Diluant Marko MP 650ml
Diluant Marko MP 5L	دوليو MP	Diluant Marko MP 5L	Diluant Marko MP 5L
Diluant Marko MP 250ml	دوليو MP	Diluant Marko MP 250ml	Diluant Marko MP 250ml
Diluant Marko MP 0.5L	دوليو MP	Diluant Marko MP 0.5L	Diluant Marko MP 0.5L
Diluant Marko MP 2L	دوليو MP	Diluant Marko MP 2L	Diluant Marko MP 2L
Diluant Marko MV3 1L	دوليو MV3	Diluant Marko MV3 1L	Diluant Marko MV3 1L
Diluant Marko MV3 650ml	دوليو MV3	Diluant Marko MV3 650ml	Diluant Marko MV3 650ml
Diluant Marko MV3 5L	دوليو MV3	Diluant Marko MV3 5L	Diluant Marko MV3 5L
Diluant Marko MV3 250ml	دوليو MV3	Diluant Marko MV3 250ml	Diluant Marko MV3 250ml
Diluant Marko MV3 0.5L	دوليو MV3	Diluant Marko MV3 0.5L	Diluant Marko MV3 0.5L
Diluant Marko MV3 2L	دوليو MV3	Diluant Marko MV3 2L	Diluant Marko MV3 2L
White Spirit Marko 1er 1L	وايت سبيريت 1er	White Spirit Marko 1er 1L	White Spirit Marko 1er 1L
White Spirit Marko 1er 650ml	وايت سبيريت 1er	White Spirit Marko 1er 650ml	White Spirit Marko 1er 650ml
White Spirit Marko 1er 5L	وايت سبيريت 1er	White Spirit Marko 1er 5L	White Spirit Marko 1er 5L
White Spirit Marko 1er 250ml	وايت سبيريت 1er	White Spirit Marko 1er 250ml	White Spirit Marko 1er 250ml
White Spirit Marko 1er 0.5L	وايت سبيريت 1er	White Spirit Marko 1er 0.5L	White Spirit Marko 1er 0.5L
White Spirit Marko 1er 2L	وايت سبيريت 1er	White Spirit Marko 1er 2L	White Spirit Marko 1er 2L
White Spirit Marko 2eme 1L	وايت سبيريت 2eme	White Spirit Marko 2eme 1L	White Spirit Marko 2eme 1L
White Spirit Marko 2eme 650ml	وايت سبيريت 2eme	White Spirit Marko 2eme 650ml	White Spirit Marko 2eme 650ml
White Spirit Marko 2eme 5L	وايت سبيريت 2eme	White Spirit Marko 2eme 5L	White Spirit Marko 2eme 5L
White Spirit Marko 2eme 250ml	وايت سبيريت 2eme	White Spirit Marko 2eme 250ml	White Spirit Marko 2eme 250ml
White Spirit Marko 2eme 0.5L	وايت سبيريت 2eme	White Spirit Marko 2eme 0.5L	White Spirit Marko 2eme 0.5L
White Spirit Marko 2eme 2L	وايت سبيريت 2eme	White Spirit Marko 2eme 2L	White Spirit Marko 2eme 2L
Essence Jupiter Marko 1L	جوبيتر	Essence Jupiter Marko 1L	Essence Jupiter Marko 1L
Essence Jupiter Marko 650ml	جوبيتر	Essence Jupiter Marko 650ml	Essence Jupiter Marko 650ml
Essence Jupiter Marko 5L	جوبيتر	Essence Jupiter Marko 5L	Essence Jupiter Marko 5L
Essence Jupiter Marko 250ml	جوبيتر	Essence Jupiter Marko 250ml	Essence Jupiter Marko 250ml
Essence Jupiter Marko 0.5L	جوبيتر	Essence Jupiter Marko 0.5L	Essence Jupiter Marko 0.5L
Essence Jupiter Marko 2L	جوبيتر	Essence Jupiter Marko 2L	Essence Jupiter Marko 2L
Esprit de sel Marko 17° 1L	ماء قاطع 17°	Esprit de sel Marko 17° 1L	Esprit de sal Marko 17° 1L
Esprit de sel Marko 17° 650ml	ماء قاطع 17°	Esprit de sel Marko 17° 650ml	Esprit de sal Marko 17° 650ml
Esprit de sel Marko 22° 1L	ماء قاطع 22°	Esprit de sel Marko 22° 1L	Esprit de sal Marko 22° 1L
Esprit de sel Marko 22° 650ml	ماء قاطع 22°	Esprit de sel Marko 22° 650ml	Esprit de sal Marko 22° 650ml
Esprit de sel Marko 33° 1L	ماء قاطع 33°	Esprit de sel Marko 33° 1L	Esprit de sal Marko 33° 1L
Esprit de sel Marko 33° 650ml	ماء قاطع 33°	Esprit de sel Marko 33° 650ml	Esprit de sal Marko 33° 650ml
Esprit de sel Marko Sec 1L	ماء قاطع Sec	Esprit de sel Marko Sec 1L	Esprit de sal Marko Sec 1L
Esprit de sel Marko Sec 650ml	ماء قاطع Sec	Esprit de sel Marko Sec 650ml	Esprit de sal Marko Sec 650ml
Huile de lin Marko 1L	ويل دولان	Huile de lin Marko 1L	Aceite de linaza Marko 1L
Huile de lin Marko 650ml	ويل دولان	Huile de lin Marko 650ml	Aceite de linaza Marko 650ml
Huile de lin Marko 5L	ويل دولان	Huile de lin Marko 5L	Aceite de linaza Marko 5L
Huile de lin Marko 250ml	ويل دولان	Huile de lin Marko 250ml	Aceite de linaza Marko 250ml
Huile de lin Marko 0.5L	ويل دولان	Huile de lin Marko 0.5L	Aceite de linaza Marko 0.5L
Huile de lin Marko 2L	ويل دولان	Huile de lin Marko 2L	Aceite de linaza Marko 2L
Acide Marko 28° 1L	أسيد 28°	Acide Marko 28° 1L	Ácido Marko 28° 1L
Acide Marko 28° 650ml	أسيد 28°	Acide Marko 28° 650ml	Ácido Marko 28° 650ml
Eau de potasse Marko 1L	بوتاس	Eau de potasse Marko 1L	Potasa Marko 1L
Eau de potasse Marko 650ml	بوتاس	Eau de potasse Marko 650ml	Potasa Marko 650ml
Degraissant Marko 750ml	مزيل الشحوم	Degraissant Marko 750ml	Desengrasante Marko 750ml
Degraissant Marko 1L	مزيل الشحوم	Degraissant Marko 1L	Desengrasante Marko 1L
Degraissant Marko 650ml	مزيل الشحوم	Degraissant Marko 650ml	Desengrasante Marko 650ml
Degraissant Marko 5L	مزيل الشحوم	Degraissant Marko 5L	Desengrasante Marko 5L
Degraissant Marko 250ml	مزيل الشحوم	Degraissant Marko 250ml	Desengrasante Marko 250ml
Degraissant Marko 0.5L	مزيل الشحوم	Degraissant Marko 0.5L	Desengrasante Marko 0.5L
Degraissant Marko 2L	مزيل الشحوم	Degraissant Marko 2L	Desengrasante Marko 2L
Eau de batterie Marko 1L	ماء البطارية	Eau de batterie Marko 1L	Agua de batería Marko 1L
Marko Flash 1250ml	ماركو فلاش	Marko Flash 1250ml	Marko Flash 1250ml
Dur-pro Marko 500ml	دور برو	Dur-pro Marko 500ml	Dur-pro Marko 500ml
Dur-pro Marko 250ml	دور برو	Dur-pro Marko 250ml	Dur-pro Marko 250ml
Dur-pro Marko 650ml	دور برو	Dur-pro Marko 650ml	Dur-pro Marko 650ml
Dur-pro Marko 1L	دور برو	Dur-pro Marko 1L	Dur-pro Marko 1L
Dur-pro Marko 2L	دور برو	Dur-pro Marko 2L	Dur-pro Marko 2L
Laque Marko 0.5kg	لاك	Laque Marko 0.5kg	Laca Marko 0.5kg
Laque Marko 1kg	لاك	Laque Marko 1kg	Laca Marko 1kg
Laque Marko 5kg	لاك	Laque Marko 5kg	Laca Marko 5kg
Laque Marko 10kg	لاك	Laque Marko 10kg	Laca Marko 10kg
Laque Marko 20kg	لاك	Laque Marko 20kg	Laca Marko 20kg
Laque Marko 30kg	لاك	Laque Marko 30kg	Laca Marko 30kg
Laque Marko 50kg	لاك	Laque Marko 50kg	Laca Marko 50kg
Vinyl Marko 0.5kg	فينيل	Vinyl Marko 0.5kg	Vinilo Marko 0.5kg
Vinyl Marko 1kg	فينيل	Vinyl Marko 1kg	Vinilo Marko 1kg
Vinyl Marko 5kg	فينيل	Vinyl Marko 5kg	Vinilo Marko 5kg
Vinyl Marko 10kg	فينيل	Vinyl Marko 10kg	Vinilo Marko 10kg
Vinyl Marko 20kg	فينيل	Vinyl Marko 20kg	Vinilo Marko 20kg
Vinyl Marko 30kg	فينيل	Vinyl Marko 30kg	Vinilo Marko 30kg
Vinyl Marko 50kg	فينيل	Vinyl Marko 50kg	Vinilo Marko 50kg
Colle Griffie Marko 0.5kg	كولا غريفي	Colle Griffie Marko 0.5kg	Cola Griffie Marko 0.5kg
Colle Griffie Marko 1kg	كولا غريفي	Colle Griffie Marko 1kg	Cola Griffie Marko 1kg
Colle Griffie Marko 5kg	كولا غريفي	Colle Griffie Marko 5kg	Cola Griffie Marko 5kg
Colle Griffie Marko 10kg	كولا غريفي	Colle Griffie Marko 10kg	Cola Griffie Marko 10kg
MarkoFlex 0.5kg	ماركوفليكس	MarkoFlex 0.5kg	MarkoFlex 0.5kg
MarkoFlex 1kg	ماركوفليكس	MarkoFlex 1kg	MarkoFlex 1kg
MarkoFlex 5kg	ماركوفليكس	MarkoFlex 5kg	MarkoFlex 5kg
MarkoFlex 10kg	ماركوفليكس	MarkoFlex 10kg	MarkoFlex 10kg
MarkoFlex 20kg	ماركوفليكس	MarkoFlex 20kg	MarkoFlex 20kg
MarkoFlex 30kg	ماركوفليكس	MarkoFlex 30kg	MarkoFlex 30kg
MarkoFlex 50kg	ماركوفليكس	MarkoFlex 50kg	MarkoFlex 50kg
Goudron Bitumineux Marko 0.5kg	القار البيتوميني	Goudron Bitumineux Marko 0.5kg	Alquitrán bituminoso Marko 0.5kg
Goudron Bitumineux Marko 1kg	القار البيتوميني	Goudron Bitumineux Marko 1kg	Alquitrán bituminoso Marko 1kg
Goudron Bitumineux Marko 5kg	القار البيتوميني	Goudron Bitumineux Marko 5kg	Alquitrán bituminoso Marko 5kg
Goudron Bitumineux Marko 10kg	القار البيتوميني	Goudron Bitumineux Marko 10kg	Alquitrán bituminoso Marko 10kg
Colle a bois Marko 0.5kg	كولا الخشب	Colle a bois Marko 0.5kg	Cola para madera Marko 0.5kg
Colle a bois Marko 1kg	كولا الخشب	Colle a bois Marko 1kg	Cola para madera Marko 1kg
Colle a bois Marko 5kg	كولا الخشب	Colle a bois Marko 5kg	Cola para madera Marko 5kg
Colle a bois Marko 10kg	كولا الخشب	Colle a bois Marko 10kg	Cola para madera Marko 10kg
Deboucheur Marko 0.5kg	مفتح المجاري	Deboucheur Marko 0.5kg	Desatascador Marko 0.5kg
Deboucheur Marko 1kg	مفتح المجاري	Deboucheur Marko 1kg	Desatascador Marko 1kg
Bouche pores Marko 0.5kg	معجون سد المسام	Bouche pores Marko 0.5kg	Masilla tapa poros Marko 0.5kg
Bouche pores Marko 1kg	معجون سد المسام	Bouche pores Marko 1kg	Masilla tapa poros Marko 1kg
Bouche pores Marko 5kg	معجون سد المسام	Bouche pores Marko 5kg	Masilla tapa poros Marko 5kg
Vernis Marko 0.5kg	فيرني	Vernis Marko 0.5kg	Barniz Marko 0.5kg
Vernis Marko 1kg	فيرني	Vernis Marko 1kg	Barniz Marko 1kg
"""

prices = {
    "Diluant Marko 1er 1L": [12.50, 13.00, 13.50, 20],
    "Diluant Marko 1er 650ml": [10.50, 11.00, 11.50, 20],
    "Diluant Marko 1er 5L": [65.00, 70.00, 80.00, 20],
    "Diluant Marko 1er 2L": [33.00, 35.00, 37.00, 20],
    "Diluant Marko 2eme 1L": [11.00, 11.50, 12.00, 20],
    "Diluant Marko 2eme 650ml": [7.50, 8.00, 9.00, 20],
    "Diluant Marko 2eme 5L": [50.00, 52.50, 55.00, 20],
    "Diluant Marko 2eme 250ml": [2.80, 3.00, 3.50, 100],
    "Diluant Marko 2eme 0.5L": [6.00, 6.50, 7.00, 20],
    "Diluant Marko 2eme 2L": [28.00, 30.00, 32.00, 20],
    "Diluant Marko MP 1L": [18.00, 19.00, 20.00, 20],
    "Diluant Marko MP 650ml": [11.00, 11.50, 12.00, 20], # guessed from 1L 650 pattern or maybe missing
    "Diluant Marko MP 5L": [80.00, 85.00, 90.00, 20],
    "Diluant Marko MP 2L": [35.00, 37.50, 40.00, 20],
    "Diluant Marko MV3 1L": [25.00, 27.00, 28.00, 20],
    "Diluant Marko MV3 0.5L": [18.00, 19.00, 20.00, 20],
    "White Spirit Marko 1er 1L": [15.00, 16.00, 17.00, 20],
    "White Spirit Marko 1er 650ml": [11.00, 11.50, 12.00, 20],
    "White Spirit Marko 1er 5L": [70.00, 75.00, 80.00, 20],
    "White Spirit Marko 1er 250ml": [4.00, 4.50, 5.00, 100],
    "White Spirit Marko 1er 0.5L": [7.50, 8.00, 8.50, 20],
    "White Spirit Marko 1er 2L": [33.00, 34.00, 35.00, 20],
    "White Spirit Marko 2eme 1L": [12.00, 12.50, 13.00, 20],
    "White Spirit Marko 2eme 650ml": [9.00, 9.50, 10.00, 20],
    "White Spirit Marko 2eme 5L": [60.00, 62.50, 65.00, 20],
    "White Spirit Marko 2eme 250ml": [3.25, 3.50, 4.00, 100],
    "White Spirit Marko 2eme 0.5L": [0.00, 0.00, 0.00, 20],
    "Essence Jupiter Marko 1L": [14.00, 14.50, 15.00, 20],
    "Essence Jupiter Marko 650ml": [10.00, 11.00, 12.00, 20],
    "Essence Jupiter Marko 5L": [75.00, 77.50, 80.00, 20],
    "Essence Jupiter Marko 250ml": [4.00, 4.50, 5.00, 100],
    "Esprit de sel Marko 17° 1L": [4.00, 4.50, 5.00, 20],
    "Esprit de sel Marko 17° 650ml": [0.00, 0.00, 0.00, 20],
    "Esprit de sel Marko 22° 1L": [5.00, 5.50, 6.00, 20],
    "Esprit de sel Marko 22° 650ml": [0.00, 0.00, 0.00, 20],
    "Esprit de sel Marko 33° 1L": [5.50, 6.00, 6.50, 20],
    "Esprit de sel Marko 33° 650ml": [0.00, 0.00, 0.00, 20],
    "Esprit de sel Marko Sec 1L": [0.00, 0.00, 0.00, 20],
    "Esprit de sel Marko Sec 650ml": [0.00, 0.00, 0.00, 20],
    "Huile de lin Marko 650ml": [9.00, 9.50, 10.00, 20],
    "Acide Marko 28° 1L": [3.00, 3.50, 4.00, 20],
    "Eau de potasse Marko 1L": [5.00, 5.50, 6.00, 20],
    "Degraissant Marko 750ml": [8.00, 8.50, 9.00, 20],
    "Eau de batterie Marko 1L": [2.50, 2.75, 3.00, 20],
    "Dur-pro Marko 500ml": [40.00, 41.00, 42.00, 20],
    "Dur-pro Marko 250ml": [20.00, 21.00, 22.00, 100],
    "Laque Marko 1kg": [20.00, 22.00, 23.00, 120],
    "Laque Marko 5kg": [100.00, 105.00, 110.00, 30],
    "Laque Marko 20kg": [500.00, 510.00, 520.00, 30],
    "Vinyl Marko 1kg": [8.00, 8.50, 9.00, 120],
    "Vinyl Marko 5kg": [27.00, 28.00, 30.00, 30],
    "Vinyl Marko 10kg": [55.00, 57.00, 60.00, 30],
    "Vinyl Marko 30kg": [140.00, 145.00, 150.00, 30],
    "Vinyl Marko 50kg": [225.00, 230.00, 235.00, 30],
    "Colle Griffie Marko 1kg": [17.50, 18.00, 19.00, 120],
    "Colle Griffie Marko 5kg": [70.00, 72.50, 75.00, 30],
    "MarkoFlex 1kg": [0.00, 0.00, 0.00, 120], # name is MarkoFlex in text, MarkoFlex Marko in image
    "MarkoFlex 5kg": [75.00, 77.50, 80.00, 30],
    "MarkoFlex 20kg": [0.00, 0.00, 0.00, 30],
    "Goudron Bitumineux Marko 1kg": [12.50, 13.00, 13.50, 120],
    "Goudron Bitumineux Marko 5kg": [0.00, 0.00, 0.00, 30],
    "Colle a bois Marko 1kg": [0.00, 0.00, 0.00, 120],
    "Colle a bois Marko 5kg": [0.00, 0.00, 0.00, 30],
    "Bouche pores Marko 1kg": [40.00, 42.00, 43.00, 120],
    "Bouche pores Marko 5kg": [160.00, 165.00, 170.00, 30],
    "Vernis Marko 1kg": [40.00, 42.00, 43.00, 120],
    "Vernis Marko 5kg": [160.00, 165.00, 170.00, 0],
    "Marko Flash 1250ml": [5.50, 6.00, 6.50, 100],
    "Dur-pro Marko 1L": [100.00, 110.00, 120.00, 0],
    "Huile de lin Marko 1L": [40.00, 50.00, 60.00, 100],
    "Degraissant Marko 1L": [10.00, 11.00, 12.00, 100],
}

def clean_unit(text):
    text = re.sub(r' \d+(\.\d+)?(L|ml|kg)$', '', text)
    return text.strip()

out = []
for line in raw_data.strip().split('\n'):
    if not line.strip(): continue
    parts = line.split('\t')
    if len(parts) != 4: continue
    
    orig_name, name_ar, name_fr, name_es = [p.strip() for p in parts]
    clean_n = clean_unit(orig_name)
    clean_fr = clean_unit(name_fr)
    clean_es = clean_unit(name_es)
    
    # parse the original unit
    match = re.search(r' (\d+(\.\d+)?)(L|ml|kg)$', orig_name)
    if not match:
        continue
    val = float(match.group(1))
    unit = match.group(3)
    
    # apply user rules
    if unit == 'L':
        if val == 5:
            new_unit = 'L'
            new_val = 4.5
        elif val == 1:
            new_unit = 'ml'
            new_val = 900
        else:
            new_unit = 'L'
            new_val = val
    elif unit == 'ml':
        if val == 250:
            new_unit = 'ml'
            new_val = 200
        elif val == 650:
            new_unit = 'ml'
            new_val = 600
        else:
            new_unit = 'ml'
            new_val = val
    else:
        new_unit = unit
        new_val = val
        
    price_data = prices.get(orig_name, [0.0, 0.0, 0.0, 0])
    
    # format new val nicely
    size_str = str(int(new_val)) if new_val == int(new_val) else str(new_val)
    
    ref = clean_n.upper().replace(' ', '-') + f"-{size_str}{new_unit.upper()}"
    ref = re.sub(r'[^A-Z0-9-]', '', ref)
    
    packaging = "Unit" if unit == 'kg' else "Bottle"
    
    block = f"TYPE: PRODUCT\n"
    block += f"NAME: {clean_n}\n"
    block += f"REFERENCE: {ref}\n"
    block += f"UNIT: {new_unit}\n"
    block += f"UNIT_SIZE: {size_str}\n"
    block += f"PURCHASE_PRICE: 0.0\n"
    block += f"SELLING_PRICE: {price_data[0]}\n"
    block += f"TIER2_PRICE: {price_data[1]}\n"
    block += f"TIER3_PRICE: {price_data[2]}\n"
    block += f"BASE_MIN_STOCK: {price_data[3]}\n"
    block += f"MAGAZIN_MIN_STOCK: 0\n"
    block += f"PACKAGING: {packaging}\n"
    block += f"NAME_AR: {name_ar}\n"
    block += f"NAME_FR: {clean_fr}\n"
    block += f"NAME_ES: {clean_es}\n"
    block += f"UNITS_PER_BOX: 0\n"
    block += "---\n"
    
    out.append(block)

with open('import_products.txt', 'w') as f:
    f.write("\n".join(out))
    
print("Generated import_products.txt")
