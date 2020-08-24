. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

$Global:OutputTextBlock = $xamlReader.FindName("OutputTextBlock")

$TraceDurationInSecondsTextBox = $xamlReader.FindName("TraceDurationInSecondsTextBox")
$TraceDurationInSecondsTextBox.Text = $Global:SecondsToSleepForTrace

$StopTraceButton = $xamlReader.FindName("StopTraceButton")
$StopTraceButton.add_click({
    switch ($Global:CurrentScenario)
    {
        $Global:Scenario1
        {
            StartCommunicationTracingStop
        }
        $Global:Scenario2
        {
            StartSubscriptionTracingStop
        }
        $Global:Scenario3
        {
            StartConfigAndWorkflowLoadingTracingStop
        }
    }
    $Global:CurrentScenario = ""
})

$durationSeconds = $Global:SecondsToSleepForTrace -as [int]
if($durationSeconds -gt 0)
{
    $StopTraceButton.IsEnabled = $false
}
else
{
    $StopTraceButton.IsEnabled = $true
}

$TraceDurationInSecondsTextBox.Add_TextChanged({
    if([string]::IsNullOrEmpty($TraceDurationInSecondsTextBox.Text) -eq $false)
    {
        $durationSeconds = $TraceDurationInSecondsTextBox.Text -as [int]
        if($durationSeconds -gt 0)
        {
            $StopTraceButton.IsEnabled = $false
        }
        else
        {
            $StopTraceButton.IsEnabled = $true
        }
    }
})

$Global:StatusLabel = $xamlReader.FindName("StatusLabel")

$ScenarioComboBox = $xamlReader.FindName("ScenarioComboBox")
$ScenarioComboBox.Items.Add($Global:Scenario1) | Out-Null
$ScenarioComboBox.Items.Add($Global:Scenario2) | Out-Null
$ScenarioComboBox.Items.Add($Global:Scenario3) | Out-Null

$StartTraceButton = $xamlReader.FindName("StartTraceButton")
$StartTraceButton.add_click({
    switch ($ScenarioComboBox.SelectedValue)
    {
        $Global:Scenario1
        {
            $Global:CurrentScenario = $Global:Scenario1
            StartCommunicationTracing($TraceDurationInSecondsTextBox.Text)
        }
        $Global:Scenario2
        {
            $Global:CurrentScenario = $Global:Scenario2
            StartSubscriptionTracing($TraceDurationInSecondsTextBox.Text)
        }
        $Global:Scenario3
        {
            $Global:CurrentScenario = $Global:Scenario3
            StartConfigAndWorkflowLoadingTracing($TraceDurationInSecondsTextBox.Text)
        }
    }
})

$CollectSCOMDataButton = $xamlReader.FindName("CollectSCOMDataButton")
$CollectSCOMDataButton.add_click({
    CollectSCOMData
})
