import urllib.request
import re
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
}

def get_exact_condition(item_id):
    url = f"https://www.ebay.co.uk/itm/{item_id}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            
            # Method 1: JSON-LD itemCondition
            # e.g. "itemCondition":"https://schema.org/NewCondition" or "https://schema.org/UsedCondition" or "https://schema.org/RefurbishedCondition"
            match_schema = re.search(r'"itemCondition"\s*:\s*"https://schema\.org/([^"]+)"', html)
            
            # Method 2: conditionDisplayName or ux-labels-values
            match_disp = re.search(r'"conditionDisplayName"\s*:\s*"([^"]+)"', html)
            
            match_textspan = re.search(r'Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>', html, re.DOTALL)
            
            schema_val = match_schema.group(1) if match_schema else None
            disp_val = match_disp.group(1) if match_disp else None
            textspan_val = match_textspan.group(1).strip() if match_textspan else None
            
            return {
                'id': item_id,
                'schema': schema_val,
                'disp': disp_val,
                'textspan': textspan_val
            }
    except Exception as e:
        return {'id': item_id, 'error': str(e)}

test_ids = ['267729753193', '267729862669', '267755974090', '267707331524', '267753890742']

for tid in test_ids:
    res = get_exact_condition(tid)
    print(res)
