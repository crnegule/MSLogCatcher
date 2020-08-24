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
    try
    {
        . "$scriptPath\Products\$($product.Name)\UI.ps1"
    }
    catch
    {
        # may add something here in the future
    }
}

$xamlReader.Add_Closing({
    $timestamp = Get-Date -format "yyyy-M-dd_HH-mm-ss"
    Add-Type -assembly "System.Io.Compression.FileSystem"
    [Io.Compression.ZipFile]::CreateFromDirectory($Global:ZipOutput, "$($Global:ZipOutput)\..\output-$($timestamp).zip")
    Remove-Item "$($Global:ZipOutput)\*" -Recurse -Force
    Write-Host "ZIP File to send is: $($Global:ZipOutput)\..\output-$($timestamp).zip"
})
$xamlReader.ShowDialog()