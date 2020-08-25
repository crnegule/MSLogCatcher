<#
  .SYNOPSIS
  Collects IIS logs easy way.

  .DESCRIPTION
  The Main.ps1 script collects all Microsft Products realted logs needed for troubleshooting

  .PARAMETER Quiet
  Runs the toll CLI mod, NO UI.
 .PARAMETER ZipLocation
  Specifies the Folder where the zip will be created, by default ZIP will be created in the Script Folder.
  Input needs to be a string. ex: "c\Temp" with NO training "\"
  .PARAMETER LogAge
  Specifies the Age of the logs you want to collect. LogAge = Days.
  By default LogAge is set for 2 days.
  

  .INPUTS
  None. You cannot pipe objects to Update-Month.ps1.

  .OUTPUTS
  None. Main.ps1 generates a zip in the Folder where the script is by default.

  .EXAMPLE 
To start Tool with UI
  .\Main.ps1

  .EXAMPLE
To start Tool with CLI and custom ZIP location
  .\Main.ps1 -Quiet $true -ZipLocation "C:\Temp"

    .EXAMPLE
To change AGE of logs and Sites that are collecter:
  .\LogCatcher.ps1 -Quiet $true -LogAge 45 -Products "IIS,SCOM,SCSM" 
     
#>

param (
  [Parameter()]
  [switch] $Quiet,
  [String] $ZipLocation,
  [int32] $LogAge,
  [String[]] $Products
)

$ErrorActionPreference = "SilentlyContinue"

$Global:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Relaunch as an elevated process:
  Start-Process powershell.exe "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

$Global:FormLocation = "$scriptPath\Form\Form.xml"
$Global:ToolLog = "$scriptPath\CollectedLogs\ToolLog.log"
$Global:ZipOutput = "$scriptPath\CollectedLogs"
$Global:DefaultMaxDays = "10"

Remove-Item "$($Global:ZipOutput)\*" -Recurse -Force

if((Test-Path $ZipOutput) -eq $False)
{
  New-Item -ItemType "directory" -Path $ZipOutput
}

function Write-OutputToLog
{
  Param(
        [string]$output
    )

    Write-Host $output
    $viewModel.OutputLogData += $output
    $output | Out-File $ToolLog -Append
}

switch ($Quiet) {
    $true
    {
      $Global:Quiet = $true
      $Global:productList = $Products
      . $scriptPath\General\CLI.ps1 -Products $Products
    }
    Default
    {
      $Global:Quiet = $false
      . $scriptPath\General\UI.ps1
    }
  }
