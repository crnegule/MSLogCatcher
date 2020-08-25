param (
    [Parameter()]
    [String] $ZipLocation,
    [int32] $LogAge,
    [String[]] $Products
)

if ($Products.Length -gt 0)
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

if((Test-Path "$($Global:ZipOutput)\*") -eq $true)
{
    $timestamp = Get-Date -format "yyyy-M-dd_HH-mm-ss"
    Add-Type -assembly "System.Io.Compression.FileSystem"
    [Io.Compression.ZipFile]::CreateFromDirectory($Global:ZipOutput, "$($Global:ZipOutput)\..\output-$($timestamp).zip")
    Remove-Item "$($Global:ZipOutput)\*" -Recurse -Force
    Write-Host "ZIP File to send is: $($Global:ZipOutput)\..\output-$($timestamp).zip"
}
