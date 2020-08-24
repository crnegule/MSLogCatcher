 ########################################################################################################################################################################
 #
 #   The original version of this script was written by Tim Culham of www.culham.net and there were additions by MBullwin from www.OpsConfig.com
 #   This is a version that we (CSS from Microsoft) are taking as a starting point and are adding (and will add) different other functionalities / data collections
 #
 ########################################################################################################################################################################

$StartTime = Get-Date

# Check if the OperationsManager Module is loaded
if(-not (Get-Module | Where-Object {$_.Name -eq "OperationsManager"}))
    {
    "The Operations Manager Module was not found...importing the Operations Manager Module"
    Import-module OperationsManager
    }
        else
	{
	"The Operations Manager Module is loaded"
	}

# Connect to localhost when running on the management server or define a server to connect to.
$connect = New-SCOMManagementGroupConnection –ComputerName localhost

# The Name and Location of are we going to save this Report
$ReportName = "$(get-date -format "yyyy-M-dd")-SCOM-HealthCheck.html"
$ReportPath = "$($Global:ZipOutput)\$ReportName"

# Create header for HTML Report
$Head = "<style>"
$Head +="BODY{background-color:#CCCCCC;font-family:Calibri,sans-serif; font-size: small;}"
$Head +="TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width: 98%;}"
$Head +="TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
$Head +="TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0; padding: 2px;}"
$Head +="</style>"


# Retrieve the name of the Operational Database and Data WareHouse Servers from the registry.
$reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\"
$OperationsManagerDBServer = $reg.DatabaseServerName
$OperationsManagerDWServer = $reg.DataWarehouseDBServerName
# If the value is empty in this key, then we'll use the Get-SCOMDataWarehouseSetting cmdlet.
If (!($OperationsManagerDWServer))
{$OperationsManagerDWServer = Get-SCOMDataWarehouseSetting | Select -expandProperty DataWarehouseServerName}

$OperationsManagerDBServer = $OperationsManagerDBServer.ToUpper()
$OperationsManagerDWServer = $OperationsManagerDWServer.ToUpper()

$ReportingURL = Get-SCOMReportingSetting | Select -ExpandProperty ReportingServerUrl
$WebConsoleURL = Get-SCOMWebAddressSetting | Select -ExpandProperty WebConsoleUrl
<#
# The number of days before Database Grooming
# These are my settings, I use this to determine if someone has changed something
# Feel free to comment this part out if you aren't interested
$AlertDaysToKeep = 2
$AvailabilityHistoryDaysToKeep = 2
$EventDaysToKeep = 1
$JobStatusDaysToKeep = 1
$MaintenanceModeHistoryDaysToKeep = 2
$MonitoringJobDaysToKeep = 2
$PerformanceDataDaysToKeep = 2
$StateChangeEventDaysToKeep = 2

# SCOM Agent Heartbeat Settings
$AgentHeartbeatInterval = 180
$MissingHeartbeatThreshold = 3
#>

# SQL Server Function to query the Operational Database Server
function Run-OpDBSQLQuery
{
    Param($sqlquery)

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$OperationsManagerDBServer;Database=OperationsManager;Integrated Security=True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $sqlquery
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = 300
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) | Out-Null
    $SqlConnection.Close()
    $DataSet.Tables[0]
}


# SQL Server Function to query the Data Warehouse Database Server
function Run-OpDWSQLQuery
{
    Param($sqlquery)

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$OperationsManagerDWServer;Database=OperationsManagerDW;Integrated Security=True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $sqlquery
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = 300
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) | Out-Null
    $SqlConnection.Close()
    $DataSet.Tables[0]
}


# Retrieve the Data for the Majority of the Report
# Truth is we probably don't need all of this data, but even on a busy environment it only takes a couple of mins to run.
Write-Host "Retrieving Agents"
$Global:OutputTextBlock.Text += "Retrieving Agents\n"
$Agents = Get-SCOMAgent
Write-Host "Retrieving Alerts"
$Global:OutputTextBlock.Text += "Retrieving Alerts\n"
$Alerts = Get-SCOMAlert
Write-Host "Retrieving Groups"
$Global:OutputTextBlock.Text += "Retrieving Groups\n"
$Groups = Get-SCOMGroup
Write-Host "Retrieving Management Group"
$Global:OutputTextBlock.Text += "Retrieving Management Group\n"
$ManagementGroup = Get-SCOMManagementGroup
Write-Host "Retrieving Management Packs"
$Global:OutputTextBlock.Text += "Retrieving Management Packs\n"
$ManagementPacks = Get-SCOMManagementPack
Write-Host "Retrieving Management Servers"
$Global:OutputTextBlock.Text += "Retrieving Management Servers\n"
$ManagementServers = Get-SCOMManagementServer
Write-Host "Retrieving Monitors"
$Global:OutputTextBlock.Text += "Retrieving Monitors\n"
$Monitors = Get-SCOMMonitor
Write-Host "Retrieving Rules"
$Global:OutputTextBlock.Text += "Retrieving Rules\n"
$Rules = Get-SCOMRule

# Check to see if the Reporting Server Site is OK 
$ReportingServerSite = New-Object System.Net.WebClient
$ReportingServerSite = [net.WebRequest]::Create($ReportingURL)
$ReportingServerSite.UseDefaultCredentials = $true
$ReportingServerStatus = $ReportingServerSite.GetResponse() | Select -expandProperty statusCode
# This code can convert the "OK" Result to an Integer, like 200
# (($web.GetResponse()).Statuscode) -as [int]

