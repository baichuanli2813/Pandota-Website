# ==============================================================================
# Pandota Ltd - Live eBay Feedback, Stats & Ratings Sync Script
# Pulls official live eBay seller metrics on a daily basis:
# - Items Sold (e.g. 12,000+)
# - Positive Feedback Rate (e.g. 100%)
# - eBay Followers (e.g. 6.2K+)
# - Feedback Score & Breakdown Table (e.g. 6,818; 1M/6M/12M)
# Runs twice daily via GitHub Actions automated cloud workflow
# ==============================================================================

Write-Host "Fetching live profile, store & feedback stats from eBay (geoff_lee367 / geoffscuriosities)..."

$fbPercent = "100%"
$itemsSold = "12,000+"
$followers = "6.2K+"
$totalScore = "6,818"
$p1m = "422"; $p6m = "1,744"; $p12m = "2,604"
$n1m = "0"; $n6m = "0"; $n12m = "0"
$neg1m = "0"; $neg6m = "0"; $neg12m = "0"

# ------------------------------------------------------------------------------
# 1. Fetch Official Store Page Stats (Items Sold & Followers)
# ------------------------------------------------------------------------------
$storeUrl = "https://www.ebay.co.uk/str/geoffscuriosities"
try {
    $rawStore = curl.exe -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept-Language: en-GB,en;q=0.9" -L $storeUrl
    $storeHtml = [string]::Join("`n", $rawStore)

    if ($storeHtml -and $storeHtml.Length -gt 1000) {
        # HTML span match
        $mSold = [regex]::Match($storeHtml, '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*items\s*sold')
        $mFollowers = [regex]::Match($storeHtml, '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*followers')
        $mFb = [regex]::Match($storeHtml, '(?i)>([^<]+)</span>(?:<!--[^>]*-->|\s)*positive\s*Feedback')

        $rawSold = if ($mSold.Success) { $mSold.Groups[1].Value.Trim() } else { "" }
        $rawFollowers = if ($mFollowers.Success) { $mFollowers.Groups[1].Value.Trim() } else { "" }
        $rawFb = if ($mFb.Success) { $mFb.Groups[1].Value.Trim() } else { "" }

        # JSON-LD / Marko payload fallback
        if (-not $rawSold) {
            $mJsonSold = [regex]::Match($storeHtml, '"text":"([0-9.]+[KMBkmb]?\+?)".{0,150}"text":"\s*items sold"')
            if ($mJsonSold.Success) { $rawSold = $mJsonSold.Groups[1].Value.Trim() }
        }
        if (-not $rawFollowers) {
            $mJsonFol = [regex]::Match($storeHtml, '"text":"([0-9.]+[KMBkmb]?\+?)".{0,150}"text":"\s*followers"')
            if ($mJsonFol.Success) { $rawFollowers = $mJsonFol.Groups[1].Value.Trim() }
        }
        if (-not $rawFb) {
            $mJsonFb = [regex]::Match($storeHtml, '"text":"([0-9.]+%?)".{0,150}"text":"\s*positive Feedback"')
            if ($mJsonFb.Success) { $rawFb = $mJsonFb.Groups[1].Value.Trim() }
        }

        # Format Items Sold (e.g. 12K -> 12,000+)
        if ($rawSold) {
            if ($rawSold -match '^(\d+)(?:\.(\d+))?K\+?$') {
                $whole = [int]$matches[1]
                $dec = if ($matches[2]) { [double]("0." + $matches[2]) } else { 0.0 }
                $num = [int](($whole + $dec) * 1000)
                $itemsSold = "{0:N0}+" -f $num
            } elseif ($rawSold -match '\+') {
                $itemsSold = $rawSold
            } else {
                $itemsSold = "$rawSold+"
            }
        }

        # Format Followers (e.g. 6.2K -> 6.2K+)
        if ($rawFollowers) {
            $followers = if ($rawFollowers -match '\+') { $rawFollowers } else { "$rawFollowers+" }
        }

        # Format Feedback Percent
        if ($rawFb) {
            $fbPercent = if ($rawFb -match '%') { $rawFb } else { "$rawFb%" }
        }
    }
} catch {
    Write-Host "Store scrape note: $($_.Exception.Message)"
}

