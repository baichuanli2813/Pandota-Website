$htmlCombined = ""
for ($p = 1; $p -le 6; $p++) {
    $path = "ebay_page_$p.html"
    if (Test-Path $path) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes) + "`n"
    }
}
if (Test-Path "ebay_raw.html") {
    $bytes = [System.IO.File]::ReadAllBytes("ebay_raw.html")
    $htmlCombined += [System.Text.Encoding]::UTF8.GetString($bytes)
}

$all82 = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

Write-Host "Inspecting raw condition text snippets for all 82 items..."

$itemsWithTrueCond = @()

foreach ($item in $all82) {
    $id = $item.ItemId
    $title = $item.Title
    
    $pos = $htmlCombined.IndexOf($id)
    $snippet = ""
    if ($pos -gt 0) {
        $snippet = $htmlCombined.Substring($pos, [Math]::Min(3000, $htmlCombined.Length - $pos))
    }
    
    $cond = "Used"
    
    if ($snippet -match 'str-item-card__property-condition"[^>]*>.*?([A-Za-z0-9\s\-\(\)]+)</span') {
        $rawCond = $matches[1].Trim()
        if ($rawCond -match 'Opened|box|never used|Open') {
            $cond = "Opened - never used"
        } elseif ($rawCond -match 'New') {
            $cond = "New"
        } elseif ($rawCond -match 'Used') {
            $cond = "Used"
        }
    }
    
    # Check if snippet or title contains Open box / Opened
    if ($snippet -match 'Opened|Open box|Unused') {
        $cond = "Opened - never used"
    } elseif ($title -match 'Open Box|Opened|never used|Open-box') {
        $cond = "Opened - never used"
    } elseif ($title -match 'NEW SEALED|SEALED') {
        $cond = "New (Sealed)"
    } elseif ($cond -eq "Used" -and $title -match '^\s*NEW\b') {
        $cond = "New"
    }
    
    if ($title -match 'FAULTY|\*FAULTY\*') {
        $cond = "For parts or not working"
    }
    
    $item | Add-Member -MemberType NoteProperty -Name "Condition" -Value $cond -Force
    Write-Host "ID $id => $cond => "$title.Substring(0, [Math]::Min(40, $title.Length))
    $itemsWithTrueCond += $item
}

$itemsWithTrueCond | ConvertTo-Json | Out-File -FilePath "all_82_with_true_cond_final.json" -Encoding utf8
Write-Host "Saved all_82_with_true_cond_final.json!"
