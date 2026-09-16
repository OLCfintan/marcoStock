import re

# Read the generated import_products.txt
with open('import_products.txt', 'r') as f:
    content = f.read()

# We will parse the blocks, build a dataset of prices
blocks = content.strip().split('---')
products = []

for b in blocks:
    if not b.strip(): continue
    lines = b.strip().split('\n')
    prod = {}
    for l in lines:
        if ': ' in l:
            k, v = l.split(': ', 1)
            prod[k] = v
    if prod:
        products.append(prod)

# Find base prices (900ml is the base 1L)
base_prices = {}
for p in products:
    name = p['NAME']
    size = p['UNIT_SIZE']
    unit = p['UNIT']
    price = float(p['SELLING_PRICE'])
    if price > 0:
        if name not in base_prices:
            base_prices[name] = {}
        base_prices[name][f"{size}{unit}"] = {
            'sell': price,
            't2': float(p['TIER2_PRICE']),
            't3': float(p['TIER3_PRICE']),
            'min': int(p['BASE_MIN_STOCK'])
        }

# Global average multipliers relative to 900ml (the 1L equivalent)
# We will collect all ratios across all families that have both 900ml and the target size
ratios = {}
for name, sizes in base_prices.items():
    if '900ml' in sizes:
        base_sell = sizes['900ml']['sell']
        for sz, data in sizes.items():
            if sz != '900ml':
                if sz not in ratios:
                    ratios[sz] = []
                ratios[sz].append(data['sell'] / base_sell)

# Average ratios
avg_ratios = {}
for sz, vals in ratios.items():
    avg_ratios[sz] = sum(vals) / len(vals)

# For sizes that might not have a ratio directly (like 0.5kg relative to 1kg)
# We do the same for kg
for name, sizes in base_prices.items():
    if '1kg' in sizes:
        base_sell = sizes['1kg']['sell']
        for sz, data in sizes.items():
            if sz != '1kg':
                if sz not in avg_ratios:
                    avg_ratios[sz] = []
                if isinstance(avg_ratios[sz], list):
                    avg_ratios[sz].append(data['sell'] / base_sell)
                    
for sz, vals in avg_ratios.items():
    if isinstance(vals, list) and len(vals) > 0:
        avg_ratios[sz] = sum(vals) / len(vals)

# If we still miss some, we can hardcode volumetric proportions roughly
def get_ratio(sz):
    if sz in avg_ratios and not isinstance(avg_ratios[sz], list):
        return avg_ratios[sz]
    # Fallback to pure math
    if 'ml' in sz:
        vol = float(sz.replace('ml', ''))
        return vol / 900.0
    elif 'L' in sz:
        vol = float(sz.replace('L', ''))
        return vol / 0.9
    elif 'kg' in sz:
        vol = float(sz.replace('kg', ''))
        return vol / 1.0
    return 1.0

# Interpolate missing prices
def round_price(val):
    # round to nearest 0.5
    return round(val * 2) / 2

for p in products:
    sell = float(p['SELLING_PRICE'])
    if sell == 0.0:
        name = p['NAME']
        sz = f"{p['UNIT_SIZE']}{p['UNIT']}"
        
        # What is the base price for this family?
        base_price = None
        if name in base_prices:
            if '900ml' in base_prices[name]:
                base_price = base_prices[name]['900ml']
            elif '1kg' in base_prices[name]:
                base_price = base_prices[name]['1kg']
                
        if base_price:
            ratio = get_ratio(sz)
            new_sell = round_price(base_price['sell'] * ratio)
            new_t2 = round_price(base_price['t2'] * ratio)
            new_t3 = round_price(base_price['t3'] * ratio)
            min_stock = base_price['min']
            
            p['SELLING_PRICE'] = str(new_sell)
            p['TIER2_PRICE'] = str(new_t2)
            p['TIER3_PRICE'] = str(new_t3)
            p['BASE_MIN_STOCK'] = str(min_stock)
        else:
            # Entire family missing (e.g. Deboucheur Marko). Just use a fallback math
            vol_ratio = get_ratio(sz)
            # assume 1kg is 40 dhs as an arbitrary mathematical fallback if completely unknown
            fallback_base = 40.0
            new_sell = round_price(fallback_base * vol_ratio)
            p['SELLING_PRICE'] = str(new_sell)
            p['TIER2_PRICE'] = str(new_sell + 1.0)
            p['TIER3_PRICE'] = str(new_sell + 2.0)
            p['BASE_MIN_STOCK'] = "20"

# Reconstruct file
out = []
for p in products:
    block = "\n".join([f"{k}: {v}" for k, v in p.items()])
    out.append(block + "\n---")
    
with open('import_products.txt', 'w') as f:
    f.write("\n\n".join(out))

print("Prices interpolated mathematically.")
