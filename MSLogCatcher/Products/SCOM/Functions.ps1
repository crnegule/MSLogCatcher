function StartCommunicationTracing($durationInSeconds)
{
    $Global:StatusLabel.Text = "RUNNING"
    $durationInSeconds = $durationInSeconds -as [int]
    $msservices = @("HealthService")
    Get-Service $msservices | Stop-Service -PassThru
    Get-Service $msservices | Start-Service -PassThru
    Start-Sleep -Seconds 1
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 2
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start HSCoreTrace -guid $Global:HSCoreProviderGuid -f "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    cmd.exe /c "netsh trace start capture=yes persistent=yes filemode=circular maxSize=1000MB traceFile=$($Global:ZipOutput)\$($Env:COMPUTERNAME)_NetworkTrace.etl"
    Write-Host "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.\n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Text = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
        cmd.exe /c "netsh trace stop"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
        Write-Host "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        $Global:StatusLabel.Text = "FINISHED"
    }
}

function StartCommunicationTracingStop()
{
    $Global:StatusLabel.Text = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "netsh trace stop"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
    Write-Host "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Text = "FINISHED"
}

function StartSubscriptionTracing($durationInSeconds)
{
    $Global:StatusLabel.Text = "RUNNING"
    $durationInSeconds = $durationInSeconds -as [int]
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop AlertSubscriptionTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 2
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start NotificationsTrace -guid $Global:NotificationsGuid -f "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start AlertSubscriptionTrace -guid $Global:AlertSubscriptionGuid -f "$($env:WINDIR)\Logs\OpsMgrTrace\AlertSubscriptionTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    Write-Host "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.\n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Text = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop AlertSubscriptionTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.log" -Destination "$($Global:ZipOutput)\NotificationsTrace.log"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\AlertSubscriptionTrace.log" -Destination "$($Global:ZipOutput)\AlertSubscriptionTrace.log"
        Write-Host "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        $Global:StatusLabel.Text = "FINISHED"
    }
}

function StartSubscriptionTracingStop()
{
    $Global:StatusLabel.Text = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop AlertSubscriptionTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.log" -Destination "$($Global:ZipOutput)\NotificationsTrace.log"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\AlertSubscriptionTrace.log" -Destination "$($Global:ZipOutput)\AlertSubscriptionTrace.log"
    Write-Host "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Text = "FINISHED"
}

function StartConfigAndWorkflowLoadingTracing($durationInSeconds)
{
    $Global:StatusLabel.Text = "RUNNING"
    $durationInSeconds = $durationInSeconds -as [int]
    $msservices = @("HealthService")
    Get-Service $msservices | Stop-Service -PassThru
    Remove-Item -Path "$($Global:SCOMInstallDirectory)Health Service State" -Recurse -Force
    Get-Service $msservices | Start-Service -PassThru
    Start-Sleep -Seconds 1
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 2
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start HSCoreTrace -guid $Global:HSCoreProviderGuid -f "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    Write-Host "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.\n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Text = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
        Write-Host "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        $Global:StatusLabel.Text = "FINISHED"
    }
}

function StartConfigAndWorkflowLoadingTracingStop()
{
    $Global:StatusLabel.Text = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
    Write-Host "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Text = "FINISHED"
}

function CollectSCOMData()
{
    . "$($Global:scriptPath)\Products\SCOM\HealthCheck.ps1"
}