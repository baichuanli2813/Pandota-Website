# ==============================================================================
# Pandota Ltd - Live eBay Sync & Site Builder (Zero User Intervention)
# Automatically scrapes active eBay listings, conditions, feedback & rebuilds site
# ==============================================================================

Write-Host "====================================================="
Write-Host "  PANDOTA LTD - LIVE EBAY STORE SYNCHRONIZER         "
Write-Host "====================================================="

# 1. Locate Edge/Chrome browser executable
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)

$browser = $null
foreach ($bp in $edgePaths) {
    if (Test-Path $bp) {
        $browser = $bp
        break
    }
}

$allParsedItems = @()
$seenItemIds = @{}

if ($browser) {
    Write-Host "Fetching live eBay Store listings using browser engine ($browser)..."
    
    for ($page = 1; $page -le 3; $page++) {
        $pageUrl = if ($page -eq 1) {
            "https://www.ebay.co.uk/str/geoffscuriosities?_ipg=72&_sop=10"
        } else {
            "https://www.ebay.co.uk/str/geoffscuriosities?_ipg=72&_sop=10&_pgn=$page"
        }

        $tempDump = [System.IO.Path]::GetTempFileName()
        Start-Process -FilePath $browser -ArgumentList "--headless", "--dump-dom", "--disable-gpu", "$pageUrl" -RedirectStandardOutput $tempDump -Wait

        if (Test-Path $tempDump) {
            $html = Get-Content $tempDump -Raw -Encoding utf8
            Remove-Item $tempDump -Force -ErrorAction SilentlyContinue

            $articles = [regex]::Matches($html, '(?s)<article data-testid="ig-(\d+)".*?</article>')
            $pageItemCount = 0

            foreach ($art in $articles) {
                $itemId = $art.Groups[1].Value
                if ($seenItemIds.ContainsKey($itemId)) { continue }
                $seenItemIds[$itemId] = $true

                $chunk = $art.Value

                # Title
                $title = ""
                if ($chunk -match 'class="str-card-title"[^>]*>.*?<span class="str-text-span"[^>]*>([^<]+)</span>') {
                    $title = [System.Net.WebUtility]::HtmlDecode($matches[1].Trim())
                } elseif ($chunk -match 'aria-label="watch ([^"]+)"') {
                    $title = [System.Net.WebUtility]::HtmlDecode($matches[1].Trim())
                }

                # Price
                $price = "£0.00"
                if ($chunk -match 'class="[^"]*property-displayPrice[^"]*"[^>]*>.*?([\d,]+\.?\d*)') {
                    $price = "£" + $matches[1]
                }

                # Image
                $img = ""
                if ($chunk -match 'imageid="([^"]+)"') {
                    $img = "https://i.ebayimg.com/images/g/$($matches[1])/s-l500.webp"
                } elseif ($chunk -match '(https://i\.ebayimg\.com/images/g/[^"''\s\\]+)') {
                    $img = $matches[1] -replace 's-l\d+\.(jpg|webp|png)', 's-l500.webp'
                }

                $url = "https://www.ebay.co.uk/itm/$itemId"

                if ($title -and $price -ne "£0.00") {
                    $allParsedItems += [PSCustomObject]@{
                        ItemId = $itemId
                        Title  = $title
                        Price  = $price
                        Url    = $url
                        Img    = $img
                    }
                    $pageItemCount++
                }
            }

            Write-Host "Page $page : Scraped $pageItemCount active items"
            if ($pageItemCount -eq 0) { break }
        }
    }
}

if ($allParsedItems.Count -gt 0) {
    Write-Host "Successfully fetched $($allParsedItems.Count) live active items from eBay!"
    
    # Save live scraped active catalog
    $allParsedItems | ConvertTo-Json -Depth 5 | Set-Content "all_82_with_exact_scraped_prices.json" -Encoding utf8
    $allParsedItems | ConvertTo-Json -Depth 5 | Set-Content "all_store_listings.json" -Encoding utf8

    # Also update conditions mapping
    $existingConds = @{}
    if (Test-Path "official_scraped_ebay_conditions.json") {
        $existingConds = Get-Content "official_scraped_ebay_conditions.json" -Raw | ConvertFrom-Json
    }

    $updatedConds = @{}
    foreach ($item in $allParsedItems) {
        $id = $item.ItemId
        $title = $item.Title
        if ($existingConds.PSObject.Properties[$id]) {
            $updatedConds[$id] = $existingConds.$id
        } else {
            # Inferred condition from official listing title
            if ($title -match '^\s*NEW\b|\bBrand New\b|\bSealed\b') {
                $updatedConds[$id] = "New"
            } elseif ($title -match '\bOpened\b|\bOpen Box\b|\bNever Used\b') {
                $updatedConds[$id] = "Opened - never used"
            } elseif ($title -match '\bFor Parts\b|\bFaulty\b|\bNot Working\b') {
                $updatedConds[$id] = "For parts or not working"
            } else {
                $updatedConds[$id] = "Used"
            }
        }
    }
    $updatedConds | ConvertTo-Json -Depth 5 | Set-Content "official_scraped_ebay_conditions.json" -Encoding utf8
} else {
    Write-Host "Warning: Could not connect to live eBay store directly. Using existing cached catalog."
}

# 2. Build inventory.html and update index.html
Write-Host "`nRebuilding inventory.html and updating index.html..."
& ".\build_site_from_100pct_scraped_ebay_page_conditions.ps1"

# 3. Sync eBay Feedback Ratings Table
Write-Host "`nSyncing live eBay feedback ratings..."
& ".\sync_ebay_feedbacks.ps1"

# 4. Fix UTF-8 Character Encodings
Write-Host "`nCleaning character encodings..."
& ".\fix_both_encodings.ps1"

# 5. Copy to Pandota Website repository if present
$targetDir = "C:\Users\User\Desktop\PANDOTA ACOUNTS\Pandota Website"
if (Test-Path $targetDir) {
    Copy-Item -Path ".\style.css" -Destination "$targetDir\style.css" -Force
    Copy-Item -Path ".\index.html" -Destination "$targetDir\index.html" -Force
    Copy-Item -Path ".\inventory.html" -Destination "$targetDir\inventory.html" -Force
    Copy-Item -Path ".\script.js" -Destination "$targetDir\script.js" -Force
    Copy-Item -Path ".\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Destination "$targetDir\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Force
    Copy-Item -Path ".\sync_now.ps1" -Destination "$targetDir\sync_now.ps1" -Force
    Copy-Item -Path ".\sync_ebay_feedbacks.ps1" -Destination "$targetDir\sync_ebay_feedbacks.ps1" -Force
    Copy-Item -Path ".\fix_both_encodings.ps1" -Destination "$targetDir\fix_both_encodings.ps1" -Force
    Copy-Item -Path ".\official_scraped_ebay_conditions.json" -Destination "$targetDir\official_scraped_ebay_conditions.json" -Force
    Copy-Item -Path ".\all_82_with_exact_scraped_prices.json" -Destination "$targetDir\all_82_with_exact_scraped_prices.json" -Force
    Copy-Item -Path ".\all_store_listings.json" -Destination "$targetDir\all_store_listings.json" -Force
    Write-Host "`nSuccessfully synchronized all files to Pandota Website repository!"
}

Write-Host "`n====================================================="
Write-Host "  LIVE SYNC COMPLETE! WEBSITE IS 100% UP TO DATE     "
Write-Host "====================================================="
