$laptops = Get-Content -Path "exact_store_laptops_prices_fixed.json" -Raw | ConvertFrom-Json

Write-Host "Original count before deduplication:" $laptops.Count

$seenIds = @{}
$seenTitles = @{}
$uniqueLaptops = @()

foreach ($item in $laptops) {
    $id = $item.ItemId
    $title = $item.Title.Trim()
    
    # Normalize title for duplicate checking
    $normTitle = $title.ToLower() -replace '\s+', ' '
    
    if (-not $seenIds.ContainsKey($id) -and -not $seenTitles.ContainsKey($normTitle)) {
        $seenIds[$id] = $true
        $seenTitles[$normTitle] = $true
        $uniqueLaptops += $item
    }
}

Write-Host "Unique laptop count after deduplication:" $uniqueLaptops.Count

$uniqueLaptops | ConvertTo-Json | Out-File -FilePath "unique_store_laptops.json" -Encoding utf8

$uniqueLaptops | Select-Object ItemId, Title, Price, Image | Format-Table -AutoSize
