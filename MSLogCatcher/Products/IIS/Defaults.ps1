$Global:FilteredIISLogsDefinition = "$scriptPath\LogsDefinition\LOGS.CSV"
$Global:CurentSites = @()
$sitesInfo = Get-Website | Sort-Object -Property id
foreach ($siteinfo in $sitesInfo)
{
    $Global:CurentSites += $siteinfo.id
}
$Global:DefaultFilteredSitesIDs = $Global:CurentSites -join ","