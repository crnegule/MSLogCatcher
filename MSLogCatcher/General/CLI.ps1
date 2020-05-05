param (
  [Parameter()]
   [String] $ZipLocation,
  [int32] $LogAge,
  [String] $Products
)

"mama --> $LogAge $ZipLocation $Products "| out-file c:\tem\mama.log -append

if (!$Products) { 
    foreach($product in Get-ChildItem "$scriptPath\Products")
{
    . "$scriptPath\Products\$($product.Name)\CLI.ps1"

    $productList = $Products

    # if($productList.Contains($product)) {
    #     try {
    #         . "$scriptPath\Products\$($product.Name)\CLI.ps1"
    #     }
    #     catch { }
    # }
}
}
else{
    foreach($product in Get-ChildItem "$scriptPath\Products")
    {
        . "$scriptPath\Products\$($product.Name)\CLI.ps1"
    
        $productList = $Products
    
        # if($productList.Contains($product)) {
        #     try {
        #         . "$scriptPath\Products\$($product.Name)\CLI.ps1"
        #     }
        #     catch { }
        # }
    }}