# Check to see if the Web Server Site is OK 
$WebConsoleSite = New-Object System.Net.WebClient
$WebConsoleSite = [net.WebRequest]::Create($WebConsoleURL)
$WebConsoleSite.UseDefaultCredentials = $true
$WebConsoleStatus = $WebConsoleSite.GetResponse() | Select -expandProperty statusCode

# SQL Server Function to query Size of the Database Server
$DatabaseSize = @"
select a.FILEID, 
[FILE_SIZE_MB]=convert(decimal(12,2),round(a.size/128.000,2)), 
[SPACE_USED_MB]=convert(decimal(12,2),round(fileproperty(a.name,'SpaceUsed')/128.000,2)), 
[FREE_SPACE_MB]=convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) , 
[GROWTH_MB]=convert(decimal(12,2),round(a.growth/128.000,2)), 
NAME=left(a.NAME,15), 
FILENAME=left(a.FILENAME,60) 
from dbo.sysfiles a
"@

#SQL Server Function to query Size of the TempDB
$TempDBSize =@"
USE tempdb 
select a.FILEID, 
[FILE_SIZE_MB]=convert(decimal(12,2),round(a.size/128.000,2)), 
[SPACE_USED_MB]=convert(decimal(12,2),round(fileproperty(a.name,'SpaceUsed')/128.000,2)), 
[FREE_SPACE_MB]=convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) , 
[GROWTH_MB]=convert(decimal(12,2),round(a.growth/128.000,2)), 
NAME=left(a.NAME,15), 
FILENAME=left(a.FILENAME,60) 
from dbo.sysfiles a
"@

#SQL Server Function to query the version of SQL
$SQLVersion =@"
SELECT  SERVERPROPERTY('productversion') AS "Product Version", SERVERPROPERTY('productlevel') AS "Service Pack", SERVERPROPERTY ('edition') AS "Edition"
"@

# Run the Size Query against the Operational Database and Data Warehouse Database Servers
$OPDBSize = Run-OpDBSQLQuery $DatabaseSize
$DWDBSize = Run-OpDWSQLQuery $DatabaseSize
$OPTPSize = Run-OpDBSQLQuery $TempDBSize
$DWTPSize = Run-OpDWSQLQuery $TempDBSize
$OPSQLVER = Run-OpDBSQLQuery $SQLVersion
$DWSQLVER = Run-OpDWSQLQuery $SQLVersion 

# Insert the Database Server details into the Report
$ReportOutput += "<h2>Database Servers</h2>"
$ReportOutput += "<p>Operational Database Server      :  $OperationsManagerDBServer</p>"
$ReportOutput += $OPSQLVER | Select "Product Version", "Service Pack", Edition | ConvertTo-Html -Fragment
$ReportOutput += "<p>Data Warehouse Database Server   :  $OperationsManagerDWServer</p>"
$ReportOutput += $DWSQLVER | Select "Product Version", "Service Pack", Edition | ConvertTo-Html -Fragment

# Insert the Size Results for the Operational Database into the Report
$ReportOutput += "<h3>$OperationsManagerDBServer Operations Manager DB</h4>"
$ReportOutput += $OPDBSize | Select Name, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, FILENAME | ConvertTo-HTML -fragment 
$ReportOutput += "<br></br>" 
$ReportOutput += "<h3>Operations Temp DB</h4>"
$ReportOutput += $OPTPSize | Select Name, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, FILENAME | ConvertTo-HTML -fragment 

# Insert the Size Results for the Data Warehouse Database and TempDB into the Report
$ReportOutput += "<br>"
$ReportOutput += "<h3>$OperationsManagerDWServer Data Warehouse DB</h4>"
$ReportOutput += $DWDBSize | Select Name, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, FILENAME | ConvertTo-HTML -fragment 
$ReportOutput += "<br></br>" 
$ReportOutput += "<h3>Data Warehouse Temp DB</h4>"
$ReportOutput += $DWTPSize | Select Name, FILE_SIZE_MB, SPACE_USED_MB, FREE_SPACE_MB, FILENAME | ConvertTo-HTML -fragment 

# SQL Query to find out how many State Changes there were yesterday
$StateChangesYesterday = @"
-- How Many State Changes Yesterday?:
select count(*) from StateChangeEvent
where cast(TimeGenerated as date) = cast(getdate()-1 as date)
"@

$StateChanges = Run-OpDBSQLQuery $StateChangesYesterday | Select -ExpandProperty Column1 | Out-String

$AllStats = @()

	    $StatSummary = New-Object psobject
        $StatSummary | Add-Member noteproperty "Open Alerts" (($Alerts | ? {$_.ResolutionState -ne 255}).count)
		$StatSummary | Add-Member noteproperty "Groups" ($Groups.Count)
  		$StatSummary | Add-Member noteproperty "Monitors" ($Monitors.Count)
		$StatSummary | Add-Member noteproperty "Rules" ($Rules.Count)
		$StatSummary | Add-Member noteproperty "State Changes Yesterday" ($StateChanges | Foreach {$_.TrimStart()} | Foreach {$_.TrimEnd()})

        $AllStats += $StatSummary


#SQL Query Top 10 Event generating computers
$TopEventGeneratingComputers = @"
SELECT top 10 LoggingComputer, COUNT(*) AS TotalEvents 
FROM EventallView 
GROUP BY LoggingComputer 
ORDER BY TotalEvents DESC
"@

