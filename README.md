# New-SNOWIncidents
PowerShell script to take SCOM alerts to create ITSM ServiceNow incidents

New-SNOWIncident.ps1 v1.0.0.0

Download [here](https://github.com/theKevinJustin/SCOM-SNOWIncidents/blob/main/New-SNowIncident.ps1)

### New-SNOWIncidents
Creates ServiceNow incidents leveraging multiple SCOM alert fields, and updates SCOM alert Owner, TicketID, and ResolutionState with successful incident creation.

Blog [(https://kevinjustin.com/blog/2024/03/27/servicenow-incident-integration/)](https://kevinjustin.com/blog/2024/03/27/servicenow-incident-integration/)

Create SNOW Incident

# Depending on how you want to randomly choose an incident
```
# Lab example
$Alerts = get-scomalert -resolutionstate 0 | where { $_.Name -like "System Center*" }

# Gather Critical, New alerts
$Alerts = get-scomalert -ResolutionState 0 -severity 2

# Debug for warning alerts
$Alerts = get-scomalert -ResolutionState 0 -severity 1

# Debug
$Alerts[0] | fl ID,Name,Description,Severity,MonitoringObjectDisplayName

# Run from PowerShell on SCOM MS (with successful pre-requisite verification)
.\New-SNOWIncident.ps1 -AlertName $Alerts[0].Name -AlertID $Alerts[0].ID -Impact 4 -Urgency 4 -Priority 3 -AssignmentGroup "System Admin" -BusinessService "System Management" -Category Support -SubCategory Repair -Channel Direct
```
