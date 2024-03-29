<#
#=================================================================================
# Script test to setup SNOW incidents using SCOM alert data
#
#  Authors: Steven Brown, Kevin Justin, Joe Kelly
#  v1.0
#=================================================================================

# Global required parameters for ServiceNow (SNow) incident creation

From SCOM:
AlertName parameter is specified in the channel as $Data[Default='Not Present']/Context/DataItem/AlertName$
AlertID can help link the alert to check for the alert to parse out $HostName, as it can reside in multiple alert properties
AlertID translates to $Data/Context/DataItem/AlertId$

# Additional fields https://blog.tyang.org/2012/01/29/command-line-parameters-for-scom-command-notification-channel/

# Find and replace various variables before running

# Setup SNOW Event Name standard
Example SNOWAlertName
	$SNOWAlertName = "<Org> <Team> SCOM Test Event - $Alert"
Example SNOWAlertName
	$SNOWAlertName = "<ORG> <Team> SCOM Event - $AlertName"
Example SNOWAlertName
	$SNOWAlertName = "##CUSTOMER## SCOM Event - $AlertName"

# Replace these variables with valid values:
##CUSTOMER##
##ServiceNowURL##

# If required, add proxy URL for REST injection
##Proxy##

Example ##Proxy##
http:/yourproxyhere.com:8080"

# Replace CallerID
##CallerID##

Example $CallerId = "##CallerID##"

Example $CallerID = "13ad1d814fb68c25038e92468c676063c"

Hard coded variables for ServiceNow (SNow) for CallerId, URL, and if Proxy needed

Hard code URL, Proxy, and CallerID, ##CUSTOMER## into ServiceNow (SNow) caller_id field to create events
#===============================================

# Don't forget to replace the following variables!

SNOW DEV URL with Prod before going to production events
$ServiceNowURL="https://##ServiceNowURL##/api/now/table/incident"

Adjust where clause based on SaaS ServiceNow URL for customer!
	e.g. $ServiceNowURL | where { $_ -notlike "*test*" } ) )

# Set AlertName for Testing
$SNOWAlertName = "##CUSTOMER## SCOM Event - $AlertName"

Proxy
$Proxy = ##Proxy##

CallerID
$CallerID = "##CallerID##"


# AssignmentGroup & TicketID
$AssignmentGroup
$TicketID = "SNOW_event"

#>

Param (
     [Parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         Position=0)]	 
     [ValidateNotNullorEmpty()]
     [String]$AlertName,
     [Parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         Position=1)]
     [ValidateNotNullorEmpty()]
     [String]$AlertID,
     [Parameter(Position=2)][String]$Impact,
     [Parameter(Position=3)][String]$Urgency,
     [Parameter(Position=4)][String]$Priority,
     [Parameter(
		 Mandatory=$true,
         ValueFromPipeline=$true,
		 Position=5)]
		 [ValidateNotNullorEmpty()]
		 [String]$AssignmentGroup,
	 [Parameter(
		 Mandatory=$true,
         ValueFromPipeline=$true,
	 	 Position=6)]
		 [ValidateNotNullorEmpty()]
		 [String]$BusinessService,
     [Parameter(
		 Mandatory=$true,
         ValueFromPipeline=$true,
	 	 Position=7)]
		 [ValidateNotNullorEmpty()]
		 [String]$Category,
     [Parameter(
	 	 Mandatory=$true,
         ValueFromPipeline=$true,
	 	 Position=8)]
		 [ValidateNotNullorEmpty()]
		 [String]$SubCategory,
     [Parameter(
	 	 Mandatory=$true,
         ValueFromPipeline=$true,
	 	 Position=9)]
		 [ValidateNotNullorEmpty()]
		 [String]$Channel
)


# Global variables
# Hard code URL, Proxy, CallerID SNOW variables into script
#===============================================

# Don't forget to replace SNOW DEV URL with Prod before going to production events

# Replace these variables with valid values:
##CUSTOMER##
##TEAM##
# Find/Replace ##Company## ##Team## to fill out short_description
##SERVICENOWURL##
##CallerID##


$ServiceNowURL = ##ServiceNowURL##/api/now/table/incident"

