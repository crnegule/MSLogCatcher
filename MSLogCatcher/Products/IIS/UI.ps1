. $scriptPath\Products\IIS\Defaults.ps1
. $scriptPath\Products\IIS\CatchIISZip.ps1
. $scriptPath\Products\IIS\GetIISStuff.ps1
. $scriptPath\Products\IIS\GetSiteStatus.ps1
. $scriptPath\Products\IIS\PopulateIISLogDefinition.ps1

$filteredstart = $xamlReader.FindName("createIISFilteredZIP")
$days = $xamlReader.FindName("FilteredDays")
$filteredIISSiteID = $xamlReader.FindName("filteredIISSiteID")
$IISsitesDataGrid = $xamlReader.FindName("IISsitesDataGrid")
$barIISCatchStatus = $xamlReader.FindName("IIStatusBar")
$update = $xamlReader.FindName("ProgressBarText")

$days.text = $DefaultMaxDays
$filteredIISSiteID.text = $DefaultFilteredIISSitesIDs
$arrproc = New-Object System.Collections.ArrayList
$CurrentIISSites = GetSiteStatus 
$arrproc.addrange(@($CurrentIISSites))
$IISsitesDataGrid.ItemsSource = @($arrproc)

$filteredstart.add_click({
    $barIISCatchStatus.value = "0"
    $MaxDays = $days.text
    $stringFilteredSitesIDs = $filteredIISSiteID.text
    $GLOBAL:IISFilteredSitesIDs = $stringFilteredSitesIDs.split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
    CatchIISzip 
    $barIISCatchStatus.value = "100"
    $update.text = "Zip generated at:  $IISFilteredZipFile"
    Invoke-Item $ZipOutput
})