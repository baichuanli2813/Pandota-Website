# ==============================================================================
# Pandota Ltd - Official Catalog & Inventory Builder
# Direct High-Speed eBay CDN Images, Dynamic Real-Time Categories (Threshold >= 2), Clean Encodings
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
Write-Host "Building inventory.html with dynamic categories (>= 2 threshold) across $totalCount active listings..."

# Recognized brand rules with distinct icons
$brandDefinitions = @(
    @{ Name = "Alienware";       Icon = "fa-gamepad";               Pattern = '(?i)\bAlienware\b' },
    @{ Name = "Dell";            Icon = "fa-desktop";               Pattern = '(?i)\b(Dell|XPS|Precision|Latitude|Inspiron)\b' },
    @{ Name = "Lenovo";          Icon = "fa-laptop";                Pattern = '(?i)\b(Lenovo|Legion|ThinkPad|LOQ|Yoga|IdeaPad)\b' },
    @{ Name = "ASUS";            Icon = "fa-microchip";             Pattern = '(?i)\b(ASUS|ROG|Zephyrus|Strix|SCAR|TUF|ZenBook|Flow|ProArt)\b' },
    @{ Name = "HP";              Icon = "fa-bolt";                  Pattern = '(?i)\b(HP|Omen|Victus|ZBook|EliteBook|Envy|Pavilion|Spectre)\b' },
    @{ Name = "Sony";            Icon = "fa-camera";                Pattern = '(?i)\b(Sony|Alpha\s*A\d+|SEL\d+|ILCE)\b' },
    @{ Name = "Microsoft";       Icon = "fa-tablet-screen-button";  Pattern = '(?i)\b(Surface|Microsoft)\b' },
    @{ Name = "MacBook";         Icon = "fa-brands fa-apple";       Pattern = '(?i)\b(MacBook|Apple|iMac|Mac\s*Mini)\b' },
    @{ Name = "Razer";           Icon = "fa-shield-halved";         Pattern = '(?i)\b(Razer|Blade)\b' },
    @{ Name = "MSI";             Icon = "fa-dragon";                Pattern = '(?i)\b(MSI|Titan|Raider|Stealth|Vector|Katana|Pulse|Creator)\b' },
    @{ Name = "Acer";            Icon = "fa-display";               Pattern = '(?i)\b(Acer|Predator|Helios|Nitro|Swift|Triton)\b' },
    @{ Name = "PC Specialist";   Icon = "fa-gears";                 Pattern = '(?i)\b(PC\s*Specialist|Defiance|Recoil|Elimina)\b' },
    @{ Name = "Samsung";         Icon = "fa-mobile-screen";         Pattern = '(?i)\b(Samsung|Galaxy\s*Book)\b' },
    @{ Name = "Gigabyte";        Icon = "fa-server";                Pattern = '(?i)\b(Gigabyte|AORUS|Aero)\b' },
    @{ Name = "Framework";       Icon = "fa-screwdriver-wrench";   Pattern = '(?i)\bFramework\b' }
)

function Detect-BrandName($title) {
    foreach ($b in $brandDefinitions) {
        if ($title -match $b.Pattern) {
            return $b.Name
        }
    }
    return "Other"
}

function Get-BrandIcon($brandName) {
    foreach ($b in $brandDefinitions) {
        if ($b.Name -eq $brandName) { return $b.Icon }
    }
    return "fa-boxes-stacked"
}

# 1. Analyze initial brand distributions
$rawBrandCounts = @{}
foreach ($it in $items) {
    $bName = Detect-BrandName $it.Title
    if (-not $rawBrandCounts.ContainsKey($bName)) { $rawBrandCounts[$bName] = 0 }
    $rawBrandCounts[$bName]++
}

# 2. Determine qualifying categories (>= 2 listings), consolidate others (< 2) into 'Other'
$qualifyingCategories = [System.Collections.Generic.List[string]]::new()
$otherCount = 0

foreach ($b in $brandDefinitions) {
    $bName = $b.Name
    if ($rawBrandCounts.ContainsKey($bName)) {
        if ($rawBrandCounts[$bName] -ge 2) {
            $qualifyingCategories.Add($bName)
        } else {
            $otherCount += $rawBrandCounts[$bName]
        }
    }
}
if ($rawBrandCounts.ContainsKey("Other")) {
    $otherCount += $rawBrandCounts["Other"]
}

# Sort qualifying categories by count descending
$sortedQualifying = $qualifyingCategories | Sort-Object { $rawBrandCounts[$_] } -Descending

Write-Host "Qualifying Category Pills (Count >= 2):"
foreach ($qc in $sortedQualifying) {
    Write-Host " - $qc ($($rawBrandCounts[$qc]) items)"
}
if ($otherCount -gt 0) {
    Write-Host " - Other ($otherCount items)"
}

# 3. Generate Category Pills HTML
$categoryPillsHtml = @"
            <button class="category-pill-btn active" data-category="all">
              <i class="fa-solid fa-border-all"></i> All ($totalCount)
            </button>
