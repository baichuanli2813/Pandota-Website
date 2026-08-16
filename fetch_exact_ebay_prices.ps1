$items = Get-Content -Path "exact_store_laptops.json" -Raw | ConvertFrom-Json

Write-Host "Updating exact prices for "$items.Count" items..."

$updatedItems = @()

foreach ($item in $items) {
    $itemId = $item.ItemId
    $url = "https://www.ebay.co.uk/itm/$itemId"
    
    # Let's fetch the html of the individual eBay item listing page
    try {
        $res = Invoke-WebRequest -Uri $url -Headers @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'} -TimeoutSec 10
        $html = $res.Content
        
        # Exact price on eBay item page is in itemprop="price" content="XXXX.XX" or class="x-price-primary"
        $price = ""
        if ($html -match 'itemprop="price"\s+content="([^"]+)"') {
            $price = "£" + $matches[1]
        } elseif ($html -match 'class="x-price-primary"[^>]*>.*?£([\d,]+(?:\.\d{2})?)') {
            $price = "£" + $matches[1]
        } elseif ($html -match '£([\d,]+(?:\.\d{2})?)') {
            $price = "£" + $matches[1]
        }
        
        # Clean title from item page
        $title = $item.Title
        if ($html -match '<h1[^>]*class="x-item-title__mainTitle"[^>]*>.*?<span[^>]*>([^<]+)</span>') {
            $title = $matches[1].Trim()
        }
        
        Write-Host "Item $itemId => $price => $title"
        
        $updatedItems += [PSCustomObject]@{
            ItemId = $itemId
            Title = $title
            Price = if ($price) { $price } else { $item.Price }
            Url = $url
            Image = $item.Image
        }
    } catch {
        Write-Host "Error fetching item $itemId"
        $updatedItems += $item
    }
}

$updatedItems | ConvertTo-Json | Out-File -FilePath "exact_store_laptops_with_prices.json" -Encoding utf8
Write-Host "Finished fetching exact live prices!"