# Self-Service,Direct options requested, Monitoring hidden, Auto-Gen requested to ServiceNow ITSM team
$Channel = "Direct"

# Values
$ServiceNowURL="https://##ServiceNowURL##/api/now/table/incident"
#$Proxy = "##CustomerProxyURL##"
$CallerID = "##CallerID##"

# Assume module NOT loaded into current PowerShell profile
Import-Module -Name CredentialManager


#=================================================================================
# Starting Script section - All scripts get this
#=================================================================================
# Gather the start time of the script
$StartTime = Get-Date

# Set variable to be used in logging events
$whoami = whoami
 
# ScriptName should match the <scriptname.ps1> to log script details
#=================================================================================
# ScriptName
$ScriptName = "New-SNowIncident.ps1"
$EventID = "700"

# Create new object for MOMScript API, or SCOM alert properties
$momapi = New-Object -comObject MOM.ScriptAPI

# Begin logging script starting into event log
# write-host "Script is starting. `n Running as ($whoami)."
$momapi.LogScriptEvent($ScriptName,$EventID,0,"Script is starting. `n Running as ($whoami).")
#=================================================================================

# PropertyBag Script section - Monitoring scripts get this
#=================================================================================
# Load SCOM PropertyBag function
$bag = $momapi.CreatePropertyBag()

$date = get-date -uFormat "%Y-%m-%d"

<#
# Retrieve SNOW credential from Credential Manager
#===============================================
# Example
# $Credential = Get-StoredCredential -Target "SNOW_Account"
#
# ID, Password, and Caller_ID are provided by AESMP team
#>

$Credential = Get-StoredCredential -Target "ServiceNowCredential"
$ServiceNowUser = $Credential.Username
$ServiceNowPassword = $Credential.GetNetworkCredential().Password

if ( $Credential -eq $Null )
	{
	write-host "ServiceNow Credential NOT stored on server"
	$momapi.LogScriptEvent($ScriptName,$EventID,0,"ServiceNow Credential NOT stored on server")
	}

#Assuming No changes, inputs passed to SCOM channel for SNOW event creation
write-host ""
#write-host "SCOM Alert alertName = $AlertName, Alert ID = $AlertID"
#$momapi.LogScriptEvent($ScriptName,$EventID,0,"SCOM Alert alertName = $AlertName, Alert ID = $AlertID")

$Alert = Get-SCOMAlert -Id $AlertID | where { ( $_.Name -eq $AlertName ) } #-AND ( $_.ResolutionState -ne 255 ) }
#write-host "SCOM Alert ready for parsing"


# Multiple locations for HostName in alerts based on class, path, and other variables
# Hostname
# Figure out hostname based on alert values
#===============================================

$MonitoringObjectPath = ($Alert |select MonitoringObjectPath).MonitoringObjectPath
$MonitoringObjectDisplayName = ($Alert |select MonitoringObjectDisplayName).MonitoringObjectDisplayName	
$PrincipalName = ($Alert |select PrincipalName).PrincipalName
$DisplayName = ($Alert |select DisplayName).DisplayName
$PKICertPath = ($Alert |select Path).Path

# Update tests with else for PowerShell script
if ( $MonitoringObjectPath -ne $null ) { $Hostname = $MonitoringObjectPath }
if ( $MonitoringObjectDisplayName -ne $null ) { $Hostname = $MonitoringObjectDisplayName }
if ( $PrincipalName -ne $null ) { $Hostname = $PrincipalName }
if ( $DisplayName -ne $null ) { $Hostname = $DisplayName }
if ( $PKICertPath -ne $null ) { $Hostname = $PKICertPath }

# Verify unique Hostname
if ( ( $Hostname | measure).Count -gt 1 )
	{
	$Hostname = $Hostname | sort -uniq
	write-host $Hostname
	}

$IP = Resolve-DNSName -Name $hostname -Type A
$ServerIP = ($IP.IPAddress)

# Remove FQDN, leaving servername
$ParseHost = $Hostname.Split(".")
$Hostname = $Parsehost[0]

<# 
Debug
$ServerIP
$MonitoringObjectPath
$MonitoringObjectDisplayName
$PrincipalName
$DisplayName
$PKICertPath
#>

