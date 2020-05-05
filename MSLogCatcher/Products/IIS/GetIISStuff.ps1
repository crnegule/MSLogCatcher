Function Get-IIS-Stuff {

    $IISTime = Get-Date
    
        Import-Module IISAdministration -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
        Import-Module WebAdministration -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
        . $scriptPath\Products\IIS\GetIISEventLogs.ps1
        Get-IIS-EventLogs

        Foreach ($Message in $ErrorMessages) {
            $IISTime = Get-Date
            $ErroText = $Message.Exception.Message
            "$IISTime Exception Message: $ErroText" | Out-File $ToolLog -Append
        }    
}
