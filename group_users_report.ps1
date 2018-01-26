<#
Purpose: Script for exporting users in a group
Notes: Requires PowerShell 3.0 or later
Example: .\group_users_report.ps1 -org "tenant.okta.com" -groupId "XXXXXXXXXXXXXXX" -api_token "XXXXXXXXXXXXXXX" -path "c:\group_users_report.csv"
#>

#requires -version 3.0

param(
    [Parameter(Mandatory=$true)]$org, # Your tentant prefix - Ex. tenant.okta.com
    [Parameter(Mandatory=$true)]$groupId, # The group ID (Ex. 00ghhgqpjTbZlje0wXXX) - Ex. https://tenant-admin.okta.com/admin/group/00ghhgqpjTbZlje0wXXX
    [Parameter(Mandatory=$true)]$api_token, # Your API Token.  You can generate this from Admin - Security - API
    [Parameter(Mandatory=$true)]$path # The path and file name for the resulting CSV file
    )

### Define $allusers as empty array
$allusers = @()

$headers = @{"Authorization" = "SSWS $api_token"; "Accept" = "application/json"; "Content-Type" = "application/json"}

### Set $uri as the API URI for use in the loop


### Use a while loop and get all users from Okta API
do {
    $webresponse = Invoke-WebRequest -Method Get -URI "https://$org/api/v1/groups/$groupId/users" -Headers $headers 
    $links = $webresponse.Headers.Link.Split("<").Split(">") 
    $uri = $links[2]
    $users = $webresponse | ConvertFrom-Json
    $allusers += $users
} while ($webresponse.Headers.Link.EndsWith('rel="next"'))

### Filter the results and remove any DEPROVISIONED users
$activeUsers = $allusers | Where-Object { $_.status -ne "DEPROVISIONED" }

### Export users to .CSV with firstName, lastName, login, email
$activeUsers | Select-Object -ExpandProperty profile | 
    Select-Object -Property firstName, lastName, login, email |  # Add / Remove the required attributes for your report
    Export-Csv -Path $path -NoTypeInformation
