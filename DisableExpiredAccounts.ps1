# SPDX-License-Identifier: MIT

# User servicable options
$TestMode = $true

$UseEventLog = $true
$EventLogDest = "Application"
$EventLogSource = "DisableExpiredAccounts"
$SendEmailReport = $true
$AlwaysEmail = $false
$PSEmailServer = "smtp.dundermifflin.com"
# No Touch!
$EmailRecipients = @()
# Ok, now you can touch again.
# Add email recipients in this format
$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"
# End user sericable options

# Setup Event Log
if ($UseEventLog){
    $Error.Clear()
    New-EventLog -LogName $EventLogDest -Source $EventLogSource
    # Powershell is dumb, and some exceptions can't be caught with a try-catch (why?)
    if ($Error[0]){
        if ($Error[0].ToString().Contains("Access is denied")){
            Write-Warning "Could not create EventLog Source- Access Denied"
            $UseEventLog = $false
        }
        if ($Error[0].ToString().Contains("source is already registered")){
            Write-Warning "EventLog already registered"
        }
    }
}

if ($UseEventLog){
    Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 100 -Message "Disable Expired Accounts Script: Startup Complete"
}

# Set up a report for later at the end.
$report = [ordered]@{}
$report.Add("User Principle Name", "Status")
$report.Add("@@@@@@@@@@", "@@@@@@")
$warnings = 0
$errors = 0
$success = 0
# Pull all expired user accounts
$ExpiredAccounts = Search-ADAccount -AccountExpired -UsersOnly

# Loop over all results
foreach ($account in $ExpiredAccounts){
    # If the account is already disabled, we don't care, so skip it and move on to the next one. Do not add to the final report.
    if ($account.Enabled -eq $false){
        Continue
    }
    # Make sure the account shows no activity since expiration, this would be really weird. Loudly complain if this happens.
    if ($account.LastLogonDate -gt $account.AccountExpirationDate){
        $report.Add($account.UserPrincipalName, "WARN: LastLogonDate newer than AccountExpirationDate. Account left untouched!")
        Write-Warning "Account Logged on since expiry. This should be impossible!!"
        if ($UseEventLog){
            Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 500 -EntryType "Warning" -Message "Account $($account.UserPrincipalName) has a LastLogonDate newer than its Expiration Date! Refusing to work on insane accounts"
        }
        $warnings++
        Continue
    }
    # Time to disable their account
    try{
        # Powershell is dumb, and does not let us try-catch-else, so we have to have to have this.....
        $DisableSuccess = $false
        Disable-ADAccount -Identity $account -WhatIf:$TestMode
        $success++
        $DisableSuccess = $true
    }
    catch{
        $report.Add($account.UserPrincipalName, "ERROR: Disable-ADAccount Failed!")
        Write-Warning "Disable-ADAccount failed - this usually means bad credentials!"
        if ($UseEventLog){
            Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 403 -EntryType "Error" -Message "Error disabling $($account.UserPrincipalName), suspect my user does not have Account Operator or better permissions"
        }
        $errors++
    }
    if ($DisableSuccess){
        $report.Add($account.UserPrincipalName, "SUCCESS: Account disabled!")
        Write-Warning "Disabled $($account.UserPrincipalName)"
        if ($UseEventLog){
            Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 200 -Message "Account $($account.UserPrincipalName) disabled"
        }
    }
}

# Build report
$EmailSubject = "DisableExpiredAccounts - Disabled: $success Errors: $errors Warnings: $warnings"
$EmailBody = $report | Format-Table -HideTableHeaders | Out-String

if ($TestMode){
    $EmailSubject += " TEST MODE"
    $EmailBody = "TEST MODE ENABLED`r`n$EmailBody"
}

if ($SendEmailReport -And (($success -gt 0) -Or $AlwaysEmail)){
    $LocalHostname = $env:COMPUTERNAME
    $LocalDomain = Get-WMIObject Win32_ComputerSystem| Select-Object -ExpandProperty Domain
    Send-MailMessage -From "$LocalHostname@$LocalDomain" -To $EmailRecipients -Subject $EmailSubject -Body $EmailBody
    Write-Warning "attempted to send email report"
    if ($UseEventLog){
        Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 200 -Message "Attemped to send email report!"
    }
}

Write-Warning $EmailSubject
Write-Warning $EmailBody

if ($UseEventLog){
    Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId 100 -Message "DisableExpiredAccounts script - done!"
}
Write-Warning "DisableExpiredAccounts script - done!"