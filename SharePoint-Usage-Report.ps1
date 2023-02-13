#Writted by Tyler Price for gathering some information from a SharePoint online tenant. 
#Last updated: 2023-02-13 
#Use at your own risk. 



#ask for URL 
$spadminURL =  $(Write-Host "What is the SharePoint admin center URL?" -ForegroundColor cyan -NoNewLine; Read-Host)
#Read-Host -prompt 'What is the SharePoint admin center URL?'

#Connect powershell
Connect-SPOService -Url $spadminURL

#Connect-PnPOnline -Url $spadminURL -UseWebLogin

Get-SPOSite -Detailed | 
    Select-Object Url,Title,Owner,IsTeamsConnected,@{Name='Site Storage (MB)'; Expression={[Math]::Round(($_.StorageUsageCurrent / 1MB),2)}},LastContentModifiedDate,SharingCapability | 
    ForEach-Object { 
        $_.SharingCapability = $_.SharingCapability -replace 'ExternalUserAndGuestSharing', 'Anyone - Allow users to share files and folders by using links that let anyone who has the link access the files or folders without authenticating.'
		$_.SharingCapability = $_.SharingCapability -replace 'ExistingExternalUserSharingOnly', 'Existing guests - Allow sharing only with guests who are already in your directory (eg manually added as a guest).'
		$_.SharingCapability = $_.SharingCapability -replace 'ExternalUserSharingOnly', 'New and existing guests - Require people who have received invitations to sign in with their work or school account (if their organization uses Microsoft 365) or a personal Microsoft account, or to provide a code that is emailed to them, to verify their identity.'
		$_.SharingCapability = $_.SharingCapability -replace 'Disabled', 'Disabled - Only sharable to people in your organization. This site cannot be shared externally.'
        $_ 
    } | 
    Export-Csv -Path C:\Tmp\sharing-status_$((Get-Date).ToString('yyyyMMdd_HHmmss')).csv -NoTypeInformation
