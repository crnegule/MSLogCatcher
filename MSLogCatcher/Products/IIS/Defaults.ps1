$Global:IISLogsDefinition = "$scriptPath\Products\IIS\IISLogsDefinition.CSV"
$Global:CurentIISSites = @()
$sitesInfo = Get-Website | Sort-Object -Property id
foreach ($siteinfo in $sitesInfo)
{
    $Global:CurentIISSites += $siteinfo.id
}

# if we want manual entry edit the DefaultFilteredIISSitesIDs = "1,2,3,"

$Global:DefaultFilteredIISSitesIDs = $Global:CurentIISSites -join ","