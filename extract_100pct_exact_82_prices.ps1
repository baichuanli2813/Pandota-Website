# Combine HTML from all 6 store pages + raw HTML
$htmlCombined = ""
for ($p = 1; $p -le 6; $p++) {
    $path = "ebay_page_$p.html"
    if (Test-Path $path) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes) + "`n`n"
    }
}
if (Test-Path "ebay_raw.html") {
    $bytes = [System.IO.File]::ReadAllBytes("ebay_raw.html")
    $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes)
}

Write-Host "Total combined store HTML length:" $htmlCombined.Length

# Regex to match item ID and its exact price snippet:
# data-testid=ig-(\d+) ... str-item-card__property-displayPrice">([^<]+)
$matches = [regex]::Matches($htmlCombined, '(?s)data-testid=ig-(\d+).*?str-item-card__property-displayPrice">([^<]+)')

$exactPriceMap = @{}

foreach ($m in $matches) {
    $itemId = $m.Groups[1].Value
    $rawPrice = $m.Groups[2].Value
    
    if ($rawPrice -match '([\d,]+\.\d{2})') {
        $exactPriceMap[$itemId] = "£" + $matches[1]
    } elseif ($rawPrice -match '([\d,]+)') {
        $exactPriceMap[$itemId] = "£" + $matches[1] + ".00"
    }
}

Write-Host "Extracted exact prices for" $exactPriceMap.Count "items."

# Also search for any missing item IDs in combined HTML
$all82 = Get-Content -Path "all_store_listings_full.json" -Raw | ConvertFrom-Json

foreach ($item in $all82) {
    $id = $item.ItemId
    if (-not $exactPriceMap.ContainsKey($id)) {
        $pos = $htmlCombined.IndexOf($id)
        if ($pos -gt 0) {
            $snippet = $htmlCombined.Substring($pos, [Math]::Min(2500, $htmlCombined.Length - $pos))
            if ($snippet -match 'str-item-card__property-displayPrice">.*?([\d,]+\.\d{2})') {
                $exactPriceMap[$id] = "£" + $matches[1]
            } elseif ($snippet -match '£([\d,]+\.\d{2})') {
                $exactPriceMap[$id] = "£" + $matches[1]
            }
        }
    }
}

Write-Host "Final Exact Price Map count:" $exactPriceMap.Count

# Apply 100% exact prices to all 82 items
$final82 = @()

foreach ($item in $all82) {
    $id = $item.ItemId
    if ($exactPriceMap.ContainsKey($id)) {
        $item.Price = $exactPriceMap[$id]
    }
    Write-Host "Item $id => "$item.Price" => "$item.Title.Substring(0, [Math]::Min(50, $item.Title.Length))
    $final82 += $item
}

$final82 | ConvertTo-Json | Out-File -FilePath "all_82_with_exact_scraped_prices.json" -Encoding utf8
Write-Host "Saved all_82_with_exact_scraped_prices.json!"
