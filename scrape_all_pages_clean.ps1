Write-Host "Scraping all pages of Pandota eBay store..."

$allParsedItems = @()
$seenIds = @{}

for ($page = 1; $page -le 6; $page++) {
    $pageUrl = "https://www.ebay.co.uk/str/geoffscuriosities?_pgn=$page"
    $outFile = "ebay_page_$page.html"
    
    Write-Host "Fetching Page $page : $pageUrl"
    curl.exe -s -L "$pageUrl" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -o $outFile
    
    if (-not (Test-Path $outFile)) { continue }
    
    $bytes = [System.IO.File]::ReadAllBytes($outFile)
    $html = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    $matches = [regex]::Matches($html, 'https://www\.ebay\.co\.uk/itm/(\d+)\?[^"]*:g:([^"&\s]+)')
    
    Write-Host "Page $page total item matches:" $matches.Count
    
    if ($matches.Count -eq 0) {
        Write-Host "Reached end of store listings."
        break
    }
    
    foreach ($m in $matches) {
        $itemId = $m.Groups[1].Value
        $imgHash = $m.Groups[2].Value
        
        if (-not $seenIds.ContainsKey($itemId)) {
            $seenIds[$itemId] = $true
            
            $pos = $html.IndexOf($itemId)
            $start = [Math]::Max(0, $pos - 400)
            $len = [Math]::Min(1800, $html.Length - $start)
            $snippet = $html.Substring($start, $len)
            
            # Extract Title
            $title = ""
            if ($snippet -match 'aria-label="([^"]+)"') {
                $title = $matches[1]
            } elseif ($snippet -match 'alt="([^"]+)"') {
                $title = $matches[1]
            }
            
            $title = $title -replace '^watch\s*', '' -replace '&#34;', '"' -replace '&amp;', '&'
            
            # Extract Price
            $price = ""
            if ($snippet -match 'str-item-card__property-displayPrice">.*?([\d,]+\.\d{2})') {
                $price = "£" + $matches[1]
            } elseif ($snippet -match '£([\d,]+\.\d{2})') {
                $price = "£" + $matches[1]
            }
            
            $imgUrl = "https://i.ebayimg.com/images/g/$imgHash/s-l500.jpg"
            $localImgName = "ebay_item_$itemId.jpg"
            $localImgPath = "images/$localImgName"
            
            # Download image if missing
            $outPath = Join-Path "c:\Users\User\Desktop\PANDOTA ACOUNTS\Website" $localImgPath
            if (-not (Test-Path $outPath)) {
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

Write-Host "TOTAL ALL UNIQUE LIVE STORE LISTINGS:" $allParsedItems.Count
$allParsedItems | ConvertTo-Json | Out-File -FilePath "all_store_listings_full.json" -Encoding utf8
Write-Host "Saved all_store_listings_full.json"
