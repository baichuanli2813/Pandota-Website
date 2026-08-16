# ==============================================================================
# Pandota Ltd - Live eBay Feedback & Ratings Table Sync Script
# Scrapes geoff_lee367 feedback profile and updates static ratings table on index.html
# ==============================================================================

Write-Host "Fetching live feedback profile from eBay (geoff_lee367)..."

$tempFile = [System.IO.Path]::GetTempFileName()
curl.exe -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: en-GB,en;q=0.9" -L "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367" -o $tempFile

if (Test-Path $tempFile) {
    $html = Get-Content $tempFile -Raw -Encoding utf8
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    if ($html -and $html.Length -gt 1000) {
        Write-Host "Successfully fetched feedback profile HTML ($($html.Length) bytes)!"

        # Extract Total Feedback Score (e.g. <p aria-label="Feedback score is 6253">6253</p>)
        $totalScore = ""
        if ($html -match '(?i)aria-label="Feedback score is\s*(\d+)"') {
            $rawScore = [int]$matches[1]
            $totalScore = "{0:N0}" -f $rawScore
        } elseif ($html -match '(?i)geoff_lee367</a>&nbsp;\(<p[^>]*>(\d+)</p>') {
            $rawScore = [int]$matches[1]
            $totalScore = "{0:N0}" -f $rawScore
        }

        # Extract Positive % (e.g. Positive Feedback (last 12 months): 100%)
        $posPercent = ""
        if ($html -match '(?i)Positive Feedback\s*\([^)]*\):\s*(\d+(?:\.\d+)?%)') {
            $posPercent = $matches[1]
        }

        # Extract Table Cells: Positive, Neutral, Negative for 1M, 6M, 12M
        $p1m = if ($html -match '(?i)positive Feedback in last 1 month">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "" }
        $p6m = if ($html -match '(?i)positive Feedback in last 6 months">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "" }
        $p12m = if ($html -match '(?i)positive Feedback in last 12 months">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "" }

        $n1m = if ($html -match '(?i)neutral Feedback in last 1 month">([\d,]+)<') { $matches[1] } else { "" }
        $n6m = if ($html -match '(?i)neutral Feedback in last 6 months">([\d,]+)<') { $matches[1] } else { "" }
        $n12m = if ($html -match '(?i)neutral Feedback in last 12 months">([\d,]+)<') { $matches[1] } else { "" }

        $neg1m = if ($html -match '(?i)negative Feedback in last 1 month">([\d,]+)<') { $matches[1] } else { "" }
        $neg6m = if ($html -match '(?i)negative Feedback in last 6 months">([\d,]+)<') { $matches[1] } else { "" }
        $neg12m = if ($html -match '(?i)negative Feedback in last 12 months">([\d,]+)<') { $matches[1] } else { "" }

        Write-Host "Scraped Live Ratings:"
        Write-Host "  Total Score: $totalScore | Positive %: $posPercent"
        Write-Host "  Positive: 1M=$p1m | 6M=$p6m | 12M=$p12m"
        Write-Host "  Neutral:  1M=$n1m | 6M=$n6m | 12M=$n12m"
        Write-Host "  Negative: 1M=$neg1m | 6M=$neg6m | 12M=$neg12m"

        # Update index.html
        if (Test-Path "index.html") {
            $indexHtml = Get-Content "index.html" -Raw -Encoding utf8

            if ($totalScore) {
                $indexHtml = $indexHtml -replace 'id="fb-total-score">[\d,]+<', "id=`"fb-total-score`">$totalScore<"
            }
            if ($p1m) {
                $indexHtml = $indexHtml -replace 'id="fb-1m-pos">[\d,]+<', "id=`"fb-1m-pos`">$p1m<"
                $indexHtml = $indexHtml -replace 'id="fb-6m-pos">[\d,]+<', "id=`"fb-6m-pos`">$p6m<"
                $indexHtml = $indexHtml -replace 'id="fb-12m-pos">[\d,]+<', "id=`"fb-12m-pos`">$p12m<"
            }
            if ($n1m) {
                $indexHtml = $indexHtml -replace 'id="fb-1m-neu">[\d,]+<', "id=`"fb-1m-neu`">$n1m<"
                $indexHtml = $indexHtml -replace 'id="fb-6m-neu">[\d,]+<', "id=`"fb-6m-neu`">$n6m<"
                $indexHtml = $indexHtml -replace 'id="fb-12m-neu">[\d,]+<', "id=`"fb-12m-neu`">$n12m<"
            }
            if ($neg1m) {
                $indexHtml = $indexHtml -replace 'id="fb-1m-neg">[\d,]+<', "id=`"fb-1m-neg`">$neg1m<"
                $indexHtml = $indexHtml -replace 'id="fb-6m-neg">[\d,]+<', "id=`"fb-6m-neg`">$neg6m<"
                $indexHtml = $indexHtml -replace 'id="fb-12m-neg">[\d,]+<', "id=`"fb-12m-neg`">$neg12m<"
            }

            [System.IO.File]::WriteAllText("$pwd\index.html", $indexHtml, [System.Text.Encoding]::UTF8)
            Write-Host "Successfully updated index.html with live feedback score ($totalScore) and ratings!"
        }
    } else {
        Write-Host "Notice: Could not parse live feedback HTML, keeping current ratings."
    }
} else {
    Write-Host "Notice: Live feedback request timed out, keeping current ratings."
}
