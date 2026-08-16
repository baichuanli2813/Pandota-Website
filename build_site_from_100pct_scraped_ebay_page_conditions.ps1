# ==============================================================================
# Pandota Ltd - Official Catalog & Inventory Builder (81 Active Listings)
# Direct High-Speed eBay CDN Images, Exact Scraped Conditions & Clean Encodings
# ==============================================================================

$items = Get-Content -Path "all_82_with_exact_scraped_prices.json" -Raw | ConvertFrom-Json
$storeListings = Get-Content -Path "all_store_listings.json" -Raw | ConvertFrom-Json
$cdnMap = @{}
foreach ($sl in $storeListings) {
    if ($sl.ItemId -and $sl.ImageUrl) {
        $cdnMap[$sl.ItemId] = $sl.ImageUrl
    }
}

$totalCount = $items.Count
Write-Host "Building inventory.html with exact $totalCount active live listings and direct eBay CDN images..."

$cardsHtml = ""

# Map of live scraped conditions directly from eBay item pages:
$liveCondMap = @{
    "267729753193" = "New"
    "267729862669" = "New"
    "267729734670" = "New"
    "267755974090" = "Used"
    "267707331524" = "New"
    "267753890742" = "New"
    "267745470208" = "New"
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
    "267430465802" = "Used"
    "267729872766" = "New"
    "267755927520" = "Used"
    "267755930402" = "New"
    "267729953043" = "New"
    "267737447289" = "Used"
    "267727293251" = "New"
    "267707202814" = "New"
    "267734395927" = "Used"
    "267749825193" = "Used"
    "267749535331" = "Used"
    "267752340040" = "Used"
    "267696116748" = "Used"
    "267724113981" = "New"
    "267705687033" = "Used"
    "267751011916" = "Used"
    "267724515696" = "Used"
    "267749826375" = "Used"
    "267752341737" = "Used"
    "267755928454" = "Used"
    "267751010844" = "Used"
    "267696126054" = "Used"
    "267749434966" = "Used"
    "267734388443" = "Used"
    "267755933329" = "Used"
    "267738488721" = "For parts or not working"
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
    "267727463283" = "Used"
    "267727425956" = "Used"
}

