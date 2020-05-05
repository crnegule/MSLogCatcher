Add-Type -AssemblyName PresentationFramework 
[string]$formDefinition = Get-Content -Path "$scriptPath\General\Main.xaml"
[string]$fullFormDefinition = ""
foreach($formItem in Get-Content -Path "$scriptPath\Products\*\Form.xaml")
{
    $fullFormDefinition += $formItem
}
[xml]$form = $formDefinition.Replace("##TABITEMSTOINSERT##", $fullFormDefinition)
$nodeReader = (New-Object System.Xml.XmlNodeReader $form)
$Global:xamlReader = [Windows.Markup.XamlReader]::Load($nodeReader) 

foreach($product in Get-ChildItem "$scriptPath\Products")
{
    try {
        . "$scriptPath\Products\$($product.Name)\UI.ps1"
    }
    catch { }
}

$xamlReader.ShowDialog()