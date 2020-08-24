. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

$Global:OutputTextBlock = $xamlReader.FindName("OutputTextBlock")

$TraceDurationInSecondsTextBox = $xamlReader.FindName("TraceDurationInSecondsTextBox")
$TraceDurationInSecondsTextBox.Text = $Global:SecondsToSleepForTrace

$Global:StatusLabel = $xamlReader.FindName("StatusLabel")

$ScenarioComboBox = $xamlReader.FindName("ScenarioComboBox")
$ScenarioComboBox.Items.Add($Global:Scenario1) | Out-Null
$ScenarioComboBox.Items.Add($Global:Scenario2) | Out-Null

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

$CollectSCOMDataButton = $xamlReader.FindName("CollectSCOMDataButton")
$CollectSCOMDataButton.add_click({
    CollectSCOMData
})
