// Pandota Ltd - Interactive Landing Page & Live Store Data Sync Script

// 1. Instant Theme Init (Runs immediately to prevent theme flash)
window.applyPandotaTheme = function(theme) {
  if (theme === 'dark') {
    document.documentElement.removeAttribute('data-theme');
    document.documentElement.setAttribute('data-theme', 'dark');
  } else {
    document.documentElement.setAttribute('data-theme', 'light');
  }
  try {
    localStorage.setItem('pandota_theme', theme);
  } catch(e) {}
  
  document.querySelectorAll('#themeToggleBtn, .theme-toggle-btn').forEach(btn => {
    btn.innerHTML = theme === 'dark' ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
    btn.setAttribute('title', theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode');
  });
};

window.togglePandotaTheme = function() {
  const current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
  const next = current === 'dark' ? 'light' : 'dark';
  window.applyPandotaTheme(next);
};

// Immediately apply saved theme on load
(function() {
  try {
    const saved = localStorage.getItem('pandota_theme') || 'light';
    window.applyPandotaTheme(saved);
  } catch(e) {
    window.applyPandotaTheme('light');
  }
})();

function setupThemeToggle() {
  try {
    const saved = localStorage.getItem('pandota_theme') || 'light';
    window.applyPandotaTheme(saved);
  } catch(e) {}
}

document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize Theme Toggle Buttons
  try { setupThemeToggle(); } catch(e) { console.error('Theme toggle error:', e); }

  // 2. Mobile Menu Toggle
  try {
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
  } catch(e) { console.error('Mobile menu error:', e); }

  // 3. FAQ Accordion Logic
  try {
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
      const questionBtn = item.querySelector('.faq-question');
      if (questionBtn) {
        questionBtn.addEventListener('click', () => {
          const isActive = item.classList.contains('active');
          faqItems.forEach(otherItem => otherItem.classList.remove('active'));
          if (!isActive) item.classList.add('active');
        });
      }
    });
  } catch(e) { console.error('FAQ error:', e); }

  // 4. Local Store Search Form (Redirects to inventory.html?q=SearchQuery)
  try {
    const searchForm = document.getElementById('ebaySearchForm');
    const searchInput = document.getElementById('ebaySearchInput');

    if (searchForm && searchInput) {
      searchForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const query = searchInput.value.trim();
        if (query) {
          window.location.href = `inventory.html?q=${encodeURIComponent(query)}`;
        } else {
          window.location.href = 'inventory.html';
        }
      });
    }
  } catch(e) { console.error('Search form error:', e); }

  // 5. Dynamic Year in Footer
  try {
    const currentYearSpan = document.getElementById('currentYear');
    if (currentYearSpan) {
      currentYearSpan.textContent = new Date().getFullYear();
    }
  } catch(e) {}

  // 6. Make all inventory cards visible initially
  try { makeAllCardsVisible(); } catch(e) {}

  // 7. Setup Inventory Page Controls
  try { setupInventoryPageControls(); } catch(e) { console.error('Inventory controls error:', e); }

  // 8. Setup Hero Stock Viewing Window Carousel
  try { setupHeroStockCarousel(); } catch(e) {}

  // 9. Live-updating Search Prompt Examples
  try { setupLiveSearchPlaceholder(); } catch(e) {}

  // 10. Live eBay Data Sync for Stats & New Listings
  try { fetchEbayLiveStats(); } catch(e) {}
  try { syncLiveEbayInventory(); } catch(e) {}

  // 11. Live Sync with eBay Feedback Profile
  try { syncLiveEbayFeedback(); } catch(e) {}

  // 12. Live In-Browser Watcher Counter Fetcher
  try { setupLiveWatcherFetcher(); } catch(e) {}
});

// Set search input placeholder based strictly on active in-stock eBay store listings (No word rotation)
function setupLiveSearchPlaceholder() {
  const inputs = [
    document.getElementById('ebaySearchInput'),
    document.getElementById('inventorySearchInput')
  ].filter(Boolean);

  if (inputs.length === 0) return;

  // Extract real active in-stock item brands/models directly from loaded grid cards
  const gridCards = document.querySelectorAll('.inventory-card .inv-card-title');
  let exampleTerms = ["Lenovo Legion", "Alienware 18", "HP Omen", "ASUS ROG", "RTX 5080"];

  if (gridCards.length > 0) {
    const extracted = [];
    gridCards.forEach(card => {
      const txt = card.textContent;
      if (txt.match(/Legion|Alienware|Omen|Zephyrus|Surface|Sony|Precision|Predator|MacBook/i)) {
        const match = txt.match(/(Legion Pro \d+|Legion Go \d+|Alienware \d+|HP Omen \d+|Zephyrus G\d+|Surface Pro \d+|Sony Alpha [^\s]+|Precision \d+)/i);
        if (match && !extracted.includes(match[1])) {
          extracted.push(match[1]);
        }
      }
    });

    if (extracted.length >= 3) {
      exampleTerms = extracted.slice(0, 4);
    }
  }

  const promptText = `e.g. ${exampleTerms.join(', ')}...`;

  inputs.forEach(input => {
    input.setAttribute('placeholder', promptText);
  });
}

