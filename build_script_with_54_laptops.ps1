$remaining = Get-Content -Path "remaining_laptops.json" -Raw | ConvertFrom-Json

Write-Host "Formatting "$remaining.Count" laptops for script.js..."

$itemsCode = @()

foreach ($item in $remaining) {
    $title = $item.Title -replace '"', '\"'
    $price = $item.Price
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
    
    $itemsCode += @"
        {
          id: "$($item.ItemId)",
          title: "$title",
          price: "$price",
          numericPrice: $numPrice,
          img: "$($item.Image)",
          link: "https://www.ebay.co.uk/itm/$($item.ItemId)",
          badge: "DPD Next-Day Delivery",
          cpu: "$cpu",
          gpu: "$gpu"
        }
"@
}

$jsonArrayString = "[" + ($itemsCode -join ",") + "]"

$scriptContent = @"
// Pandota Ltd - Interactive Landing Page & Live Store Data Sync Script

document.addEventListener('DOMContentLoaded', () => {
  // 1. Mobile Menu Toggle
  const mobileToggle = document.getElementById('mobileToggle');
  const navLinks = document.getElementById('navLinks');

  if (mobileToggle && navLinks) {
    mobileToggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
      const icon = mobileToggle.querySelector('i');
      if (icon) {
        if (navLinks.classList.contains('active')) {
          icon.className = 'fa-solid fa-xmark';
        } else {
          icon.className = 'fa-solid fa-bars';
        }
      }
    });

    // Close menu when clicking link
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        const icon = mobileToggle.querySelector('i');
        if (icon) icon.className = 'fa-solid fa-bars';
      });
    });
  }

  // 2. FAQ Accordion Logic
  const faqItems = document.querySelectorAll('.faq-item');

  faqItems.forEach(item => {
    const questionBtn = item.querySelector('.faq-question');
    questionBtn.addEventListener('click', () => {
      const isActive = item.classList.contains('active');

      // Close all active items
      faqItems.forEach(otherItem => {
        otherItem.classList.remove('active');
      });

      // Toggle clicked item
      if (!isActive) {
        item.classList.add('active');
      }
    });
  });

  // 3. Pandota Live eBay Store Search Form
  const searchForm = document.getElementById('ebaySearchForm');
  const searchInput = document.getElementById('ebaySearchInput');

  if (searchForm && searchInput) {
    searchForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const query = searchInput.value.trim();
      const baseUrl = 'https://www.ebay.co.uk/str/geoffscuriosities';
      
      if (query) {
        window.open(`\${baseUrl}?_nkw=\${encodeURIComponent(query)}`, '_blank');
      } else {
        window.open(baseUrl, '_blank');
      }
    });
  }

  // 4. Dynamic Year in Footer
  const currentYearSpan = document.getElementById('currentYear');
  if (currentYearSpan) {
    currentYearSpan.textContent = new Date().getFullYear();
  }

  // 5. Live eBay Data Sync for Stats
  fetchEbayLiveStats();

  // 6. Setup Inventory Page Controls
  setupInventoryPageControls();

  // 7. Scroll Reveal & Infinite Scroll Observer
  setupScrollRevealAndInfiniteScroll();
});

// Live Fetch eBay Feedback, Items Sold, and Followers
async function fetchEbayLiveStats() {
  const storeUrl = 'https://www.ebay.co.uk/str/geoffscuriosities';
  const proxyUrl = `https://api.allorigins.win/get?url=\${encodeURIComponent(storeUrl)}`;

  try {
    const response = await fetch(proxyUrl);
    if (!response.ok) return;

    const data = await response.json();
    if (!data || !data.contents) return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(data.contents, 'text/html');

    const statsContainer = doc.querySelector('.str-seller-card__store-stats-content') || doc.body;
    const statsText = statsContainer.textContent || doc.body.textContent;

    // Extract Feedback %
    const feedbackMatch = statsText.match(/(\d+(?:\.\d+)?%)\s*positive/i);
    if (feedbackMatch && feedbackMatch[1]) {
      const feedbackEl = document.getElementById('stat-feedback');
      if (feedbackEl) feedbackEl.textContent = feedbackMatch[1];
    }

    // Extract Items Sold
    const itemsSoldMatch = statsText.match(/(\d+(?:,\d+)*(?:\.\d+)?[KkM]?\+?)\s*items sold/i);
    if (itemsSoldMatch && itemsSoldMatch[1]) {
      const itemsEl = document.getElementById('stat-items-sold');
      if (itemsEl) {
        const val = itemsSoldMatch[1];
        itemsEl.textContent = val.includes('+') ? val : `\${val}+`;
      }
    }

    // Extract Followers
    const followersMatch = statsText.match(/(\d+(?:\.\d+)?[KkM]?\+?)\s*followers/i);
    if (followersMatch && followersMatch[1]) {
      const followersEl = document.getElementById('stat-followers');
      if (followersEl) {
        const val = followersMatch[1];
        followersEl.textContent = val.includes('+') ? val : `\${val}+`;
      }
    }
  } catch (err) {
    console.log('Using cached stats from eBay store:', err);
  }
}

