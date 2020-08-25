function StartCommunicationTracing($durationInSeconds)
{
    $Global:StatusLabel.Content = "RUNNING"
    $durationInSeconds = $durationInSeconds -as [int]
    $msservices = @("HealthService")
    Get-Service $msservices | Stop-Service -PassThru
    Get-Service $msservices | Start-Service -PassThru
    Start-Sleep -Seconds 1
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 2
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start HSCoreTrace -guid "$($Global:productPath)\etwscenarios\Scenario1.ctl" -f "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    cmd.exe /c "netsh trace start capture=yes persistent=yes filemode=circular maxSize=1000MB traceFile=$($Global:ZipOutput)\$($Env:COMPUTERNAME)_NetworkTrace.etl"
    Write-OutputToLog "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.`n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Content = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
        cmd.exe /c "netsh trace stop"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
        Write-OutputToLog "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.`n"
        $Global:StatusLabel.Content = "FINISHED"
    }
}

function StartCommunicationTracingStop()
{
    $Global:StatusLabel.Content = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "netsh trace stop"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
    Write-OutputToLog "We finished."
    $Global:OutputTextBlock.Text += "We finished.`n"
    $Global:StatusLabel.Content = "FINISHED"
}

function StartSubscriptionTracing($durationInSeconds)
{
    $Global:StatusLabel.Content = "RUNNING"
    $durationInSeconds = $durationInSeconds -as [int]
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
    Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
    Start-Sleep -Seconds 2
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start NotificationsTrace -guid "$($Global:productPath)\etwscenarios\Scenario2.ctl" -f "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    Write-OutputToLog "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.\n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Content = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.log" -Destination "$($Global:ZipOutput)\NotificationsTrace.log"
        Write-OutputToLog "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        $Global:StatusLabel.Content = "FINISHED"
    }
}

function StartSubscriptionTracingStop()
{
    $Global:StatusLabel.Content = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop NotificationsTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop AlertSubscriptionTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\NotificationsTrace.log" -Destination "$($Global:ZipOutput)\NotificationsTrace.log"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\AlertSubscriptionTrace.log" -Destination "$($Global:ZipOutput)\AlertSubscriptionTrace.log"
    Write-OutputToLog "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Content = "FINISHED"
}

function StartConfigAndWorkflowLoadingTracing($durationInSeconds)
{
    $Global:StatusLabel.Content = "RUNNING"
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
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start HSCoreTrace -guid "$($Global:productPath)\etwscenarios\Scenario3.ctl" -f "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
    Write-OutputToLog "We are starting."
    $Global:OutputTextBlock.Text += "We are starting.\n"
    if($durationInSeconds -gt 0)
    {
        Start-Sleep -Seconds $durationInSeconds
        $Global:StatusLabel.Content = "STOPPING"
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
        Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
        Write-OutputToLog "We finished."
        $Global:OutputTextBlock.Text += "We are finishing.\n"
        $Global:StatusLabel.Content = "FINISHED"
    }
}

function StartConfigAndWorkflowLoadingTracingStop()
{
    $Global:StatusLabel.Content = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop HSCoreTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\HSCoreTrace.log" -Destination "$($Global:ZipOutput)\HSCoreTrace.log"
    [Io.Compression.ZipFile]::CreateFromDirectory($Global:ZipOutput, "$($Global:ZipOutput)\..\output-$(Get-Date -format 'yyyy-M-dd').zip")
    Write-OutputToLog "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Content = "FINISHED"
}