#SQL Query number of Events Generated per day
$NumberOfEventsPerDay = @"
SELECT CASE WHEN(GROUPING(CONVERT(VARCHAR(20), TimeAdded, 101)) = 1) 
THEN 'All Days' 
ELSE CONVERT(VARCHAR(20), TimeAdded, 101) END AS DayAdded, 
COUNT(*) AS NumEventsPerDay 
FROM EventAllView 
GROUP BY CONVERT(VARCHAR(20), TimeAdded, 101) WITH ROLLUP 
ORDER BY DayAdded DESC
"@

#SQL Query Most Common Events by Publishername
$MostCommonEventsByPub = @"
SELECT top 25 Number AS "Event Number", Publishername, COUNT(*) AS TotalEvents 
FROM EventAllView 
GROUP BY Number, Publishername 
ORDER BY TotalEvents DESC
"@

#SQL Query the Number of Performance Insertions per Day
$NumberofPerInsertsPerDay = @"
SELECT CASE WHEN(GROUPING(CONVERT(VARCHAR(20), TimeSampled, 101)) = 1) 
THEN 'All Days' ELSE CONVERT(VARCHAR(20), TimeSampled, 101) 
END AS DaySampled, COUNT(*) AS NumPerfPerDay 
FROM PerformanceDataAllView 
GROUP BY CONVERT(VARCHAR(20), TimeSampled, 101) WITH ROLLUP 
ORDER BY DaySampled DESC
"@

#SQL Query the Most common perf insertions by perf counter name
$MostCommonPerfByN = @" 
select top 25 pcv.objectname, pcv.countername, count (pcv.countername) as total from 
performancedataallview as pdv, performancecounterview as pcv 
where (pdv.performancesourceinternalid = pcv.performancesourceinternalid) 
group by pcv.objectname, pcv.countername 
order by count (pcv.countername) desc
"@

#SQL Query the Top 25 Alerts by Alert Count
$MostCommonAByAC = @"
SELECT Top 25 AlertStringName, Name, SUM(1) AS 
AlertCount, SUM(RepeatCount+1) AS AlertCountWithRepeatCount 
FROM Alertview WITH (NOLOCK) 
GROUP BY AlertStringName, Name 
ORDER BY AlertCount DESC
"@

#SQL Query for Stale State Change Data
$StaleStateChangeData = @"
declare @statedaystokeep INT 
SELECT @statedaystokeep = DaysToKeep from PartitionAndGroomingSettings WHERE ObjectName = 'StateChangeEvent' 
SELECT COUNT(*) as 'Total StateChanges', 
count(CASE WHEN sce.TimeGenerated > dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as 'within grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-30,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 30 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-90,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 90 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-365,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 365 days' 
from StateChangeEvent sce
"@

#SQL Query Noisest monitors changing state in the past 7 days
$NoisyMonitorData = @"
select distinct top 25
m.DisplayName as MonitorDisplayName, 
m.Name as MonitorIdName, 
mt.typename AS TargetClass,
count(sce.StateId) as NumStateChanges  
from StateChangeEvent sce with (nolock) 
join state s with (nolock) on sce.StateId = s.StateId 
join monitorview m with (nolock) on s.MonitorId = m.Id 
join managedtype mt with (nolock) on m.TargetMonitoringClassId = mt.ManagedTypeId 
where m.IsUnitMonitor = 1 
  -- Scoped to within last 7 days 
AND sce.TimeGenerated > dateadd(dd,-7,getutcdate()) 
group by m.DisplayName, m.Name,mt.typename 
order by NumStateChanges desc
"@

#SQL Query Top 25 Monitors changing state by Object
$NoisyMonitorByObject =@"
select distinct top 25  
bme.DisplayName AS ObjectName, 
bme.Path, 
m.DisplayName as MonitorDisplayName, 
m.Name as MonitorIdName, 
mt.typename AS TargetClass,
count(sce.StateId) as NumStateChanges  
from StateChangeEvent sce with (nolock) 
join state s with (nolock) on sce.StateId = s.StateId 
join BaseManagedEntity bme with (nolock) on s.BasemanagedEntityId = bme.BasemanagedEntityId 
join MonitorView m with (nolock) on s.MonitorId = m.Id 
join managedtype mt with (nolock) on m.TargetMonitoringClassId = mt.ManagedTypeId 
where m.IsUnitMonitor = 1 
   -- Scoped to specific Monitor (remove the "--" below): 
   -- AND m.MonitorName like ('%HealthService%') 
   -- Scoped to specific Computer (remove the "--" below): 
   -- AND bme.Path like ('%sql%') 
   -- Scoped to within last 7 days 
AND sce.TimeGenerated > dateadd(dd,-7,getutcdate()) 
group by s.BasemanagedEntityId,bme.DisplayName,bme.Path,m.DisplayName,m.Name,mt.typename 
order by NumStateChanges desc
"@

#SQL Query Grooming Settings for the Operational Database
$OpsDBGrooming =@"
SELECT
ObjectName, 
GroomingSproc, 
DaysToKeep, 
GroomingRunTime,
DataGroomedMaxTime 
FROM PartitionAndGroomingSettings WITH (NOLOCK)
"@


#SQL Query DW DB Staging Tables
$DWDBStagingTables = @"
select count(*) AS "Alert Staging Table"  from Alert.AlertStage 
"@

$DWDBStagingTablesEvent =@"
select count (*) AS "Event Staging Table"  from Event.eventstage 
"@

$DWDBStagingTablesPerf =@"
select count (*) AS "Perf Staging Table"  from Perf.PerformanceStage 
"@

$DWDBStagingTablesState =@"
select count (*) AS "State Staging Table"  from state.statestage 
"@

#SQL Query DW Grooming Retention
$DWDBGroomingRetention =@"
select ds.datasetDefaultName AS 'Dataset Name', sda.AggregationTypeId AS 'Agg Type 0=raw, 20=Hourly, 30=Daily', sda.MaxDataAgeDays AS 'Retention Time in Days' 
from dataset ds, StandardDatasetAggregation sda 
WHERE ds.datasetid = sda.datasetid ORDER by "Retention Time in Days" desc
"@

#SQL function to Query the Top 25 largest tables in a database
$DWDBLargestTables =@"
SELECT TOP 25 
a2.name AS [tablename], (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved, 
a1.rows as row_count, a1.data * 8 AS data, 
(CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size, 
(CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused, 
(row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1, 
a3.name AS [schemaname] 
FROM (SELECT ps.object_id, SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows], 
SUM (ps.reserved_page_count) AS reserved, 
SUM (CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) 
ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END ) AS data, 
SUM (ps.used_page_count) AS used 
FROM sys.dm_db_partition_stats ps 
GROUP BY ps.object_id) AS a1 
LEFT OUTER JOIN (SELECT it.parent_id, 
SUM(ps.reserved_page_count) AS reserved, 
SUM(ps.used_page_count) AS used 
FROM sys.dm_db_partition_stats ps 
INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id) 
WHERE it.internal_type IN (202,204) 
GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id) 
INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id ) 
INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id) 
WHERE a2.type <> N'S' and a2.type <> N'IT'   
"@