"@

foreach ($qc in $sortedQualifying) {
    $cIcon = Get-BrandIcon $qc
    $cCount = $rawBrandCounts[$qc]
    $categoryPillsHtml += @"

            <button class="category-pill-btn" data-category="$qc">
              <i class="fa-solid $cIcon"></i> $qc ($cCount)
            </button>
"@
}

if ($otherCount -gt 0) {
    $categoryPillsHtml += @"

            <button class="category-pill-btn" data-category="Other">
              <i class="fa-solid fa-boxes-stacked"></i> Other ($otherCount)
            </button>
"@
}

# Automatically update/load official conditions directly from eBay store if online
$condFile = "official_scraped_ebay_conditions.json"
$officialConds = $null
if (Test-Path $condFile) {
    $officialConds = Get-Content -Path $condFile -Raw | ConvertFrom-Json
}

$countNew = 0
$countOpened = 0
$countUsed = 0
$countParts = 0
$countCoupons = 0

# Count active coupons across items
foreach ($it in $items) {
    if ($it.PSObject.Properties['Coupon'] -and $it.Coupon -and $it.Coupon.ToString().Trim() -ne "") {
        $countCoupons++
    }
}

$cardsHtml = ""

foreach ($it in $items) {
    $itemId = $it.ItemId
    $titleRaw = $it.Title
    $title = [System.Net.WebUtility]::HtmlEncode($titleRaw)
    $price = $it.Price
    $numPrice = ($price -replace '[^\d.]', '').Trim()
    if (-not $numPrice) { $numPrice = "0" }
    $url = $it.Url
    $img = $it.Img

    # Determine assigned category for filtering
    $detectedBrand = Detect-BrandName $titleRaw
    $assignedCategory = if ($qualifyingCategories.Contains($detectedBrand)) { $detectedBrand } else { "Other" }

    # Condition is determined directly from official eBay listing condition
    $cond = if ($it.PSObject.Properties['Condition'] -and $it.Condition) {
        $it.Condition
    } elseif ($officialConds.PSObject.Properties[$itemId]) {
        $officialConds.$itemId
    } else {
        "Used"
    }

    if ($cond -eq "New") { $countNew++ }
    elseif ($cond -eq "Opened - never used") { $countOpened++ }
    elseif ($cond -eq "For parts or not working") { $countParts++ }
    else { $countUsed++ }

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

    # Build feature pills with Category badge first
    $cardIcon = Get-BrandIcon $detectedBrand
    $displayBadge = if ($detectedBrand -ne "Other") { $detectedBrand } else { "Specialty" }

    $pills = @()
    $pills += "<span class=`"inv-card-pill category-pill`"><i class=`"fa-solid $cardIcon`"></i> $displayBadge</span>"

    if ($cond -eq "New") {
        $pills += '<span><i class="fa-solid fa-sparkles"></i> New</span>'
    } elseif ($cond -eq "Opened - never used") {
        $pills += '<span><i class="fa-solid fa-box-open"></i> Opened - never used</span>'
    } elseif ($cond -eq "For parts or not working") {
        $pills += '<span><i class="fa-solid fa-wrench"></i> For Parts</span>'
    } else {
        $pills += '<span><i class="fa-solid fa-rotate-left"></i> Used</span>'
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

    # Extract Views from eBay Seller Analytics
    $viewsCount = if ($it.PSObject.Properties['Views'] -and $it.Views -ne $null) {
        [int]$it.Views
    } else {
        0
    }
    
    $pillsHtml = $pills -join "`n                "

    # Direct high-speed eBay CDN Image URL with universal .jpg fallback
    $cdnImg = if ($cdnMap.ContainsKey($itemId) -and $cdnMap[$itemId]) {
        $cdnMap[$itemId]
    } elseif ($img) {
        $img
    } else {
        "images/ebay_item_$itemId.jpg"
    }

    if ($cdnImg -match '\.webp') {
        $cdnImg = $cdnImg -replace '\.webp', '.jpg'
    }

    # Dynamic eBay Coupon Badge
    $couponBadgeHtml = ""
    $couponAttr = ""
    if ($it.PSObject.Properties['Coupon'] -and $it.Coupon -and $it.Coupon.ToString().Trim() -ne "") {
        $couponCode = [System.Net.WebUtility]::HtmlEncode($it.Coupon.ToString().Trim())
        $couponAttr = "data-coupon=`"true`""
        $couponBadgeHtml = @"
                <div class="inv-card-coupon-badge" title="eBay Promo Code: $couponCode">
                  <i class="fa-solid fa-ticket"></i>
                  <span>$couponCode</span>
                </div>
"@
    }

    # 24h Views Badge (Exact eBay Analytics data)
    $viewsBadgeHtml = if ($viewsCount -gt 0) {
        @"
                <div class="inv-card-views-prominent-badge" title="$viewsCount views in the last 24 hours on eBay">
                  <i class="fa-solid fa-eye"></i>
                  <span class="views-count">$($viewsCount.ToString("N0")) views (24h)</span>
                </div>
"@
    } else {
        @"
                <div class="inv-card-views-prominent-badge new-listing-views-badge" title="Brand new listing on eBay">
                  <i class="fa-solid fa-bolt"></i>
                  <span class="views-count">Just Listed</span>
                </div>
"@
    }

    # Watchers Badge (Top right overlay on photo)
    $watchCount = if ($it.PSObject.Properties['Watchers'] -and $it.Watchers -ne $null) {
        [int]$it.Watchers
    } else {
        0
    }

    $watchOverlayHtml = if ($watchCount -gt 0) {
        @"
              <div class="inv-card-photo-watcher-badge" title="$watchCount buyers watching on eBay">
                <i class="fa-solid fa-heart"></i>
                <span class="watcher-count" data-item-id="$itemId">$watchCount watching</span>
              </div>
"@
    } else {
        @"
              <div class="inv-card-photo-watcher-badge" title="Active listing on eBay">
                <i class="fa-regular fa-heart" style="color: #94a3b8;"></i>
                <span class="watcher-count" data-item-id="$itemId">Active</span>
              </div>
"@
    }

    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-item-id="$itemId" data-brand="$detectedBrand" data-category="$assignedCategory" data-price="$numPrice" data-condition="$cond" data-watchers="$watchCount" data-views="$viewsCount" $couponAttr>
            <div class="inv-card-img-wrap">
              <img src="$cdnImg" alt="$title" loading="lazy" referrerpolicy="no-referrer" onerror="if(!this.dataset.triedJpg && this.src.indexOf('.webp')!==-1){this.dataset.triedJpg='1';this.src=this.src.replace('.webp','.jpg');}else if(!this.dataset.triedBackup){this.dataset.triedBackup='1';this.src='images/ebay_item_$itemId.jpg';}">
$watchOverlayHtml
            </div>
            <div class="inv-card-body">
              <div class="inv-card-price-row">
                <div class="inv-card-price">$price</div>
$couponBadgeHtml
$viewsBadgeHtml
              </div>
              <h3 class="inv-card-title">$title</h3>
              <div class="inv-card-features">
                $pillsHtml
              </div>
              <a href="$url" target="_blank" rel="noopener" class="btn btn-ebay" style="width: 100%; margin-top: auto;">
                <span>View Listing on eBay</span>
                <i class="fa-solid fa-arrow-up-right-from-square"></i>
              </a>
            </div>
          </div>
"@
}

# 4. Generate Condition Pills (Never show any pill with 0 count)
$conditionPillsList = @()
$conditionPillsList += @"
            <button class="condition-pill-btn active" data-condition="all">
              <i class="fa-solid fa-border-all"></i> All Conditions ($totalCount)
            </button>
"@

if ($countNew -gt 0) {
    $conditionPillsList += @"
            <button class="condition-pill-btn" data-condition="New">
              <i class="fa-solid fa-sparkles"></i> New ($countNew)
            </button>
"@
}
if ($countOpened -gt 0) {
    $conditionPillsList += @"
            <button class="condition-pill-btn" data-condition="Opened - never used">
              <i class="fa-solid fa-box-open"></i> Opened - never used ($countOpened)
            </button>
"@
}
if ($countUsed -gt 0) {
    $conditionPillsList += @"
            <button class="condition-pill-btn" data-condition="Used">
              <i class="fa-solid fa-rotate-left"></i> Used ($countUsed)
            </button>
"@
}
if ($countParts -gt 0) {
    $conditionPillsList += @"
            <button class="condition-pill-btn" data-condition="For parts or not working">
              <i class="fa-solid fa-wrench"></i> For Parts ($countParts)
            </button>
"@
}
if ($countCoupons -gt 0) {
    $conditionPillsList += @"
            <button class="condition-pill-btn coupon-pill-btn" data-condition="coupon" id="couponFilterPill">
              <i class="fa-solid fa-tag"></i> eBay Coupons ($countCoupons)
            </button>
"@
}
$conditionPillsHtml = $conditionPillsList -join "`n"

$fullHtml = @"
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>All Active Inventory ($totalCount Listings) - Pandota Ltd Official eBay Store</title>
  <meta name="description" content="Browse all $totalCount active listings live from Pandota's official eBay store (geoffscuriosities). High-performance laptops, gaming rigs, workstations, and electronics.">
  <meta name="keywords" content="Pandota inventory, Pandota laptops, Pandota eBay listings, Lenovo Legion, Alienware, ASUS ROG, HP Omen, eBay UK seller">
  <link rel="canonical" href="https://pandota.co.uk/inventory.html">

  <!-- Google tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-SJXRYQ5DQT"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', 'G-SJXRYQ5DQT');
  </script>

  <!-- OpenGraph Brand Identity -->
  <meta property="og:site_name" content="Pandota">
  <meta property="og:title" content="All Active Inventory ($totalCount Listings) - Pandota Ltd">
  <meta property="og:description" content="Browse active gaming laptops, ultrabooks, and workstations from Pandota Ltd.">
  <meta property="og:url" content="https://pandota.co.uk/inventory.html">
  <meta property="og:type" content="website">
  <meta property="og:image" content="https://pandota.co.uk/images/panda_logo.png">

  <!-- Schema.org Knowledge Graph Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "@id": "https://pandota.co.uk/#organization",
        "name": "Pandota",
        "legalName": "Pandota Ltd",
        "alternateName": ["Pandota UK", "Pandota Store", "Pandota Laptops", "geoffscuriosities"],
        "url": "https://pandota.co.uk",
        "logo": "https://pandota.co.uk/images/panda_logo.png",
        "email": "purchasing@pandota.co.uk",
        "identifier": "14961273",
        "sameAs": [
          "https://www.ebay.co.uk/str/geoffscuriosities",
          "https://www.ebay.co.uk/usr/geoff_lee367",
          "https://find-and-update.company-information.service.gov.uk/company/14961273"
        ],
        "address": {
          "@type": "PostalAddress",
          "streetAddress": "24 Groveley Lane",
          "addressLocality": "Birmingham",
          "postalCode": "B31 4QH",
          "addressCountry": "GB"
        }
      },
      {
        "@type": "CollectionPage",
        "@id": "https://pandota.co.uk/inventory.html#webpage",
        "url": "https://pandota.co.uk/inventory.html",
        "name": "Complete Store Inventory - Pandota Ltd",
        "isPartOf": { "@id": "https://pandota.co.uk/#website" },
        "about": { "@id": "https://pandota.co.uk/#organization" }
      }
    ]
  }
  </script>

  <!-- Immediate Theme Engine -->
  <script>
    (function() {
      window.applyPandotaTheme = function(theme) {
        if (theme === 'dark') {
          document.documentElement.removeAttribute('data-theme');
          document.documentElement.setAttribute('data-theme', 'dark');
        } else {
          document.documentElement.setAttribute('data-theme', 'light');
        }
        try { localStorage.setItem('pandota_theme', theme); } catch(e) {}
        
        var toggleBtns = document.querySelectorAll('#themeToggleBtn');
        toggleBtns.forEach(function(btn) {
          var icon = btn.querySelector('i');
          if (icon) {
            icon.className = theme === 'dark' ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
          }
        });
      };

      window.togglePandotaTheme = function() {
        var current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
        var next = current === 'dark' ? 'light' : 'dark';
        window.applyPandotaTheme(next);
      };

      window.togglePandotaMobileMenu = function() {
        var navLinks = document.getElementById('navLinks');
        var btn = document.getElementById('mobileToggle');
        if (!navLinks) return;
        var isOpen = navLinks.classList.toggle('active');
        if (btn) {
          var icon = btn.querySelector('i');
          if (icon) {
            icon.className = isOpen ? 'fa-solid fa-xmark' : 'fa-solid fa-bars';
          }
        }
      };

      window.handleEmailSpecsClick = function(e) {
        var email = 'purchasing@pandota.co.uk';
        var mailtoUrl = 'mailto:' + email + '?subject=Laptop%20Sale%20%2F%20Supplier%20Inquiry%20-%20Pandota';
        
        // 1. Copy to clipboard
        try {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(email);
          } else {
            var temp = document.createElement('input');
            temp.value = email;
            document.body.appendChild(temp);
            temp.select();
            document.execCommand('copy');
            document.body.removeChild(temp);
          }
        } catch(err) {}

        // 2. Button visual feedback
        var btn = document.getElementById('emailSpecsBtn');
        var btnText = document.getElementById('emailSpecsBtnText');
        if (btnText) {
          var original = btnText.innerHTML;
          btnText.innerHTML = 'Email Copied (' + email + ')';
          if (btn) btn.style.background = '#10b981';
          setTimeout(function() {
            if (btnText) btnText.innerHTML = original;
            if (btn) btn.style.background = '';
          }, 3500);
        }

        // 3. Show Toast Notification
        var toast = document.getElementById('emailToast');
        if (!toast) {
          toast = document.createElement('div');
          toast.id = 'emailToast';
          toast.className = 'email-copy-toast';
          document.body.appendChild(toast);
        }
        toast.innerHTML = '<i class="fa-solid fa-circle-check"></i> <span>Copied <strong>' + email + '</strong> to clipboard (Opening email...)</span>';
        toast.classList.add('show');
        setTimeout(function() {
          toast.classList.remove('show');
        }, 4000);

        // 4. Trigger mailto
        setTimeout(function() {
          window.location.href = mailtoUrl;
        }, 250);
      };

      var saved = 'light';
      try { saved = localStorage.getItem('pandota_theme') || 'light'; } catch(e) {}
      window.applyPandotaTheme(saved);
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
          <li><a href="sell.html" class="nav-sell-highlight"><i class="fa-solid fa-money-bill-wave"></i> Sell to Us</a></li>
          <li><a href="index.html#contact">Contact Us</a></li>
        </ul>
      </nav>

      <div class="nav-actions">
        <button class="theme-toggle-btn" id="themeToggleBtn" onclick="togglePandotaTheme()" aria-label="Toggle Light/Dark Theme" title="Toggle Light/Dark Theme">
          <i class="fa-solid fa-moon"></i>
        </button>
        <button class="mobile-toggle" id="mobileToggle" onclick="togglePandotaMobileMenu()" aria-label="Toggle mobile menu">
          <i class="fa-solid fa-bars"></i>
        </button>
      </div>
    </div>
  </header>

  <main>
    <!-- Inventory Page Hero Header -->
    <section class="inventory-hero">
      <div class="container">
        <div class="section-title-area" style="margin-bottom: 24px;">
          <div class="pill-badge" style="margin-bottom: 14px;">
            <span class="live-pulse-dot"></span>
            <span>Live Sync with eBay Store</span>
          </div>
          <h1 class="section-heading inventory-main-heading">Complete Store Inventory (<span id="inventoryHeaderCount">$totalCount</span> Listings)</h1>
          <p class="section-desc">
            Filter by category, condition, or search below!
          </p>
        </div>

        <!-- Filter Controls Bar with Dynamic Category & Condition Pills -->
        <div class="inventory-controls-bar" style="flex-direction: column; align-items: stretch; gap: 14px;">
          
          <!-- Dynamic Category Filter Pills Bar (Threshold >= 2 items) -->
          <div class="category-filter-row" id="categoryFilterRow">
            <div class="filter-group-label"><i class="fa-solid fa-layer-group"></i> Category:</div>
$categoryPillsHtml
          </div>

          <!-- Dynamic Condition Filter Pills Bar (Never shows 0 count pills) -->
          <div class="condition-filter-row" id="conditionFilterRow">
            <div class="filter-group-label"><i class="fa-solid fa-filter"></i> Condition:</div>
$conditionPillsHtml
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
                <option value="watchers-desc">Most Watchers</option>
                <option value="views-desc">Most Viewed</option>
                <option value="watchers-asc">Fewest Watchers</option>
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
  <footer class="footer">
    <div class="container">
      <div class="footer-top-grid">
        <div class="footer-brand-col">
          <a href="index.html" class="logo-brand">
            <img src="images/panda_logo.png" alt="Pandota Logo" class="brand-panda-img">
            <span>PANDOTA</span>
          </a>
          <p class="footer-tagline">
            Specialist UK retailer of high-performance laptops, mobile workstations, and gaming rigs on eBay since 2013.
          </p>
        </div>

        <div class="footer-info-col">
          <h4>Company Details</h4>
          <ul class="footer-company-details">
            <li><i class="fa-solid fa-building"></i> <span><strong>Pandota Ltd</strong> (Registered in England &amp; Wales)</span></li>
            <li><i class="fa-solid fa-hashtag"></i> <span>Company Number: <strong>14961273</strong></span></li>
            <li><i class="fa-solid fa-location-dot"></i> <span>Registered Address: <strong>24 Groveley Lane, Birmingham, England, B31 4QH</strong></span></li>
          </ul>
        </div>

        <div class="footer-nav-col">
          <h4>Quick Links</h4>
          <ul>
            <li><a href="index.html">Home</a></li>
            <li><a href="inventory.html">All Inventory</a></li>
            <li><a href="sell.html">Sell to Us</a></li>
            <li><a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener">eBay Store</a></li>
            <li><a href="https://www.ebay.co.uk/cnt/InterMessageWithSeller?requested=geoff_lee367" target="_blank" rel="noopener">Contact via eBay</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <p>&copy; <span id="currentYear">2026</span> Pandota Ltd. All rights reserved.</p>
        <p>Official eBay Store: <a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener">geoffscuriosities</a> &bull; VAT Reg: GB 444 3804 05</p>
      </div>
    </div>
  </footer>

  <!-- Instant Filtering, Real-Time Dynamic Filter Sync & Sorting Logic -->
  <script>
  (function() {
    var BRAND_RULES = [
      { name: 'Alienware', icon: 'fa-gamepad', pattern: /\bAlienware\b/i },
      { name: 'Dell', icon: 'fa-desktop', pattern: /\b(Dell|XPS|Precision|Latitude|Inspiron)\b/i },
      { name: 'Lenovo', icon: 'fa-laptop', pattern: /\b(Lenovo|Legion|ThinkPad|LOQ|Yoga|IdeaPad)\b/i },
      { name: 'ASUS', icon: 'fa-microchip', pattern: /\b(ASUS|ROG|Zephyrus|Strix|SCAR|TUF|ZenBook|Flow|ProArt)\b/i },
      { name: 'HP', icon: 'fa-bolt', pattern: /\b(HP|Omen|Victus|ZBook|EliteBook|Envy|Pavilion|Spectre)\b/i },
      { name: 'Sony', icon: 'fa-camera', pattern: /\b(Sony|Alpha\s*A\d+|SEL\d+|ILCE)\b/i },
      { name: 'Microsoft', icon: 'fa-tablet-screen-button', pattern: /\b(Surface|Microsoft)\b/i },
      { name: 'MacBook', icon: 'fa-brands fa-apple', pattern: /\b(MacBook|Apple|iMac|Mac\s*Mini)\b/i },
      { name: 'Razer', icon: 'fa-shield-halved', pattern: /\b(Razer|Blade)\b/i },
      { name: 'MSI', icon: 'fa-dragon', pattern: /\b(MSI|Titan|Raider|Stealth|Vector|Katana|Pulse|Creator)\b/i },
      { name: 'Acer', icon: 'fa-display', pattern: /\b(Acer|Predator|Helios|Nitro|Swift|Triton)\b/i },
      { name: 'PC Specialist', icon: 'fa-gears', pattern: /\b(PC\s*Specialist|Defiance|Recoil|Elimina)\b/i },
      { name: 'Samsung', icon: 'fa-mobile-screen', pattern: /\b(Samsung|Galaxy\s*Book)\b/i },
      { name: 'Gigabyte', icon: 'fa-server', pattern: /\b(Gigabyte|AORUS|Aero)\b/i },
      { name: 'Framework', icon: 'fa-screwdriver-wrench', pattern: /\bFramework\b/i }
    ];

    function detectCardBrand(title) {
      for (var i = 0; i < BRAND_RULES.length; i++) {
        if (BRAND_RULES[i].pattern.test(title)) return BRAND_RULES[i];
      }
      return { name: 'Other', icon: 'fa-boxes-stacked' };
    }

    function initInventoryControls() {
      var grid = document.getElementById('inventoryGrid');
      var searchInput = document.getElementById('inventorySearchInput');
      var sortSelect = document.getElementById('inventorySortSelect');
      var categoryRow = document.getElementById('categoryFilterRow');
      var conditionRow = document.getElementById('conditionFilterRow');
      if (!grid) return;

      var activeCategory = 'all';
      var activeCondition = 'all';

      // Dynamically rebuild category & condition pills from live cards in real time
      function refreshLiveFilterPills() {
        var cards = Array.from(grid.querySelectorAll('.inventory-card'));
        if (!cards.length) return;

        var brandCounts = {};
        var condCounts = { 'New': 0, 'Opened - never used': 0, 'Used': 0, 'For parts or not working': 0, 'coupon': 0 };

        cards.forEach(function(card) {
          var title = (card.querySelector('.inv-card-title')?.textContent || '').trim();
          var detected = detectCardBrand(title);
          var bName = detected.name;
          brandCounts[bName] = (brandCounts[bName] || 0) + 1;

          var cond = (card.getAttribute('data-condition') || '').trim();
          if (condCounts.hasOwnProperty(cond)) condCounts[cond]++;
          if (card.getAttribute('data-coupon') === 'true') condCounts['coupon']++;
        });

        // Determine qualifying categories (>= 2 listings), consolidate others (< 2) into 'Other'
        var qualifying = [];
        var otherCount = 0;

        BRAND_RULES.forEach(function(rule) {
          var count = brandCounts[rule.name] || 0;
          if (count >= 2) {
            qualifying.push({ name: rule.name, icon: rule.icon, count: count });
          } else if (count > 0) {
            otherCount += count;
          }
        });
        if (brandCounts['Other']) otherCount += brandCounts['Other'];

        // Sort qualifying categories by count descending
        qualifying.sort(function(a, b) { return b.count - a.count; });

        // Update card data-category in real time based on active qualifying categories
        cards.forEach(function(card) {
          var title = (card.querySelector('.inv-card-title')?.textContent || '').trim();
          var detected = detectCardBrand(title);
          var isQual = qualifying.some(function(q) { return q.name.toLowerCase() === detected.name.toLowerCase(); });
          card.setAttribute('data-category', isQual ? detected.name : 'Other');
        });

        // Render Category Pills HTML
        if (categoryRow) {
          var catHtml = '<div class="filter-group-label"><i class="fa-solid fa-layer-group"></i> Category:</div>';
          catHtml += '<button class="category-pill-btn' + (activeCategory === 'all' ? ' active' : '') + '" data-category="all"><i class="fa-solid fa-border-all"></i> All (' + cards.length + ')</button>';
          
          qualifying.forEach(function(q) {
            var isActive = (activeCategory.toLowerCase() === q.name.toLowerCase());
            catHtml += '<button class="category-pill-btn' + (isActive ? ' active' : '') + '" data-category="' + q.name + '"><i class="fa-solid ' + q.icon + '"></i> ' + q.name + ' (' + q.count + ')</button>';
          });

          if (otherCount > 0) {
            var isOtherActive = (activeCategory.toLowerCase() === 'other');
            catHtml += '<button class="category-pill-btn' + (isOtherActive ? ' active' : '') + '" data-category="Other"><i class="fa-solid fa-boxes-stacked"></i> Other (' + otherCount + ')</button>';
          }

          categoryRow.innerHTML = catHtml;
          bindCategoryListeners();
        }

        // Render Condition Pills HTML (Never render 0 count pills)
        if (conditionRow) {
          var condHtml = '<div class="filter-group-label"><i class="fa-solid fa-filter"></i> Condition:</div>';
          condHtml += '<button class="condition-pill-btn' + (activeCondition === 'all' ? ' active' : '') + '" data-condition="all"><i class="fa-solid fa-border-all"></i> All Conditions (' + cards.length + ')</button>';
          
          if (condCounts['New'] > 0) {
            condHtml += '<button class="condition-pill-btn' + (activeCondition === 'New' ? ' active' : '') + '" data-condition="New"><i class="fa-solid fa-sparkles"></i> New (' + condCounts['New'] + ')</button>';
          }
          if (condCounts['Opened - never used'] > 0) {
            condHtml += '<button class="condition-pill-btn' + (activeCondition === 'Opened - never used' ? ' active' : '') + '" data-condition="Opened - never used"><i class="fa-solid fa-box-open"></i> Opened - never used (' + condCounts['Opened - never used'] + ')</button>';
          }
          if (condCounts['Used'] > 0) {
            condHtml += '<button class="condition-pill-btn' + (activeCondition === 'Used' ? ' active' : '') + '" data-condition="Used"><i class="fa-solid fa-rotate-left"></i> Used (' + condCounts['Used'] + ')</button>';
          }
          if (condCounts['For parts or not working'] > 0) {
            condHtml += '<button class="condition-pill-btn' + (activeCondition === 'For parts or not working' ? ' active' : '') + '" data-condition="For parts or not working"><i class="fa-solid fa-wrench"></i> For Parts (' + condCounts['For parts or not working'] + ')</button>';
          }
          if (condCounts['coupon'] > 0) {
            condHtml += '<button class="condition-pill-btn coupon-pill-btn' + (activeCondition === 'coupon' ? ' active' : '') + '" data-condition="coupon"><i class="fa-solid fa-tag"></i> eBay Coupons (' + condCounts['coupon'] + ')</button>';
          }

          conditionRow.innerHTML = condHtml;
          bindConditionListeners();
        }
      }

      function bindCategoryListeners() {
        if (!categoryRow) return;
        categoryRow.querySelectorAll('.category-pill-btn').forEach(function(btn) {
          btn.onclick = function(e) {
            if (e) e.preventDefault();
            categoryRow.querySelectorAll('.category-pill-btn').forEach(function(b) { b.classList.remove('active'); });
            btn.classList.add('active');
            activeCategory = btn.getAttribute('data-category') || 'all';
            filterGrid();
          };
        });
      }

      function bindConditionListeners() {
        if (!conditionRow) return;
        conditionRow.querySelectorAll('.condition-pill-btn').forEach(function(btn) {
          btn.onclick = function(e) {
            if (e) e.preventDefault();
            conditionRow.querySelectorAll('.condition-pill-btn').forEach(function(b) { b.classList.remove('active'); });
            btn.classList.add('active');
            activeCondition = btn.getAttribute('data-condition') || 'all';
            filterGrid();
          };
        });
      }

      function getCardPrice(card) {
        var attr = card.getAttribute('data-price');
        if (attr && !isNaN(parseFloat(attr)) && parseFloat(attr) > 0) return parseFloat(attr);
        var priceEl = card.querySelector('.inv-card-price');
        if (priceEl) {
          var p = parseFloat(priceEl.textContent.replace(/[^\d.]/g, ''));
          if (!isNaN(p)) return p;
        }
        return 0;
      }

      function getCardWatchers(card) {
        var attr = card.getAttribute('data-watchers');
        if (attr && !isNaN(parseInt(attr, 10))) return parseInt(attr, 10);
        return 0;
      }

      function getCardViews(card) {
        var attr = card.getAttribute('data-views');
        if (attr && !isNaN(parseInt(attr, 10))) return parseInt(attr, 10);
        return 0;
      }

      function sortGrid(mode) {
        var cards = Array.from(grid.querySelectorAll('.inventory-card'));
        cards.sort(function(a, b) {
          if (mode === 'watchers-desc') {
            var wDiff = getCardWatchers(b) - getCardWatchers(a);
            return wDiff !== 0 ? wDiff : getCardPrice(b) - getCardPrice(a);
          }
          if (mode === 'watchers-asc') {
            var wDiff = getCardWatchers(a) - getCardWatchers(b);
            return wDiff !== 0 ? wDiff : getCardPrice(a) - getCardPrice(b);
          }
          if (mode === 'views-desc') {
            var vDiff = getCardViews(b) - getCardViews(a);
            return vDiff !== 0 ? vDiff : getCardPrice(b) - getCardPrice(a);
          }
          var pA = getCardPrice(a);
          var pB = getCardPrice(b);
          return mode === 'price-asc' ? (pA - pB) : (pB - pA);
        });

        cards.forEach(function(card) {
          grid.appendChild(card);
        });
      }

      function filterGrid() {
        var query = searchInput ? searchInput.value.toLowerCase().trim() : '';
        var queryWords = query ? query.split(/\s+/).filter(function(w) { return w.length > 0; }) : [];
        var cards = grid.querySelectorAll('.inventory-card');
        var visible = 0;
        var total = cards.length;

        cards.forEach(function(card) {
          var title = (card.querySelector('.inv-card-title')?.textContent || '').toLowerCase();
          var features = (card.querySelector('.inv-card-features')?.textContent || '').toLowerCase();
          var cond = (card.getAttribute('data-condition') || '').trim();
          var cat = (card.getAttribute('data-category') || '').trim();
          var combinedText = (title + ' ' + features + ' ' + cond + ' ' + cat).toLowerCase();

          var matchesSearch = queryWords.length === 0 || queryWords.every(function(word) {
            return combinedText.indexOf(word) !== -1;
          });
          var matchesCategory = (activeCategory === 'all') || (cat.toLowerCase() === activeCategory.toLowerCase());
          var matchesCond = true;

          if (activeCondition !== 'all') {
            if (activeCondition === 'coupon') {
              matchesCond = (card.getAttribute('data-coupon') === 'true');
            } else if (activeCondition === 'New') {
              matchesCond = (cond === 'New');
            } else if (activeCondition === 'Opened - never used') {
              matchesCond = (cond === 'Opened - never used');
            } else if (activeCondition === 'Used') {
              matchesCond = (cond === 'Used');
            } else if (activeCondition === 'For parts or not working') {
              matchesCond = (cond === 'For parts or not working');
            } else {
              matchesCond = cond.toLowerCase() === activeCondition.toLowerCase();
            }
          }

          if (matchesSearch && matchesCond && matchesCategory) {
            card.style.setProperty('display', 'flex', 'important');
            card.style.setProperty('opacity', '1', 'important');
            visible++;
          } else {
            card.style.setProperty('display', 'none', 'important');
          }
        });

        var visibleSpan = document.getElementById('visibleCount');
        if (visibleSpan) visibleSpan.textContent = visible;

        var subtext = document.getElementById('filteredResultsCount');
        if (subtext) {
          var activeFilters = [];
          if (activeCategory !== 'all') activeFilters.push('Category: ' + activeCategory);
          if (activeCondition !== 'all') activeFilters.push('Condition: ' + activeCondition);
          if (query) activeFilters.push('Search: "' + query + '"');

          if (activeFilters.length > 0) {
            subtext.innerHTML = '<i class="fa-solid fa-filter"></i> Showing <strong>' + visible + '</strong> of <strong>' + total + '</strong> active listings (' + activeFilters.join(' &bull; ') + ')';
          } else {
            subtext.innerHTML = 'Showing <span id="visibleCount" style="font-weight: 700; color: var(--text-main);">' + total + '</span> of ' + total + ' items in stock';
          }
        }
      }

      refreshLiveFilterPills();

      if (searchInput) {
        searchInput.oninput = filterGrid;
        var params = new URLSearchParams(window.location.search);
        var q = params.get('q');
        if (q) {
          searchInput.value = q;
        }
      }

      if (sortSelect) {
        sortSelect.onchange = function() {
          sortGrid(sortSelect.value);
        };
        sortGrid(sortSelect.value || 'price-desc');
      }

      // Standalone Theme Toggle Helper
      if (typeof window.applyPandotaTheme === 'function') {
        var currentSaved = 'dark';
        try { currentSaved = localStorage.getItem('pandota_theme') || 'dark'; } catch(e) {}
        window.applyPandotaTheme(currentSaved);
      }

      filterGrid();
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initInventoryControls);
    } else {
      initInventoryControls();
    }
  })();
  </script>
</body>
</html>
"@

[System.IO.File]::WriteAllText("$pwd\inventory.html", $fullHtml, [System.Text.Encoding]::UTF8)

# Update count references in index.html safely
if (Test-Path "index.html") {
    $indexHtml = Get-Content "index.html" -Raw -Encoding utf8
    $indexHtml = $indexHtml -replace 'View All \(\d+\)', "View All ($totalCount)"
    $indexHtml = $indexHtml -replace '\b\d+\+\s*Laptops\b', "$totalCount+ Laptops"
    [System.IO.File]::WriteAllText("$pwd\index.html", $indexHtml, [System.Text.Encoding]::UTF8)
}

Write-Host "Successfully built inventory.html and updated index.html with exactly $totalCount active live listings and dynamic threshold-based categories!"
