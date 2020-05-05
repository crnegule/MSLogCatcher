
param (
    [Parameter()]
    [String] $CLIZipLocation=$ZipLocation,
    [int32] $CLILogAge = $LogAge

    )

. $scriptPath\Products\IIS\GetIISStuff.ps1
. $scriptPath\Products\IIS\Defaults.ps1
. $scriptPath\Products\IIS\PopulateIISLogDefinition.ps1
. $scriptPath\Products\IIS\CatchIISZip.ps1


Get-IIS-Stuff
"mama --> $LogAge "| out-file c:\tem\mama.log -append
"tata -> $CLILogAge" | out-file c:\tem\mama.log -append
if ($CLILogAge -eq 0) 
{ $GLOBAL:MaxDays = $Global:DefaultMaxDays }
else 
{ $GLOBAL:MaxDays = $CLILogAge }

    $GLOBAL:IISFilteredSitesIDs = $DefaultFilteredIISSitesIDs.split(",", [System.StringSplitOptions]::RemoveEmptyEntries)


if ($CLIZipLocation) { 
    $Global:ZipOutput = $CLIZipLocation
    }

CatchIISZip -ea silentlycontinue -ErrorVariable +ErrorMessages
Write-Output "Zip can be found at the following path: $IISFilteredZipFile"
