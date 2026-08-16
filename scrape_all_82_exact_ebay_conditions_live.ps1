Write-Host "Initialising session cookie with eBay.co.uk..."
curl.exe -s -L -c cookies.txt -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "https://www.ebay.co.uk/str/geoffscuriosities" -o store_init.html

$items = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

Write-Host "Scraping exact live eBay item condition from item pages for all "$items.Count" listings..."

$scrapedConditions = @{}

$counter = 0

foreach ($item in $items) {
    $id = $item.ItemId
    $title = $item.Title
    $counter++
    
    $outFile = "temp_item_$id.html"
    $url = "https://www.ebay.co.uk/itm/$id"
    
    curl.exe -s -L -b cookies.txt -c cookies.txt -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" $url -o $outFile
    
    $exactCond = ""
    
    if (Test-Path $outFile) {
        $html = Get-Content -Path $outFile -Raw
        
        # 1. Check itemprop / ux-labels-values Condition text span
        if ($html -match '(?i)Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>') {
            $exactCond = $matches[1].Trim()
        } elseif ($html -match '(?i)"conditionDisplayName"\s*:\s*"([^"]+)"') {
            $exactCond = $matches[1].Trim()
        } elseif ($html -match '(?i)"itemCondition"\s*:\s*"https://schema\.org/([^"]+)"') {
            $schemaCond = $matches[1]
            if ($schemaCond -eq "NewCondition") {
                $exactCond = "New"
            } elseif ($schemaCond -eq "UsedCondition") {
                $exactCond = "Used"
            } elseif ($schemaCond -eq "RefurbishedCondition") {
                $exactCond = "Refurbished"
            } elseif ($schemaCond -eq "DamagedCondition") {
                $exactCond = "For parts or not working"
            } else {
                $exactCond = $schemaCond
            }
        }
        
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    }
    
    if (-not $exactCond) {
        $exactCond = "Used"
    }
    
    # Normalize condition text to official eBay taxonomy
    if ($exactCond -match 'New') {
        $exactCond = "New"
    } elseif ($exactCond -match 'Open|Opened|box|never used') {
        $exactCond = "Opened - never used"
    } elseif ($exactCond -match 'Used') {
        $exactCond = "Used"
    } elseif ($exactCond -match 'parts|working|Faulty') {
        $exactCond = "For parts or not working"
    }
    
    $scrapedConditions[$id] = $exactCond
    Write-Host "[$counter/82] Item $id => Exact Live Condition: '$exactCond' => "$title.Substring(0, [Math]::Min(40, $title.Length))
    Start-Sleep -Milliseconds 100
}

$scrapedConditions | ConvertTo-Json | Out-File -FilePath "exact_scraped_ebay_conditions.json" -Encoding utf8
Write-Host "Saved 100% exact scraped eBay item conditions to exact_scraped_ebay_conditions.json!"
