$items = Get-Content -Path "all_82_with_exact_conditions.json" -Raw | ConvertFrom-Json

Write-Host "Building HTML for all "$items.Count" listings with exact eBay condition pills..."

$cardsHtml = ""

foreach ($item in $items) {
    $itemId = $item.ItemId
    $titleRaw = $item.Title.Trim()
    $title = [System.Web.HttpUtility]::HtmlEncode($titleRaw)
    $price = $item.Price
    $url = $item.Url
    $img = $item.Image
    $cond = $item.Condition
    
    $numPrice = 999
    if ($price -match '[\d,]+(?:\.\d{2})?') {
        $numPrice = [double]($matches[0] -replace ',', '')
    }
    
    $pills = @()
    
    # 1. Condition Pill (Requested by User)
    $condIcon = "fa-circle-check"
    if ($cond -match 'New') {
        $condIcon = "fa-sparkles"
    } elseif ($cond -match 'Opened') {
        $condIcon = "fa-box-open"
    } elseif ($cond -match 'Used') {
        $condIcon = "fa-rotate-left"
    } elseif ($cond -match 'parts|working') {
        $condIcon = "fa-wrench"
    }
    
    $pills += "<span><i class=`"fa-solid $condIcon`"></i> $cond</span>"
    
    # 2. CPU / Processor / Sensor / Spec
    if ($titleRaw -match '(Ultra 9 \d+HX|Ultra 9 \d+H|Ultra 7 \d+HX|Ultra 7 \d+H|Ultra 5 \d+V|Ultra 5 \d+U|i9 \d+HX|i9 \d+H|i7 \d+HX|i7 \d+H|i7 \d+U|i7 \d+th Gen|i5 \d+th Gen|Ryzen AI 9 HX \d+|Ryzen 9 \d+HX|Ryzen 7 \d+HS|Snapdragon X2 Elite|Snapdragon X)') {
        $pills += "<span><i class=`"fa-solid fa-microchip`"></i> " + $matches[1] + "</span>"
    } elseif ($titleRaw -match '(Ultra 9|Ultra 7|Ultra 5|i9|i7|i5|Ryzen 9|Ryzen 7|Ryzen AI)') {
        $pills += "<span><i class=`"fa-solid fa-microchip`"></i> " + $matches[1] + "</span>"
    } elseif ($titleRaw -match '(26MP|33MP|24\.2 MP)') {
        $pills += "<span><i class=`"fa-solid fa-camera`"></i> " + $matches[1] + " Sensor</span>"
    }
    
    # 3. GPU / Lens Spec
    if ($titleRaw -match '(RTX 5090|RTX 5080|RTX 5070 Ti|RTX 5070|RTX 5060|RTX 4090|RTX 4080|RTX 4070|RTX 4060|RTX 4050|RTX 3080 Ti|RTX 3070 Ti|RTX 3070|RTX 3050|RTX 2060|RTX 2000 Ada|RTX PRO 4000|RTX PRO 3000|RTX PRO 2000|RTX PRO 500|RTX A2000|RTX 5000 Ada)') {
        $pills += "<span><i class=`"fa-solid fa-compact-disc`"></i> RTX " + ($matches[1] -replace 'RTX\s*', '') + "</span>"
    } elseif ($titleRaw -match '(\d+-\d+mm F/?\d+\.\d|\d+-\d+mm|\d+mm F/?\d+\.\d|\d+mm)') {
        $pills += "<span><i class=`"fa-solid fa-circle-dot`"></i> " + $matches[1] + "</span>"
    }
    
    # 4. RAM / Storage / Display
    $ramStr = ""
    $storageStr = ""
    $displayStr = ""
    
    if ($titleRaw -match '(\d+GB RAM|\d+GB)') {
        $ramStr = $matches[1]
    }
    if ($titleRaw -match '(\d+TB SSD|\d+TB|\d+GB SSD|\d+GB Raid 0)') {
        $storageStr = $matches[1]
    }
    if ($titleRaw -match '(300Hz|250Hz|240Hz|180Hz|165Hz|144Hz|120Hz|OLED|4K|QHD\+|MiniLED|Mini LED|3\.2K|2\.8K)') {
        $displayStr = $matches[1]
    }
    
    if ($ramStr -and $storageStr) {
        $pills += "<span><i class=`"fa-solid fa-memory`"></i> $ramStr &bull; $storageStr</span>"
    } elseif ($ramStr -and $displayStr) {
        $pills += "<span><i class=`"fa-solid fa-memory`"></i> $ramStr &bull; $displayStr</span>"
    } elseif ($displayStr) {
        $pills += "<span><i class=`"fa-solid fa-desktop`"></i> $displayStr</span>"
    } elseif ($ramStr) {
        $pills += "<span><i class=`"fa-solid fa-memory`"></i> $ramStr</span>"
    }
    
    $pillsHtml = $pills -join "`n                "
    
    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-price="$numPrice">
            <div class="inv-card-badge">Official eBay Listing</div>
            <div class="inv-card-img-wrap">
              <img src="$img" alt="$title">
            </div>
            <div class="inv-card-body">
              <div class="inv-card-price">$price</div>
              <h3 class="inv-card-title">$title</h3>
              <div class="inv-card-features">
                $pillsHtml
              </div>
              <a href="$url" target="_blank" rel="noopener" class="btn btn-ebay" style="width: 100%; margin-top: 14px;">
                <span>View Listing on eBay</span>
                <i class="fa-solid fa-arrow-up-right-from-square"></i>
              </a>
            </div>
          </div>