#write-host "SCOM Alert Hostname = $Hostname"

# Combined event
write-host "SCOM Alert - Hostname = $Hostname, AlertName = $AlertName, Alert ID = $AlertID"
$momapi.LogScriptEvent($ScriptName,$EventID,0,"SCOM Alert - Hostname = $Hostname, AlertName = $AlertName, Alert ID = $AlertID")



# Determine SCOM Alert Description excludex JSON special characters
#===============================================
#write-host "Begin SCOM Alert Description JSON audit"
$Description = $Alert.Description

$Description = $Description -replace "^@", ""
$Description = $Description -replace "=", ":"
$Description = $Description -replace ";", ","
$Description = $Description -replace "`", "#"
$Description = $Description -replace "{", "*"
$Description = $Description -replace "}", "*"
$Description = $Description -replace "\n", "\\n"
$Description = $Description -replace "\r", "\\r"
$Description = $Description -replace "\\\\n", "\\n"

#write-host "SCOM Alert Description formatted for JSON"
#write-host $Description
#Add-Event $Description

#write-host "End GLobal section"
#Add-Event "End GLobal section"
write-host ""

# End Global section

<#
.Synopsis
   New-SNowIncident creates ServiceNow (SNow) Incidents
.DESCRIPTION
   Create ServiceNow (SNow) Incidents using New-SNowIncident
.EXAMPLE
   Example of how to use this cmdlet

   To provide input parameters for ALL incident pieces   
      New-SNowIncident -AlertName <> -AlertID <> -Impact <> -Urgency <> -Priority <> -AssignmentGroup <> -BusinessService <> -Category <> -SubCategory <>
.EXAMPLE
   Example of New-SNowIncident required parameters
      New-SNowIncident -AlertName <> -AlertID <> -AssignmentGroup <> -BusinessService <> -Category <> -SubCategory <>
.EXAMPLE
   Example of New-SNowIncident required parameters
      New-SNowIncident -AlertName "System Center Management Health Service Unloaded System Rule(s)" -AlertID 5e0f7d66-1aae-43d6-8002-73f7668dc889 -AssignmentGroup "System Admins" -BusinessService SYSMAN -Category Support -SubCategory Repair
.EXAMPLE
   Example of New-SNowIncident required parameters
      New-SNowIncident -AlertName "System Center Management Health Service Unloaded System Rule(s)" -AlertID 72094f43-d157-4034-9b45-521fdb35147f -Incident 4 -Severity 2 -Priority 3 -AssignmentGroup "System Admins" -BusinessService SYSMAN -Category "SYSMAN Support" -SubCategory Repair
.EXAMPLE
   Example of New-SNowIncident required parameters
      New-SNowIncident -AlertName "System Center Management Health Service Unloaded System Rule(s)" -AlertID 72094f43-d157-4034-9b45-521fdb35147f -Channel "Direct"
.INPUTS
   Strings can be used for the following inputs:
	-AlertName 
	-AlertID
	-Impact
	-Urgency
	-Priority
	-AssignmentGroup
	-BusinessService
	-Category
	-SubCategory
	-Channel
.OUTPUTS
   Script leverages Add-Event function to create Operations Manager Event ID 700 events, as well as write-host elements to screen.
   NOTE: write-host elements largely disabled and intended for debug purposes.
   
   Example outputs running functions from PowerShell
   PS C:\Users\scomadmin> Get-SNowParameters
	https://##ServiceNowURL##/api/now/table/incident
	
	PROD ServiceNow URL specified

	CredentialManager PoSH Module NOT Installed
	
	ServiceNow Credential NOT stored on server
	ServiceNow User NOT stored on server
	ServiceNow Password NOT stored on server
	
   	Additional Output example error - 
		Most likely when script run from non-DOD server, or server NOT on trusted network
	
	PS C:\Users\scomadmin> New-SNowIncident
	Error: The remote certificate is invalid according to the validation procedure.
.NOTES
   Validates required URL, ID/Password is stored on server.

.COMPONENT
   New-SNowIncident script used to create ServiceNow (SNow) Incidents.