// Controls for inventory.html filtering & sorting
function setupInventoryPageControls() {
  const searchInput = document.getElementById('inventorySearchInput');
  const sortSelect = document.getElementById('inventorySortSelect');
  const grid = document.getElementById('fullInventoryGrid');

  if (!grid) return;

  function filterCards() {
    const searchTerm = searchInput ? searchInput.value.toLowerCase().trim() : '';
    const cards = grid.querySelectorAll('.inventory-card');

    cards.forEach(card => {
      const title = card.querySelector('.inv-card-title').textContent.toLowerCase();
      const matchesSearch = !searchTerm || title.includes(searchTerm);

      if (matchesSearch) {
        card.style.display = 'flex';
        card.classList.add('is-visible');
      } else {
        card.style.display = 'none';
      }
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', filterCards);
  }

  if (sortSelect) {
    sortSelect.addEventListener('change', () => {
      const cardsArray = Array.from(grid.querySelectorAll('.inventory-card'));
      const mode = sortSelect.value;

      if (mode === 'price-asc') {
        cardsArray.sort((a, b) => parseFloat(a.getAttribute('data-price') || 0) - parseFloat(b.getAttribute('data-price') || 0));
      } else if (mode === 'price-desc') {
        cardsArray.sort((a, b) => parseFloat(b.getAttribute('data-price') || 0) - parseFloat(a.getAttribute('data-price') || 0));
      }

      cardsArray.forEach(card => grid.appendChild(card));
    });
  }
}

// Scroll Reveal & Infinite Scroll Loading for ALL 72 Store Laptops
function setupScrollRevealAndInfiniteScroll() {
  const cards = document.querySelectorAll('.reveal-on-scroll');
  const sentinel = document.getElementById('inventoryScrollSentinel');
  const grid = document.getElementById('fullInventoryGrid');

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px 50px 0px' });

    cards.forEach(card => observer.observe(card));

    if (sentinel && grid) {
      let currentIndex = 0;
      const batchSize = 12;
      const extraItems = $jsonArrayString;

      const sentinelObserver = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && currentIndex < extraItems.length) {
          const nextBatch = extraItems.slice(currentIndex, currentIndex + batchSize);
          currentIndex += batchSize;
          
          setTimeout(() => {
            let appendedAny = false;
            nextBatch.forEach(item => {
              const existingLink = grid.querySelector(`a[href="\${item.link}"]`);
              if (!existingLink) {
                appendedAny = true;
                const newCard = document.createElement('div');
                newCard.className = 'inventory-card reveal-on-scroll';
                newCard.setAttribute('data-price', item.numericPrice);
                newCard.innerHTML = `
                  <div class="inv-card-badge">\${item.badge}</div>
                  <div class="inv-card-img-wrap">
                    <img src="\${item.img}" alt="\${item.title}">
                  </div>
                  <div class="inv-card-body">
                    <div class="inv-card-price">\${item.price}</div>
                    <h3 class="inv-card-title">\${item.title}</h3>
                    <div class="inv-card-features">
                      <span><i class="fa-solid fa-microchip"></i> \${item.cpu}</span>
                      <span><i class="fa-solid fa-compact-disc"></i> \${item.gpu}</span>
                    </div>
                    <a href="\${item.link}" target="_blank" rel="noopener" class="btn btn-ebay" style="width: 100%; margin-top: 12px;">
                      <span>View Listing on eBay</span>
                      <i class="fa-solid fa-arrow-up-right-from-square"></i>
                    </a>
                  </div>
                `;
                grid.appendChild(newCard);
                observer.observe(newCard);
                setTimeout(() => newCard.classList.add('is-visible'), 100);
              }
            });

            if (currentIndex >= extraItems.length || !appendedAny) {
              sentinel.style.display = 'none';
            }
          }, 300);
        }
      }, { threshold: 0.2 });

      sentinelObserver.observe(sentinel);
    }
  } else {
    cards.forEach(card => card.classList.add('is-visible'));
    if (sentinel) sentinel.style.display = 'none';
  }
}
"@

$scriptContent | Out-File -FilePath "script.js" -Encoding utf8
Write-Host "Updated script.js with all 54 remaining store laptops."
