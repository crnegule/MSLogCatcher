. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

$traceCommunicationButton = $xamlReader.FindName("HSCommunicationScenarioButton")

$traceCommunicationButton.add_click({
    StartCommunicationTracing;
})
