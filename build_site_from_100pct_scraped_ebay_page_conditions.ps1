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

foreach ($it in $items) {
    $itemId = $it.ItemId
    $titleRaw = $it.Title
    $title = [System.Net.WebUtility]::HtmlEncode($titleRaw)
    $price = $it.Price
    $numPrice = ($price -replace '[^\d.]', '').Trim()
    if (-not $numPrice) { $numPrice = "0" }
    $url = $it.Url
    $img = $it.Img

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

    # Build condition badge matching official eBay status
    $pills = @()
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
    
    $pillsHtml = $pills -join "`n                "
    $cdnImg = if ($cdnMap.ContainsKey($itemId)) { $cdnMap[$itemId] } else { $img }

    # Use 100% exact Seller Hub Watchers directly from item
    $watchCount = if ($it.PSObject.Properties['Watchers'] -and $it.Watchers -ne $null) {
        [int]$it.Watchers
    } else {
        0
    }

    $watchBadgeHtml = if ($watchCount -gt 0) {
        @"
                <div class="inv-card-watcher-badge" title="$watchCount buyers watching on eBay">
                  <i class="fa-solid fa-heart" style="color: #ef4444;"></i>
                  <span class="watcher-count" data-item-id="$itemId">$watchCount watching</span>
                </div>
"@
    } else {
        @"
                <div class="inv-card-watcher-badge" title="Active listing on eBay">
                  <i class="fa-regular fa-heart" style="color: #94a3b8;"></i>
                  <span class="watcher-count" data-item-id="$itemId">Active</span>
                </div>
"@
    }

    $cardsHtml += @"
          <!-- Item $itemId -->
          <div class="inventory-card" data-item-id="$itemId" data-price="$numPrice" data-condition="$cond">
            <div class="inv-card-img-wrap">
              <img src="$cdnImg" alt="$title" loading="lazy" referrerpolicy="no-referrer">
            </div>
            <div class="inv-card-body">
              <div class="inv-card-price-row">
                <div class="inv-card-price">$price</div>
$watchBadgeHtml
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
  <link rel="canonical" href="https://pandota.co.uk/inventory.html">

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
        "@type": "WebSite",
        "@id": "https://pandota.co.uk/#website",
        "url": "https://pandota.co.uk",
        "name": "Pandota",
        "publisher": { "@id": "https://pandota.co.uk/#organization" }
      }
    ]
  }
  </script>

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
        
        var btns = document.querySelectorAll('#themeToggleBtn, .theme-toggle-btn');
        btns.forEach(function(btn) {
          btn.innerHTML = theme === 'dark' ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
          btn.setAttribute('title', theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode');
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
          <li><a href="index.html#sell">Sell to Us</a></li>
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
              <i class="fa-solid fa-sparkles"></i> New ($countNew)
            </button>
            <button class="condition-pill-btn" data-condition="Opened - never used">
              <i class="fa-solid fa-box-open"></i> Opened - never used ($countOpened)
            </button>
            <button class="condition-pill-btn" data-condition="Used">
              <i class="fa-solid fa-rotate-left"></i> Used ($countUsed)
            </button>
            <button class="condition-pill-btn" data-condition="For parts or not working">
              <i class="fa-solid fa-wrench"></i> For Parts ($countParts)
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
            <li><a href="index.html#sell">Sell to Us</a></li>
            <li><a href="https://www.ebay.co.uk/str/geoffscuriosities" target="_blank" rel="noopener">eBay Store</a></li>
            <li><a href="https://www.ebay.co.uk/cnt/InterMessageWithSeller?requested=geoff_lee367" target="_blank" rel="noopener">Contact via eBay</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom" style="justify-content: center; text-align: center;">
        <p>&copy; <span id="currentYear">2026</span> Pandota Ltd. All rights reserved.</p>
      </div>
    </div>
  </footer>

  <script src="script.js?v=2.0"></script>
  
  <script>
  (function() {
    function initInventoryControls() {
      var searchInput = document.getElementById('inventorySearchInput');
      var sortSelect = document.getElementById('inventorySortSelect');
      var grid = document.getElementById('inventoryGrid');
      if (!grid) return;

      var activeCondition = 'all';

      function getCardPrice(card) {
        var attr = card.getAttribute('data-price');
        if (attr && !isNaN(parseFloat(attr)) && parseFloat(attr) > 0) {
          return parseFloat(attr);
        }
        var priceEl = card.querySelector('.inv-card-price');
        if (priceEl) {
          var parsed = parseFloat(priceEl.textContent.replace(/[^\d.]/g, ''));
          if (!isNaN(parsed)) return parsed;
        }
        return 0;
      }

      function sortGrid(mode) {
        var cards = Array.from(grid.querySelectorAll('.inventory-card'));
        cards.sort(function(a, b) {
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
        var cards = grid.querySelectorAll('.inventory-card');
        var visible = 0;
        var total = cards.length;

        cards.forEach(function(card) {
          var title = (card.querySelector('.inv-card-title')?.textContent || '').toLowerCase();
          var features = (card.querySelector('.inv-card-features')?.textContent || '').toLowerCase();
          var cond = (card.getAttribute('data-condition') || '').trim();

          var matchesSearch = !query || title.indexOf(query) !== -1 || features.indexOf(query) !== -1;
          var matchesCond = true;

          if (activeCondition !== 'all') {
            if (activeCondition === 'New') {
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

          if (matchesSearch && matchesCond) {
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
          if (activeCondition !== 'all' || query) {
            subtext.innerHTML = '<i class="fa-solid fa-filter"></i> Showing <strong>' + visible + '</strong> of <strong>' + total + '</strong> active listings';
          } else {
            subtext.innerHTML = 'Showing <span id="visibleCount" style="font-weight: 700; color: var(--text-main);">' + total + '</span> of ' + total + ' items in stock';
          }
        }
      }

      // Direct onclick binding for condition buttons
      document.querySelectorAll('.condition-pill-btn').forEach(function(btn) {
        btn.onclick = function(e) {
          if (e) e.preventDefault();
          document.querySelectorAll('.condition-pill-btn').forEach(function(b) { b.classList.remove('active'); });
          btn.classList.add('active');
          activeCondition = btn.getAttribute('data-condition') || 'all';
          filterGrid();
        };
      });

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

# Update count references in index.html
if (Test-Path "index.html") {
    $indexHtml = Get-Content "index.html" -Raw -Encoding utf8
    $indexHtml = $indexHtml -replace 'View All \(\d+\)', "View All ($totalCount)"
    $indexHtml = $indexHtml -replace '\b\d+\+\s*Laptops\b', "$totalCount+ Laptops"
    [System.IO.File]::WriteAllText("$pwd\index.html", $indexHtml, [System.Text.Encoding]::UTF8)
}

Write-Host "Successfully built inventory.html and updated index.html with exactly $totalCount active live listings!"

# Automatically copy all updated files to Pandota Website repo if folder exists
$targetRepo = "C:\Users\User\Desktop\PANDOTA ACOUNTS\Pandota Website"
if (Test-Path $targetRepo) {
    Copy-Item -Path "$pwd\style.css" -Destination "$targetRepo\style.css" -Force
    Copy-Item -Path "$pwd\index.html" -Destination "$targetRepo\index.html" -Force
    Copy-Item -Path "$pwd\inventory.html" -Destination "$targetRepo\inventory.html" -Force
    Copy-Item -Path "$pwd\script.js" -Destination "$targetRepo\script.js" -Force
    Copy-Item -Path "$pwd\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Destination "$targetRepo\build_site_from_100pct_scraped_ebay_page_conditions.ps1" -Force
    if (Test-Path "$pwd\sync_now.ps1") { Copy-Item -Path "$pwd\sync_now.ps1" -Destination "$targetRepo\sync_now.ps1" -Force }
    if (Test-Path "$pwd\official_scraped_ebay_conditions.json") { Copy-Item -Path "$pwd\official_scraped_ebay_conditions.json" -Destination "$targetRepo\official_scraped_ebay_conditions.json" -Force }
    if (Test-Path "$pwd\all_82_with_exact_scraped_prices.json") { Copy-Item -Path "$pwd\all_82_with_exact_scraped_prices.json" -Destination "$targetRepo\all_82_with_exact_scraped_prices.json" -Force }
    if (Test-Path "$pwd\all_store_listings.json") { Copy-Item -Path "$pwd\all_store_listings.json" -Destination "$targetRepo\all_store_listings.json" -Force }
    Write-Host "Automatically synchronized all updated files to Pandota Website repository!"
}