// Interactive Hero Stock Carousel Navigation (Auto-Updating Live eBay Sync)
function setupHeroStockCarousel() {
  const prevBtn = document.getElementById('heroPrevBtn');
  const nextBtn = document.getElementById('heroNextBtn');
  const counterEl = document.getElementById('heroCardCounter');
  
  const imgEl = document.getElementById('heroStockImg');
  const titleEl = document.getElementById('heroStockTitle');
  const priceEl = document.getElementById('heroStockPrice');
  const linkEl = document.getElementById('heroStockLink');
  const container = document.getElementById('heroLiveStockContainer');

  if (!container) return;

  // Active flagship listings with direct high-speed eBay CDN images, watchers, and views
  let liveListings = [
    {
      title: "NEW Lenovo Legion 9 18\" Ultra 9 275HX 64GB 2TB RTX 5090 UHD+ 4K 240Hz Laptop",
      price: "£3,799.00",
      img: "https://i.ebayimg.com/images/g/CXoAAeSw-MdqfbfC/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267755998578",
      watchers: 6,
      views: 0
    },
    {
      title: "Alienware 18 Area-51 Ultra 9 275HX RTX 5080 32GB 2TB QHD+ 300Hz Gaming Laptop",
      price: "£2,599.00",
      img: "https://i.ebayimg.com/images/g/IMQAAeSwqhxqRVu-/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267745470208",
      watchers: 44,
      views: 729
    },
    {
      title: "NEW HP Omen MAX 16 Ultra 9 275HX RTX 5090 64GB 2TB QHD 240Hz OLED Gaming Laptop",
      price: "£2,899.00",
      img: "https://i.ebayimg.com/images/g/2HwAAeSwSKxqfZrP/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267755930402",
      watchers: 8,
      views: 0
    },
    {
      title: "NEW Lenovo Legion Pro 7i U9 275HX RTX 5080 32GB 2TB 240Hz OLED Laptop W11Pro WTY",
      price: "£2,599.00",
      img: "https://i.ebayimg.com/images/g/HlsAAeSwdh5qezif/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267753890742",
      watchers: 12,
      views: 284
    },
    {
      title: "NEW ASUS ROG Zephyrus G14 Ryzen AI 9 HX 370 32GB 2TB RTX 5080 OLED 120Hz Laptop",
      price: "£2,699.00",
      img: "https://i.ebayimg.com/images/g/nhAAAeSwYexqVg10/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267727321251",
      watchers: 45,
      views: 1968
    },
    {
      title: "NEW Lenovo Legion Go 2 - Z2 Extreme 32GB 1TB OLED 144Hz Portable Mini PC Console",
      price: "£1,099.00",
      img: "https://i.ebayimg.com/images/g/OPEAAeSwiSdqGr2r/s-l500.jpg",
      url: "https://www.ebay.co.uk/itm/267727293251",
      watchers: 24,
      views: 890
    },
    {
      title: "Razer Blade 16 i9 13950HX RTX 4080 32GB 1TB QHD+ 240Hz Laptop",
      price: "£949.00",
      img: "https://i.ebayimg.com/images/g/vCIAAeSwbXZqT130/s-l500.webp",
      url: "https://www.ebay.co.uk/itm/267713401569",
      watchers: 82,
      views: 2411
    }
  ];

  let currentIndex = 0;
  let autoCycleTimer = null;

  function renderHeroItem(idx) {
    if (!liveListings || liveListings.length === 0) return;
    const item = liveListings[idx];
    if (!item) return;

    if (imgEl) {
      imgEl.src = item.img;
      imgEl.alt = item.title;
    }
    if (titleEl) titleEl.textContent = item.title;
    if (priceEl) priceEl.textContent = item.price;
    if (linkEl) linkEl.href = item.url;
    if (counterEl) counterEl.textContent = `${idx + 1} / ${liveListings.length}`;

    // Watchers Overlay Badge (Top Right of Photo)
    const heroWatcherEl = document.getElementById('heroStockWatcher');
    const heroWatcherTextEl = document.getElementById('heroStockWatcherText');
    if (heroWatcherEl && heroWatcherTextEl) {
      const wCount = typeof item.watchers === 'number' ? item.watchers : 0;
      if (wCount > 0) {
        heroWatcherEl.style.display = 'inline-flex';
        heroWatcherTextEl.textContent = `${wCount} watching`;
      } else {
        heroWatcherEl.style.display = 'inline-flex';
        heroWatcherTextEl.textContent = 'Active';
      }
    }

    // Views Badge (Prominent beside price)
    const heroViewsEl = document.getElementById('heroStockViews');
    const heroViewsTextEl = document.getElementById('heroStockViewsText');
    if (heroViewsEl && heroViewsTextEl) {
      const vCount = typeof item.views === 'number' ? item.views : 0;
      if (vCount > 0) {
        heroViewsEl.className = 'inv-card-views-prominent-badge';
        heroViewsTextEl.textContent = `${vCount.toLocaleString()} views (24h)`;
        const icon = heroViewsEl.querySelector('i');
        if (icon) icon.className = 'fa-solid fa-eye';
      } else {
        heroViewsEl.className = 'inv-card-views-prominent-badge new-listing-views-badge';
        heroViewsTextEl.textContent = 'Just Listed';
        const icon = heroViewsEl.querySelector('i');
        if (icon) icon.className = 'fa-solid fa-bolt';
      }
    }

    // Dynamic eBay Coupon Badge for Hero Card
    let couponBadgeEl = container.querySelector('.hero-stock-coupon-badge');
    if (item.coupon) {
      if (!couponBadgeEl) {
        couponBadgeEl = document.createElement('div');
        couponBadgeEl.className = 'hero-stock-coupon-badge';
        if (titleEl) titleEl.parentNode.insertBefore(couponBadgeEl, titleEl);
      }
      couponBadgeEl.innerHTML = `<i class="fa-solid fa-ticket"></i> ${item.coupon}`;
      couponBadgeEl.style.display = 'inline-flex';
    } else {
      if (couponBadgeEl) couponBadgeEl.remove();
    }
  }

  function startAutoCycle() {
    stopAutoCycle();
    autoCycleTimer = setInterval(() => {
      if (liveListings.length > 1) {
        currentIndex = (currentIndex + 1) % liveListings.length;
        renderHeroItem(currentIndex);
      }
    }, 5000); // Auto-update to next item every 5 seconds
  }

  function stopAutoCycle() {
    if (autoCycleTimer) clearInterval(autoCycleTimer);
  }

  window.heroPrevItem = function() {
    if (liveListings.length === 0) return;
    currentIndex = (currentIndex - 1 + liveListings.length) % liveListings.length;
    renderHeroItem(currentIndex);
    startAutoCycle();
  };

  window.heroNextItem = function() {
    if (liveListings.length === 0) return;
    currentIndex = (currentIndex + 1) % liveListings.length;
    renderHeroItem(currentIndex);
    startAutoCycle();
  };

  if (prevBtn) {
    prevBtn.addEventListener('click', (e) => {
      e.preventDefault();
      window.heroPrevItem();
    });
  }

  if (nextBtn) {
    nextBtn.addEventListener('click', (e) => {
      e.preventDefault();
      window.heroNextItem();
    });
  }

  container.addEventListener('mouseenter', stopAutoCycle);
  container.addEventListener('mouseleave', startAutoCycle);

  // Live Fetch Active eBay Store Listings so sold items are automatically replaced
  async function fetchLiveStoreItems() {
    const storeUrl = 'https://www.ebay.co.uk/str/geoffscuriosities';
    const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(storeUrl)}&disableCache=true`;

    try {
      const response = await fetch(proxyUrl);
      if (!response.ok) return;

      const data = await response.json();
      if (!data || !data.contents) return;

      const parser = new DOMParser();
      const doc = parser.parseFromString(data.contents, 'text/html');

      const cardEls = doc.querySelectorAll('article.str-item-card, div.str-item-card');
      const scrapedLiveItems = [];

      cardEls.forEach(card => {
        const linkEl = card.querySelector('a.str-item-card__link, a[href*="/itm/"]');
        if (!linkEl) return;

        const href = linkEl.getAttribute('href') || '';
        const idMatch = href.match(/itm\/(\d+)/);
        if (!idMatch) return;

        const id = idMatch[1];
        const titleEl = card.querySelector('.str-item-card__property-title, .str-card-title, h3');
        const priceEl = card.querySelector('.str-item-card__property-displayPrice, .str-item-card__primary span');
        const imgEl = card.querySelector('img');

        // Extract active eBay coupon if present
        const couponEl = card.querySelector('.str-item-card__coupon, .str-item-card__promotion, .ux-textspans--RED, [class*="coupon"]');
        let couponText = '';
        if (couponEl) {
          couponText = couponEl.textContent.trim();
        } else {
          const cardText = card.textContent || '';
          const match = cardText.match(/(\d+%\s+off|save\s+£\d+|coupon|code:\s*[A-Z0-9]+)/i);
          if (match) couponText = match[0];
        }

        let imgSrc = '';
        if (imgEl) {
          imgSrc = imgEl.getAttribute('data-src') || imgEl.getAttribute('src') || '';
          if (imgSrc.startsWith('data:image') && imgEl.getAttribute('data-src')) {
            imgSrc = imgEl.getAttribute('data-src');
          }
        }
        if (!imgSrc || imgSrc.startsWith('data:image')) {
          imgSrc = `https://i.ebayimg.com/images/g/ebay_item_${id}/s-l500.jpg`;
        }

        scrapedLiveItems.push({
          title: titleText,
          price: priceText,
          img: imgSrc,
          url: `https://www.ebay.co.uk/itm/${id}`,
          coupon: couponText
        });
      });

      if (scrapedLiveItems.length > 0) {
        liveListings = scrapedLiveItems;
        currentIndex = 0;
        renderHeroItem(0);
        console.log(`Hero Viewing Window: Successfully synced ${liveListings.length} active live eBay store listings!`);
      }
    } catch (err) {
      console.log('Hero live store sync fallback:', err);
    }
  }

  fetchLiveStoreItems();
  startAutoCycle();
}