function StartWorkflowTracing
{
    Param(
        [string]$workflowName,
        [string]$durationInSeconds
    )

    if(-not (Get-Module | Where-Object {$_.Name -eq "OperationsManager"}))
    {
        Write-OutputToLog "The Operations Manager Module was not found...importing the Operations Manager Module"
        Import-Module OperationsManager
    }
    else
    {
        Write-OutputToLog "The Operations Manager Module is loaded"
    }

    $ManagementPackId = "SCOMCustomMSCollectorWorkflowTracingMp"
    $ManagementPackName = "SCOM Custom MSCollector Workflow Tracing MP"
    $ManagementPackDescription = "Auto Generated Management Pack for SCOM MSCollector Workflow Tracing (should be deleted after troubleshooting)"
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup("localhost")
    $mp = $mg.GetManagementPacks($ManagementPackId)

    if($null -ne $mp)
    {
        Remove-SCOMManagementPack -ManagementPack $mp
    }

    $MpStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
    $mp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($ManagementPackId, $ManagementPackName, (New-Object Version(1, 0, 0)), $MpStore)
    $mg.ImportManagementPack($mp)
    $mp = $mg.GetManagementPacks($ManagementPackId)[0]
    $mp.DisplayName = $ManagementPackName
    $mp.Description = $ManagementPackDescription
    $mp.AcceptChanges()

    $workflow = Get-SCOMDiscovery -Name $WorkflowName
    if($null -ne $workflow)
    {
        $target = Get-SCOMClass -Id $workflow.Target.Id
        $override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryPropertyOverride($mp, "$($ManagementPackId)_$($workflow.Name)_TraceEnabledOverride")
        $override.Discovery = $workflow
    }
    else
    {
        $workflow = Get-SCOMMonitor -Name $WorkflowName
        if($null -ne $workflow)
        {
            $target = Get-SCOMClass -Id $workflow.Target.Id
            $override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorPropertyOverride($mp, "$($ManagementPackId)_$($workflow.Name)_TraceEnabledOverride")
            $override.Monitor = $workflow
        }
        else
        {
            $workflow = Get-SCOMRule -Name $WorkflowName
            if($null -ne $workflow)
            {
                $target = Get-SCOMClass -Id $workflow.Target.Id
                $override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRulePropertyOverride($mp, "$($ManagementPackId)_$($workflow.Name)_TraceEnabledOverride")
                $override.Rule = $workflow
            }
        }
    }

    if($null -ne $workflow)
    {
        $override.Property = 'TraceEnabled'
        $override.Value = 'true'
        $override.Context = $target
        $override.DisplayName = "$($ManagementPackId)_$($workflow.Name)_TraceEnabledOverride"
        $mp.Verify()
        $mp.AcceptChanges()
        
        $Global:StatusLabel.Content = "RUNNING"
        $durationInSeconds = $durationInSeconds -as [int]
        $msservices = @("HealthService")
        Get-Service $msservices | Stop-Service -PassThru
        Get-Service $msservices | Start-Service -PassThru
        Start-Sleep -Seconds 1
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop WorkflowTrace
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\StopTracing.cmd"
        Remove-Item -Path "$env:WINDIR\Logs\OpsMgrTrace\*"
        Start-Sleep -Seconds 2
        cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -start WorkflowTrace -guid "$($Global:productPath)\etwscenarios\Scenario4.ctl" -f "$($env:WINDIR)\Logs\OpsMgrTrace\WorkflowTrace.etl" -ft 2 -flag 0x3FFFFFFF -level 4 -cir 999
        Write-OutputToLog "We are starting."
        $Global:OutputTextBlock.Text += "We are starting.\n"
        if($durationInSeconds -gt 0)
        {
            Start-Sleep -Seconds $durationInSeconds
            $Global:StatusLabel.Content = "STOPPING"
            cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop WorkflowTrace
            cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
            Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\WorkflowTrace.log" -Destination "$($Global:ZipOutput)\WorkflowTrace.log"
            Remove-SCOMManagementPack -ManagementPack $mp
            Write-OutputToLog "We finished."
            $Global:OutputTextBlock.Text += "We are finishing.\n"
            $Global:StatusLabel.Content = "FINISHED"
        }
    }
}

function StartWorkflowTracingStop()
{
    $ManagementPackId = "SCOMCustomMSCollectorWorkflowTracingMp"
    $Global:StatusLabel.Content = "STOPPING"
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\TraceLogSM.exe" -stop WorkflowTrace
    cmd.exe /c "$($Global:SCOMInstallDirectory)Tools\FormatTracing.cmd"
    Copy-Item -Path "$($env:WINDIR)\Logs\OpsMgrTrace\WorkflowTrace.log" -Destination "$($Global:ZipOutput)\WorkflowTrace.log"
    [Io.Compression.ZipFile]::CreateFromDirectory($Global:ZipOutput, "$($Global:ZipOutput)\..\output-$(Get-Date -format 'yyyy-M-dd').zip")
    if(-not (Get-Module | Where-Object {$_.Name -eq "OperationsManager"}))
    {
        Write-OutputToLog "The Operations Manager Module was not found...importing the Operations Manager Module"
        Import-Module OperationsManager
    }
    else
    {
        Write-OutputToLog "The Operations Manager Module is loaded"
    }
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup("localhost")
    $mp = $mg.GetManagementPacks($ManagementPackId)
    if($null -ne $mp)
    {
        Remove-SCOMManagementPack -ManagementPack $mp
    }
    Write-OutputToLog "We finished."
    $Global:OutputTextBlock.Text += "We finished.\n"
    $Global:StatusLabel.Content = "FINISHED"
}

function CollectSCOMData()
{
    $Global:StatusLabel.Content = "RUNNING"
    . "$($Global:scriptPath)\Products\SCOM\HealthCheck.ps1"
    $Global:StatusLabel.Content = "FINISHED"
}