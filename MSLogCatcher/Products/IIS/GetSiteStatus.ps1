#Function GetSiteStatus {
#    $CurrentSites = Get-Website | Select-Object id, state, name, applicationPool, physicalPath | Sort-Object -Property id
#    Return $CurrentSites
#}