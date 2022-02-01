# Disable Expired Accounts

A PS script that will safely disable expired AD accounts.

# Instructions

Run the script as a user with permissions to disable accounts, maybe set it up as a scheduled task, if you want.

## User options

On/Off (boolean) togles are set with $true or $false

String options must be wrapped in quotes.

User serviceable options:

$TestMode, set to $true to perform a dry run, no changes will be made in AD. $false enables making changes. Default: $true

$UseEventLog, set to $true or $false to control Event Log logging. Default: $true

$EventLogDest, set to a string the Event Log that will be used for logging. Default: "Application"

$EventLogSource, set to a string the Event Log source. Default: "DisableExpiredAccounts"

$SendEmailReport, set to $true to control the email report. Default: $true

$AlwaysEmail, set to $true to always send an email report, even if nothing happened. Default: $false

$ClearExpirationAfterDisable, set to $true to clear the expiration date on the account after it is successfully disabled. Default: $false

$PSEmailServer, set to a string (in quotes) to the smtp server that the email report will be sent via. Default value is a placeholder, this must be configured correctly to use the email feature.

$AllowAdminDisable, set to $true to allow the automated disabling of accounts with adminCount > 1 (indicates the user is/was granted administrative privielges). Default: $false

To set email recipients, add `$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"` to the end of the marked user serviceable options area. Obviously replace the name and email with your own, just use the same format (I can't belive I have to say that). Add as many as you like (probably?)

## Event Log Reference

Event ID: 100

Informational Message - Script starting up or shutting down

Event ID: 500

Warning Message - Account to be disabled has logged on since being expired, manual intervention required

Event ID: 501

Error Message - Account has the adminCount attribute set and the script is configured to not allow disabling of administrative users. Manual intervention required.

Event ID: 403

Error Message - Exception in Disable-ADAccount/Clear-ADAccountExpiration - most likely a permissions error

Event ID: 200

Informational Message - Account sucessfully disabled

Informational Message - Email report sent
