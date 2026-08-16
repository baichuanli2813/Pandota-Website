$html = Get-Content -Path "ebay_raw.html" -Raw

# Search for item prices near item IDs in ebay_raw.html
# In eBay store markup: <span class="str-item-card__property-displayPrice"><span class=" ">£1,049.00</span></span>
# Or inside data structures

$items = Get-Content -Path "exact_store_laptops.json" -Raw | ConvertFrom-Json

Write-Host "Total items to update price for:" $items.Count

foreach ($item in $items) {
    $id = $item.ItemId
    $pos = $html.IndexOf($id)
    
    if ($pos -gt 0) {
        # Grab surrounding snippet (600 chars before, 1500 chars after)
        $start = [Math]::Max(0, $pos - 400)
        $len = [Math]::Min(2000, $html.Length - $start)
        $snippet = $html.Substring($start, $len)
        
        # Extract price string matching £XX.XX or £X,XXX.XX
        $prices = [regex]::Matches($snippet, '£[\d,]+(?:\.\d{2})?')
        
        if ($prices.Count -gt 0) {
            $item.Price = $prices[0].Value
        } else {
            # Try searching for "price":{"value":"..."} or similar JSON
            if ($snippet -match '"value":"([^"]+)"') {
                $item.Price = "£" + $matches[1]
            }
        }
        
        Write-Host "ID $id => "$item.Price" => "$item.Title.Substring(0, [Math]::Min(50, $item.Title.Length))
    }
}

$items | ConvertTo-Json | Out-File -FilePath "exact_store_laptops_prices_fixed.json" -Encoding utf8
Write-Host "Wrote exact_store_laptops_prices_fixed.json"
