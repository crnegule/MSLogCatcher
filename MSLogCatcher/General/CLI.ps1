param (
    [Parameter()]
    [String] $ZipLocation,
    [int32] $LogAge,
    [String[]] $Products
)

if (!$Products)
{ 
    foreach($product in $Products)
    {
        . "$($Global:scriptPath)\Products\$($product)\CLI.ps1"
    }
}
else
{
    foreach($product in Get-ChildItem "$scriptPath\Products")
    {
        . "$($Global:scriptPath)\Products\$($product)\CLI.ps1"
    }
}
