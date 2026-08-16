$html = Get-Content -Path "ebay_raw.html" -Raw

$matches = [regex]::Matches($html, 'https://www\.ebay\.co\.uk/itm/(\d+)\?[^"]*:g:([^"&\s]+)')

$items = @()
$seen = @{}

foreach ($m in $matches) {
    $itemId = $m.Groups[1].Value
    $imgHash = $m.Groups[2].Value
    
    if (-not $seen.ContainsKey($itemId)) {
        $seen[$itemId] = $true
        
        $pos = $html.IndexOf($itemId)
        $start = [Math]::Max(0, $pos - 600)
        $len = [Math]::Min(1600, $html.Length - $start)
        $block = $html.Substring($start, $len)
        
        # Title
        $title = ""
        if ($block -match 'aria-label="([^"]+)"') {
            $title = $matches[1]
        } elseif ($block -match 'alt="([^"]+)"') {
            $title = $matches[1]
        }
        
        $title = $title -replace '^watch\s*', '' -replace '&#34;', '"' -replace '&amp;', '&'
        
        # Extract Price (e.g. £1,049.00 or £2,599.00)
        $price = ""
        $priceMatches = [regex]::Matches($block, '£[\d,]+(?:\.\d{2})?')
        if ($priceMatches.Count -gt 0) {
            $price = $priceMatches[0].Value
        }
        
        $imgUrl = "https://i.ebayimg.com/images/g/$imgHash/s-l500.jpg"
        $localImgName = "ebay_item_$itemId.jpg"
        $localImgPath = "images/$localImgName"
        
        # Filter: Exclude Sony camera accessories, focus 100% on laptops/gaming/workstations
        if ($title -and $title -notmatch 'Sony Alpha|Sony FE|Sony E-mount' -and $title -notmatch 'Shop on eBay') {
            $items += [PSCustomObject]@{
                ItemId = $itemId
                Title = $title.Trim()
                Price = if ($price) { $price } else { "View Price on eBay" }
                Url = "https://www.ebay.co.uk/itm/$itemId"
                Image = $localImgPath
                ImageUrl = $imgUrl
            }
        }
    }
}

Write-Host "Total real laptop items extracted:" $items.Count
$items | ConvertTo-Json | Out-File -FilePath "exact_store_laptops.json" -Encoding utf8

$items | Select-Object ItemId, Title, Price, Image | Format-Table -AutoSize