"@
}

$fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>All Active Inventory (82 Listings) - Pandota Ltd Official eBay Store</title>
  <meta name="description" content="Browse all 82 active listings live from Pandota's official eBay store (geoffscuriosities). High-performance laptops, gaming rigs, workstations, and electronics.">
  <meta name="keywords" content="Pandota inventory, Pandota laptops, Pandota eBay listings, Lenovo Legion, Alienware, ASUS ROG, HP Omen, eBay UK seller">

  <!-- FontAwesome Icons & Google Fonts -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
  
  <!-- Stylesheets -->
  <link rel="stylesheet" href="style.css">
</head>
<body>

  <!-- Header & Navigation -->
  <header class="header">
    <div class="container header-container">
      <a href="index.html" class="logo-brand" aria-label="Pandota Home">
        <img src="images/panda_logo.png" alt="Pandota Panda Logo" class="brand-panda-img">
        <span>PANDOTA</span>
      </a>

      <nav>
        <ul class="nav-links" id="navLinks">
          <li><a href="index.html#about">About Pandota</a></li>
          <li><a href="index.html#features">What We Do</a></li>
          <li><a href="inventory.html" class="active-nav">All Inventory (82 Listings)</a></li>
          <li><a href="index.html#faq">FAQ</a></li>
        </ul>
      </nav>

      <div class="nav-actions">
        <a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener" class="btn btn-ebay">
          <span class="ebay-logo-svg-wrap">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 122 48.6" class="ebay-svg-logo" aria-hidden="true">
              <path fill="#e53238" d="M24.4 22.8c-.3-5.7-4.4-7.8-8.8-7.8-4.8 0-8.5 2.5-9.2 7.9H24.4zm-18.1 4.1c.4 5.6 4.2 8.8 9.5 8.8 3.6 0 6.9-1.5 8-4.8l6.3-.1c-1.2 6.6-8.2 8.8-14.1 8.9C4.9 39.8 0 33.9 0 25.8 0 16.9 5 11 15.8 10.9c8.6 0 15 4.4 15 14.3v1.6H6.3z"/>
              <path fill="#0064d2" d="M46.5 35.4c5.7 0 9.5-4.1 9.5-10.3s-3.9-10.2-9.6-10.2-9.5 4.1-9.5 10.3 3.9 10.2 9.6 10.2zM30.7 0l6.1-.1v15.4c3-3.6 7.1-4.7 11.2-4.7 6.8 0 14.4 4.5 14.5 14.5.1 8.3-5.9 14.4-14.4 14.5-4.5 0-8.6-1.5-11.2-4.7v3.8h-6l.1-6.4V0z"/>
              <path fill="#f5af02" d="M77.3 25.7c-5.5.2-9 1.2-9 4.9 0 2.4 1.9 4.9 6.7 4.9 6.4 0 9.8-3.6 9.8-9.3v-.6c-2.3 0-5 .1-7.5.1zm13.7 7.5c0 1.8.1 3.5.2 5.1h-5.7c-.1-1.1-.2-2.4-.2-3.8-3.1 3.8-6.7 4.9-11.8 4.9-7.5 0-11.6-3.9-11.6-8.5 0-6.7 5.4-9 15-9.3 2.6-.1 5.5-.1 7.9-.1v-.6c0-4.5-2.9-6.3-7.9-6.3-3.7 0-6.4 1.6-6.7 4.2l-6.4.1c.6-6.6 7.5-8.3 13.6-8.3 7.3 0 13.4 2.5 13.4 10.2v12.4z"/>
              <path fill="#86b817" d="M91.9 19.9l-4.5-8.4h7.2l10.6 20.9 10.3-21h6.5l-18.7 37.3h-6.9l5.4-10.3-9.9-18.5z"/>
            </svg>
          </span>
          <span>Visit Pandota eBay Store</span>
          <i class="fa-solid fa-arrow-up-right-from-square"></i>
        </a>
        <button class="mobile-toggle" id="mobileToggle" aria-label="Toggle mobile menu">
          <i class="fa-solid fa-bars"></i>
        </button>
      </div>
    </div>
  </header>

  <main>
    <!-- Inventory Page Hero Header -->
    <section class="section" style="padding: 60px 0 40px; background: rgba(24, 24, 27, 0.4);">
      <div class="container">
        <div class="section-title-area" style="margin-bottom: 30px;">
          <div class="pill-badge" style="margin-bottom: 16px;">
            <span class="live-pulse-dot"></span>
            <span>Live Sync with eBay Store &bull; 82 Active Listings</span>
          </div>
          <h1 class="section-heading" style="font-size: 3rem;">Complete Store Inventory (82 Listings)</h1>
          <p class="section-desc">
            Browse all 82 active listings currently available on Pandota's official eBay store. Real-time search and price sorting below!
          </p>
        </div>

        <!-- Filter Controls Bar -->
        <div class="inventory-controls-bar">
          <div class="search-filter-input-wrap">
            <i class="fa-solid fa-magnifying-glass search-icon"></i>
            <input type="text" id="inventorySearchInput" placeholder="Search by model, brand, condition..." class="inventory-search-input">
          </div>

          <div class="sort-select-wrap">
            <label for="inventorySortSelect" style="font-size: 0.875rem; color: var(--text-muted);">Sort:</label>
            <select id="inventorySortSelect" class="inventory-sort-select">
              <option value="featured">Featured / Best Match</option>
              <option value="price-asc">Price: Low to High</option>
              <option value="price-desc">Price: High to Low</option>
            </select>
          </div>
        </div>
      </div>
    </section>

    <!-- Full Inventory Grid Section with ALL 82 Real eBay Store Items -->
    <section class="section" style="padding: 40px 0 90px;">
      <div class="container">
        <div id="fullInventoryGrid" class="full-inventory-grid">

