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

$$PSEmailServer, set to a string (in quotes) to the smtp server that the email report will be sent via

To set email recipients, add `$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"` to the end of the marked user serviceable options area. Obviously replace the name and email with your own, just use the same format (I can't belive I have to say that). Add as many as you like (probably?)
