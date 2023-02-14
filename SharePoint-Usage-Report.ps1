#Writted by Tyler Price for gathering some information from a SharePoint online tenant. 
#Last updated: 2023-02-15
#
#Script assumes SPOservice module is installed already. 
#Script assumes you have the SharePoint administrtaor role.
#
#Use at your own risk. 


# Ask for URL 
$spadminURL =  $(Write-Host "What is the SharePoint admin center URL?" -ForegroundColor cyan -NoNewLine; Read-Host)

# Check if the "C:\Temp" folder exists and create it if it doesn't
if (!(Test-Path -Path "C:\Temp" -PathType Container)) {
    New-Item -ItemType Directory -Path "C:\Temp"
}

# Connect PowerShell
Connect-SPOService -Url $spadminURL

# Get SharePoint sites with storage usage details and members
Get-SPOSite -Detailed | 
    Select-Object Url,Title,Owner,IsTeamsConnected,@{Name='Storage Used (GB)';Expression={$_.StorageUsageCurrent/1024}},LastContentModifiedDate,SharingCapability, @{Name='Direct Members';Expression={
        $members = (Get-SPOUser -Site $_.Url -Limit All | Where-Object { $_.UserType -eq "Member" }).LoginName
        $members = $members -split ';'
        $resolved_members = @()
        foreach ($member in $members) {
            if ($member -match '^c:0o.c\|(.+?)@') {
                $group_id = $matches[1]
                $group_members = Get-SPOSiteGroup -Site $_.Url -Group $group_id | Select-Object -ExpandProperty Users | Where-Object { $_.UserType -eq "Member" } | Select-Object -ExpandProperty LoginName
                $resolved_members += $group_members
            } elseif ($member -notlike '*@*') {
# Ignore group IDs
            } else {
                $resolved_members += $member
            }
        }
        $resolved_members -join ';'
    }} | 
    ForEach-Object { 
# Update SharingCapability to show more descriptive text
        $_.SharingCapability = $_.SharingCapability -replace 'ExternalUserAndGuestSharing', 'Anyone - Allow users to share files and folders by using links that let anyone who has the link access the files or folders without authenticating.'
        $_.SharingCapability = $_.SharingCapability -replace 'ExistingExternalUserSharingOnly', 'Existing guests - Allow sharing only with guests who are already in your directory (e.g., manually added as a guest).'
        $_.SharingCapability = $_.SharingCapability -replace 'ExternalUserSharingOnly', 'New and existing guests - Require people who have received invitations to sign in with their work or school account (if their organization uses Microsoft 365) or a personal Microsoft account, or to provide a code that is emailed to them, to verify their identity.'
        $_.SharingCapability = $_.SharingCapability -replace 'Disabled', 'Disabled - Only sharable to people in your organization. This site cannot be shared externally.'
        $_ 
    } | 
    Export-Csv -Path C:\Temp\SharePoint-Usage-Members-Sharing_$((Get-Date).ToString('yyyyMMdd_HHmmss')).csv -NoTypeInformation