#SQL Function to query and check backup status of SQL Databases
$SQLBackupStatus =@"
SELECT 
d.name, 
DATEDIFF(Day, COALESCE(MAX(b.backup_finish_date), d.create_date), GETDATE()) AS [DaysSinceBackup]
FROM 
sys.databases d
LEFT OUTER JOIN msdb.dbo.backupset b
ON d.name = b.database_name 
WHERE 
d.is_in_standby = 0 
AND source_database_id is null
AND d.name NOT LIKE 'tempdb'
AND (b.[type] IN ('D', 'I') OR b.[type] IS NULL)
GROUP BY 
d.name, d.create_date
"@

# Run additional SQL Queries against the Operational Database
$OPTOPALERT = Run-OpDBSQLQuery $TopEventGeneratingComputers
$OPNUMEPERDAY = Run-OpDBSQLQuery $NumberOfEventsPerDay
$OPMOSTCOMEVENT = Run-OpDBSQLQuery $MostCommonEventsByPub
$OPPERFIPERD = Run-OpDBSQLQuery $NumberofPerInsertsPerDay
$OPPERFIBYN = Run-OpDBSQLQuery $MostCommonPerfByN
$OPTOPALERTC = Run-OpDBSQLQuery $MostCommonAByAC
$OPSTALESTD = Run-OpDBSQLQuery $StaleStateChangeData
$OPNOISYMON = Run-OpDBSQLQuery $NoisyMonitorData
$OPNOISYMONOBJ = Run-OpDBSQLQuery $NoisyMonitorByObject 
$OPDBGROOM = Run-OpDBSQLQuery $OpsDBGrooming
$OPLARGTAB = Run-OpDBSQLQuery $DWDBLargestTables
$OPDBBACKUP = Run-OpDBSQLQuery $SQLBackupStatus

#Run additional SQL Queries against the DW DB
$DWDBSGTB = Run-OpDWSQLQuery $DWDBStagingTables
$DWDBSGTBEV = Run-OpDWSQLQuery $DWDBStagingTablesEvent
$DWDBSGTBPE = Run-OpDWSQLQuery $DWDBStagingTablesPerf
$DWDBSGTBST = Run-OpDWSQLQuery $DWDBStagingTablesState
$DWDBGRET = Run-OpDWSQLQuery $DWDBGroomingRetention
$DWDBLARGETAB = Run-OpDWSQLQuery $DWDBLargestTables
$DWDBBACKUP = Run-OpDWSQLQuery $SQLBackupStatus

#Output to HTML Report

$ReportOutput += "<h2>Operational Database Health</h2>"
$ReportOutput += "<h3>Operations Database Backup Status</h3>"
$ReportOutput += $OPDBBACKUP | Select name, DaysSinceBackup | ConvertTo-HTML -Fragment
$ReportOutput += "<h3>Operations Database Top 25 Largest Tables</h3>"
$ReportOutput += $OPLARGTAB | Select tablename, reserved, row_count, data, index_size, unused |ConvertTo-Html -Fragment
$ReportOutput += "<h3>Number of Events Generated Per Day</h3>"
$ReportOutput += $OPNUMEPERDAY | Select NumEventsPerDay, DayAdded | ConvertTo-HTML -Fragment
$ReportOutput += "<h3>Top 10 Event Generating Computers</h3>"
$ReportOutput += $OPTOPALERT | Select LoggingComputer, TotalEvents | ConvertTo-HTML -Fragment
$ReportOutput += "<h3>Top 25 Events By Publisher</h3>"
$ReportOutput += $OPMOSTCOMEVENT | Select "Event Number", Publishername, TotalEvents | ConvertTo-Html -Fragment
$ReportOutput += "<h3>Number of Perf Insertions Per Day</h3>"
$ReportOutput += $OPPERFIPERD | Select DaySampled, NumPerfPerDay | ConvertTo-Html -Fragment
$ReportOutput += "<h3>Top 25 Perf Insertions by Object/Counter Name</h3>"
$ReportOutput += $OPPERFIBYN | Select objectname, countername, total | ConvertTo-Html -Fragment
$ReportOutput += "<h3>Top 25 Alerts by Alert Count</h3>"
$ReportOutput += $OPTOPALERTC | Select AlertStringName, Name, AlertCount, AlertCountWithRepeatCount | ConvertTo-Html -Fragment



