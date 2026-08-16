$html = Get-Content -Path "ebay_raw.html" -Raw

# Search for JSON blobs embedded in eBay store page (e.g. window.__INITIAL_STATE__ or item items array)
$jsonMatches = [regex]::Matches($html, '(?s)"items":\s*(\[\{.*?\}\])')
Write-Host "Found item JSON blocks: "$jsonMatches.Count

$itemIds = [regex]::Matches($html, 'itm/(\d{12})') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

Write-Host "Found unique item IDs:" $itemIds.Count

$results = @()

foreach ($id in $itemIds) {
    # Extract block surrounding this item ID
    $pattern = [regex]::Escape($id)
    $blockMatch = [regex]::Match($html, "(?s)<a[^>]*itm/$id.*?>.*?</a>")
    
    # Extract title
    $titleMatch = [regex]::Match($html, "href=`"[^`"]*itm/$id[^`"]*`"[^>]*title=`"([^`"]+)`"")
    if (-not $titleMatch.Success) {
        $titleMatch = [regex]::Match($html, "href=`"[^`"]*itm/$id[^`"]*`"[^>]*>([^<]+)</a>")
    }
    
    # Extract image URL
    $imgMatch = [regex]::Match($html, "i\.ebayimg\.com/images/g/([^/]+)/s-l\d+\.(jpg|png|webp)")
    
    # Extract price
    $priceMatch = [regex]::Match($html, "£[\d,]+(?:\.\d{2})?")
    
    $results += [PSCustomObject]@{
        Id = $id
        Url = "https://www.ebay.co.uk/itm/$id"
        TitleMatch = $titleMatch.Groups[1].Value
    }
}

$results | ConvertTo-Json | Out-File -FilePath "parsed_items.json" -Encoding utf8
Write-Host "Wrote parsed_items.json"
