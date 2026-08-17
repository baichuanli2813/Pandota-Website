# ==============================================================================
# Pandota Ltd - Direct eBay Seller Hub Synchronizer (In-Stock Only: Qty >= 1)
# Uses authorized Seller User Token to fetch 100% exact listings, conditions & watcher counts
# ==============================================================================

Write-Host "====================================================="
Write-Host "  PANDOTA LTD - DIRECT SELLER HUB SYNCHRONIZER       "
Write-Host "====================================================="

# 1. Load Credentials (from GitHub Actions Environment Variables or local ebay_credentials.json)
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

if (-not $token) {
    Write-Host "Error: eBay User Token not available in environment variables or ebay_credentials.json."
    exit 1
}

Write-Host "Fetching active in-stock listings directly from eBay Seller Hub database..."

$allInStockItems = @()
$page = 1
$totalPages = 1

do {
    $xmlReq = @"
<?xml version="1.0" encoding="utf-8"?>
<GetMyeBaySellingRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>$token</eBayAuthToken>
  </RequesterCredentials>
  <ActiveList>
    <Include>true</Include>
    <Pagination>
      <EntriesPerPage>200</EntriesPerPage>
      <PageNumber>$page</PageNumber>
    </Pagination>
  </ActiveList>
  <DetailLevel>ReturnAll</DetailLevel>
</GetMyeBaySellingRequest>
"@

    $reqFile = [System.IO.Path]::GetTempFileName()
    $respFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($reqFile, $xmlReq, [System.Text.Encoding]::UTF8)

    curl.exe -s -X POST "https://api.ebay.com/ws/api.dll" `
      -H "X-EBAY-API-COMPATIBILITY-LEVEL: 967" `
      -H "X-EBAY-API-DEV-NAME: $devId" `
      -H "X-EBAY-API-APP-NAME: $appId" `
      -H "X-EBAY-API-CERT-NAME: $certId" `
      -H "X-EBAY-API-CALL-NAME: GetMyeBaySelling" `
      -H "X-EBAY-API-SITEID: 3" `
      -H "Content-Type: text/xml" `
      -d "@$reqFile" `
      -o "$respFile"

    $rawResp = Get-Content $respFile -Raw -Encoding utf8
    Remove-Item $reqFile, $respFile -Force -ErrorAction SilentlyContinue

    [xml]$doc = $rawResp
    if ($doc.GetMyeBaySellingResponse.Ack -ne "Success" -and $doc.GetMyeBaySellingResponse.Ack -ne "Warning") {
        Write-Host "API Notice: $($doc.GetMyeBaySellingResponse.Errors.LongMessage)"
        break
    }

    $activeList = $doc.GetMyeBaySellingResponse.ActiveList
    $totalEntries = [int]$activeList.PaginationResult.TotalNumberOfEntries
    $totalPages = [int]$activeList.PaginationResult.TotalNumberOfPages

    $itemsOnPage = $activeList.ItemArray.Item
    if ($itemsOnPage) {
        foreach ($item in $itemsOnPage) {
            # Filter strictly for available quantity >= 1
            $qtyAvail = [int]$item.QuantityAvailable
            if ($qtyAvail -lt 1) {
                continue # Skip out-of-stock / sold items
            }

            $itemId = [string]$item.ItemID
            $title = [string]$item.Title
            
            # Price
            $rawPrice = [string]$item.SellingStatus.CurrentPrice.'#text'
            $priceNum = 0.0
            [double]::TryParse($rawPrice, [ref]$priceNum) | Out-Null
            $priceStr = "£" + [string]::Format("{0:N2}", $priceNum)
            
            # Watchers (100% exact from Seller Hub)
            $rawWatch = [string]$item.WatchCount
            $watchers = 0
            if ($rawWatch) { [int]::TryParse($rawWatch, [ref]$watchers) | Out-Null }
            
            # Picture
            $img = ""
            if ($item.PictureDetails.GalleryURL) {
                $img = [string]$item.PictureDetails.GalleryURL
                $img = $img -replace 's-l\d+\.(jpg|webp|png)', 's-l500.jpg'
            } elseif ($item.PictureDetails.PictureURL) {
                $img = [string]($item.PictureDetails.PictureURL[0])
                $img = $img -replace 's-l\d+\.(jpg|webp|png)', 's-l500.jpg'
            }

            $allInStockItems += [PSCustomObject]@{
                ItemId       = $itemId
                Title        = $title
                Price        = $priceStr
                NumPrice     = $priceNum
                AvailableQty = $qtyAvail
                Url          = "https://www.ebay.co.uk/itm/$itemId"
                Img          = $img
                Watchers     = $watchers
                Condition    = "Used" # Default, will fetch exact ConditionID next
            }
        }
    }

    Write-Host "Page $page of $totalPages checked ($($allInStockItems.Count) in-stock items found so far)"
    $page++
} while ($page -le $totalPages -and $page -le 5)

Write-Host "`nSuccessfully retrieved $($allInStockItems.Count) currently active, in-stock items from Seller Hub!"

# Fetch exact ConditionDisplayName and latest high-res photo for each in-stock item using GetItem
Write-Host "Fetching official eBay condition and live photos for each in-stock listing..."

$condsMap = @{}
$itemIndex = 0

foreach ($it in $allInStockItems) {
    $itemIndex++
    $id = $it.ItemId
    
    $xmlReq = @"
<?xml version="1.0" encoding="utf-8"?>
<GetItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>$token</eBayAuthToken>
  </RequesterCredentials>
  <ItemID>$id</ItemID>
  <DetailLevel>ItemReturnAttributes</DetailLevel>
</GetItemRequest>
"@

    $reqFile = [System.IO.Path]::GetTempFileName()
    $respFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($reqFile, $xmlReq, [System.Text.Encoding]::UTF8)

    curl.exe -s -X POST "https://api.ebay.com/ws/api.dll" `
      -H "X-EBAY-API-COMPATIBILITY-LEVEL: 967" `
      -H "X-EBAY-API-DEV-NAME: $devId" `
      -H "X-EBAY-API-APP-NAME: $appId" `
      -H "X-EBAY-API-CERT-NAME: $certId" `
      -H "X-EBAY-API-CALL-NAME: GetItem" `
      -H "X-EBAY-API-SITEID: 3" `
      -H "Content-Type: text/xml" `
      -d "@$reqFile" `
      -o "$respFile"

    $rawResp = Get-Content $respFile -Raw -Encoding utf8
    Remove-Item $reqFile, $respFile -Force -ErrorAction SilentlyContinue

    [xml]$doc = $rawResp
    $itemObj = $doc.GetItemResponse.Item

    $cond = "Used"
    if ($itemObj) {
        $cId = [string]$itemObj.ConditionID
        $cName = [string]$itemObj.ConditionDisplayName
        
        if ($cId -eq "1000" -or $cName -match "Brand New|New$") {
            $cond = "New"
        } elseif ($cId -eq "1500" -or $cName -match "Opened|Open Box|Never Used|New other") {
            $cond = "Opened - never used"
        } elseif ($cId -eq "7000" -or $cName -match "Parts|Faulty|not working") {
            $cond = "For parts or not working"
        } else {
            $cond = "Used"
        }

        # Auto-update to latest high-resolution cover photo from eBay listing
        if ($itemObj.PictureDetails -and $itemObj.PictureDetails.PictureURL) {
            $livePic = [string]($itemObj.PictureDetails.PictureURL[0])
            if ($livePic -and $livePic.Trim() -ne "") {
                $it.Img = $livePic -replace 's-l\d+\.(jpg|webp|png)', 's-l500.jpg'
            }
        }
    }
    
    $it.Condition = $cond
    $condsMap[$id] = $cond
}

Write-Host "Finished fetching exact conditions for all $($allInStockItems.Count) items!"

# Fetch live view counts from eBay Analytics API
$oauthToken = $env:EBAY_OAUTH_TOKEN
if (-not $oauthToken -and $creds -and $creds.OAuthUserToken) {
    $oauthToken = $creds.OAuthUserToken
}

$viewsLookup = @{}
if ($oauthToken) {
    Write-Host "`nFetching official live views from eBay Seller Analytics API..."
    try {
        $now = [DateTime]::UtcNow
        $startDate = $now.AddDays(-28).ToString("yyyyMMdd")
        $endDate = $now.ToString("yyyyMMdd")
        $filterParam = [System.Uri]::EscapeDataString("marketplace_ids:{EBAY_GB},date_range:[$startDate..$endDate]")
        $analyticsUrl = "https://api.ebay.com/sell/analytics/v1/traffic_report?dimension=LISTING&metric=LISTING_VIEWS_TOTAL&filter=$filterParam"
        $analyticsHeaders = @{
            "Authorization" = "Bearer $oauthToken"
            "Accept"        = "application/json"
        }
        $analyticsResp = Invoke-RestMethod -Uri $analyticsUrl -Method Get -Headers $analyticsHeaders -TimeoutSec 15
        if ($analyticsResp -and $analyticsResp.records) {
            foreach ($rec in $analyticsResp.records) {
                $recItemId = $rec.dimensionValues[0].value
                $recViews = [int]$rec.metricValues[0].value
                $viewsLookup[$recItemId] = $recViews
            }
            Write-Host "Successfully loaded live page view counts for $($viewsLookup.Count) listings!"
        }
    } catch {
        Write-Host "Analytics view fetch note: $($_.Exception.Message)"
    }
}

foreach ($it in $allInStockItems) {
    $id = $it.ItemId
    $v = if ($viewsLookup.ContainsKey($id)) { $viewsLookup[$id] } else { 0 }
    $it | Add-Member -MemberType NoteProperty -Name "Views" -Value $v -Force
}

# Save exact in-stock catalog with exact Watchers, Views and Conditions
$allInStockItems | ConvertTo-Json -Depth 5 | Set-Content "all_82_with_exact_scraped_prices.json" -Encoding utf8
$allInStockItems | ConvertTo-Json -Depth 5 | Set-Content "all_store_listings.json" -Encoding utf8
$condsMap | ConvertTo-Json -Depth 5 | Set-Content "official_scraped_ebay_conditions.json" -Encoding utf8

# 2. Build inventory.html and update index.html
Write-Host "`nRebuilding inventory.html with exact in-stock listings, conditions and watchers..."
& ".\build_site_from_100pct_scraped_ebay_page_conditions.ps1"

# 3. Sync Feedback Ratings
Write-Host "`nSyncing live eBay feedback ratings..."
& ".\sync_ebay_feedbacks.ps1"

# 4. Clean Encodings
Write-Host "`nCleaning character encodings..."
& ".\fix_both_encodings.ps1"

# 5. Copy to Pandota Website repo
$targetDir = "C:\Users\User\Desktop\PANDOTA ACOUNTS\Pandota Website"
if (Test-Path $targetDir) {
    Copy-Item -Path ".\style.css" -Destination "$targetDir\style.css" -Force
    Copy-Item -Path ".\index.html" -Destination "$targetDir\index.html" -Force
    Copy-Item -Path ".\inventory.html" -Destination "$targetDir\inventory.html" -Force
    Copy-Item -Path ".\script.js" -Destination "$targetDir\script.js" -Force
    Copy-Item -Path ".\sitemap.xml" -Destination "$targetDir\sitemap.xml" -Force
    Copy-Item -Path ".\robots.txt" -Destination "$targetDir\robots.txt" -Force
    Copy-Item -Path ".\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Destination "$targetDir\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Force
    Copy-Item -Path ".\sync_seller_hub_exact.ps1" -Destination "$targetDir\sync_seller_hub_exact.ps1" -Force
    Copy-Item -Path ".\sync_ebay_api.ps1" -Destination "$targetDir\sync_ebay_api.ps1" -Force
    Copy-Item -Path ".\SYNC_PANDOTA_STORE.bat" -Destination "$targetDir\SYNC_PANDOTA_STORE.bat" -Force
    Copy-Item -Path ".\sync_ebay_feedbacks.ps1" -Destination "$targetDir\sync_ebay_feedbacks.ps1" -Force
    Copy-Item -Path ".\fix_both_encodings.ps1" -Destination "$targetDir\fix_both_encodings.ps1" -Force
    Copy-Item -Path ".\official_scraped_ebay_conditions.json" -Destination "$targetDir\official_scraped_ebay_conditions.json" -Force
    Copy-Item -Path ".\all_82_with_exact_scraped_prices.json" -Destination "$targetDir\all_82_with_exact_scraped_prices.json" -Force
    Copy-Item -Path ".\all_store_listings.json" -Destination "$targetDir\all_store_listings.json" -Force
    Write-Host "`nSuccessfully synchronized all files to Pandota Website repository!"
}

Write-Host "`n====================================================="
Write-Host "  IN-STOCK (QTY >= 1) EXACT SYNC COMPLETE!           "
Write-Host "====================================================="
