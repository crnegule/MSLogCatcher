. $scriptPath\Products\IIS\Defaults.ps1
. $scriptPath\Products\IIS\CatchFilteredIISzip.ps1
. $scriptPath\Products\IIS\GetIISStuff.ps1
. $scriptPath\Products\IIS\GetSiteStatus.ps1
. $scriptPath\Products\IIS\PopulateFilteredLogDefinition.ps1

$filteredstart = $xamlReader.FindName("createFilteredZIP")
$days = $xamlReader.FindName("FilteredDays")
$filteredSiteID = $xamlReader.FindName("FilteredSiteID")
$sitesDataGrid = $xamlReader.FindName("sitesDataGrid")
$barCatchStatus = $xamlReader.FindName("StatusBar")
$update = $xamlReader.FindName("ProgressBarText")

$days.text = $DefaultMaxDays
$filteredSiteID.text = $DefaultFilteredSitesIDs
$arrproc = New-Object System.Collections.ArrayList
$CurrentSites = GetSiteStatus 
$arrproc.addrange(@($CurrentSites))
$sitesDataGrid.ItemsSource = @($arrproc)

$filteredstart.add_click({
    $barCatchStatus.value = "0"
    $MaxDays = $days.text
    $stringFilteredSitesIDs = $filteredSiteID.text
    $FilteredSitesIDs = $stringFilteredSitesIDs.split(",", [System.StringSplitOptions]::RemoveEmptyEntries) 
    $barCatchStatus.value = "100"
    $update.text = "Zip generated at:  $FilteredZipFile"
})