CARD_HOLDER_PLACEHOLDER

        </div>

        <!-- Catalog Loaded Completion Badge -->
        <div class="all-loaded-banner" style="text-align: center; margin-top: 40px; padding: 20px; color: var(--text-sub); display: flex; align-items: center; justify-content: center; gap: 10px; font-size: 0.95rem; border-top: 1px solid rgba(255, 255, 255, 0.08);">
          <i class="fa-solid fa-circle-check" style="color: #22c55e; font-size: 1.1rem;"></i>
          <span>Showing all 82 active listings live from Pandota's eBay store</span>
        </div>
      </div>
    </section>
  </main>

  <!-- Footer -->
  <footer class="footer">
    <div class="container">
      <div class="footer-grid">
        <div class="footer-brand">
          <a href="index.html" class="logo-brand">
            <img src="images/panda_logo.png" alt="Pandota Logo" class="brand-panda-img">
            <span>PANDOTA LTD</span>
          </a>
          <p>
            Pandota Ltd is a UK registered seller on eBay (Est. 2013) delivering high-performance laptops, gaming systems, and workstations.
          </p>
        </div>

        <div class="footer-col">
          <h4>Pandota Navigation</h4>
          <ul>
            <li><a href="index.html#about">About Pandota</a></li>
            <li><a href="inventory.html">All Inventory (82 Listings)</a></li>
            <li><a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener">Official eBay Store</a></li>
            <li><a href="index.html#faq">Buyer FAQ</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Pandota Benefits</h4>
          <ul>
            <li><a href="index.html#features">100% Positive Feedback</a></li>
            <li><a href="index.html#features">Fast Dispatch</a></li>
            <li><a href="index.html#features">Official VAT Invoices</a></li>
            <li><a href="index.html#features">30-Day Return Guarantee</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Store Highlights</h4>
          <ul>
            <li><span>100% Positive Feedback</span></li>
            <li><span>11,000+ Items Sold</span></li>
            <li><span>Selling Laptops since 2013</span></li>
            <li><span>UK Registered Business Seller</span></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <p>&copy; <span id="currentYear">2026</span> Pandota Ltd. All rights reserved.</p>
        <p>
          <a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener" style="color: #ffffff; text-decoration: underline;">Visit Pandota on eBay.co.uk</a>
        </p>
      </div>
    </div>
  </footer>

  <script src="script.js"></script>
</body>
</html>
"@

$finalHtml = $fullHtml.Replace("CARD_HOLDER_PLACEHOLDER", $cardsHtml)
[System.IO.File]::WriteAllText("inventory.html", $finalHtml, [System.Text.Encoding]::UTF8)
Write-Host "Successfully built inventory.html with EXACT EBAY CONDITION PILLS!"