// Ensure all cards are visible
function makeAllCardsVisible() {
  const cards = document.querySelectorAll('.inventory-card');
  cards.forEach(card => {
    card.style.display = 'flex';
    card.style.opacity = '1';
    card.classList.add('is-visible');
  });
}

// Live Fetch eBay Feedback, Items Sold, and Followers
async function fetchEbayLiveStats() {
  const storeUrl = 'https://www.ebay.co.uk/str/geoffscuriosities';
  const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(storeUrl)}`;

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
        itemsEl.textContent = val.includes('+') ? val : `${val}+`;
      }
    }

    // Extract Followers
    const followersMatch = statsText.match(/(\d+(?:\.\d+)?[KkM]?\+?)\s*followers/i);
    if (followersMatch && followersMatch[1]) {
      const followersEl = document.getElementById('stat-followers');
      if (followersEl) {
        const val = followersMatch[1];
        followersEl.textContent = val.includes('+') ? val : `${val}+`;
      }
    }
  } catch (err) {
    console.log('Using cached stats from eBay store:', err);
  }
}

// Automatically detect and sync newly published eBay listings in real-time
async function syncLiveEbayInventory() {
  const grid = document.getElementById('fullInventoryGrid');
  if (!grid) return;

  const storeUrl = 'https://www.ebay.co.uk/str/geoffscuriosities';
  const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(storeUrl)}&disableCache=true`;

  try {
    const response = await fetch(proxyUrl);
    if (!response.ok) return;

    const data = await response.json();
    if (!data || !data.contents) return;

    const parser = new DOMParser();
    const doc = parser.parseFromString(data.contents, 'text/html');

    // Extract item cards from live eBay store page
    const liveCards = doc.querySelectorAll('article.str-item-card, div.str-item-card');
    const existingIds = new Set();
    grid.querySelectorAll('.inventory-card').forEach(card => {
      const match = card.querySelector('a.btn-ebay')?.href.match(/itm\/(\d+)/);
      if (match) existingIds.add(match[1]);
    });

    let newItemsCount = 0;

    liveCards.forEach(card => {
      const linkEl = card.querySelector('a.str-item-card__link, a[href*="/itm/"]');
      if (!linkEl) return;

      const href = linkEl.getAttribute('href') || '';
      const idMatch = href.match(/itm\/(\d+)/);
      if (!idMatch) return;

      const itemID = idMatch[1];

      // Extract active eBay coupon
      const couponEl = card.querySelector('.str-item-card__coupon, .str-item-card__promotion, .ux-textspans--RED, [class*="coupon"]');
      let couponText = '';
      if (couponEl) {
        couponText = couponEl.textContent.trim();
      } else {
        const cardText = card.textContent || '';
        const match = cardText.match(/(\d+%\s+off|save\s+£\d+|coupon|code:\s*[A-Z0-9]+)/i);
        if (match) couponText = match[0];
      }

      // If existing card, dynamically update/add/remove coupon badge
      const existingCard = Array.from(grid.querySelectorAll('.inventory-card')).find(c => {
        const link = c.querySelector('a.btn-ebay')?.href || '';
        return link.includes(itemID);
      });

      if (existingCard) {
        let couponBadge = existingCard.querySelector('.inv-card-coupon-badge');
        if (couponText) {
          if (!couponBadge) {
            couponBadge = document.createElement('div');
            couponBadge.className = 'inv-card-coupon-badge';
            const cardBody = existingCard.querySelector('.inv-card-body');
            const titleEl = existingCard.querySelector('.inv-card-title');
            if (cardBody && titleEl) cardBody.insertBefore(couponBadge, titleEl);
          }
          couponBadge.innerHTML = `<i class="fa-solid fa-tag"></i> ${couponText}`;
        } else {
          if (couponBadge) couponBadge.remove();
        }
      }

        // Extract exact condition from live eBay store item card
        const condEl = card.querySelector('.str-item-card__property-condition, [class*="condition"], .ux-textspans--SECONDARY');
        const condRaw = (condEl ? condEl.textContent.trim() : '').toLowerCase();
        let exactCond = "Used";
        let condBadgeHtml = '<span><i class="fa-solid fa-rotate-left"></i> Used</span>';
        
        if (condRaw.includes('opened') || condRaw.includes('open box') || condRaw.includes('never used')) {
          exactCond = "Opened - never used";
          condBadgeHtml = '<span><i class="fa-solid fa-box-open"></i> Opened - never used</span>';
        } else if (condRaw.includes('brand new') || condRaw.includes('new with') || condRaw === 'new') {
          exactCond = "New";
          condBadgeHtml = '<span><i class="fa-solid fa-sparkles"></i> New</span>';
        } else if (condRaw.includes('parts') || condRaw.includes('faulty') || condRaw.includes('not working')) {
          exactCond = "For parts or not working";
          condBadgeHtml = '<span><i class="fa-solid fa-wrench"></i> For Parts</span>';
        }

        const newCard = document.createElement('div');
        newCard.className = 'inventory-card is-visible';
        newCard.setAttribute('data-item-id', itemID);
        newCard.setAttribute('data-price', priceText.replace(/[^\d.]/g, '') || '999');
        newCard.setAttribute('data-condition', exactCond);
        newCard.style.display = 'flex';
        newCard.style.opacity = '1';

        const couponBadgeHtml = couponText ? `<div class="inv-card-coupon-badge"><i class="fa-solid fa-tag"></i> ${couponText}</div>` : '';

        newCard.innerHTML = `
          <div class="inv-card-badge">NEW Live Listing</div>
          <div class="inv-card-img-wrap">
            <img src="${imgSrc}" alt="${titleText}">
          </div>
          <div class="inv-card-body">
            <div class="inv-card-price">${priceText}</div>
            ${couponBadgeHtml}
            <h3 class="inv-card-title">${titleText}</h3>
            <div class="inv-card-features">
              ${condBadgeHtml}
              <span><i class="fa-solid fa-store"></i> Pandota Store</span>
            </div>
            <a href="https://www.ebay.co.uk/itm/${itemID}" target="_blank" rel="noopener" class="btn btn-ebay" style="width: 100%; margin-top: 14px;">
              <span>View Listing on eBay</span>
              <i class="fa-solid fa-arrow-up-right-from-square"></i>
            </a>
          </div>
        `;

        grid.insertBefore(newCard, grid.firstChild);
        existingIds.add(itemID);
        newItemsCount++;
      }
    });

    if (newItemsCount > 0) {
      console.log(`Live Sync: Automatically loaded ${newItemsCount} newly listed item(s) from eBay!`);
    }
  } catch (err) {
    console.log('Live store sync fallback:', err);
  }
}

