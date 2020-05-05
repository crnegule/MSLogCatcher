
  Function Get-IIS-EventLogs {

    $Global:IISEventLogs = Get-WinEvent -ListLog * | Where-Object {$_.LogName  -Like "Application*" -OR $_.LogName  -Like "Security*" -OR $_.LogName  -Like "Setup*" -OR $_.LogName  -Like "System*"  -OR $_.LogName  -Like "*IIS*" -OR $_.LogName  -Like "*CAPI2*"  }| Where-Object {$_.IsEnabled  -eq "True"} 

}