. $scriptPath\Products\SCOM\Defaults.ps1
. $scriptPath\Products\SCOM\Functions.ps1

$scsmScenario_1Button = $xamlReader.FindName("SCSMScenario_1Button")

$scsmScenario_1Button.add_click({
    StartCommunicationTracing;
})