// Controls for inventory.html filtering & sorting
function setupInventoryPageControls() {
  const searchInput = document.getElementById('inventorySearchInput');
  const sortSelect = document.getElementById('inventorySortSelect');
  const grid = document.getElementById('inventoryGrid') || document.getElementById('fullInventoryGrid');

  if (!grid) return;

  let activeConditionFilter = 'all';

  function filterCards() {
    const searchTerm = searchInput ? searchInput.value.toLowerCase().trim() : '';
    const cards = grid.querySelectorAll('.inventory-card');
    let visibleCount = 0;
    const totalCount = cards.length;

    cards.forEach(card => {
      const title = (card.querySelector('.inv-card-title')?.textContent || '').toLowerCase();
      const featuresText = (card.querySelector('.inv-card-features')?.textContent || '').toLowerCase();
      const cardCond = (card.getAttribute('data-condition') || '').trim();
      
      const matchesSearch = !searchTerm || title.includes(searchTerm) || featuresText.includes(searchTerm);
      
      let matchesCondition = true;
      if (activeConditionFilter && activeConditionFilter !== 'all') {
        if (activeConditionFilter === 'coupon') {
          matchesCondition = (card.getAttribute('data-coupon') === 'true');
        } else if (activeConditionFilter === 'New') {
          matchesCondition = (cardCond === 'New');
        } else if (activeConditionFilter === 'Opened - never used') {
          matchesCondition = (cardCond === 'Opened - never used');
        } else if (activeConditionFilter === 'Used') {
          matchesCondition = (cardCond === 'Used');
        } else if (activeConditionFilter === 'For parts or not working') {
          matchesCondition = (cardCond === 'For parts or not working');
        } else {
          matchesCondition = cardCond.toLowerCase() === activeConditionFilter.toLowerCase();
        }
      }

      if (matchesSearch && matchesCondition) {
        card.style.display = 'flex';
        card.style.opacity = '1';
        card.classList.add('is-visible');
        visibleCount++;
      } else {
        card.style.display = 'none';
        card.classList.remove('is-visible');
      }
    });

    // Update count in header and subtext
    const headerCountSpan = document.getElementById('inventoryHeaderCount');
    if (headerCountSpan) {
      headerCountSpan.textContent = totalCount;
    }

    const visibleCountSpan = document.getElementById('visibleCount');
    if (visibleCountSpan) {
      visibleCountSpan.textContent = visibleCount;
    }

    const filteredResultsEl = document.getElementById('filteredResultsCount');
    if (filteredResultsEl) {
      if (activeConditionFilter !== 'all' || searchTerm) {
        filteredResultsEl.innerHTML = `<i class="fa-solid fa-filter"></i> Showing <strong>${visibleCount}</strong> of <strong>${totalCount}</strong> active listings`;
      } else {
        filteredResultsEl.innerHTML = `Showing <span id="visibleCount" style="font-weight: 700; color: var(--text-main);">${totalCount}</span> of ${totalCount} items in stock`;
      }
    }
  }

  // Delegated click handler on condition buttons
  document.addEventListener('click', (e) => {
    const pill = e.target.closest('.condition-pill-btn');
    if (!pill) return;
    e.preventDefault();
    document.querySelectorAll('.condition-pill-btn').forEach(p => p.classList.remove('active'));
    pill.classList.add('active');
    activeConditionFilter = pill.getAttribute('data-condition') || 'all';
    filterCards();
  });

  function getCardPrice(card) {
    const attr = card.getAttribute('data-price');
    if (attr && !isNaN(parseFloat(attr)) && parseFloat(attr) > 0) {
      return parseFloat(attr);
    }
    const priceEl = card.querySelector('.inv-card-price');
    if (priceEl) {
      const parsed = parseFloat(priceEl.textContent.replace(/[^\d.]/g, ''));
      if (!isNaN(parsed)) return parsed;
    }
    return 0;
  }

  function getCardWatchers(card) {
    const attr = card.getAttribute('data-watchers');
    if (attr && !isNaN(parseInt(attr, 10))) {
      return parseInt(attr, 10);
    }
    const watcherCountEl = card.querySelector('.watcher-count');
    if (watcherCountEl) {
      const parsed = parseInt(watcherCountEl.textContent.replace(/[^\d]/g, ''), 10);
      if (!isNaN(parsed)) return parsed;
    }
    return 0;
  }

  function getCardViews(card) {
    const attr = card.getAttribute('data-views');
    if (attr && !isNaN(parseInt(attr, 10))) {
      return parseInt(attr, 10);
    }
    return 0;
  }

  function applySorting(mode) {
    const cardsArray = Array.from(grid.querySelectorAll('.inventory-card'));

    cardsArray.sort((a, b) => {
      if (mode === 'watchers-desc') {
        const wA = getCardWatchers(a);
        const wB = getCardWatchers(b);
        if (wB !== wA) return wB - wA;
        return getCardPrice(b) - getCardPrice(a);
      }
      if (mode === 'watchers-asc') {
        const wA = getCardWatchers(a);
        const wB = getCardWatchers(b);
        if (wA !== wB) return wA - wB;
        return getCardPrice(a) - getCardPrice(b);
      }
      if (mode === 'views-desc') {
        const vA = getCardViews(a);
        const vB = getCardViews(b);
        if (vB !== vA) return vB - vA;
        return getCardPrice(b) - getCardPrice(a);
      }
      const pA = getCardPrice(a);
      const pB = getCardPrice(b);
      return mode === 'price-asc' ? (pA - pB) : (pB - pA);
    });

    cardsArray.forEach(card => grid.appendChild(card));
  }

  if (searchInput) {
    const urlParams = new URLSearchParams(window.location.search);
    const initialQuery = urlParams.get('q');
    if (initialQuery) {
      searchInput.value = initialQuery;
    }

    searchInput.addEventListener('input', filterCards);
  }

  if (sortSelect) {
    sortSelect.addEventListener('change', (e) => {
      applySorting(e.target.value);
    });
    // Apply initial sort (High to Low default)
    applySorting(sortSelect.value || 'price-desc');
  }

  // Initial filter run
  filterCards();
}