.ROLE
   Use New-SNowIncident in ITSM integration for Incident Management
.FUNCTIONALITY
   Setup ServiceNow (SNoW) incidents, based on strategy 'intervention required' monitoring and alerting.
#>



function Add-Event
{
<#
.Synopsis
   Create Events in Operations Manager event log
.DESCRIPTION
   Setup MOMAPI Event Logging to Operations Manager event log

   Create $StartTime, $whoami, $ScriptName,$Event, $momapi
   Begin logging script runtime events using EventID 700.
	
   Log script runtime events using EventID 700.
.EXAMPLE
   Example of how to use this cmdlet:
	Log-Event <string>
.EXAMPLE
   Example using new line `n:
	Log-Event "Script is starting. `n Running as ($whoami)."
.INPUTS
   Input string of what you want added to Operations Manager event log
.OUTPUTS
   Creates EventID 700 events added to Operations Manager event log.
.NOTES
   Use newline `n, or carriage returns `r to format additional lines into Event.
.COMPONENT
   Leverage function to create events with debug or error conditions related to new ServiceNow (SNow) incidents.
.ROLE
   Used as event logging function
.FUNCTIONALITY
   Create events related to new ServiceNow (SNow) incidents.
#>

[CmdletBinding()]
Param (
     [Parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         Position=0)]
     [ValidateNotNullorEmpty()]
     [String]$Message
)

$momapi.LogScriptEvent($ScriptName,$EventID,0,$Message)

}



