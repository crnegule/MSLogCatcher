Function Get-IIS-Stuff {

    $Time = Get-Date
    
        Import-Module IISAdministration -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
        Import-Module WebAdministration -ErrorAction silentlycontinue -ErrorVariable +ErrorMessages
        . $scriptPath\General\GetIISEventLogs.ps1
        Get-IIS-EventLogs

        Foreach ($Message in $ErrorMessages) {
            $Time = Get-Date
            $ErroText = $Message.Exception.Message
            "$Time Exception Message: $ErroText" | Out-File $ToolLog -Append
        }    
}