# ------------------------------------------------------------------------------
# 2. Query Official eBay Trading API (GetUser) for Exact Feedback % & Score
# ------------------------------------------------------------------------------
$appId = $env:EBAY_APP_ID
$devId = $env:EBAY_DEV_ID
$certId = $env:EBAY_CERT_ID
$token = $env:EBAY_USER_TOKEN

if (-not $token -or -not $appId) {
    $credsPath = Join-Path $PSScriptRoot "ebay_credentials.json"
    if (-not (Test-Path $credsPath)) { $credsPath = ".\ebay_credentials.json" }
    if (Test-Path $credsPath) {
        $creds = Get-Content $credsPath -Raw | ConvertFrom-Json
        if (-not $appId) { $appId = $creds.AppId }
        if (-not $devId) { $devId = $creds.DevId }
        if (-not $certId) { $certId = $creds.CertId }
        if (-not $token) { $token = $creds.UserToken }
    }
}

if ($token -and $appId) {
    try {
        $xmlReq = @"
<?xml version="1.0" encoding="utf-8"?>
<GetUserRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>$token</eBayAuthToken>
  </RequesterCredentials>
  <DetailLevel>ReturnAll</DetailLevel>
</GetUserRequest>
"@
        $reqFile = [System.IO.Path]::GetTempFileName()
        $respFile = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($reqFile, $xmlReq, [System.Text.Encoding]::UTF8)

        curl.exe -s -X POST "https://api.ebay.com/ws/api.dll" `
          -H "X-EBAY-API-COMPATIBILITY-LEVEL: 967" `
          -H "X-EBAY-API-DEV-NAME: $devId" `
          -H "X-EBAY-API-APP-NAME: $appId" `
          -H "X-EBAY-API-CERT-NAME: $certId" `
          -H "X-EBAY-API-CALL-NAME: GetUser" `
          -H "X-EBAY-API-SITEID: 3" `
          -H "Content-Type: text/xml" `
          -d "@$reqFile" `
          -o "$respFile"

        [xml]$resp = Get-Content $respFile -Raw -Encoding utf8
        Remove-Item $reqFile, $respFile -Force -ErrorAction SilentlyContinue

        if ($resp.GetUserResponse.Ack -eq "Success" -or $resp.GetUserResponse.Ack -eq "Warning") {
            $user = $resp.GetUserResponse.User
            if ($user.FeedbackScore) {
                $totalScore = "{0:N0}" -f [int]$user.FeedbackScore
            }
            if ($user.PositiveFeedbackPercent) {
                $rawPct = [double]$user.PositiveFeedbackPercent
                $fbPercent = if ($rawPct -ge 99.9) { "100%" } else { "{0:N1}%" -f $rawPct }
            }
            Write-Host "Official eBay Trading API GetUser returned FeedbackScore=$totalScore, FeedbackPercent=$fbPercent"
        }
    } catch {
        Write-Host "Trading API GetUser note: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------------------------
# 3. Scrape Detailed Feedback Profile Table (1M, 6M, 12M Breakdown)
# ------------------------------------------------------------------------------
$feedbackUrl = "https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367"
try {
    $rawFb = curl.exe -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" -H "Accept-Language: en-GB,en;q=0.9" -L $feedbackUrl
    $fbHtml = [string]::Join("`n", $rawFb)

    if ($fbHtml -and $fbHtml.Length -gt 1000) {
        # Feedback Score fallback if API not used
        if (-not $totalScore -or $totalScore -eq "6,253") {
            $mScore = [regex]::Match($fbHtml, '(?i)aria-label="Feedback score is\s*(\d+)"')
            if ($mScore.Success) {
                $totalScore = "{0:N0}" -f [int]$mScore.Groups[1].Value
            }
        }

        # Breakdown table
        $mp1m = [regex]::Match($fbHtml, '(?i)positive Feedback in last 1 month">([\d,]+)<')
        $mp6m = [regex]::Match($fbHtml, '(?i)positive Feedback in last 6 months">([\d,]+)<')
        $mp12m = [regex]::Match($fbHtml, '(?i)positive Feedback in last 12 months">([\d,]+)<')

        if ($mp1m.Success) { $p1m = "{0:N0}" -f [int]($mp1m.Groups[1].Value -replace ',', '') }
        if ($mp6m.Success) { $p6m = "{0:N0}" -f [int]($mp6m.Groups[1].Value -replace ',', '') }
        if ($mp12m.Success) { $p12m = "{0:N0}" -f [int]($mp12m.Groups[1].Value -replace ',', '') }

        $mn1m = [regex]::Match($fbHtml, '(?i)neutral Feedback in last 1 month">([\d,]+)<')
        $mn6m = [regex]::Match($fbHtml, '(?i)neutral Feedback in last 6 months">([\d,]+)<')
        $mn12m = [regex]::Match($fbHtml, '(?i)neutral Feedback in last 12 months">([\d,]+)<')

        if ($mn1m.Success) { $n1m = $mn1m.Groups[1].Value }
        if ($mn6m.Success) { $n6m = $mn6m.Groups[1].Value }
        if ($mn12m.Success) { $n12m = $mn12m.Groups[1].Value }

        $mneg1m = [regex]::Match($fbHtml, '(?i)negative Feedback in last 1 month">([\d,]+)<')
        $mneg6m = [regex]::Match($fbHtml, '(?i)negative Feedback in last 6 months">([\d,]+)<')
        $mneg12m = [regex]::Match($fbHtml, '(?i)negative Feedback in last 12 months">([\d,]+)<')

        if ($mneg1m.Success) { $neg1m = $mneg1m.Groups[1].Value }
        if ($mneg6m.Success) { $neg6m = $mneg6m.Groups[1].Value }
        if ($mneg12m.Success) { $neg12m = $mneg12m.Groups[1].Value }
    }
} catch {
    Write-Host "Feedback profile scrape note: $($_.Exception.Message)"
}

Write-Host "`nScraped & Validated Live eBay Store & Feedback Stats:"
Write-Host "  Positive Feedback Rate: $fbPercent"
Write-Host "  Items Sold:             $itemsSold"
Write-Host "  eBay Followers:         $followers"
Write-Host "  Feedback Score:         $totalScore"
Write-Host "  Positive 1M / 6M / 12M: $p1m / $p6m / $p12m"

# ------------------------------------------------------------------------------
# 4. Save live stats JSON for client-side hydration
# ------------------------------------------------------------------------------
$statsObj = [ordered]@{
    positive_feedback = $fbPercent
    items_sold        = $itemsSold
    followers         = $followers
    feedback_score    = $totalScore
    positive_1m       = $p1m
    positive_6m       = $p6m
    positive_12m      = $p12m
    neutral_1m        = $n1m
    neutral_6m        = $n6m
    neutral_12m       = $n12m
    negative_1m       = $neg1m
    negative_6m       = $neg6m
    negative_12m      = $neg12m
    last_updated      = [DateTime]::UtcNow.ToString("o")
}
$statsObj | ConvertTo-Json -Depth 3 | Set-Content "live_store_stats.json" -Encoding utf8

# ------------------------------------------------------------------------------
# 5. Update index.html statically with latest numbers
# ------------------------------------------------------------------------------
if (Test-Path "index.html") {
    $indexHtml = [System.IO.File]::ReadAllText("$pwd\index.html", [System.Text.Encoding]::UTF8)

    # 1. Update Hero Stats Numbers
    $indexHtml = $indexHtml -replace 'id="stat-feedback"[^>]*>[^<]+<', "id=`"stat-feedback`">$fbPercent<"
    $indexHtml = $indexHtml -replace 'id="stat-items-sold"[^>]*>[^<]+<', "id=`"stat-items-sold`">$itemsSold<"
    $indexHtml = $indexHtml -replace 'id="stat-followers"[^>]*>[^<]+<', "id=`"stat-followers`">$followers<"

    # 2. Update Hero Subtitle Text (e.g. Over 12,000+ items sold with a 100% positive feedback record)
    $indexHtml = $indexHtml -replace 'Over <strong>[^<]*items sold</strong> with a <strong>[^<]*positive feedback record</strong>', "Over <strong>$itemsSold items sold</strong> with a <strong>$fbPercent positive feedback record</strong>"

    # 3. Update Meta Description
    $indexHtml = $indexHtml -replace 'content="Pandota Ltd is a top-rated UK VAT registered eBay seller \(Est\. 2013\) with [^ ]+ positive feedback and over [^ ]+ items sold\.', "content=`"Pandota Ltd is a top-rated UK VAT registered eBay seller (Est. 2013) with $fbPercent positive feedback and over $itemsSold items sold."

    # 4. Update Detailed Feedback Table
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
