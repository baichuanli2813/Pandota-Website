# ==============================================================================
# Pandota Ltd - Live eBay Feedback, Stats & Ratings Sync Script
# Scrapes geoff_lee367 profile & feedback to update hero stats and ratings table
# Runs twice daily via GitHub Actions automated cloud workflow
# ==============================================================================

Write-Host "Fetching live profile & feedback stats from eBay (geoff_lee367)..."

$tempFileProfile = [System.IO.Path]::GetTempFileName()
$tempFileFeedback = [System.IO.Path]::GetTempFileName()

curl.exe -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: en-GB,en;q=0.9" -L "https://www.ebay.co.uk/usr/geoff_lee367" -o $tempFileProfile
curl.exe -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: en-GB,en;q=0.9" -L "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367" -o $tempFileFeedback

$fbPercent = "100%"
$itemsSold = "11,000+"
$followers = "5.9K+"
$totalScore = "6,253"
$p1m = ""; $p6m = ""; $p12m = ""
$n1m = ""; $n6m = ""; $n12m = ""
$neg1m = ""; $neg6m = ""; $neg12m = ""

# 1. Parse Profile HTML (Hero Stats)
if (Test-Path $tempFileProfile) {
    $htmlProfile = Get-Content $tempFileProfile -Raw -Encoding utf8
    Remove-Item $tempFileProfile -Force -ErrorAction SilentlyContinue

    if ($htmlProfile -and $htmlProfile.Length -gt 1000) {
        if ($htmlProfile -match '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*positive\s*Feedback') {
            $fbPercent = $matches[1].Trim()
        }
        if ($htmlProfile -match '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*items\s*sold') {
            $rawSold = $matches[1].Trim()
            $itemsSold = if ($rawSold -match '\+') { $rawSold } else { "$rawSold+" }
        }
        if ($htmlProfile -match '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*followers') {
            $rawFollowers = $matches[1].Trim()
            $followers = if ($rawFollowers -match '\+') { $rawFollowers } else { "$rawFollowers+" }
        }
    }
}

# 2. Parse Feedback Profile HTML (Ratings Table & Exact Feedback Score)
if (Test-Path $tempFileFeedback) {
    $htmlFeedback = Get-Content $tempFileFeedback -Raw -Encoding utf8
    Remove-Item $tempFileFeedback -Force -ErrorAction SilentlyContinue

    if ($htmlFeedback -and $htmlFeedback.Length -gt 1000) {
        # Total Feedback Score
        if ($htmlFeedback -match '(?i)aria-label="Feedback score is\s*(\d+)"') {
            $totalScore = "{0:N0}" -f [int]$matches[1]
        } elseif ($htmlFeedback -match '(?i)geoff_lee367</a>&nbsp;\(<p[^>]*>(\d+)</p>') {
            $totalScore = "{0:N0}" -f [int]$matches[1]
        }

        # Detailed Breakdown Table
        $p1m = if ($htmlFeedback -match '(?i)positive Feedback in last 1 month">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "333" }
        $p6m = if ($htmlFeedback -match '(?i)positive Feedback in last 6 months">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "1,840" }
        $p12m = if ($htmlFeedback -match '(?i)positive Feedback in last 12 months">([\d,]+)<') { "{0:N0}" -f [int]($matches[1] -replace ',', '') } else { "3,463" }

        $n1m = if ($htmlFeedback -match '(?i)neutral Feedback in last 1 month">([\d,]+)<') { $matches[1] } else { "0" }
        $n6m = if ($htmlFeedback -match '(?i)neutral Feedback in last 6 months">([\d,]+)<') { $matches[1] } else { "0" }
        $n12m = if ($htmlFeedback -match '(?i)neutral Feedback in last 12 months">([\d,]+)<') { $matches[1] } else { "0" }

        $neg1m = if ($htmlFeedback -match '(?i)negative Feedback in last 1 month">([\d,]+)<') { $matches[1] } else { "0" }
        $neg6m = if ($htmlFeedback -match '(?i)negative Feedback in last 6 months">([\d,]+)<') { $matches[1] } else { "0" }
        $neg12m = if ($htmlFeedback -match '(?i)negative Feedback in last 12 months">([\d,]+)<') { $matches[1] } else { "0" }
    }
}

Write-Host "Scraped Live Store & Feedback Stats:"
Write-Host "  Hero Positive %: $fbPercent"
Write-Host "  Hero Items Sold: $itemsSold"
Write-Host "  Hero Followers:  $followers"
Write-Host "  Feedback Score:  $totalScore"
Write-Host "  Positive 1M/6M/12M: $p1m / $p6m / $p12m"

# Save live stats JSON for client-side live hydration
$statsObj = [ordered]@{
    positive_feedback = $fbPercent
    items_sold        = $itemsSold
    followers         = $followers
    feedback_score    = $totalScore
    positive_1m       = $p1m
    positive_6m       = $p6m
    positive_12m      = $p12m
    last_updated      = [DateTime]::UtcNow.ToString("o")
}
$statsObj | ConvertTo-Json -Depth 3 | Set-Content "live_store_stats.json" -Encoding utf8

# Update index.html
if (Test-Path "index.html") {
    $indexHtml = Get-Content "index.html" -Raw -Encoding utf8

    # 1. Update Hero Stats
    $indexHtml = $indexHtml -replace 'id="stat-feedback"[^>]*>[^<]+<', "id=`"stat-feedback`">$fbPercent<"
    $indexHtml = $indexHtml -replace 'id="stat-items-sold"[^>]*>[^<]+<', "id=`"stat-items-sold`">$itemsSold<"
    $indexHtml = $indexHtml -replace 'id="stat-followers"[^>]*>[^<]+<', "id=`"stat-followers`">$followers<"

    # 2. Update Feedback Ratings Table
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
    Write-Host "Successfully updated index.html with live Hero stats and feedback ratings!"
}
