function StartCommunicationTracing()
{
    $msservices = @("HealthService")
    Get-Service $msservices | Stop-Service -PassThru
    Set-Location -Path "$($SCOMInstallDirectory)Tools"
    Remove-Item -Path "$($SCOMInstallDirectory)Health Service State" -Recurse -Force
    Get-Service $msservices | Start-Service -PassThru
    Start-Sleep -Seconds 2
    cmd.exe /c "$($SCOMInstallDirectory)Tools\StopTracing.cmd"
    . $($SCOMInstallDirectory)Tools\TraceLogSM.exe -stop HSCoreTrace
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 3
    . $($SCOMInstallDirectory)Tools\TraceLogSM.exe -start HSCoreTrace -guid "#417B7AE0-9B8F-4e3f-8FCA-19C706EFF3D4" -f "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    Start-Sleep -Seconds 900
    . $($SCOMInstallDirectory)Tools\TraceLogSM.exe -stop HSCoreTrace
    cmd.exe /c "$($SCOMInstallDirectory)Tools\FormatTracing.cmd"
}