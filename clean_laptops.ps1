$raw = Get-Content -Path 'ebay_live_products.json' -Raw | ConvertFrom-Json
$clean = foreach ($item in $raw) {
    $t = $item.Title -replace '^watch\s*', '' -replace '&#34;', '"' -replace '&amp;', '&'
    
    # Filter out camera accessories, keeping laptops & computers
    if ($t -and $item.Price -and $t -notmatch 'Sony Alpha|Sony FE|Sony E') {
        [PSCustomObject]@{
            ItemId = $item.ItemId
            Title = $t.Trim()
            Price = $item.Price
            Url = "https://www.ebay.co.uk/itm/" + $item.ItemId
            Image = $item.LocalImage
        }
    }
}

$clean | ConvertTo-Json | Out-File -FilePath 'exact_store_laptops.json' -Encoding utf8
Write-Host "Clean laptop count:" $clean.Count
$clean | Select-Object ItemId, Title, Price, Image | Format-Table -AutoSize
