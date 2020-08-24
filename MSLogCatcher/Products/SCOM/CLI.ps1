. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

if($Global:CollectLogs)
{
    CollectSCOMData
}

if([string]::IsNullOrEmpty($Global:CurrentScenario) -eq $false)
{
    switch ($Global:CurrentScenario)
    {
        $Global:Scenario1
        {
            StartCommunicationTracing($Global:SecondsToSleepForTrace)
        }
        $Global:Scenario2
        {
            StartSubscriptionTracing($Global:SecondsToSleepForTrace)
        }
        $Global:Scenario3
        {
            StartConfigAndWorkflowLoadingTracing($Global:SecondsToSleepForTrace)
        }
    }
}