$all82 = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json

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

Write-Host "Extracting condition for all 82 items..."

$updated82 = @()

foreach ($item in $all82) {
    $id = $item.ItemId
    $title = $item.Title
    $cond = ""
    
    $pos = $htmlCombined.IndexOf($id)
    if ($pos -gt 0) {
        $snippet = $htmlCombined.Substring($pos, [Math]::Min(2000, $htmlCombined.Length - $pos))
        if ($snippet -match 'str-item-card__property-condition">[^<]*<span[^>]*>([^<]+)</span>') {
            $cond = $matches[1].Trim()
        } elseif ($snippet -match 'str-item-card__property-condition">([^<]+)') {
            $cond = $matches[1].Trim()
        }
    }
    
    # Fallback to strict Title condition parsing if HTML tag missing
    if (-not $cond -or $cond -match 'Shop on eBay') {
        if ($title -match 'NEW SEALED|SEALED') {
            $cond = "New (Sealed)"
        } elseif ($title -match '\bNEW\b') {
            $cond = "New"
        } elseif ($title -match 'Open Box|Opened') {
            $cond = "Opened - never used"
        } elseif ($title -match 'FAULTY|\*FAULTY\*') {
            $cond = "For parts or not working"
        } else {
            $cond = "Used"
        }
    }
    
    # Normalize condition text cleanly
    if ($title -match 'NEW SEALED|SEALED') {
        $cond = "New (Sealed)"
    } elseif ($cond -eq "New" -or ($title -match '\bNEW\b' -and $cond -notmatch 'Sealed')) {
        $cond = "New"
    } elseif ($cond -match 'Open|Opened') {
        $cond = "Opened - never used"
    } elseif ($cond -match 'Used|Pre-owned') {
        $cond = "Used"
    } elseif ($title -match 'FAULTY|\*FAULTY\*') {
        $cond = "For parts or not working"
    }
    
    $item | Add-Member -MemberType NoteProperty -Name "Condition" -Value $cond -Force
    Write-Host "ID $id => $cond => "$title.Substring(0, [Math]::Min(45, $title.Length))
    $updated82 += $item
}

$updated82 | ConvertTo-Json | Out-File -FilePath "all_82_with_exact_conditions.json" -Encoding utf8
Write-Host "Saved all_82_with_exact_conditions.json successfully!"