# Get the alerts with a repeat count higher than the variable $RepeatCount
$RepeatCount = 200

$ReportOutput += "<br>"
$ReportOutput += "<h3>Alerts with a Repeat Count higher than $RepeatCount</h3>"


# Produce a table of all Open Alerts above the repeatcount and add it to the Report
$ReportOutput += $Alerts | ? {$_.RepeatCount -ge $RepeatCount -and $_.ResolutionState -ne 255} | select Name, Category, NetBIOSComputerName, RepeatCount | sort repeatcount -desc | ConvertTo-HTML -fragment

#Output to HTML report
$ReportOutput += "<h3>Stale State Change Data</h3>"
$ReportOutput += $OPSTALESTD | Select "Total StateChanges", "within grooming retention", "> grooming retention","> 30 days","> 90 days","> 365 days"| ConvertTo-Html -Fragment
$ReportOutput += "<h3>Top 25 Monitors Changing State in the last 7 Days</h3>"
$ReportOutput += $OPNOISYMON | Select MonitorDisplayName, MonitorIdName, TargetClass, NumStateChanges | ConvertTo-Html -Fragment 
$ReportOutput += "<h3>Top 25 Monitors Changing State By Object</h3>"
$ReportOutput += $OPNOISYMONOBJ | Select ObjectName, Path, MonitorDisplayName, MonitorIdName,TargetClass, NumStateChanges | ConvertTo-Html -Fragment 
$ReportOutput += "<h3>Operations Database Grooming History</h3>"
$ReportOutput += $OPDBGROOM | Select ObjectName, GroomingSproc, DaysToKeep, GroomingRunTime,DataGroomedMaxTime | ConvertTo-HTML -Fragment 

# SQL Query to find out what Grooming Jobs have run in the last 24 hours
$DidGroomingRun = @"
-- Did Grooming Run?:
SELECT [InternalJobHistoryId]
      ,[TimeStarted]
      ,[TimeFinished]
      ,[StatusCode]
      ,[Command]
      ,[Comment]
FROM [dbo].[InternalJobHistory]
WHERE [TimeStarted] >= DATEADD(day, -2, GETDATE())
Order by [TimeStarted]
"@

# Produce a table of Grooming History and add it to the Report
$ReportOutput += "<h3>Grooming History From The Past 48 Hours</h3>"
$ReportOutput += Run-OpDBSQLQuery $DidGroomingRun InternalJobHistoryId, TimeStarted, TimeFinished, StatusCode, Command, Comment | Select | ConvertTo-HTML -fragment

#Produce Table of DW DB Health
$ReportOutput +="<h2>Data Warehouse Database Health</h2>"
$ReportOutput +="<h3>Data Warehouse DB Backup Status</h3>"
$ReportOutput +=$DWDBBACKUP | Select name, DaysSinceBackup | ConvertTo-Html -Fragment
$ReportOutput +="<h3>Data Warehouse Top 25 Largest Tables</h3>"
$ReportOutput +=$DWDBLARGETAB | Select tablename, reserved, row_count, data, index_size, unused |ConvertTo-Html -fragment
$ReportOutput +="<h3>Data Warehouse Staging Tables</h3>"
$ReportOutput +=$DWDBSGTB | Select "Alert Staging Table", Table | ConvertTo-Html -Fragment
$ReportOutput +=$DWDBSGTBEV | Select "Event Staging Table", Table | ConvertTo-Html -Fragment
$ReportOutput +=$DWDBSGTBPE | Select "Perf Staging Table", Table | ConvertTo-Html -Fragment
$ReportOutput +=$DWDBSGTBST | Select "State Staging Table", Table| ConvertTo-Html -Fragment
$ReportOutput +="<h3>Data Warhouse Grooming Retention</h3>"
$ReportOutput +=$DWDBGRET | Select "Dataset Name", "Agg Type 0=raw, 20=Hourly, 30=Daily","Retention Time in Days"| ConvertTo-Html -Fragment

# Insert the Results for the Number of Management Servers into the Report
$ReportOutput += "<p>Number of Management Servers     :  $($ManagementServers.count)</p>"

# Retrieve the data for the Management Servers
$ReportOutput += "<br>"
$ReportOutput += "<h2>Management Servers</h2>"

$AllManagementServers = @()

