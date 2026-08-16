# Read raw html as byte array or raw string
$bytes = [System.IO.File]::ReadAllBytes("ebay_raw.html")
$html = [System.Text.Encoding]::UTF8.GetString($bytes)

# Regex matching each article card:
# data-testid=ig-(\d+) ... str-item-card__property-displayPrice">([^<]+)
$matches = [regex]::Matches($html, '(?s)data-testid=ig-(\d+).*?str-item-card__property-displayPrice">([^<]+)')

Write-Host "Matched item prices count:" $matches.Count

$priceMap = @{}

foreach ($m in $matches) {
    $itemId = $m.Groups[1].Value
    $rawPrice = $m.Groups[2].Value
    
    # Extract numbers and decimal point, e.g. 1,049.00 or 2,599.00
    if ($rawPrice -match '([\d,]+\.\d{2})') {
        $priceMap[$itemId] = "£" + $matches[1]
    } elseif ($rawPrice -match '([\d,]+)') {
        $priceMap[$itemId] = "£" + $matches[1] + ".00"
    }
}

Write-Host "Price Map contains:" $priceMap.Count "items."

# Load current exact_store_laptops.json and apply the exact live prices!
$laptops = Get-Content -Path "exact_store_laptops.json" -Raw | ConvertFrom-Json

$updatedLaptops = @()

foreach ($laptop in $laptops) {
    $id = $laptop.ItemId
    if ($priceMap.ContainsKey($id)) {
        $laptop.Price = $priceMap[$id]
    } else {
        # Fallback price regex search around this ID in html
        $pos = $html.IndexOf($id)
        if ($pos -gt 0) {
            $snippet = $html.Substring($pos, [Math]::Min(3000, $html.Length - $pos))
            if ($snippet -match 'str-item-card__property-displayPrice">.*?([\d,]+\.\d{2})') {
                $laptop.Price = "£" + $matches[1]
            }
        }
    }
    
    Write-Host "Item "$laptop.ItemId" => "$laptop.Price" => "$laptop.Title
    $updatedLaptops += $laptop
}

$updatedLaptops | ConvertTo-Json | Out-File -FilePath "exact_store_laptops_prices_fixed.json" -Encoding utf8
Write-Host "Saved 100% exact prices into exact_store_laptops_prices_fixed.json!"
