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

Write-Host "Extracting exact eBay item conditions for all store listings..."

# Regex matching item ID and condition element in eBay store card:
# data-testid=ig-(\d+) ... str-item-card__property-condition">([^<]+)
$matches = [regex]::Matches($htmlCombined, '(?s)data-testid=ig-(\d+).*?str-item-card__property-condition">([^<]+)')

$conditionMap = @{}

foreach ($m in $matches) {
    $itemId = $m.Groups[1].Value
    $rawCond = $m.Groups[2].Value.Trim()
    
    if ($rawCond) {
        $conditionMap[$itemId] = $rawCond
    }
}

Write-Host "Extracted conditions count from HTML:" $conditionMap.Count

# Load current 82 listings dataset
$all82 = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

$updated82 = @()

foreach ($item in $all82) {
    $id = $item.ItemId
    $title = $item.Title
    $cond = ""
    
    if ($conditionMap.ContainsKey($id)) {
        $cond = $conditionMap[$id]
    } else {
        # Fallback condition check from title text
        if ($title -match 'NEW SEALED|SEALED') {
            $cond = "New (Sealed)"
        } elseif ($title -match '\bNEW\b') {
            $cond = "New"
        } elseif ($title -match 'Open Box|Opened|Unused') {
            $cond = "Opened - never used"
        } elseif ($title -match 'FAULTY|\*FAULTY\*') {
            $cond = "For parts or not working"
        } else {
            $cond = "Used"
        }
    }
    
    # Normalize condition text
    if ($title -match 'NEW SEALED|SEALED') {
        $cond = "New (Sealed)"
    } elseif ($title -match '\bNEW\b' -and $cond -notmatch 'Sealed') {
        $cond = "New"
    } elseif ($cond -match 'Open|Opened') {
        $cond = "Opened - never used"
    } elseif ($cond -match 'Used|Pre-owned') {
        $cond = "Used"
    } elseif ($title -match 'FAULTY|\*FAULTY\*') {
        $cond = "For parts or not working"
    }
    
    $item | Add-Member -MemberType NoteProperty -Name "Condition" -Value $cond -Force
    Write-Host "Item $id => Condition: $cond => "$title.Substring(0, [Math]::Min(45, $title.Length))
    $updated82 += $item
}

$updated82 | ConvertTo-Json | Out-File -FilePath "all_82_with_conditions.json" -Encoding utf8
Write-Host "Saved all_82_with_conditions.json"
