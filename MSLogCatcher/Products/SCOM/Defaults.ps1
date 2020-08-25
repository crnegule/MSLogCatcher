$Global:productPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Global:SCOMInstallDirectory = ""
try
{
    $Global:SCOMInstallDirectory = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Agent").InstallDirectory
    if([string]::IsNullOrEmpty($instDir)) {
        $Global:SCOMInstallDirectory = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Server").InstallDirectory
    }
} catch [ItemNotFoundException] {
    $Global:SCOMInstallDirectory = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Server").InstallDirectory
}

$Global:Scenario1 = "Communication"
$Global:Scenario2 = "Subscription"
$Global:Scenario3 = "Config/Workflow loading"
$Global:Scenario4 = "Workflow tracing"

$Global:CurrentScenario = ""

$Global:SecondsToSleepForTrace = 900

if($Global:Quiet)
{
    # (default) variables for quite mode
    $Global:CollectLogs = $true
    $Global:CurrentScenario = $Scenario1
    $Global:WorkflowNameToTrace = "Microsoft.Exchange.2010.ClientAccessRole.DiscoveryRule"
}
