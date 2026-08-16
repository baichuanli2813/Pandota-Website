$laptops = Get-Content -Path "all_unique_laptops_full.json" -Raw | ConvertFrom-Json

Write-Host "Rendering all "$laptops.Count" laptops directly into HTML..."

$allCardsHtml = ""

foreach ($item in $laptops) {
    $itemId = $item.ItemId
    $title = [System.Web.HttpUtility]::HtmlEncode($item.Title)
    $price = $item.Price
    $url = $item.Url
    $img = $item.Image
    
    $numPrice = 999
    if ($price -match '[\d,]+(?:\.\d{2})?') {
        $numPrice = [double]($matches[0] -replace ',', '')
    }
    
    $cpu = "High-Performance CPU"
    if ($item.Title -match '(Ultra 9|Ultra 7|Ultra 5|i9|i7|i5|Ryzen 9|Ryzen 7|Ryzen AI|Snapdragon X)') {
        $cpu = $matches[1]
    }
    
    $gpu = "High-Performance GPU"
    if ($item.Title -match '(RTX 5090|RTX 5080|RTX 5070 Ti|RTX 5070|RTX 5060|RTX 4090|RTX 4080|RTX 4070|RTX 4060|RTX 4050|RTX 3070 Ti|RTX 3050|RTX A2000|Ada|Graphics)') {
        $gpu = $matches[1]
    }
    
    $allCardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-price="$numPrice">
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

$allCardsHtml | Out-File -FilePath "all_72_cards_block.html" -Encoding utf8
Write-Host "Generated HTML block for all 72 laptops."
