$allParsedItems = @()
$seenIds = @{}

Write-Host "Scraping all pagination pages of Pandota eBay store..."

for ($page = 1; $page -le 10; $page++) {
    $pageUrl = "https://www.ebay.co.uk/str/geoffscuriosities?_pgn=$page"
    $outputFile = "ebay_page_$page.html"
    
    Write-Host "Fetching page $page : $pageUrl"
    
    curl.exe -s -L $pageUrl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -o $outputFile
    
    if (-not (Test-Path $outputFile)) { continue }
    
    $bytes = [System.IO.File]::ReadAllBytes($outputFile)
    $html = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    # Extract item card blocks
    $matches = [regex]::Matches($html, '(?s)data-testid=ig-(\d+).*?href="(https://www\.ebay\.co\.uk/itm/\d+[^\"]*)".*?aria-label="([^"]+)"')
    
    if ($matches.Count -eq 0) {
        # Fallback regex for item URLs and images
        $matches = [regex]::Matches($html, 'https://www\.ebay\.co\.uk/itm/(\d+)\?[^"]*:g:([^"&\s]+)')
    }
    
    Write-Host "Page $page found "$matches.Count" raw items."
    
    if ($matches.Count -eq 0) {
        Write-Host "No more items found on page $page. Stopping pagination."
        break
    }
    
    foreach ($m in $matches) {
        $itemId = $m.Groups[1].Value
        $imgHash = $m.Groups[2].Value
        
        if (-not $seenIds.ContainsKey($itemId)) {
            $seenIds[$itemId] = $true
            
            $pos = $html.IndexOf($itemId)
            $start = [Math]::Max(0, $pos - 400)
            $len = [Math]::Min(2000, $html.Length - $start)
            $snippet = $html.Substring($start, $len)
            
            # Title
            $title = ""
            if ($snippet -match 'alt="([^"]+)"') {
                $title = $matches[1]
            } elseif ($snippet -match 'aria-label="([^"]+)"') {
                $title = $matches[1]
            }
            
            $title = $title -replace '^watch\s*', '' -replace '&#34;', '"' -replace '&amp;', '&'
            
            # Price
            $price = ""
            if ($snippet -match 'str-item-card__property-displayPrice">.*?([\d,]+\.\d{2})') {
                $price = "£" + $matches[1]
            } elseif ($snippet -match '£([\d,]+\.\d{2})') {
                $price = "£" + $matches[1]
            }
            
            $imgUrl = if ($imgHash) { "https://i.ebayimg.com/images/g/$imgHash/s-l500.jpg" } else { "" }
            if ($snippet -match '(https://i\.ebayimg\.com/images/g/[^/]+/s-l\d+\.(jpg|png|webp))') {
                $imgUrl = $matches[1] -replace 's-l\d+', 's-l500'
            }
            
            $localImgName = "ebay_item_$itemId.jpg"
            $localImgPath = "images/$localImgName"
            
            # Download image if not existing
            $outPath = Join-Path "c:\Users\User\Desktop\PANDOTA ACOUNTS\Website" $localImgPath
            if ($imgUrl -and -not (Test-Path $outPath)) {
                try {
                    Invoke-WebRequest -Uri $imgUrl -OutFile $outPath -ErrorAction SilentlyContinue
                } catch {}
            }
            
            if ($title -and $title -notmatch 'Shop on eBay') {
                $allParsedItems += [PSCustomObject]@{
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
}

Write-Host "GRAND TOTAL UNIQUE STORE ITEMS FETCHED:" $allParsedItems.Count
$allParsedItems | ConvertTo-Json | Out-File -FilePath "all_store_listings.json" -Encoding utf8
Write-Host "Saved all_store_listings.json"
