$items = Get-Content -Path "exact_store_laptops.json" -Raw | ConvertFrom-Json

Write-Host "Loaded exact laptops:" $items.Count

$cardsHtml = ""

foreach ($item in $items) {
    $itemId = $item.ItemId
    $title = [System.Web.HttpUtility]::HtmlEncode($item.Title)
    $url = "https://www.ebay.co.uk/itm/$itemId"
    $img = $item.Image
    
    # Estimate numeric price for sorting
    $numPrice = 999
    if ($title -match 'RTX 5090') { $numPrice = 3899 }
    elseif ($title -match 'RTX 5080') { $numPrice = 2599 }
    elseif ($title -match 'RTX 5070|RTX 4090') { $numPrice = 1849 }
    elseif ($title -match 'RTX 4080') { $numPrice = 2199 }
    elseif ($title -match 'RTX 4070') { $numPrice = 1049 }
    elseif ($title -match 'RTX 4060') { $numPrice = 849 }
    
    # Extract CPU tag
    $cpu = "High-Spec Processor"
    if ($title -match '(Ultra 9|Ultra 7|Ultra 5|i9|i7|i5|Ryzen 9|Ryzen 7|Ryzen AI|Snapdragon X)') {
        $cpu = $matches[1]
    }
    
    # Extract GPU tag
    $gpu = "NVIDIA GeForce RTX"
    if ($title -match '(RTX 5090|RTX 5080|RTX 5070 Ti|RTX 5070|RTX 5060|RTX 4090|RTX 4080|RTX 4070|RTX 4060|RTX 4050|RTX 3070 Ti|RTX 3050|RTX A2000|Ada)') {
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
              <div class="inv-card-price">View Live Price on eBay</div>
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

$cardsHtml | Out-File -FilePath "generated_cards.html" -Encoding utf8
Write-Host "Generated card HTML block for all 38 laptops."
