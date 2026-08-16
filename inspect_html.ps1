$html = Get-Content -Path "ebay_raw.html" -Raw

# Search for /itm/ occurrences
$matches = [regex]::Matches($html, '(?s)<a[^>]+href="([^"]*itm/(\d+)[^"]*)"[^>]*>(.*?)</a>')
Write-Host "Total item link matches found: "$matches.Count

$items = @()
$seen = @{}

foreach ($m in $matches) {
    $url = $m.Groups[1].Value
    $id = $m.Groups[2].Value
    $inner = $m.Groups[3].Value
    
    if (-not $seen.ContainsKey($id)) {
        $seen[$id] = $true
        
        # Look around in html for img and price near this link
        $pos = $html.IndexOf($id)
        $start = [Math]::Max(0, $pos - 500)
        $len = [Math]::Min(1500, $html.Length - $start)
        $snippet = $html.Substring($start, $len)
        
        # Extract title
        $title = ""
        if ($snippet -match 'class="str-item-card__property-title"[^>]*><span[^>]*>([^<]+)</span>') {
            $title = $matches[1]
        } elseif ($snippet -match 'alt="([^"]+)"') {
            $title = $matches[1]
        }
        
        # Extract image
        $img = ""
        if ($snippet -match '(https://i\.ebayimg\.com/images/g/[^/]+/s-l\d+\.(jpg|png|webp))') {
            $img = $matches[1] -replace 's-l\d+', 's-l500'
        }
        
        # Extract price
        $price = ""
        if ($snippet -match '(£[\d,]+(?:\.\d{2})?)') {
            $price = $matches[1]
        }
        
        $items += [PSCustomObject]@{
            Id = $id
            Url = "https://www.ebay.co.uk/itm/$id"
            Title = $title
            Price = $price
            Image = $img
            Snippet = $snippet.Substring(0, [Math]::Min(200, $snippet.Length))
        }
    }
}

$items | Select-Object -First 10 | Format-List
$items | ConvertTo-Json | Out-File -FilePath "live_ebay_listings.json" -Encoding utf8