// Real-Time Live Sync with eBay Feedback Profile Ratings Table & Reviews
async function syncLiveEbayFeedback() {
  const targetUrl = 'https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367';
  const proxyUrls = [
    `https://api.allorigins.win/raw?url=${encodeURIComponent(targetUrl)}`,
    `https://corsproxy.io/?${encodeURIComponent(targetUrl)}`
  ];

  for (const proxyUrl of proxyUrls) {
    try {
      const response = await fetch(proxyUrl);
      if (!response.ok) continue;
      const htmlText = await response.text();
      if (!htmlText || htmlText.length < 500) continue;

      // 1. eBay's feedback table uses: aria-label="positive Feedback in last 1 month">333</button>
      const extract = (type, period) => {
        const regex = new RegExp(`aria-label="${type} Feedback in last ${period}"[^>]*>(\\d+)<`, 'i');
        const m = htmlText.match(regex);
        return m ? m[1] : null;
      };

      const pos1  = extract('positive', '1 month');
      const pos6  = extract('positive', '6 months');
      const pos12 = extract('positive', '12 months');
      const neu1  = extract('neutral',  '1 month');
      const neu6  = extract('neutral',  '6 months');
      const neu12 = extract('neutral',  '12 months');
      const neg1  = extract('negative', '1 month');
      const neg6  = extract('negative', '6 months');
      const neg12 = extract('negative', '12 months');

      // Update rating numbers if positive values found
      if (pos1 && pos6 && pos12) {
        const fmt = n => n ? Number(n).toLocaleString() : '0';
        const update = (id, value) => {
          const el = document.getElementById(id);
          if (el) el.textContent = fmt(value);
        };

        // Extract and update total feedback score
        const totalMatch = htmlText.match(/Feedback score is\s*(\d[\d,]*)/i);
        if (totalMatch) {
          update('fb-total-score', totalMatch[1].replace(/,/g, ''));
        }

        update('fb-1m-pos',  pos1);
        update('fb-6m-pos',  pos6);
        update('fb-12m-pos', pos12);
        update('fb-1m-neu',  neu1);
        update('fb-6m-neu',  neu6);
        update('fb-12m-neu', neu12);
        update('fb-1m-neg',  neg1);
        update('fb-6m-neg',  neg6);
        update('fb-12m-neg', neg12);
      }

      // 2. Extract recent feedbacks from HTML table rows
      const parser = new DOMParser();
      const doc = parser.parseFromString(htmlText, 'text/html');
      const feedbackRows = doc.querySelectorAll('tr[data-feedback-id]');

      if (feedbackRows.length > 0) {
        const liveFeedbacks = [];
        feedbackRows.forEach(row => {
          const commentEl = row.querySelector('.card__comment span, [data-testid="feedback-comment"]');
          const itemEl = row.querySelector('.card__item span');
          const buyerEl = row.querySelector('.card__from span');
          const scoreEl = row.querySelector('.no-wrap span');
          const dateEl = row.querySelector('[aria-label^="Past"]');

          const priceEl = row.querySelector('.card__price span');
          let price = priceEl ? priceEl.textContent.trim() : '';
          price = price.replace(/^\?/, '£').replace(/^\xA3/, '£');

          if (commentEl && commentEl.textContent.trim()) {
            let comment = commentEl.getAttribute('aria-label') || commentEl.textContent.trim();
            comment = comment.replace(/\?+/g, "'").replace(/'+/g, "'").trim();
            const buyer = buyerEl ? buyerEl.textContent.replace('Feedback left by buyer.', '').replace('Buyer:', '').trim() : 'Verified Buyer';
            const score = scoreEl ? scoreEl.textContent.trim() : '';
            let itemTitle = itemEl ? itemEl.textContent.replace(/\(#\d*\)?$/, '').trim() : 'High Performance Laptop';
            const date = dateEl ? (dateEl.getAttribute('aria-label') || dateEl.textContent.trim()) : 'Recently';

            liveFeedbacks.push({ comment, buyer, score, itemTitle, price, date });
          }
        });

        if (liveFeedbacks.length > 0) {
          // Prioritize most recent 'Past month' reviews first
          liveFeedbacks.sort((a, b) => {
            const aIsMonth = a.date.toLowerCase().includes('month') && !a.date.toLowerCase().includes('6');
            const bIsMonth = b.date.toLowerCase().includes('month') && !b.date.toLowerCase().includes('6');
            if (aIsMonth && !bIsMonth) return -1;
            if (!aIsMonth && bIsMonth) return 1;
            return 0;
          });

          const slider = document.getElementById('feedbackSlider');
          if (slider) {
            slider.innerHTML = liveFeedbacks.map(fb => `
              <a href="https://www.ebay.co.uk/fdbk/feedback_profile/geoff_lee367?filter=feedback_page:RECEIVED_AS_SELLER" target="_blank" rel="noopener" class="feedback-card" style="flex: 0 0 calc(33.333% - 14px); min-width: 300px;" title="View feedback on eBay">
                <div class="feedback-header">
                  <div class="feedback-stars"><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i></div>
                  <span class="verified-badge"><i class="fa-solid fa-circle-check"></i> Verified eBay Buyer</span>
                </div>
                <p class="feedback-comment">"${fb.comment}"</p>
                <div class="feedback-footer">
                  <div class="buyer-info">
                    <span class="buyer-name">Buyer: ${fb.buyer} ${fb.score ? `<span class="buyer-score">(${fb.score})</span>` : ''}</span>
                    <span class="buyer-item">${fb.itemTitle}</span>
                  </div>
                  <div class="feedback-meta-right">
                    ${fb.price ? `<span class="feedback-price">${fb.price}</span>` : ''}
                    <span class="feedback-date">${fb.date}</span>
                  </div>
                </div>
              </a>
            `).join('');
            console.log(`Live Feedback Sync: Rendered ${liveFeedbacks.length} authentic feedbacks directly from eBay!`);
          }
        }
      }

      break;
    } catch (err) {
      console.log('Live feedback sync proxy notice:', err.message);
    }
  }
}

// 12. Live In-Browser Watcher Counter Fetcher (Exact number next to heart symbol on eBay)
function setupLiveWatcherFetcher() {
  const cards = document.querySelectorAll('.inventory-card[data-item-id]');
  if (!cards.length) return;

  const fetchedCache = new Map();

  async function fetchItemWatchers(itemId, callback) {
    if (fetchedCache.has(itemId)) {
      callback(fetchedCache.get(itemId));
      return;
    }

    const sessionKey = 'eb_w_' + itemId;
    const sessionVal = sessionStorage.getItem(sessionKey);
    if (sessionVal !== null) {
      const parsed = parseInt(sessionVal, 10);
      fetchedCache.set(itemId, parsed);
      callback(parsed);
      return;
    }

    const targetUrl = `https://www.ebay.co.uk/itm/${itemId}`;
    const proxies = [
      `https://api.allorigins.win/raw?url=${encodeURIComponent(targetUrl)}`,
      `https://corsproxy.io/?${encodeURIComponent(targetUrl)}`
    ];

    for (const proxy of proxies) {
      try {
        const res = await fetch(proxy);
        if (!res.ok) continue;
        const text = await res.text();
        if (!text || text.length < 500) continue;

        let watchers = 0;
        // Check exact eBay heart/watchlist patterns
        const m1 = text.match(/(?:aria-label="[^"]*?|title="[^"]*?)(\d+)\s*(?:watchers?|people are watching|watching)/i);
        const m2 = text.match(/"watchCount"\s*:\s*(\d+)/i);
        const m3 = text.match(/<button[^>]*?(?:watch|heart)[^>]*?>.*?(\d+).*?<\/button>/is);
        const m4 = text.match(/\b(\d+)\s*(?:watchers?|people watching|watching in last \d+ hours)\b/i);

        if (m1) watchers = parseInt(m1[1], 10);
        else if (m2) watchers = parseInt(m2[1], 10);
        else if (m3) watchers = parseInt(m3[1], 10);
        else if (m4) watchers = parseInt(m4[1], 10);

        if (isNaN(watchers)) watchers = 0;

        fetchedCache.set(itemId, watchers);
        sessionStorage.setItem(sessionKey, watchers.toString());
        callback(watchers);
        return;
      } catch (e) {
        // try next proxy
      }
    }

    // fallback 0 if no public watchers
    fetchedCache.set(itemId, 0);
    sessionStorage.setItem(sessionKey, '0');
    callback(0);
  }

  function applyWatcherBadge(card, watchers) {
    let badge = card.querySelector('.inv-card-watcher-badge');
    if (!badge) {
      const priceRow = card.querySelector('.inv-card-price-row') || card.querySelector('.inv-card-body');
      if (priceRow) {
        badge = document.createElement('div');
        badge.className = 'inv-card-watcher-badge';
        priceRow.appendChild(badge);
      }
    }
    if (badge) {
      if (watchers && watchers > 0) {
        badge.innerHTML = `<i class="fa-solid fa-heart" style="color: #ef4444;"></i> <span class="watcher-count">${watchers} watching</span>`;
        badge.style.color = '#ef4444';
        badge.style.background = 'rgba(239, 68, 68, 0.08)';
        badge.style.borderColor = 'rgba(239, 68, 68, 0.2)';
      } else {
        badge.innerHTML = `<i class="fa-regular fa-heart" style="color: #94a3b8;"></i> <span class="watcher-count">Active</span>`;
      }
    }
  }

  // IntersectionObserver to fetch as items scroll into view
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const card = entry.target;
          const itemId = card.getAttribute('data-item-id');
          if (itemId) {
            fetchItemWatchers(itemId, (count) => {
              applyWatcherBadge(card, count);
            });
          }
          obs.unobserve(card);
        }
      });
    }, { rootMargin: '200px 0px' });

    cards.forEach(card => observer.observe(card));
  } else {
    // Fallback for older browsers: fetch first 8
    Array.from(cards).slice(0, 8).forEach(card => {
      const itemId = card.getAttribute('data-item-id');
      if (itemId) {
        fetchItemWatchers(itemId, (count) => applyWatcherBadge(card, count));
      }
    });
  }

  // Expose global helper for Hero Featured Card
  window.fetchLiveItemWatchers = fetchItemWatchers;
}

