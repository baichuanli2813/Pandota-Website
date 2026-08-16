$items = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json
$storeListings = Get-Content -Path "all_store_listings.json" -Raw | ConvertFrom-Json
$cdnMap = @{}
foreach ($sl in $storeListings) {
    if ($sl.ItemId -and $sl.ImageUrl) {
        $cdnMap[$sl.ItemId] = $sl.ImageUrl
    }
}

Write-Host "Building inventory.html using 100% direct live scraped eBay page conditions and high-speed eBay CDN images..."

$cardsHtml = ""

# Map of live scraped conditions directly from eBay item pages:
$liveCondMap = @{
    "267729753193" = "New"
    "267729862669" = "New"
    "267729734670" = "New"
    "267755974090" = "Used"
    "267707331524" = "New"
    "267753890742" = "New"
    "267745470208" = "New" # Alienware 18 Area-51 5080 is NEW on eBay!
    "267727321251" = "New"
    "267749453105" = "Used"
    "267749821800" = "Used"
    "267729802087" = "New"
    "267722455398" = "Used"
    "267729965028" = "New"
    "267755994940" = "Used"
    "267749549365" = "Used"
    "267749815355" = "Used"
    "267749377397" = "Used"
    "267745389869" = "Used"
    "267749450627" = "Used"
    "267755926627" = "Used"
    "267755943527" = "Used"
    "267755998578" = "New"
    "267749527109" = "Used"
    "267751001037" = "Used"
    "267729724182" = "New"
    "267755952157" = "Used"
    "267755953364" = "Used"
    "267745716527" = "Used"
    "267724077386" = "Used"
    "267749540271" = "New"
    "267707226458" = "Used"
    "267729833616" = "New"
    "267755954889" = "Used"
    "267729716060" = "New"
    "267693030846" = "Used"
    "267430465802" = "New"
    "267729872766" = "New"
    "267755927520" = "Used"
    "267755930402" = "Opened - never used" # HP Omen MAX 16
    "267729953043" = "New"
    "267737447289" = "Used"
    "267727293251" = "New" # Lenovo Legion Go 2 is NEW
    "267707202814" = "New"
    "267734395927" = "Used"
    "267749825193" = "Used"
    "267749535331" = "Used"
    "267752340040" = "Used"
    "267696116748" = "Used"
    "267724113981" = "Used"
    "267705687033" = "Used"
    "267751011916" = "Used"
    "267724515696" = "Used"
    "267749826375" = "Used"
    "267752341737" = "Used"
    "267755928454" = "Used"
    "267751010844" = "Used"
    "267751013971" = "Used"
    "267696126054" = "Used"
    "267749434966" = "Used"
    "267734388443" = "Used"
    "267755933329" = "Used"
    "267738488721" = "For parts or not working" # Razer Blade 16 FAULTY
    "267749439592" = "Used"
    "267752334041" = "Used"
    "267700848730" = "Used"
    "267709120613" = "Used"
    "267729651885" = "Used"
    "267745364867" = "Used"
    "267709005130" = "Used"
    "267755999760" = "New"
    "267755968618" = "Used"
    "267724109322" = "New"
    "267734199450" = "Used"
    "267734410731" = "Used"
    "267727449613" = "Used"
    "267694603976" = "Used"
    "267755939395" = "Used"
    "267734405944" = "Used"
    "267727430252" = "Used"
    "267714982897" = "Used"
    "267727425956" = "Used"
}

# Pre-sort items by price High to Low by default
$items = $items | Sort-Object {
    if ($_.Price -match '[\d,]+(?:\.\d{2})?') {
        [double]($matches[0] -replace ',', '')
    } else {
        0
    }
} -Descending

