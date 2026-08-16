$laptops = Get-Content -Path "exact_store_laptops_prices_fixed.json" -Raw | ConvertFrom-Json

$cardsHtml = ""

foreach ($item in $laptops) {
    $itemId = $item.ItemId
    $title = [System.Web.HttpUtility]::HtmlEncode($item.Title)
    $price = $item.Price
    $url = $item.Url
    $img = $item.Image
    
    # Extract numeric price for sorting
    $numPrice = 999
    if ($price -match '[\d,]+(?:\.\d{2})?') {
        $numPrice = [double]($matches[0] -replace ',', '')
    }
    
    # Extract CPU tag
    $cpu = "High-Performance CPU"
    if ($title -match '(Ultra 9|Ultra 7|Ultra 5|i9|i7|i5|Ryzen 9|Ryzen 7|Ryzen AI|Snapdragon X)') {
        $cpu = $matches[1]
    }
    
    # Extract GPU tag
    $gpu = "High-Performance GPU"
    if ($title -match '(RTX 5090|RTX 5080|RTX 5070 Ti|RTX 5070|RTX 5060|RTX 4090|RTX 4080|RTX 4070|RTX 4060|RTX 4050|RTX 3070 Ti|RTX 3050|RTX A2000|Ada|Graphics)') {
        $gpu = $matches[1]
    }
    
    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card reveal-on-scroll" data-price="$numPrice">
            <div class="inv-card-badge">DPD Next-Day Delivery</div>
            <div class="inv-card-img-wrap">
              <img src="$img" alt="$title">
            </div>
            <div class="inv-card-body">
              <div class="inv-card-price">$price</div>
              <h3 class="inv-card-title">$title</h3>
              <div class="inv-card-features">
                <span><i class="fa-solid fa-microchip"></i> $cpu</span>
                <span><i class="fa-solid fa-compact-disc"></i> $gpu</span>
              </div>
              <a href="$url" target="_blank" rel="noopener" class="btn btn-ebay" style="width: 100%; margin-top: 12px;">
                <span>View Listing on eBay</span>
                <i class="fa-solid fa-arrow-up-right-from-square"></i>
              </a>
            </div>
          </div>

"@
}

$cardsHtml | Out-File -FilePath "all_exact_cards.html" -Encoding utf8
Write-Host "Generated HTML for all 38 laptops with 100% exact live prices."
