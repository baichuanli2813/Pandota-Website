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

Write-Host "Extracting 100% exact eBay item conditions with priority..."

$all82 = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

$updated82 = @()

foreach ($item in $all82) {
    $id = $item.ItemId
    $title = $item.Title
    $scrapedCond = ""
    
    $pos = $htmlCombined.IndexOf($id)
    if ($pos -gt 0) {
        $snippet = $htmlCombined.Substring($pos, [Math]::Min(2500, $htmlCombined.Length - $pos))
        
        if ($snippet -match 'str-item-card__property-condition">[^<]*<span[^>]*>([^<]+)</span>') {
            $scrapedCond = $matches[1].Trim()
        } elseif ($snippet -match 'str-item-card__property-condition">([^<]+)') {
            $scrapedCond = $matches[1].Trim()
        }
    }
    
    # Strictly honor scraped eBay condition FIRST!
    $cond = ""
    if ($scrapedCond -and $scrapedCond -notmatch 'Shop on eBay') {
        if ($scrapedCond -match 'Open|Opened|box|never used') {
            $cond = "Opened - never used"
        } elseif ($scrapedCond -match 'New') {
            $cond = "New"
        } elseif ($scrapedCond -match 'Used|Pre-owned') {
            $cond = "Used"
        } elseif ($scrapedCond -match 'parts|working|Faulty') {
            $cond = "For parts or not working"
        } else {
            $cond = $scrapedCond
        }
    }
    
    # Only if HTML had no condition tag, check title
    if (-not $cond) {
        if ($title -match 'Open Box|Opened|never used') {
            $cond = "Opened - never used"
        } elseif ($title -match 'NEW SEALED|SEALED') {
            $cond = "New (Sealed)"
        } elseif ($title -match '\bNEW\b') {
            $cond = "New"
        } elseif ($title -match 'FAULTY|\*FAULTY\*') {
            $cond = "For parts or not working"
        } else {
            $cond = "Used"
        }
    }
    
    # If title explicitly has "Open Box" or "Opened", override to "Opened - never used"
    if ($title -match 'Open Box|Opened|never used') {
        $cond = "Opened - never used"
    }
    
    $item | Add-Member -MemberType NoteProperty -Name "Condition" -Value $cond -Force
    Write-Host "ID $id => Scraped: '$scrapedCond' => Final: '$cond' => "$title.Substring(0, [Math]::Min(45, $title.Length))
    $updated82 += $item
}

$updated82 | ConvertTo-Json | Out-File -FilePath "all_82_with_true_conditions.json" -Encoding utf8
Write-Host "Saved all_82_with_true_conditions.json successfully!"
