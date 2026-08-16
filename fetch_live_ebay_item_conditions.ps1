Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
$client.DefaultRequestHeaders.Add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
$client.DefaultRequestHeaders.Add("Accept-Language", "en-GB,en-US;q=0.9,en;q=0.8")

$items = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

Write-Host "Fetching live eBay item condition for all "$items.Count" items directly from eBay.co.uk..."

$results = @{}

foreach ($item in $items) {
    $id = $item.ItemId
    $title = $item.Title
    $url = "https://www.ebay.co.uk/itm/$id"
    
    $exactCond = "Used"
    
    try {
        $html = $client.GetStringAsync($url).Result
        
        if ($html -match '"itemCondition"\s*:\s*"https://schema\.org/([^"]+)"') {
            $schemaCond = $matches[1]
            if ($schemaCond -eq "NewCondition") {
                $exactCond = "New"
            } elseif ($schemaCond -eq "UsedCondition") {
                $exactCond = "Used"
            } elseif ($schemaCond -eq "RefurbishedCondition") {
                $exactCond = "Refurbished"
            } elseif ($schemaCond -eq "DamagedCondition") {
                $exactCond = "For parts or not working"
            }
        } elseif ($html -match '"conditionDisplayName"\s*:\s*"([^"]+)"') {
            $exactCond = $matches[1]
        } elseif ($html -match 'Condition:</span>.*?<span[^>]*class="ux-textspans"[^>]*>([^<]+)</span>') {
            $exactCond = $matches[1].Trim()
        } else {
            # Fallback check from title
            if ($title -match 'SEALED') {
                $exactCond = "New"
            } elseif ($title -match 'FAULTY|\*FAULTY\*') {
                $exactCond = "For parts or not working"
            } elseif ($title -match 'Open Box|Opened|Unused') {
                $exactCond = "Opened - never used"
            } elseif ($title -match '^\s*NEW\b') {
                $exactCond = "New"
            } else {
                $exactCond = "Used"
            }
        }
    } catch {
        # Fallback check if request fails
        if ($title -match 'SEALED') {
            $exactCond = "New"
        } elseif ($title -match 'FAULTY|\*FAULTY\*') {
            $exactCond = "For parts or not working"
        } elseif ($title -match 'Open Box|Opened|Unused') {
            $exactCond = "Opened - never used"
        } elseif ($title -match '^\s*NEW\b') {
            $exactCond = "New"
        } else {
            $exactCond = "Used"
        }
    }
    
    $results[$id] = $exactCond
    Write-Host "Item $id => Live Condition: $exactCond => "$title.Substring(0, [Math]::Min(45, $title.Length))
    Start-Sleep -Milliseconds 150
}

$results | ConvertTo-Json | Out-File -FilePath "live_scraped_ebay_conditions.json" -Encoding utf8
Write-Host "Saved live_scraped_ebay_conditions.json successfully!"
