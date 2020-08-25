. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

$viewModel = New-Object PSObject -Property @{OutputLogData = Get-Content -Path $Global:ToolLog }
$xamlReader.DataContext = $viewModel

$Global:OutputTextBlock = $xamlReader.FindName("OutputTextBlock")

$CustomInputTextBox = $xamlReader.FindName("CustomInputTextBox")

$TraceDurationInSecondsTextBox = $xamlReader.FindName("TraceDurationInSecondsTextBox")
$TraceDurationInSecondsTextBox.Text = $Global:SecondsToSleepForTrace

$StopTraceButton = $xamlReader.FindName("StopTraceButton")
$StopTraceButton.Add_Click({
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
        $Global:Scenario4
        {
            StartWorkflowTracingStop
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
$ScenarioComboBox.Items.Add($Global:Scenario4) | Out-Null

$ScenarioComboBox.Add_DropDownClosed({
    
    switch ($ScenarioComboBox.SelectedValue)
    {
        $Global:Scenario4
        {
            $CustomInputTextBox.Text = "Enter the (internal) name (not DisplayName) of the Workflow here ..."
            $CustomInputTextBox.IsEnabled = $true
        }
        default
        {
            $CustomInputTextBox.Text = "Depending on the selected scenario, we might need custom input here"
            $CustomInputTextBox.IsEnabled = $false
        }
    }
})

$StartTraceButton = $xamlReader.FindName("StartTraceButton")
$StartTraceButton.Add_Click({
    switch ($ScenarioComboBox.SelectedValue)
    {
        $Global:Scenario1
        {
            $Global:CurrentScenario = $Global:Scenario1
            StartCommunicationTracing($TraceDurationInSecondsTextBox.Text.Trim())
        }
        $Global:Scenario2
        {
            $Global:CurrentScenario = $Global:Scenario2
            StartSubscriptionTracing($TraceDurationInSecondsTextBox.Text.Trim())
        }
        $Global:Scenario3
        {
            $Global:CurrentScenario = $Global:Scenario3
            StartConfigAndWorkflowLoadingTracing($TraceDurationInSecondsTextBox.Text.Trim())
        }
        $Global:Scenario4
        {
            $Global:CurrentScenario = $Global:Scenario4
            StartWorkflowTracing -workflowName $CustomInputTextBox.Text.Trim() -durationInSeconds $TraceDurationInSecondsTextBox.Text.Trim()
        }
    }
})

$CollectSCOMDataButton = $xamlReader.FindName("CollectSCOMDataButton")
$CollectSCOMDataButton.Add_Click({
    CollectSCOMData

    $xamlReader.Dispatcher.Invoke(
        [action]{$OutputTextBlock.AddText("$(Get-Content -Path $Global:ToolLog)`n")},
        "Render"
    )
})