/**
 * Enhanced Email Us / Copy-to-Clipboard Handler
 */
function setupEmailSpecsHandler() {
  const emailButtons = document.querySelectorAll('.btn-specs-highlight, .sell-cta-subtext');
  if (!emailButtons || emailButtons.length === 0) return;

  const emailAddress = "purchasing@pandota.co.uk";

  // Create toast notification element if not exists
  let toast = document.getElementById('emailCopyToast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'emailCopyToast';
    toast.className = 'email-copy-toast';
    toast.innerHTML = `<i class="fa-solid fa-circle-check"></i> <span><strong>${emailAddress}</strong> copied to clipboard!</span>`;
    document.body.appendChild(toast);
  }

  let toastTimer = null;
  function showToast(msg) {
    if (msg) toast.innerHTML = msg;
    toast.classList.add('show');
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toast.classList.remove('show');
    }, 4000);
  }

  emailButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      // Copy email to clipboard
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(emailAddress).then(() => {
          showToast(`<i class="fa-solid fa-circle-check"></i> <span><strong>${emailAddress}</strong> copied to clipboard!</span>`);
        }).catch(() => {
          showToast(`<i class="fa-solid fa-envelope"></i> <span>Send specs to: <strong>${emailAddress}</strong></span>`);
        });
      } else {
        showToast(`<i class="fa-solid fa-envelope"></i> <span>Send specs to: <strong>${emailAddress}</strong></span>`);
      }

      // If it's the badge (not a link), prevent default navigation
      if (!btn.getAttribute('href')) {
        e.preventDefault();
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  setupEmailSpecsHandler();
});
