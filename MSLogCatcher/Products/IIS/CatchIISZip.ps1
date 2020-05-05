function CatchIISzip {
    $date = Get-Date -Format "yyyy-MM-dd-T-HH-mm-ss"
    $IISTime = Get-Date 
    PopulateIISLogDefinition -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages | Out-Null
    $FilteredIISLOGSDefinitions = Import-Csv $IISLogsDefinition
    $FilteredTempLocation = $ZipOutput + "\FilteredIISMSDT"
    If (Test-path $FilteredTempLocation) { Get-ChildItem $FilteredTempLocation | Remove-Item -Recurse -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages }
    new-item -Path $ZipOutput -ItemType "directory" -Name "FilteredIISMSDT" -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages | Out-Null
    "$IISTime IISLogCollection was run for  the SiteIDS: $IISFilteredSitesIDs with LogsAges filter set at $Global:MaxDays" | Out-File $ToolLog -Append
    $Global:IISFilteredZipFile = $ZipOutput + "IIS-LOGS-" + $date + ".zip"
    If (Test-path $IISFilteredZipFile) { Remove-item $IISFilteredZipFile -Force } 
    $GeneralTempLocation = $FilteredTempLocation + "\General"
    $SiteTempLocation = $FilteredTempLocation + "\Sites"
    foreach ($FilteredLogDefinition in $FilteredIISLOGSDefinitions) {
        if ($FilteredLogDefinition.Level -eq 'Site') {
            if ($FilteredLogDefinition.Product -eq "SitePath" ) {
                $idFloder = $SiteTempLocation + "\" + $FilteredLogDefinition.LogName
            
                new-item -Path $SiteTempLocation -ItemType "directory" -Name $FilteredLogDefinition.LogName -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages | Out-Null
                Robocopy.exe $FilteredLogDefinition.Location $idFloder *.config /s | Out-Null
            }
            elseif ($FilteredLogDefinition.Product -eq "FrebLogs" ) {
                $idFloder = $SiteTempLocation + "\" + $FilteredLogDefinition.LogName
                $SiteLogs = $idFloder + "\FrebLogs"
                Robocopy.exe $FilteredLogDefinition.Location $SiteLogs /s /maxage:$MaxDays | Out-Null
            }
            else {
                $idFloder = $SiteTempLocation + "\" + $FilteredLogDefinition.LogName
                $SiteLogs = $idFloder + "\IISLogs"
                Robocopy.exe $FilteredLogDefinition.Location $SiteLogs /s /maxage:$MaxDays | Out-Null
            }
 
        }
        else {
            if ( $FilteredLogDefinition.TypeInfo -eq "Folder" ) {
                if ( $FilteredLogDefinition.LogName -eq "HTTPERRLog" ) {
                    $httperr = $GeneralTempLocation + "\HttpERR"
                    Robocopy.exe $FilteredLogDefinition.Location $httperr /s | Out-Null
                }
                elseif ( $FilteredLogDefinition.LogName -eq "IISConfig" ) {
                    $IISConfig = $GeneralTempLocation + "\IISConfig"
                    Robocopy.exe $FilteredLogDefinition.Location $IISConfig *.config /s | Out-Null
                }
                else {
                    $NETFramework = $GeneralTempLocation + "\NETFramework"
                    Robocopy.exe $FilteredLogDefinition.Location $NETFramework *.config /s | Out-Null
                }
            }
            else {
                Copy-Item -Path $FilteredLogDefinition.Location -Destination $GeneralTempLocation -Recurse -Force -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
 
            }
        }
    }

    $ExcludeFilter = @()
    $Errlog = "HTTP*"
    $ExcludeFilter += $Errlog
    foreach ($id in $IISFilteredSitesIDs) {
        $stringtoADD = "*" + $id
        $ExcludeFilter += $stringtoADD
    }
    $iisInfo = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp\
    IF ($iisInfo.MajorVersion -ge 8) {
        if ($Host.Version.Major -ge 5) {
            GenerateSiteOverview -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages | Out-Null
            $logName = $GeneralTempLocation + "\SiteOverview.csv"
            $Global:SiteOverview | Export-csv -Path $logName -NoTypeInformation -Force -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::CreateFromDirectory($FilteredTempLocation, $IISFilteredZipFile)
    
            Remove-Item -Recurse $FilteredTempLocation -Force -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages    
        }
        else {
            
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::CreateFromDirectory($FilteredTempLocation, $IISFilteredZipFile) 
            Remove-Item -Recurse $FilteredTempLocation -Force -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages 
        }
    }
    else {
        if ($Host.Version.Major -ge 3) {  
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::CreateFromDirectory($FilteredTempLocation, $IISFilteredZipFile) 
            Remove-Item -Recurse $FilteredTempLocation -Force -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages   
            "$IISTime Exception Message: IIS server version is lower than 8.0 so no SiteOverView generated!" | Out-File $ToolLog -Append

        }

        else {
            "$IISTime Exception Message: IIS server version is lower than 8.0 so no SiteOverView generated!" | Out-File $ToolLog -Append
            "$IISTime Exception Message: Zip was not created as system.io.compression.filesystem version could not be loaded!" | Out-File $ToolLog -Append
        }
    }

    Foreach ($Message in $ErrorMessages) {
        $IISTime = Get-Date
        $ErroText = $Message.Exception.Message
        "$IISTime Exception Message: $ErroText" | Out-File $ToolLog -Append
    }
    "$IISTime Tool has Finished running!" | Out-File $ToolLog -Append
}
