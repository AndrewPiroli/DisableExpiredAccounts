# Disable Expired Accounts

A PS script that will safely disable expired AD accounts.

# Instructions

Run the script as a user with permissions to disable accounts, maybe set it up as a scheduled task, if you want.

## User options

User serviceable options:

$TestMode, set to $true or $false to enable a dry run. No Changes will be made in AD

$UseEventLog, set to $true or $false to enable Event Log logging.

$EventLogDest, set to a string (in quotes) to the Event Log that will be used for logging.

$EventLogSource, set to a string (in quotes) to the name of the source the script will log as to the Event Log

$SendEmailReport, set to $true or $false to enable the email report.

$AlwaysEmail, set to $true or $false to always send a report, even if nothing happened.

$ClearExpirationAfterDisable, set to $true or $false to clear the expiration date on the account after it is successfully disabled

$PSEmailServer, set to a string (in quotes) to the smtp server that the email report will be sent via

$AllowAdminDisable, Set to $true (default is $false) to allow the automated disabling of accounts with adminCount > 1 (indicates the user is/was granted administrative privielges).

To set email recipients, add `$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"` to the end of the marked user serviceable options area. Obviously replace the name and email with your own, just use the same format (I can't belive I have to say that). Add as many as you like (probably?)

## Event Log Reference

Event ID: 100

Informational Message - Script starting up or shutting down

Event ID: 500

Warning Message - Account to be disabled has logged on since being expired, manual intervention needed

Event ID: 501

Error Message - Account has the adminCount attribute set and the script is configured to not allow disabling of administrative users. Manual intervention required.

Event ID: 403

Error Message - Exception in Disable-ADAccount/Clear-ADAccountExpiration - most likely a permissions error

Event ID: 200

Informational Message - Account sucessfully disabled

Informational Message - Email report sent
