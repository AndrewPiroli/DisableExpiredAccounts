# SPDX-License-Identifier: MIT

# Script Global Variables
$EmailRecipients = @()
$report = [ordered]@{}
$report.Add("User Principal Name", "Status")
$report.Add("", "")
$warnings = 0
$errors = 0
$success = 0
#
# User servicable options
$TestMode = $true
$UseEventLog = $true
$EventLogDest = "Application"
$EventLogSource = "DisableExpiredAccounts"
$SendEmailReport = $true
$AlwaysEmail = $false
$ClearExpirationAfterDisable = $false
$PSEmailServer = "smtp.dundermifflin.com"
$AllowAdminDisable = $false
# Add email recipients in this format
$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"
# End user sericable options

# Helper function for eventlog
function Write-DEAEventlog {
    param (
        [Parameter(Mandatory=$true)]
        $EventID,
        [Parameter(Mandatory=$false)]
        $Severity="Information",
        [Parameter(Mandatory=$true)]
        $Message
    )
    if ($UseEventLog -eq $false){
        return
    }
    Write-EventLog -LogName $EventLogDest -Source $EventLogSource -EventId $EventID -Message $Message -EntryType $Severity
}

# Setup Event Log
if ($UseEventLog){
    $Error.Clear()
    New-EventLog -LogName $EventLogDest -Source $EventLogSource
    # Powershell is dumb, and some exceptions can't be caught with a try-catch (why?)
    if ($Error[0]){
        if ($Error[0].ToString().Contains("Access is denied")){
            Write-Output "Could not create EventLog Source- Access Denied"
            $UseEventLog = $false
        }
        if ($Error[0].ToString().Contains("source is already registered")){
            Write-Output "EventLog already registered"
        }
    }
}

Write-DEAEventLog -EventId 100 -Message "Disable Expired Accounts Script: Startup Complete"

# Pull all expired user accounts
$ExpiredAccounts = Search-ADAccount -AccountExpired -UsersOnly

# Loop over all results
foreach ($account in $ExpiredAccounts){
    # If the account is already disabled, we don't care, so skip it and move on to the next one. Do not add to the final report.
    if ($account.Enabled -eq $false){
        Continue
    }
    # Even though it's a terrible idea to run the script with permissions to disable admins anyway
    # we should add a guard rail just in case an admin account comes up.
    # Are there better admin checks? Yes. Should the script support OU and group level exclusions? Yes.
    # We will get there at some point.
    if (-not $AllowAdminDisable){
        if ((Get-ADUser $account -Properties adminCount).adminCount -gt 0){ # This works even if adminCount is not set (acts like $null -gt 0)
            $report.Add($account.UserPrincipalName, "ERROR: User has adminCount! Refusing to disable an administrative user.")
            Write-Output "$($account.UserPrincipalName) has adminCount! Refusing to disable an administrative user."
            Write-DEAEventlog -EventID 501 -Severity "Error" -Message "$($account.UserPrincipalName) has adminCount! Refusing to disable an administrative user."
            $errors++
            Continue
        }
    }
    # Make sure the account shows no activity since expiration, this would be really weird. Loudly complain if this happens.
    if ($account.LastLogonDate -gt $account.AccountExpirationDate){
        $report.Add($account.UserPrincipalName, "WARN: LastLogonDate newer than AccountExpirationDate. Account left untouched!")
        Write-Output "Account Logged on since expiry. This should be impossible!!"
        Write-DEAEventLog -EventId 500 -Severity "Warning" -Message "Account $($account.UserPrincipalName) has a LastLogonDate newer than its Expiration Date! Refusing to work on insane accounts"
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
        Write-Output "Disable-ADAccount failed - this usually means bad credentials!"
        Write-DEAEventLog -EventId 403 -Severity "Error" -Message "Error disabling $($account.UserPrincipalName), suspect my user does not have Account Operator or better permissions"
        $errors++
    }
    if ($DisableSuccess){
        Write-Output "Disabled $($account.UserPrincipalName)"
        Write-DEAEventLog -EventId 200 -Message "Account $($account.UserPrincipalName) disabled"
        if ($ClearExpirationAfterDisable){
            try{
                Clear-ADAccountExpiration -Identity $account -WhatIf:$TestMode
                Write-DEAEventlog -EventID 200 -Message "Cleared $($account.UserPrincipalName) expiration date!"
                Write-Output "Cleared $($account.UserPrincipalName) expiration date!"
                $report.Add($account.UserPrincipalName, "SUCCESS: Account disabled & Expiration date cleared!")
            }
            catch{
                Write-DEAEventlog -EventID 403 -Severity "Error" -Message "Failed to clear expiration date: $($account.UserPrincipalName)"
                Write-Output "Failed to clear expiration date: $($account.UserPrincipalName)"
                $report.Add($account.UserPrincipalName, "WARNING: Account disabled but expiration date failed to clear")
                $warnings++
            }
        }
        else{
            $report.Add($account.UserPrincipalName, "SUCCESS: Account disabled!")
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

if ($SendEmailReport -And (($success+$warnings+$errors -gt 0) -Or $AlwaysEmail)){
    $LocalHostname = $env:COMPUTERNAME
    $LocalDomain = Get-WMIObject Win32_ComputerSystem| Select-Object -ExpandProperty Domain
    Send-MailMessage -From "$LocalHostname@$LocalDomain" -To $EmailRecipients -Subject $EmailSubject -Body $EmailBody
    Write-Output "attempted to send email report"
    Write-DEAEventLog -EventId 200 -Message "Attemped to send email report!"
}

Write-Output $EmailSubject
Write-Output $EmailBody

Write-DEAEventLog -EventId 100 -Message "DisableExpiredAccounts script - done!"
Write-Output "DisableExpiredAccounts script - done!"
