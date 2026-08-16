$items = Get-Content -Path "all_store_listings_full.json" -Raw | ConvertFrom-Json
Write-Host "GRAND TOTAL STORE LISTINGS:" $items.Count

# Filter for laptops & computers (excluding camera lenses)
$laptops = foreach ($item in $items) {
    if ($item.Title -notmatch 'Sony Alpha|Sony FE|Sony E-mount') {
        $item
    }
}

Write-Host "TOTAL UNIQUE LAPTOPS:" $laptops.Count

$laptops | ConvertTo-Json | Out-File -FilePath "all_unique_laptops_full.json" -Encoding utf8
Write-Host "Wrote all_unique_laptops_full.json"