ForEach ($ManagementServer in $ManagementServers)
{
    # Find out the Server Uptime for each of the Management Servers
    #Original query referenced -computer $ManagementServer.Name this was an error I modified to .Displayname to fix#
	$lastboottime = (Get-WmiObject -Class Win32_OperatingSystem -computername $ManagementServer.DisplayName).LastBootUpTime
	$sysuptime = (Get-Date) – [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
	$totaluptime = "” + $sysuptime.days + “ days ” + $sysuptime.hours + “ hours ” + $sysuptime.minutes + “ minutes ” + $sysuptime.seconds + “ seconds”

    # Find out the Number of WorkFlows Running on each of the Management Servers
    $perfWorkflows = Get-Counter -ComputerName $ManagementServer.DisplayName -Counter "\Health Service\Workflow Count" -SampleInterval 1 -MaxSamples 1
    
    # The Performance Counter seems to return a lot of other characters and spaces...I only want the number of workflows, let's dump the rest
    [int]$totalWorkflows = $perfWorkflows.readings.Split(':')[-1] | Foreach {$_.TrimStart()} | Foreach {$_.TrimEnd()}

	$ManagementServerProperty = New-Object psobject
	$ManagementServerProperty | Add-Member noteproperty "Management Server" ($ManagementServer.DisplayName)
  	$ManagementServerProperty | Add-Member noteproperty "Health State" ($ManagementServer.HealthState)
	$ManagementServerProperty | Add-Member noteproperty "Version" ($ManagementServer.Version)
	$ManagementServerProperty | Add-Member noteproperty "Action Account" ($ManagementServer.ActionAccountIdentity)
	$ManagementServerProperty | Add-Member noteproperty "System Uptime" ($totaluptime)
	$ManagementServerProperty | Add-Member noteproperty "Workflows" ($totalWorkflows)
    $AllManagementServers += $ManagementServerProperty
}

# Insert the Results for the Management Servers into the Report
$ReportOutput += $AllManagementServers | Select "Management Server", "Health State", "Version", "Action Account", "System Uptime", "Workflows" | Sort-Object "Management Server" | ConvertTo-HTML -fragment 

# Insert the Results for the Stats and State Changes into the Report
$ReportOutput += "<br>"
$ReportOutput += "<h2>Daily KPI</h2>"
$ReportOutput += $AllStats | Select "Open Alerts", "Groups", "Monitors", "Rules", "State Changes Yesterday" | ConvertTo-HTML -fragment

# Retrieve and Insert the Results for the Management Packs that have been modified into the Report
Write-Host "Checking for Management Packs that have been modified in the last 24 hours"

$ReportOutput += "<br>"
$ReportOutput += "<h2>Management Packs Modified in the Last 24 Hours</h2>"
    If (!($ManagementPacks | where {$_.LastModified -ge (Get-Date).addhours(-24)}))
        {
            $ReportOutput += "<p>No Management Packs have been updated in the last 24 hours</p>"
        }
            Else
        {
            $ReportOutput += $ManagementPacks | where {$_.LastModified -ge (Get-Date).addhours(-24)} | select Name, LastModified | ConvertTo-HTML -fragment
        }


# Retrieve and Insert the Results for the Default Management Pack into the Report
# This 'should be empty'...don't store stuff here!
Write-Host "Checking for the Default Management Pack for Overrides"
$ReportOutput += "<br>"
$ReportOutput += "<h2>The Default Management Pack</h2>"

# Excluding these 2 ID's as they are part of the default MP for DefaultUser and Language Code Overrides
$excludedID = "5a67584f-6f63-99fc-0d7a-55587d47619d", "e358a914-c851-efaf-dda9-6ca5ef1b3eb7"
$defaultMP = $ManagementPacks | where {$_.Name -match "Microsoft.SystemCenter.OperationsManager.DefaultUser"}
##Changed below line for compat with PowerShell 2.0
##If (!($defaultMP.GetOverrides() | ? {$_.ID -notin $excludedID}))
If (!($defaultMP.GetOverrides() | ? {$excludedID -NotContains $_.ID}))
    {
        $ReportOutput += "<p>There are no Overrides being Stored in the Default Management Pack</p>"
    }
        Else
    {
        
        ##Changed below line for compat with PowerShell 2.0
        #$foundOverride = Get-SCOMClassInstance -id ($defaultMP.GetOverrides() | ? {$_.ID -notin $excludedID -AND $_.ContextInstance -ne $guid} | select -expandproperty ContextInstance -ea SilentlyContinue)
         $foundOverride = Get-SCOMClassInstance -id ($defaultMP.GetOverrides() | ? {$excludedID -NotContains $_.ID -AND $_.ContextInstance -ne $guid} | select -expandproperty ContextInstance -ea SilentlyContinue)


$ReportOutput += "<p>Found overrides against the following targets: $foundOverride.Displayname</p>"
##PowerShell 2.0 Compat
##$ReportOutput += $($defaultMP.GetOverrides() | ? {$_.ID -notin $excludedID} | Select Name, Property, Value, LastModified, TimeAdded) | ConvertTo-HTML -fragment
$ReportOutput += $($defaultMP.GetOverrides() | ? {$excludedID -NotContains $_.ID} | Select Name, Property, Value, LastModified, TimeAdded) | ConvertTo-HTML -fragment

}



# Show all Agents that are in an Uninitialized State
Write-Host "Checking for Uninitialized Agents"

$ReportOutput += "<br>"
$ReportOutput += "<h2>Uninitialized Agents</h2>"
    If (!($Agents | where {$_.HealthState -eq "Uninitialized"} | select Name))
    {
        $ReportOutput += "<p>No Agents are in the Uninitialized State</p>"
    }
        Else
    {
        $ReportOutput += $Agents | where {$_.HealthState -eq "Uninitialized"} | select Name | ConvertTo-HTML -fragment
    }


# Show a Summary of all Agents States
$healthy = $uninitialized = $warning = $critical = 0

Write-Host "Checking Agent States"

$ReportOutput += "<br>"
$ReportOutput += "<h3>Agent Stats</h3>"

switch ($Agents | Select-Object HealthState ) {
	{$_.HealthState -like "Success"} {$healthy++}
	{$_.HealthState -like "Uninitialized"} {$uninitialized++}
	{$_.HealthState -like "Warning"}  {$warning++}
	{$_.HealthState -like "Error"} {$critical++}
}
$totalagents = ($healthy + $warning + $critical + $uninitialized)

$AllAgents = @()

	    $iAgent = New-Object psobject
        $iAgent | Add-Member noteproperty "Agents Healthy" ($healthy)
		$iAgent | Add-Member noteproperty "Agents Warning" ($warning)
  		$iAgent | Add-Member noteproperty "Agents Critical" ($critical)
		$iAgent | Add-Member noteproperty "Agents Uninitialized" ($uninitialized)
		$iAgent | Add-Member noteproperty "Total Agents" ($totalagents)

        $AllAgents += $iAgent

$ReportOutput += $AllAgents | Select "Agents Healthy", "Agents Warning", "Agents Critical", "Agents Uninitialized", "Total Agents" | ConvertTo-HTML -fragment

# Agent Pending Management States
Write-Host "Checking Agent Pending Management States"

$ReportOutput += "<br>"
$ReportOutput += "<h3>Agent Pending Management Summary</h3>"

$pushInstall = $PushInstallFailed = $ManualApproval = $RepairAgent = $RepairFailed = $UpdateFailed = 0

$agentpending = Get-SCOMPendingManagement
switch ($agentpending | Select-Object AgentPendingActionType ) {
	{$_.AgentPendingActionType -like "PushInstall"} {$pushInstall++}
	{$_.AgentPendingActionType -like "PushInstallFailed"} {$PushInstallFailed++}
	{$_.AgentPendingActionType -like "ManualApproval"}  {$ManualApproval++}
	{$_.AgentPendingActionType -like "RepairAgent"} {$RepairAgent++}
	{$_.AgentPendingActionType -like "RepairFailed"} {$RepairFailed++}
	{$_.AgentPendingActionType -like "UpdateFailed"} {$UpdateFailed++}

}

$AgentsPending = @()

	    $AgentSummary = New-Object psobject
        $AgentSummary | Add-Member noteproperty "Push Install" ($pushInstall)
		$AgentSummary | Add-Member noteproperty "Push Install Failed" ($PushInstallFailed)
  		$AgentSummary | Add-Member noteproperty "Manual Approval" ($ManualApproval)
		$AgentSummary | Add-Member noteproperty "Repair Agent" ($RepairAgent)
		$AgentSummary | Add-Member noteproperty "Repair Failed" ($RepairFailed)
		$AgentSummary | Add-Member noteproperty "Update Failed" ($UpdateFailed)

        $AgentsPending += $AgentSummary

# Produce a table of all Agent Pending Management States and add it to the Report
$ReportOutput += $AgentsPending | Select "Push Install", "Push Install Failed", "Manual Approval", "Repair Agent", "Repair Failed", "Update Failed" | ConvertTo-HTML -fragment

$ReportOutput += "<br>"
$ReportOutput += "<h2>Alerts</h2>"

$AlertsAll = ($Alerts | ? {$_.ResolutionState -ne 255}).Count
$AlertsWarning = ($Alerts | ? {$_.Severity -eq "Warning" -AND $_.ResolutionState -ne 255}).Count
$AlertsError = ($Alerts | ? {$_.Severity -eq "Error" -AND $_.ResolutionState -ne 255}).Count
$AlertsInformation = ($Alerts | ? {$_.Severity -eq "Information" -AND $_.ResolutionState -ne 255}).Count
$Alerts24hours = ($Alerts | ? {$_.TimeRaised -ge (Get-Date).addhours(-24) -AND $_.ResolutionState -ne 255}).count

$AllAlerts = @()


	    $AlertSeverity = New-Object psobject
		$AlertSeverity | Add-Member noteproperty "Warning" ($AlertsWarning)
  		$AlertSeverity | Add-Member noteproperty "Error" ($AlertsError)
		$AlertSeverity | Add-Member noteproperty "Information" ($AlertsInformation)
		$AlertSeverity | Add-Member noteproperty "Last 24 Hours" ($Alerts24hours)
		$AlertSeverity | Add-Member noteproperty "Total Open Alerts" ($AlertsAll)
        $AllAlerts += $AlertSeverity


# Produce a table of all alert counts for warning, error, information, Last 24 hours and Total Alerts and add it to the Report
$ReportOutput += $AllAlerts | Select "Warning", "Error", "Information", "Last 24 Hours", "Total Open Alerts" | ConvertTo-HTML -fragment

<#
# Check if the Action Account is a Local Administrator on Each Management Server
# This will only work if the account is a member of the Local Administrators Group directly.
# If it has access by Group Membership, you can look for that Group instead
# $ActionAccount = "YourGrouptoCheck"
# Then replace all 5 occurrences below of $ManagementServer.ActionAccountIdentity with $ActionAccount

Write-Host "Checking if the Action Account is a member of the Local Administrators Group for each Management Server"

$ReportOutput += "<br>"
$ReportOutput += "<h2>SCOM Action Account</h2>"

ForEach ($ms in $ManagementServers.DisplayName | sort DisplayName)
{
$admins = @()
$group =[ADSI]"WinNT://$ms/Administrators" 
$members = @($group.psbase.Invoke("Members"))
$members | foreach {
 $obj = new-object psobject -Property @{
 Server = $Server
 Admin = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
 }
 $admins += $obj
 }

 If ($admins.admin -match $ManagementServer.ActionAccountIdentity)
 {
 # Write-Host "The user $($ManagementServer.ActionAccountIdentity) is a Local Administrator on $ms"
 $ReportOutput += "<p>The user $($ManagementServer.ActionAccountIdentity) is a Local Administrator on $ms</p>"
 }
 Else
 {
 # Write-Host "The user $($ManagementServer.ActionAccountIdentity) is NOT a Local Administrator on $ms"
 $ReportOutput += "<p><span style=`"color: `#CC0000;`">The user $($ManagementServer.ActionAccountIdentity) is NOT a Local Administrator on $ms</span></p>"
 }
}
#>



# Objects in Maintenance Mode

#SQL Query Servers in MMode
$ServersInMM =@"
select DisplayName from dbo.MaintenanceMode mm
join dbo.BaseManagedEntity bm on mm.BaseManagedEntityId = bm.BaseManagedEntityId
where Path is NULL and IsInMaintenanceMode = 1
"@

$OpsDBSIMM = Run-OpDBSQLQuery $ServersInMM

$ReportOutput += "<br>"
$ReportOutput += "<h2>Servers in Maintenance Mode</h2>"

If (!($OpsDBSIMM))
    {
    $ReportOutput += "<p>There are no objects in Maintenance Mode</p>"
    }
    Else
    {
    $ReportOutput += $OpsDBSIMM | Select DisplayName | ConvertTo-HTML -fragment
    }

<#
# Global Grooming Settings
# Simple comparisons against the values set at the beginning of this script
# I use this to see if anyone has changed the settings. So set the values at the top of this script to match the values that your environment 'should' be set to.

$ReportOutput += "<br>"
$ReportOutput += "<h2>SCOM Global Settings</h2>"


$SCOMDatabaseGroomingSettings = Get-SCOMDatabaseGroomingSetting


If ($SCOMDatabaseGroomingSettings.AlertDaysToKeep -ne $AlertDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Alert Days to Keep has been changed! Reset back to $AlertDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Alert Days is correctly set to $AlertDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.AvailabilityHistoryDaysToKeep -ne $AvailabilityHistoryDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Availability History Days has been changed! Reset back to $AvailabilityHistoryDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Availability History Days is correctly set to $AvailabilityHistoryDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.EventDaysToKeep -ne $EventDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Event Days has been changed! Reset back to $EventDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Event Days is correctly set to $EventDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.JobStatusDaysToKeep -ne $JobStatusDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Job Days (Task History) has been changed! Reset back to $JobStatusDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Job Days (Task History) is correctly set to $JobStatusDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.MaintenanceModeHistoryDaysToKeep -ne $MaintenanceModeHistoryDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Maintenance Mode History has been changed! Reset back to $MaintenanceModeHistoryDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Maintenance Mode History is correctly set to $MaintenanceModeHistoryDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.MonitoringJobDaysToKeep -ne $MonitoringJobDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Monitoring Job Data has been changed! Reset back to $MonitoringJobDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Monitoring Job Data is correctly set to $MonitoringJobDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.PerformanceDataDaysToKeep -ne $PerformanceDataDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">Performance Data has been changed! Reset back to $PerformanceDataDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>Performance Data is correctly set to $PerformanceDataDaysToKeep</p>"}

If ($SCOMDatabaseGroomingSettings.StateChangeEventDaysToKeep -ne $StateChangeEventDaysToKeep)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">State Change Data has been changed! Reset back to $StateChangeEventDaysToKeep</span></p>"}
    Else {$ReportOutput += "<p>State Change Data is correctly set to $StateChangeEventDaysToKeep</p>"}


