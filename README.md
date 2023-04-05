# Disable Expired Accounts

A PS script that will safely disable expired AD accounts.

# Instructions

Run the script as a user with permissions to disable accounts, maybe set it up as a scheduled task, if you want.

## User options

On/Off (boolean) togles are set with $true or $false

String options must be wrapped in quotes.

|            Option            	|                                                            Description                                                            	|   Type  	|       Default Value      	|
|:----------------------------:	|:---------------------------------------------------------------------------------------------------------------------------------:	|:-------:	|:------------------------:	|
|           $TestMode          	|                                              Perform a dry run. No changes are made.                                              	| Boolean 	|           $true          	|
|         $UseEventLog         	|                                                  Master switch for event logging                                                  	| Boolean 	|           $true          	|
|         $EventLogDest        	| The destination event log. The script will attempt to register it if it doesn't exist,<br>this may require administrative rights. 	|  String 	|       "Application"      	|
|        $EventLogSource       	|                                                     The source for event logs.                                                    	|  String 	| "DisableExpiredAccounts" 	|
|       $SendEmailReport       	|                                                Master switch for the email report.                                                	| Boolean 	|           $true          	|
|         $AlwaysEmail         	|                                     Send the email report even if there is nothing to report.                                     	| Boolean 	|          $false          	|
| $ClearExpirationAfterDisable 	|                                 Clear the expiration date on any account disabled by this script.                                 	| Boolean 	|          $false          	|
|        $PSEmailServer        	|                                     The host of the SMTP server to send the email report via.                                     	|  String 	|           None           	|
|      $AllowAdminDisable      	|                                   Allow the script to disable a user with administrative rights.                                  	| Boolean 	|          $false          	|
| $RestrictedGroups | Accounts contained in the specified groups will not be disabled if $AllowAdminDisable is false | Array of strings | @("Administrators", "Enterprise Admins", "Domain Admins", "Schema Admins", "Protected Users") |
|         $MaxDisable      	|                                     The maximum number of users the script may disable at one time.                                  	| Integer 	|             5          	|

To set email recipients, add `$EmailRecipients += "Michael Scott <mscott@dundermifflin.com>"` to the end of the marked user serviceable options area. Obviously replace the name and email with your own, just use the same format (I can't belive I have to say that). Add as many as you like (probably?)

## Event Log Reference

| Event ID |      Type     |                                                                                Description                                                                               |
|:--------:|:-------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|    100   | Informational |                                                                              Script startup                                                                              |
|    101   | Informational |                                                                              Script shutdown                                                                             |
|    200   | Informational |                                                                             Account Disabled                                                                             |
|    201   | Informational |                                                                          Cleared expiration date                                                                         |
|    202   | Informational |                                                                             Sent email report                                                                            |
|    403   |     Error     |                                   Exception disabling account or clearing expiration. Manual intervention required (check permissions)                                   |
|    500   |     Error     |       Account to be disabled has logged on after expiration. Someone is trying to disable and account by setting the expiration date. Manual intervention required.      |
|    501   |     Error     | Account failed admin check (either adminCount or member of a Restricted Group) and the script is configured to not allow disabling admins. Manual Intervention required. |
|    502   |     Error     |                                            Max number of automated actions reached. Manual intervention or re-run the script.                                            |
