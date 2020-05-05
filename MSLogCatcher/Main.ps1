$ErrorActionPreference = "SilentlyContinue"

param (
  [Parameter()]
  [bool] $Quiet,
  [String] $ZipLocation,
  [int32] $LogAge,
  [String[]] $Products
)

$Global:scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  # Relaunch as an elevated process:
  # Start-Process powershell.exe "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  # exit
}

$Global:FormLocation = "$scriptPath\Form\Form.xml"
$Global:ToolLog = "$scriptPath\ScriptLog\ToolLog.log"
$Global:ZipOutput = "$scriptPath" #if you want to revert to Original replace with : $Global:ZipOutput = "$scriptPath"
$Global:DefaultMaxDays = "2"

switch ($Quiet) {
    $true {
      $Global:productList = $Products
      . $scriptPath\General\CLI.ps1
    }
    Default {
      . $scriptPath\General\UI.ps1
    }
  }