# SCOM Agent Heartbeat Settings
$HeartBeatSetting = Get-SCOMHeartbeatSetting

If ($HeartBeatSetting.AgentHeartbeatInterval -ne 180 -AND $HeartBeatSetting.MissingHeartbeatThreshold -ne 3)
    {$ReportOutput += "<p><span style=`"color: `#CC0000;`">The HeartBeat Settings have been changed! Reset back to $AgentHeartbeatInterval and $MissingHeartbeatThreshold</span></p>"}
    Else {$ReportOutput += "<p>The HeartBeat Settings are correctly set to Interval: $AgentHeartbeatInterval and Missing Threshold: $MissingHeartbeatThreshold</p>"}
#>
# How long did this script take to run?
$EndTime=Get-Date
$TotalRunTime=$EndTime-$StartTime

# Add the time to the Report
$ReportOutput += "<br>"
$ReportOutput += "<p>Total Script Run Time: $($TotalRunTime.hours) hrs $($TotalRunTime.minutes) min $($TotalRunTime.seconds) sec</p>"

# Close the Body of the Report
$ReportOutput += "</body>"

Write-Host "Saving HTML Report to $ReportPath"

# Save the Final Report to a File
ConvertTo-HTML -head $Head -body "$ReportOutput" | Out-File $ReportPath

# A bit of cleanup
Clear-Variable Agents, Alerts, Groups, ManagementGroup, ManagementPacks, ManagementServer, Monitors, Rules, ReportOutput, StartTime, EndTime, TotalRunTime, SCOMDatabaseGroomingSettings