foreach ($it in $items) {
    $itemId = $it.ItemId
    $titleRaw = $it.Title
    $title = [System.Net.WebUtility]::HtmlEncode($titleRaw)
    $price = $it.Price
    $numPrice = $it.NumPrice
    $url = $it.Url
    $img = $it.Img

    # Determine condition
    $cond = if ($liveCondMap.ContainsKey($itemId)) {
        $liveCondMap[$itemId]
    } elseif ($titleRaw -match '\b(NEW|SEALED|BRAND NEW)\b') {
        "New"
    } elseif ($titleRaw -match '\b(FAULTY|FOR PARTS|AS IS)\b') {
        "For parts or not working"
    } else {
        "Used"
    }

    # Extract CPU
    $cpu = ""
    if ($titleRaw -match '(Ultra\s*\d\s*[\d\w]+)') {
        $cpu = $matches[1]
    } elseif ($titleRaw -match '(Ryzen\s*(?:AI)?\s*\d\s*[\d\w]+)') {
        $cpu = $matches[1]
    } elseif ($titleRaw -match '(i\d\s*\d+[\d\w]*)') {
        $cpu = $matches[1]
    } elseif ($titleRaw -match '(Snapdragon\s*X\s*[\w\d]+)') {
        $cpu = $matches[1]
    } elseif ($titleRaw -match '(M\d\s*(?:Pro|Max)?)') {
        $cpu = $matches[1]
    }

    # Extract GPU
    $gpu = ""
    if ($titleRaw -match '(RTX\s*(?:PRO\s*)?\d{4}(?:\s*Ti|\s*Ada|\s*Blackwell)?)') {
        $gpu = $matches[1]
    } elseif ($titleRaw -match '(RTX\s*A\d{4})') {
        $gpu = $matches[1]
    } elseif ($titleRaw -match '(Radeon\s*[\d\w]+)') {
        $gpu = $matches[1]
    }

    # Extract RAM & Storage
    $ramStr = ""
    $storageStr = ""
    if ($titleRaw -match '(\d+GB\s*RAM|\b(?:16|32|64|128)GB\b)') {
        $ramStr = $matches[1] -replace '\s*RAM', ''
    }
    if ($titleRaw -match '(\d+(?:\.\d+)?TB|\b512GB\b|\b256GB\b)') {
        $storageStr = $matches[1]
    }

    # Build pills
    $pills = @()
    if ($cond -eq "New") {
        $pills += '<span><i class="fa-solid fa-sparkles"></i> New</span>'
    } elseif ($cond -eq "Opened - never used") {
        $pills += '<span><i class="fa-solid fa-box-open"></i> Open Box</span>'
    } elseif ($cond -eq "For parts or not working") {
        $pills += '<span><i class="fa-solid fa-wrench"></i> For Parts</span>'
    }

    if ($cpu) {
        $pills += '<span><i class="fa-solid fa-microchip"></i> ' + $cpu + '</span>'
    }
    if ($gpu) {
        $pills += '<span><i class="fa-solid fa-compact-disc"></i> ' + $gpu + '</span>'
    }
    if ($ramStr -and $storageStr) {
        $pills += '<span><i class="fa-solid fa-memory"></i> ' + $ramStr + ' &bull; ' + $storageStr + '</span>'
    } elseif ($ramStr) {
        $pills += '<span><i class="fa-solid fa-memory"></i> ' + $ramStr + '</span>'
    }
    
    $pillsHtml = $pills -join "`n                "
    $cdnImg = if ($cdnMap.ContainsKey($itemId)) { $cdnMap[$itemId] } else { $img }

    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-item-id="$itemId" data-price="$numPrice">
            <div class="inv-card-img-wrap">
              <img src="$cdnImg" alt="$title" loading="lazy" referrerpolicy="no-referrer">
            </div>
            <div class="inv-card-body">
              <div class="inv-card-price-row">
                <div class="inv-card-price">$price</div>
              </div>
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
<html lang="en" data-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>All Active Inventory ($totalCount Listings) - Pandota Ltd Official eBay Store</title>
  <meta name="description" content="Browse all $totalCount active listings live from Pandota's official eBay store (geoffscuriosities). High-performance laptops, gaming rigs, workstations, and electronics.">
  <meta name="keywords" content="Pandota inventory, Pandota laptops, Pandota eBay listings, Lenovo Legion, Alienware, ASUS ROG, HP Omen, eBay UK seller">

  <script>
    (function() {
      var saved = localStorage.getItem('pandota_theme') || 'light';
      document.documentElement.setAttribute('data-theme', saved);
    })();
  </script>

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
          <i class="fa-solid fa-moon"></i>
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
          <h1 class="section-heading inventory-main-heading">Complete Store Inventory (<span id="inventoryHeaderCount">$totalCount</span> Listings)</h1>
          <p class="section-desc">
            Filter by condition or search below!
          </p>
        </div>

        <!-- Filter Controls Bar with Search by Condition Pills -->
        <div class="inventory-controls-bar" style="flex-direction: column; align-items: stretch; gap: 16px;">
          
          <!-- Condition Filter Pills Bar -->
          <div class="condition-filter-row" id="conditionFilterRow">
            <button class="condition-pill-btn active" data-condition="all">
              <i class="fa-solid fa-border-all"></i> All Items ($totalCount)
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

    <!-- Full Inventory Grid Section with ALL Real eBay Store Items -->
    <section class="inventory-grid-section">
      <div class="container">
        <!-- Filtered Results Subtext Line just above the first product photo -->
        <div class="filtered-results-count" id="filteredResultsCount" style="margin-bottom: 24px;">
          Showing <span id="visibleCount" style="font-weight: 700; color: var(--text-main);">$totalCount</span> of $totalCount items in stock
        </div>

        <div class="full-inventory-grid" id="inventoryGrid">
$cardsHtml
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

  <script src="script.js?v=1.2"></script>
</body>
</html>
"@

[System.IO.File]::WriteAllText("$pwd\inventory.html", $fullHtml, [System.Text.Encoding]::UTF8)

# Update count references in index.html
if (Test-Path "index.html") {
    $indexHtml = Get-Content "index.html" -Raw -Encoding utf8
    $indexHtml = $indexHtml -replace 'View All \(\d+\)', "View All ($totalCount)"
    $indexHtml = $indexHtml -replace '\b\d+\+\s*Laptops\b', "$totalCount+ Laptops"
    [System.IO.File]::WriteAllText("$pwd\index.html", $indexHtml, [System.Text.Encoding]::UTF8)
}

Write-Host "Successfully built inventory.html and updated index.html with exactly $totalCount active live listings!"
