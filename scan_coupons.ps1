$json = Get-Content 'all_82_with_exact_scraped_prices.json' -Raw | ConvertFrom-Json
Write-Host "Total catalog listings checked: " $json.Count

$found = @()
foreach ($item in $json) {
    if ($item.Title -match '(\d+%\s*off|coupon|voucher|code|save)') {
        $found += $item
    }
}

Write-Host "Listings with active coupon keywords in title: " $found.Count

if ($found.Count -gt 0) {
    foreach ($f in $found) {
        Write-Host "- [$($f.ItemId)] $($f.Title) ($($f.Price))"
    }
} else {
    Write-Host "Currently, none of the 82 active eBay listings have explicit coupon codes in their listing titles."
}
