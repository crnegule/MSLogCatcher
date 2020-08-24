function StartCommunicationTracing($durationInSeconds)
{
    $durationInSeconds = $durationInSeconds -as [int]
    $msservices = @("HealthService")
    Get-Service $msservices | Stop-Service -PassThru
    Set-Location -Path "$($Global:SCOMInstallDirectory)Tools"
    Remove-Item -Path "$($Global:SCOMInstallDirectory)Health Service State" -Recurse -Force
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
        Write-Host "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
        cmd.exe /c "netsh trace stop"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
    }
}

function StartCommunicationTracingStop()
{
    Write-Host "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "netsh trace stop"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
}

function CollectSCOMData()
{
    . "$($Global:scriptPath)\Products\SCOM\HealthCheck.ps1"
}