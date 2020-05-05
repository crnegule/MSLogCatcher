foreach($product in Get-ChildItem "$scriptPath\Products")
{
    if($productList.Contains($product)) {
        try {
            . "$scriptPath\Products\$($product.Name)\CLI.ps1"
        }
        catch { }
    }
}