function Add-SCOMAlertFields
{
	#===============================================================
	# Gather values to update SCOM alert
	#===============================================================
	#write-host "Begin Add-SCOMAlertFields function"
	#add-event "Begin Add-SCOMAlertFields function"

	$AlertResolutionState = 249

	if ( $AlertResolutionState -ne 255 )
		{
		#write-host "Processed SCOM alert, changing Resolution State to $($AlertResolutionState)"
		#Add-Event "Processed SCOM alert, changing Resolution State to $($AlertResolutionState)"
		}
	if ( $AlertResolutionState -eq 255 )
		{
		$TicketID = "Closed_NO_SNOW_Incident"
		write-host "Exiting - ServiceNow (SNow) Incident NOT created as SCOM alert closed"
		Add-Event "Exiting - ServiceNow (SNow) Incident NOT created as SCOM alert closed"
		exit $0
		}

	# Debug
	# Additional scripting to pull number,assignment_group field for INC from $result into SCOM alert
	if ( $Response -ne $null )
		{
		$TicketID = $Response.result.Number

		#write-host "SNOW Incident TicketID = $TicketID"
		#add-event "SNOW Incident TicketID = $TicketID"		
		}
	if ( $Response -eq $null )
		{
		$TicketID = "NO_SNOW_Incident"

		#write-host "SNOW Incident TicketID = $TicketID"
		#add-event "SNOW Incident TicketID = $TicketID"		
		}

	# AssignmentGroup & TicketID is freeform string field
	#write-host "SNOW Incident AssignmentGroup = $AssignmentGroup"
	#add-event "SNOW Incident AssignmentGroup = $AssignmentGroup"

	#Combine into single line or event
	write-host "SNOW Incident - TicketID = $TicketID, AssignmentGroup = $AssignmentGroup, ResolutionState = $AlertResolutionState"
	add-event "SNOW Incident - TicketID = $TicketID, AssignmentGroup = $AssignmentGroup, ResolutionState = $AlertResolutionState"


	# Get-SCOM alert and update alert
	#================================
	# If TicketID not created, update Resolution State and alert history
	if ( $TicketID -eq $Null )
		{
		$Alert | Set-SCOMAlert -Owner $AssignmentGroup -ResolutionState $AlertResolutionState `
		-Comment "ServiceNow SCOM event automation - Set Owner, Resolution state in current alert $(Get-date)"

		write-host ""	
		write-host "SCOM alert updated for Owner $($AssignmentGroup), ResolutionState $($AlertResolutionState)"
		Add-Event "SCOM alert updated for Owner $($AssignmentGroup), ResolutionState $($AlertResolutionState)"
		}

	# If TicketID created, update TicketID, Resolution State, and alert history
	# Get-SCOMAlert -Name "$AlertName" -ResolutionState $AlertResolutionState | Set-SCOMAlert -ticketID $TicketID `

	if ( $TicketID -ne $Null )
		{
		$Alert | Set-SCOMAlert -ticketID $TicketID `
		-Owner "$AssignmentGroup"  -ResolutionState $AlertResolutionState `
		-Comment "ServiceNow SCOM event automation - Set TicketID, Owner, Resolution state in current alert $(Get-date)"

	write-host "SCOM alert updated for Ticket $($TicketID), Owner $($AssignmentGroup), ResolutionState $($AlertResolutionState)"
	Add-Event "SCOM alert updated for Ticket $($TicketID), Owner $($AssignmentGroup), ResolutionState $($AlertResolutionState)"

	}



<# Resolve alert?
#===========================
Get-SCOMAlert -Name "$AlertName" -ResolutionState 0 | Resolve-SCOMAlert -ticketID $TicketID `
	-Owner "$AssignmentGroup" `
	-Comment "Resolve ServiceNow SCOM alert automation - Set Ticket, Owner, Resolution state in current alert"

	Add-Event "Resolved SCOM alert $TicketID for group $AssignmentGroup"
#>

write-host ""
#write-host "End Add-SCOMAlertFields function"
#add-event "End Add-SCOMAlertFields function"

}



function Get-SNowParameters
{
<#
.Synopsis
   Get ServiceNow (SNow) Incident parameters
.DESCRIPTION
   This function is used to gather and validate SNow parameters.

   Get-SNowParameters function validates multiple required parameters to create a populated ServiceNow incident.
	Parameters include ServiceNow URL (prod/test), ServiceNow user/pass (leveraging Credential Manager)

   ServiceNow specific fields that are required for RESTAPI Incident creation include:
	CallerID, AssignmentGroup, Business_Service, Category, SubCategory, AlertName, Priority, Impact, and Severity into the REST payload variable $IncidentData.  The $IncidentData array is tested, and then converted to JSON payload for invoke-RestMethod injection.

.EXAMPLE
   Example of how to use this cmdlet

   Get-SNowParameters

.EXAMPLE
   Another example of how to use this cmdlet
   
.INPUTS
   No Inputs
.OUTPUTS
   Function will output various validation messages for ServiceNow incidents

   TEST ServiceNow URL specified
   PROD ServiceNow URL specified
   NO ServiceNow URL specified

   CredentialManager PoSH Module NOT Installed

   ServiceNow User NOT stored on server
   ServiceNow Password NOT stored on server

   ServiceNow (SNow) incident NOT needed as SCOM alert is CLOSED

   Hostname = $HostName

   Invalid or null parameters passed for impact,Urgency,Priority in SNow incident
.NOTES
   Leverages parameter provided variables to create ServiceNow (SNow) incident
.COMPONENT
   Get-SNowParameters function is contained in the New-SNowIncident.ps1 script
.ROLE
   Get function of New-SNowIncident.ps1 script
.FUNCTIONALITY
   Function get's or validates required fields to create ServiceNow (SNow) incident
#>



#Write-host "Begin function get-SNOWIncident"
#Add-Event "Begin function get-SNOWIncident"

<#
# Set up ServiceNow URL connection pieces
#===============================================
#>

#write-host $ServiceNowURL
#write-host "ServiceNow (SNow) URL specified = $($ServiceNowURL)"
#Add-Event "ServiceNow (SNow) URL specified = $($ServiceNowURL)"

if ( ( $ServiceNowURL | where { $_ -like "*test*" } ) )
	{
	write-host "TEST ServiceNow URL specified"
	Add-Event "TEST ServiceNow URL specified"
	}

if ( ( $ServiceNowURL | where { $_ -notlike "*test*" } ) )
	{
	write-host "PROD ServiceNow URL specified"
	Add-Event "PROD ServiceNow URL specified"
	}

if ( $ServiceNowURL -eq $null )
	{
	write-host "Exiting - NO ServiceNow URL specified"
	Add-Event "Exiting - NO ServiceNow URL specified"
	exit $0
	}


<#
# Pre-req for CredentialManager powershell (posh) module
# Assume module NOT loaded into current PowerShell profile

Import-Module -Name CredentialManager
#>

# Verify Credential Manager snap in installed
$CredMgrModuleBase = Get-Module -Name CredentialManager

if ( $CredMgrModuleBase.ModuleBase -ne $Null )
	{
	write-host "CredentialManager PoSH Module Installed, ModuleBase = $($CredMgrModuleBase.ModuleBase)"
	Add-Event "ServiceNow Credential PowerShell module installed, ModuleBase = $($CredMgrModuleBase.ModuleBase)"
	}

if ( $CredMgrModuleBase.ModuleBase -eq $Null )
	{
	write-host "CredentialManager PoSH Module NOT Installed"
	Add-Event "ServiceNow Credential PowerShell module NOT installed"
	exit $0
	}

<#
# Verify SNOW credential exists in Credential Manager
#===============================================
# Example
# $Credential = Get-StoredCredential -Target "SNOW_Account"
#
# ID, Password, and Caller_ID are provided by AESMP team

# From Global section
$Credential = Get-StoredCredential -Target "ServiceNowCredential"
$ServiceNowUser = $Credential.Username
$ServiceNowPassword = $Credential.GetNetworkCredential().Password
#>

if ( $Credential -ne $null )
	{
	Write-host "Stored Credential variable exists"
	Add-Event "Stored Credential variable exists"
	}

# Test Credential variables for User password are provided
#===============================================

if ( $Credential.UserName -eq $null )
	{
	write-host "ServiceNow Credential NOT stored on server - credential $($Credential), username $($Credential.UserName)"
	Add-Event "ServiceNow Credential NOT stored on server - credential $($Credential), username $($Credential.UserName)"
	exit $0
	}


# Test Credential variables for User password are provided
#===============================================
#===============================================
if ( $ServiceNowUser -eq $null )
	{
	write-host "ServiceNow User NOT stored on server"
	Add-Event "ServiceNow User NOT stored on server"
	}
if ( $ServiceNowPassword -eq $null )
	{
	write-host "ServiceNow Password NOT stored on server"
	Add-Event "ServiceNow Password NOT stored on server"
	}
	
	
	
<#
# Alert may not have server listed as offending object with issue
# $AlertID parameter passed into script to then audit alert, and find where alert originated

# Other test scenarios
Gather Critical, New alerts

Example of new, critical alerts
$Alert = get-scomalert -ResolutionState 0 -severity 2

Example of new, warning alerts
$Alert = get-scomalert -ResolutionState 0 -severity 1

Example of alert with resolution LT 255
$Alert = get-scomalert -Name $AlertName -ResolutionState (0..254)

Example of alert specified from input variables
$Alert = get-scomalert -Name $AlertName -ResolutionState (0..254)

Example of alertID specified with where clause
$Alert = Get-SCOMAlert -Id $AlertID | where { ( $_.Name -eq $AlertName ) -AND ( $_.ResolutionState -ne 255 ) }
#>

# Evaluate alert closed before SCOM channel SNOW script executed
#===============================================
# Get ResolutionState
$AlertResolutionState = $Alert.ResolutionState

if ( $AlertResolutionState -eq 255 )
	{
	$TicketID = "Closed_NO_SNOW_Incident"
	write-host "Exiting as SCOM Alert closed - ServiceNow (SNow) Incident NOT created as SCOM alert closed"
	Add-Event "Exiting as SCOM Alert closed - ServiceNow (SNow) Incident NOT created as SCOM alert closed"
	exit $0
	}

if ( $AlertResolutionState -ne 255 )
	{
	#write-host "SCOM alert resolutionState = $($AlertResolutionState)"
	#Add-Event "SCOM alert resolutionState = $($AlertResolutionState)"
	}

# Set Alert ManagementGroup, Category from SCOM alert to use in event fields
$AlertManagementGroup = $Alert.ManagementGroup.Name
#write-host "SCOM Alert Management Group Name = $($AlertManagementGroup)"

$AlertCategory = $Alert.Category
#write-host "SCOM Alert Category = $($AlertCategory)"


# Determine SCOM Alert Severity to ITSM tool impact
#===============================================
$Severity = $Alert.Severity
#write-host "SCOM Alert Severity = $($Severity)"
#Add-Event "SCOM Alert Severity = $($Severity)"

If ( $Severity -eq "Warning" )
	{
	$EventSeverity = "Minor"
	}
If ( $Severity -eq "Critical" )
	{
	$EventSeverity = "Critical"
	}


# IF $Impact, $Urgency, $Priority are null, set the values based on the Severity of the SCOM alert
if ( $Impact -ne $null )
	{
	#write-host "ServiceNow variables for Impact $($Impact)"
	#Add-Event "ServiceNow variables for Impact $($Impact)"
	}
if ( $Urgency -ne $null )
	{
	#write-host "ServiceNow variables for Urgency $($Urgency)"
	#Add-Event "ServiceNow variables for Urgency $($Urgency)"
	}
if ( $Priority -ne $null )
	{
	#write-host "ServiceNow variables for Priority $($Priority)"
	#Add-Event "ServiceNow variables for Priority $($Priority)"
	}

# NOC only concerned with Priority
if ( $Priority -eq $Null )
	{
	#Write-host "Priority NOT passed for SNow Incident"
	#Add-Event "Priority NOT passed for SNow Incident"
	If ( $Severity -eq "Warning" )
		{
		$Impact = "4"
		$Urgency = "4"
		$Priority = "3"
		}
	If ( $Severity -eq "Error" )
		{
		$Impact = "4"
		$Urgency = "4"
		$Priority = "2"
		}
	If ( $Severity -eq "Informational" )
		{
		Exit $0
		}
	}

Write-host ""
write-host "ServiceNow (SNow) variables`nURL specified = $($ServiceNowURL)`nImpact $($Impact), Urgency $($Urgency), Priority $($Priority)`n`nSCOM alert fields gathered:`nResolutionState = $($AlertResolutionState), Severity = $($Severity), Category = $($AlertCategory)`nManagement Group Name = $($AlertManagementGroup)"
Add-Event "ServiceNow (SNow) variables`nURL specified = $($ServiceNowURL)`nImpact $($Impact), Urgency $($Urgency), Priority $($Priority)`n`nSCOM alert fields gathered:`nResolutionState = $($AlertResolutionState), Severity = $($Severity), Category = $($AlertCategory)`nManagement Group Name = $($AlertManagementGroup)"

#Write-host "Function get-SNOWIncident ran successfully"
#Add-Event "Function get-SNOWIncident ran successfully"
Write-host ""

}



function New-SNowIncident
{
<#
.Synopsis
   Create new ServiceNow (SNow) Incident
.DESCRIPTION
   New-SNowIncident function will create SNOW incidents using passed alert data (SCOM source).

   New-SNowIncident function follows the Get-SNowIncident function to create a populated ServiceNow incident.

   ServiceNow specific fields that are required for RESTAPI Incident creation include: 
	CallerID, AssignmentGroup, Business_Service, Category, SubCategory, AlertName, Priority, Impact, and Severity into the REST payload variable $IncidentData.  The $IncidentData array is tested, and then converted to JSON payload for invoke-RestMethod injection.

.EXAMPLE
   Example of how to use this cmdlet
   
   New-ServiceIncident   
.INPUTS
   No inputs for this function.
.OUTPUTS
   Function will output various validation messages for ServiceNow incidents
   
   ServiceNow Incident payload `n `n $($IncidentData)
   
   Completed ServiceNow incident creation for ($date) `n $IncidentData"
   
   Attempting to create incident for $AlertName on $HostName...
   
   Incident created successfully. Incident Number: $($response.result.number)
   
   Failed to create incident. Error: $($response.result.number)
   
   Error: $errorMessage in REST Response
   
   Updated SCOM alert $TicketID for group $AssignmentGroup
   
   Completed ServiceNow incident creation for ($date) `n $IncidentData
   
   Script Completed. `n Script Runtime: ($ScriptTime) seconds.
.NOTES
   Generates events tracking pieces, and results from incident creation.
   Final piece is SCOM alert updated with incident #, Assignment Group.
.COMPONENT
   New-SNowIncident function belongs to New-SNowIncident.ps1
.ROLE
   The New-SNowIncident function creates NEW ServiceNow (SNow) incidents.
.FUNCTIONALITY
   Create new ServiceNow (SNow) Incident, and update SCOM alert with Incident number, AssignmentGroup
#>

<#
# Set up ServiceNow connection pieces from top level parameters
#===============================================

 	[String]$AlertName,
    [String]$AlertID,
    [String]$Impact,
    [String]$Urgency,
    [String]$Priority,
    [String]$AssignmentGroup,
	[String]$BusinessService,
    [String]$Category,
    [String]$SubCategory,
	[String]$Channel
#>


# Set up IncidentData variable with SCOM to SNow fields
#===============================================
#write-host "Create ServiceNow incident for ($date)."
#Add-Event "Create ServiceNow incident for ($date)."

# Build SNOW IncidentData variable with SCOM to SNow fields
#===============================================

$incidentData = @{
	caller_id = $CallerID
	business_service = $BusinessService
	assignment_group = $AssignmentGroup
	short_description = "RCC-C - SYM SCOM " + $AlertName
	description = $Description
	contact_type = $Channel
	impact = $Impact
	urgency = $Urgency
	priority = $Priority
	cmdb_ci = $Hostname
	# AESMP test does not contain
	category = $Category
	subcategory = $SubCategory
} | ConvertTo-Json

write-host "ServiceNow Incident payload `n$($IncidentData)"
Add-Event "ServiceNow Incident payload `n$($IncidentData)"
write-host ""

# Build headers variable
#===============================================
    $headers = @{
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }

# Set up REST method JSON request
#===============================================
try
	{
        $base64Auth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($ServiceNowUser):$($ServiceNowPassword)"))
        
        $headers.Add("Authorization", "Basic $base64Auth")
        
        Write-Host "Attempting to create incident for hostname - $HostName..."
        Add-Event "Attempting to create incident for hostname - $HostName..."

		if ( $Proxy -eq $null)
			{
			$response = Invoke-RestMethod -Uri $ServiceNowURL -Method Post -Headers $headers -Body $incidentData
			}
		if ( $Proxy -ne $null)
			{
			$response = Invoke-RestMethod -Uri $ServiceNowURL -Method Post -Headers $headers -Body $incidentData -Proxy $Proxy
			}

        # Test Incident returned
		$response
		if ( $response -eq $null )
			{
			write-host "Null try response"
			$TicketID = "NO_SNOW_Incident"
			}
		
        if ( $response.result.number -ne $Null ) 
			{
			Write-host "Incident created successfully. Incident Number: $($response.result.number)"
			Add-Event "Incident created successfully. Incident Number: $($response.result.number)"
			} 
        else
        	{
			Write-Host "Error: Failed to create incident."
			Add-Event "Error: Failed to create incident."
			}
	}
catch
	{
        $errorMessage = $_.Exception.Message
       
        if ($_.Exception.InnerException)
        	{
		$errorMessage = $_.Exception.InnerException.Message
	        }
        
		# Test Incident returned
		if ( $response -eq $null ) { write-host "Null catch response"}
		
		Write-Host "Error: REST Response Error Message: $errorMessage"
		Write-Host ""
		Add-Event "Error: REST Response Error Message: $errorMessage"
	}


Add-SCOMAlertFields

}


# Execute functions
Get-SNowParameters
New-SNowIncident


#============================================================
$Result = "GOOD"
$Message = "Completed ServiceNow incident creation for ($date)"

#Write-Host "Completed ServiceNow incident creation for ($date) `n $IncidentData"
Add-Event "Completed ServiceNow incident creation for ($date) `n $IncidentData"

<#
$bag.AddValue('Result',$Result)
$bag.AddValue('Count',$Test)
$bag.AddValue('Message',$Message)
$bag.AddValue('Summary',$DNSMessage)
#>

# Return all bags
$bag
#=================================================================================
# End MAIN script section
 
  
# End of script section
#=================================================================================
#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
Add-Event "Script Completed. `n Script Runtime: ($ScriptTime) seconds."
#=================================================================================
# End of script