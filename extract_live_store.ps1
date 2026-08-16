$html = Get-Content -Path "ebay_raw.html" -Raw

# In eBay modern store pages, items are in JS data or HTML cards.
# Let's search for item cards with href containing /itm/
# We split by <article or <div class="str-item-card" or <li

$itemBlocks = $html -split 'class="str-item-card'

$parsedList = @()
$seen = @{}

foreach ($block in $itemBlocks) {
    if ($block -match 'href="(https://www\.ebay\.co\.uk/itm/(\d+)[^"]*)"') {
        $url = $matches[1]
        $itemId = $matches[2]
        
        if (-not $seen.ContainsKey($itemId)) {
            $seen[$itemId] = $true
            
            # Title: aria-label or title or alt or text inside aria-label
            $title = ""
            if ($block -match 'alt="([^"]+)"') {
                $title = $matches[1]
            } elseif ($block -match 'aria-label="([^"]+)"') {
                $title = $matches[1]
            } elseif ($block -match 'str-item-card__property-title[^>]*>([^<]+)<') {
                $title = $matches[1]
            }
            
            # Price: £XXXX.XX
            $price = ""
            if ($block -match '(£[\d,]+(?:\.\d{2})?)') {
                $price = $matches[1]
            }
            
            # Image: s-l300 or s-l500 image URL
            $img = ""
            if ($block -match 'src="(https://i\.ebayimg\.com/images/g/[^"]+)"') {
                $img = $matches[1]
            } elseif ($block -match 'data-src="(https://i\.ebayimg\.com/images/g/[^"]+)"') {
                $img = $matches[1]
            }
            
            # Ensure high res image s-l500
            if ($img -and $img -match 's-l\d+') {
                $img = $img -replace 's-l\d+', 's-l500'
            }
            
            if ($title -and $title -notmatch 'Shop on eBay' -and $price) {
                $parsedList += [PSCustomObject]@{
                    ItemId = $itemId
                    Title = $title.Trim()
                    Price = $price.Trim()
                    Url = "https://www.ebay.co.uk/itm/$itemId"
                    Image = $img
                }
            }
        }
    }
}

Write-Host "Parsed valid items:" $parsedList.Count
$parsedList | ConvertTo-Json | Out-File -FilePath "valid_ebay_items.json" -Encoding utf8

# Print out top 10 items to check accuracy
$parsedList | Select-Object -First 10 | Format-Table -AutoSize