foreach ($item in $items) {
    $itemId = $item.ItemId
    $titleRaw = $item.Title.Trim()
    $title = [System.Web.HttpUtility]::HtmlEncode($titleRaw)
    $price = $item.Price
    $url = $item.Url
    $img = $item.Image
    
    # Direct live scraped condition from eBay item page
    $exactCond = "Used"
    if ($liveCondMap.ContainsKey($itemId)) {
        $exactCond = $liveCondMap[$itemId]
    }
    
    $condIcon = "fa-rotate-left"
    if ($exactCond -eq "New") {
        $condIcon = "fa-sparkles"
    } elseif ($exactCond -eq "Opened - never used") {
        $condIcon = "fa-box-open"
    } elseif ($exactCond -eq "For parts or not working") {
        $condIcon = "fa-wrench"
    } else {
        $condIcon = "fa-rotate-left"
    }
    
    $numPrice = 999
    if ($price -match '[\d,]+(?:\.\d{2})?') {
        $numPrice = [double]($matches[0] -replace ',', '')
    }
    
    $pills = @()
    
    # 1. Condition Pill directly from live eBay item page
    $pills += '<span><i class="fa-solid ' + $condIcon + '"></i> ' + $exactCond + '</span>'
    
    # 2. CPU / Processor / Sensor / Spec
    if ($titleRaw -match '(Ultra 9 \d+HX|Ultra 9 \d+H|Ultra 7 \d+HX|Ultra 7 \d+H|Ultra 5 \d+V|Ultra 5 \d+U|i9 \d+HX|i9 \d+H|i7 \d+HX|i7 \d+H|i7 \d+U|i7 \d+th Gen|i5 \d+th Gen|Ryzen AI 9 HX \d+|Ryzen 9 \d+HX|Ryzen 7 \d+HS|Snapdragon X2 Elite|Snapdragon X|Z2 Extreme)') {
        $pills += '<span><i class="fa-solid fa-microchip"></i> ' + $matches[1] + '</span>'
    } elseif ($titleRaw -match '(Ultra 9|Ultra 7|Ultra 5|i9|i7|i5|Ryzen 9|Ryzen 7|Ryzen AI)') {
        $pills += '<span><i class="fa-solid fa-microchip"></i> ' + $matches[1] + '</span>'
    } elseif ($titleRaw -match '(26MP|33MP|24\.2 MP)') {
        $pills += '<span><i class="fa-solid fa-camera"></i> ' + $matches[1] + ' Sensor</span>'
    }
    
    # 3. GPU / Lens Spec
    if ($titleRaw -match '(RTX 5090|RTX 5080|RTX 5070 Ti|RTX 5070|RTX 5060|RTX 4090|RTX 4080|RTX 4070|RTX 4060|RTX 4050|RTX 3080 Ti|RTX 3070 Ti|RTX 3070|RTX 3050|RTX 2060|RTX 2000 Ada|RTX PRO 4000|RTX PRO 3000|RTX PRO 2000|RTX PRO 500|RTX A2000|RTX 5000 Ada)') {
        $pills += '<span><i class="fa-solid fa-compact-disc"></i> RTX ' + ($matches[1] -replace 'RTX\s*', '') + '</span>'
    } elseif ($titleRaw -match '(\d+-\d+mm F/?\d+\.\d|\d+-\d+mm|\d+mm F/?\d+\.\d|\d+mm)') {
        $pills += '<span><i class="fa-solid fa-circle-dot"></i> ' + $matches[1] + '</span>'
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
        $pills += '<span><i class="fa-solid fa-memory"></i> ' + $ramStr + ' &bull; ' + $storageStr + '</span>'
    } elseif ($ramStr -and $displayStr) {
        $pills += '<span><i class="fa-solid fa-memory"></i> ' + $ramStr + ' &bull; ' + $displayStr + '</span>'
    } elseif ($displayStr) {
        $pills += '<span><i class="fa-solid fa-desktop"></i> ' + $displayStr + '</span>'
    } elseif ($ramStr) {
        $pills += '<span><i class="fa-solid fa-memory"></i> ' + $ramStr + '</span>'
    }
    
    $pillsHtml = $pills -join "`n                "
    
    $cdnImg = if ($cdnMap.ContainsKey($itemId)) { $cdnMap[$itemId] } else { $img }

    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-price="$numPrice">
            <div class="inv-card-img-wrap">
              <img src="$cdnImg" alt="$title" loading="lazy" referrerpolicy="no-referrer">
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
          <li><a href="inventory.html" class="active-nav">All Inventory</a></li>
          <li><a href="#contact">Contact Us</a></li>
        </ul>
      </nav>

      <div class="nav-actions">
        <button class="theme-toggle-btn" id="themeToggleBtn" aria-label="Toggle Light/Dark Theme" title="Toggle Light/Dark Theme">
          <i class="fa-solid fa-sun"></i>
        </button>
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
    <section class="inventory-hero">
      <div class="container">
        <div class="section-title-area" style="margin-bottom: 30px;">
          <div class="pill-badge" style="margin-bottom: 16px;">
            <span class="live-pulse-dot"></span>
            <span>Live Sync with eBay Store</span>
          </div>
          <h1 class="section-heading inventory-main-heading">Complete Store Inventory (<span id="inventoryHeaderCount">82</span> Listings)</h1>
          <p class="section-desc">
            Filter by condition or search below!
          </p>
        </div>

        <!-- Filter Controls Bar with Search by Condition Pills -->
        <div class="inventory-controls-bar" style="flex-direction: column; align-items: stretch; gap: 16px;">
          
          <!-- Condition Filter Pills Bar -->
          <div class="condition-filter-row" id="conditionFilterRow">
            <button class="condition-pill-btn active" data-condition="all">
              <i class="fa-solid fa-border-all"></i> All Items (82)
            </button>
            <button class="condition-pill-btn" data-condition="New">
              <i class="fa-solid fa-sparkles"></i> New
            </button>
            <button class="condition-pill-btn" data-condition="Opened - never used">
              <i class="fa-solid fa-box-open"></i> Opened - never used
            </button>
            <button class="condition-pill-btn" data-condition="Used">
              <i class="fa-solid fa-rotate-left"></i> Used
            </button>
            <button class="condition-pill-btn" data-condition="For parts or not working">
              <i class="fa-solid fa-wrench"></i> For Parts
            </button>
          </div>

          <!-- Search & Sort Row -->
          <div style="display: flex; gap: 16px; flex-wrap: wrap; width: 100%; align-items: center;">
            <div class="search-filter-input-wrap" style="flex: 1; min-width: 280px;">
              <i class="fa-solid fa-magnifying-glass search-icon"></i>
              <input type="text" id="inventorySearchInput" placeholder="e.g. Legion Go 2, RTX 5080, Alienware, Omen..." class="inventory-search-input">
            </div>

            <div class="sort-select-wrap">
              <label for="inventorySortSelect" style="font-size: 0.875rem; color: var(--text-muted);">Sort:</label>
              <select id="inventorySortSelect" class="inventory-sort-select">
                <option value="price-desc" selected>Price: High to Low</option>
                <option value="price-asc">Price: Low to High</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Full Inventory Grid Section with ALL 82 Real eBay Store Items -->
    <section class="inventory-grid-section">
      <div class="container">
        <!-- Filtered Results Subtext Line just above the first product photo -->
        <div class="filtered-results-count" id="filteredResultsCount" style="margin-bottom: 24px;">
          <i class="fa-solid fa-list-check"></i> Showing all 82 active listings
        </div>

        <div id="fullInventoryGrid" class="full-inventory-grid">

CARD_HOLDER_PLACEHOLDER

        </div>

        <!-- Catalog Loaded Completion Badge -->
        <div class="all-loaded-banner" style="text-align: center; margin-top: 40px; padding: 20px; color: var(--text-sub); display: flex; align-items: center; justify-content: center; gap: 10px; font-size: 0.95rem; border-top: 1px solid rgba(255, 255, 255, 0.08);">
          <i class="fa-solid fa-circle-check" style="color: #22c55e; font-size: 1.1rem;"></i>
          <span>Showing all 82 active listings live from Pandota's eBay store</span>
        </div>
      </div>
    <!-- Contact Us Section -->
    <section class="section" id="contact" style="padding: 60px 0 40px;">
      <div class="container" style="max-width: 760px; text-align: center;">
        <div class="contact-box" style="background: var(--bg-card); border: 1px solid var(--border-active); border-radius: var(--radius-lg); padding: 40px 24px; box-shadow: var(--shadow-lg);">
          <div style="width: 54px; height: 54px; border-radius: 50%; background: rgba(0, 100, 210, 0.15); color: var(--ebay-blue); display: flex; align-items: center; justify-content: center; margin: 0 auto 18px; font-size: 1.5rem;">
            <i class="fa-solid fa-comments"></i>
          </div>
          <h2 class="section-heading" style="font-size: 2rem; margin-bottom: 12px;">Contact Us</h2>
          <p class="section-desc" style="max-width: 580px; margin: 0 auto 24px; font-size: 1.05rem;">
            Have a question about an item or need help choosing the right spec? Please contact us via <strong>eBay messaging</strong> for fast, friendly support!
          </p>
          <a href="https://www.ebay.co.uk/cnt/InterMessageWithSeller?requested=geoff_lee367" target="_blank" rel="noopener" class="btn btn-ebay" style="font-size: 1rem; padding: 14px 28px; display: inline-flex; align-items: center; gap: 8px;">
            <i class="fa-solid fa-paper-plane"></i>
            <span>Message Us on eBay</span>
            <i class="fa-solid fa-arrow-up-right-from-square"></i>
          </a>
        </div>
      </div>
    </section>
  </main>

  <!-- Footer -->
  <footer class="footer" style="padding: 30px 0;">
    <div class="container" style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 16px;">
      <a href="index.html" class="logo-brand">
        <img src="images/panda_logo.png" alt="Pandota Logo" class="brand-panda-img">
        <span>PANDOTA</span>
      </a>
      <p style="font-size: 0.9rem; color: var(--text-muted);">&copy; <span id="currentYear">2026</span> Pandota Ltd. All rights reserved.</p>
    </div>
  </footer>

  <script src="script.js"></script>
</body>
</html>
"@

$finalHtml = $fullHtml.Replace("CARD_HOLDER_PLACEHOLDER", $cardsHtml)
[System.IO.File]::WriteAllText("inventory.html", $finalHtml, [System.Text.Encoding]::UTF8)
Write-Host "Successfully rebuilt inventory.html using 100% direct live scraped eBay page conditions!"
