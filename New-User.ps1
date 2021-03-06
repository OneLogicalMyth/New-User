﻿#requires -version 4
# Generated by: Liam Glanfield @OneLogicalMyth
# Copyright: (c) 2015 Liam Glanfield. All rights reserved.  Licensed with GNU GENERAL PUBLIC LICENSE.
# Version: 1.1 - Bug fixes for username generation and length
# Version: 1.2 - More error handling to capture creation failures user accounts as per issue #1
# Version: 1.3 - Added support for disabling Emails

#region Configuration
 
    #The smtp relay address
    $PSEmailServer = $null

    #results output
    $ResultsFile = 'C:\Users\Administrator\Desktop\UserResults.csv'

    #CSV file location
    $CSVFile = 'C:\Users\Administrator\Desktop\SampleADUsers.csv'

    #Build config hash for splatting
    $NewUserConfig = @{

        #OU to store new users in
        OU = 'OU=People,DC=test,DC=local'

        #'me@company.com' replace with email address if you want a BCC copy of the email sent
        AdminEmail = $null

        #Email from
        EmailFrom = '"IT Department" <servicedesk@company.com>'

        #Email subject
        EmailSubject = 'Your New User Account Details'

        #Email address for the service desk, used when email is sent as a point of contact if they have question
        ServiceDeskEmail = 'help@company.com'

        #users home drive permissions
        HomePermission = 'Modify' #Modify is recommended to stop permissions being removed and backups failing!

        #users home drive root, the root share for example \\file-server-01\homes$
        HomeRoot = '\\AD1\homes$'
        HomeDriveLetter = 'H:'
    
        #Groups to add user to, the samaccountname, sid or DN can be used
        Groups = @(
                    'Department1',
                    'Department2',
                    'Department3',
                    'Department4'
                )
    }

#endregion

#region Functions

Function New-EmailTemplate {
param($Name,$Username,$Password,$ServiceDeskEmail)

#taken and modified from https://github.com/leemunroe/responsive-html-email-template/blob/master/email.html
#thanks!

@"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta name="viewport" content="width=device-width" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Really Simple HTML Email Template</title>
<style>
/* -------------------------------------
		GLOBAL
------------------------------------- */
* {
	margin: 0;
	padding: 0;
	font-family: "Helvetica Neue", "Helvetica", Helvetica, Arial, sans-serif;
	font-size: 100%;
	line-height: 1.6;
}
img {
	max-width: 100%;
}
body {
	-webkit-font-smoothing: antialiased;
	-webkit-text-size-adjust: none;
	width: 100%!important;
	height: 100%;
}
/* -------------------------------------
		ELEMENTS
------------------------------------- */
.password {
	color: #348eda;
}
.btn-primary {
	text-decoration: none;
	color: #FFF;
	background-color: #348eda;
	border: solid #348eda;
	border-width: 10px 20px;
	line-height: 2;
	font-weight: bold;
	margin-right: 10px;
	text-align: center;
	display: inline-block;
	border-radius: 25px;
}
.btn-secondary {
	text-decoration: none;
	color: #FFF;
	background-color: #aaa;
	border: solid #aaa;
	border-width: 10px 20px;
	line-height: 2;
	font-weight: bold;
	margin-right: 10px;
	text-align: center;
	display: inline-block;
	border-radius: 25px;
}
.last {
	margin-bottom: 0;
}
.first {
	margin-top: 0;
}
.padding {
	padding: 10px 0;
}
/* -------------------------------------
		BODY
------------------------------------- */
table.body-wrap {
	width: 100%;
	padding: 20px;
}
table.body-wrap .container {
	border: 1px solid #f0f0f0;
}
/* -------------------------------------
		FOOTER
------------------------------------- */
table.footer-wrap {
	width: 100%;	
	clear: both!important;
}
.footer-wrap .container p {
	font-size: 12px;
	color: #666;
	
}
table.footer-wrap a {
	color: #999;
}
/* -------------------------------------
		TYPOGRAPHY
------------------------------------- */
h1, h2, h3 {
	font-family: "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
	color: #000;
	margin: 40px 0 10px;
	line-height: 1.2;
	font-weight: 200;
}
h1 {
	font-size: 36px;
}
h2 {
	font-size: 28px;
}
h3 {
	font-size: 22px;
}
p, ul, ol {
	margin-bottom: 10px;
	font-weight: normal;
	font-size: 14px;
}
ul li, ol li {
	margin-left: 5px;
	list-style-position: inside;
}
/* ---------------------------------------------------
		RESPONSIVENESS
		Nuke it from orbit. It's the only way to be sure.
------------------------------------------------------ */
/* Set a max-width, and make it display as block so it will automatically stretch to that width, but will also shrink down on a phone or something */
.container {
	display: block!important;
	max-width: 600px!important;
	margin: 0 auto!important; /* makes it centered */
	clear: both!important;
}
/* Set the padding on the td rather than the div for Outlook compatibility */
.body-wrap .container {
	padding: 20px;
}
/* This should also be a block element, so that it will fill 100% of the .container */
.content {
	max-width: 600px;
	margin: 0 auto;
	display: block;
}
/* Let's make sure tables in the content area are 100% wide */
.content table {
	width: 100%;
}
</style>
</head>

<body bgcolor="#f6f6f6">

<!-- body -->
<table class="body-wrap" bgcolor="#f6f6f6">
	<tr>
		<td></td>
		<td class="container" bgcolor="#FFFFFF">

			<!-- content -->
			<div class="content">
			<table>
				<tr>
					<td>
						<p>Hi $Name,</p>
						<p>Your new user account has been created.</p>
						<p>You can now login using the details below.</p>
						<h2>Username</h2>
                        <p><span class="password btn-primary">$Username</span></p>
						<h2>Password</h2>
                        <p><span class="password btn-primary">$Password</span></p>
						<p class="padding"></p>
						<p>Thanks,<br/>IT Department</p>
					</td>
				</tr>
			</table>
			</div>
			<!-- /content -->
			
		</td>
		<td></td>
	</tr>
</table>
<!-- /body -->

<!-- footer -->
<table class="footer-wrap">
	<tr>
		<td></td>
		<td class="container">
			
			<!-- content -->
			<div class="content">
				<table>
					<tr>
						<td align="center">
							<p>Want help logging on contact us at: <a href="mailto:$ServiceDeskEmail"><unsubscribe>$ServiceDeskEmail</unsubscribe></a>.
							</p>
						</td>
					</tr>
				</table>
			</div>
			<!-- /content -->
			
		</td>
		<td></td>
	</tr>
</table>
<!-- /footer -->

</body>
</html>
"@

}

#Using try catch to supress errors
function Test-User {
param($Username)
    try
    {
        Get-ADUser -Identity $Username | Out-Null
        return $true
    }
    catch
    {
        return $false
    }
}

function New-Username {
param($FirstName,$LastName)

    #Get basic username first
    $OrigUsername = $FirstName + '.' + $LastName
    $Username = $OrigUsername
    $i = 1

    #while get-aduser returns a result keep trying a different number
    while((Test-User $Username)){
        $Username = $OrigUsername + $i
        $i++
    }

    #unquie username returned
    return $Username

}

function New-Password {

    #generate a new password from GUID to make life easy
    $GUID = [guid]::NewGuid().guid.split('-')

    #in rare cases it fails to meet complexity so having to add a $ on the end
    return (([string](Get-Date).DayOfWeek) + '-' + $GUID[2].ToUpper() + '-' + $GUID[3] + '$')

}

function New-User {
param(
    [string]$HomeRoot,
    [System.Security.AccessControl.FileSystemRights]$HomePermission='Modify',
    [string]$AdminEmail=$null,
    [string]$EmailFrom,
    [string]$EmailSubject,
    [string]$ServiceDeskEmail,
    [string[]]$Groups,
    [string]$OU,
    [string]$HomeDriveLetter
    )

    #Get domain name
    $DomainName = (Get-ADDomain).dnsroot

    foreach($User IN $input){

        #Reset the failures or set if first one
        $Failures = @()

        #Get username and password
        $Username = New-Username -FirstName $User.GivenName -LastName $User.Surname
        $Password = New-Password

        #Build home path
        $HomeDirectory = Join-Path $HomeRoot $Username

        try
        {

            if($Username.length -gt 20){
                throw "$Username is greater than 20 this can not be used, user account not created!"
            }

            #split out username again, why?
            #because if you have a duplicate user you most likely to have duplicae DN!
            $UsernameSplit = $Username.Split('.')

            #Create new user account
            $NewUserInfo = @{
                Path = $OU
                Name = "$($UsernameSplit[1]), $($UsernameSplit[0])"
                DisplayName = "$($UsernameSplit[1]), $($UsernameSplit[0])"
                SamAccountName = $Username
                UserPrincipalName = "$Username@$DomainName"
                HomeDirectory = $HomeDirectory
                HomeDrive = $HomeDriveLetter
                Enabled = $true
                ChangePasswordAtLogon = $true
                AccountPassword = (ConvertTo-SecureString -String $Password -AsPlainText -Force)
                ErrorAction = 'Stop'
            }
            $User | New-ADUser @NewUserInfo

            #Account created OK
            $UserCreated = $true

        }
        catch
        {
            #user failed to create
            Write-Error "Failed to create user '$Username' - $_"
            $Failures += $_.ToString()

            #Account failed to create
            $UserCreated = $false
        }

        #if user account created continue
        if($UserCreated){

            try
            {
                #Loop through the groups and add the user to them
                foreach($Group IN $Groups){
                    Add-ADGroupMember -Identity $Group -Members $Username -ErrorAction Stop
                }

            }
            catch
            {
                Write-Warning "Failed to add user '$Username' to groups - $_"
                $Failures += $_.ToString()
            }


            try
            {
                #if home directory not present create one
                if(-not (Test-Path $HomeDirectory)){
                    New-Item -Path $HomeDirectory -ItemType Directory -ErrorAction stop | Out-Null
                    $ACL = Get-Acl $HomeDirectory -ErrorAction Stop
                    $Inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
                    $Propagation = [system.security.accesscontrol.PropagationFlags]"None"
                    $Rule = New-Object system.security.accesscontrol.filesystemaccessrule($Username,$HomePermission, $Inherit, $Propagation, "Allow") -ErrorAction Stop
                    $ACL.SetAccessRule($Rule)
                    Set-Acl $HomeDirectory $ACL -ErrorAction Stop | Out-Null
                }

            }
            catch
            {
                #failed to create home directory, non fatal user can still work so warning only
                Write-Warning "Failed to create user home directory '$HomeDirectory' for '$Username' - $_"
                $Failures += $_.ToString()
            }


            try
            {
                #All seems great so far so lets email them the good news
                $Body = New-EmailTemplate -Name $User.GivenName -Username $Username -Password $Password -ServiceDeskEmail $ServiceDeskEmail

                if($AdminEmail -and $PSEmailServer){
                    Send-MailMessage -To $User.EmailAddress -Bcc $AdminEmail -Body $Body -BodyAsHtml -From $EmailFrom -Subject $EmailSubject -ErrorAction Stop
                }elseif($PSEmailServer){
                    Send-MailMessage -To $User.EmailAddress -Body $Body -BodyAsHtml -From $EmailFrom -Subject $EmailSubject -ErrorAction Stop
                }
            }
            catch
            {
                Write-Warning "Failed to send email with password for user '$Username' - $_"
                $Failures += $_.ToString()
            }

        }#end if user created


        #Output some basic details for reference
        $Out = '' | Select-Object Username, HomeDirectory, Password, AccountCreated, HomeCreated, Failures
        $Out.Username = $Username
        $Out.HomeDirectory = $HomeDirectory
        $Out.Password = $Password
        $Out.AccountCreated = (Test-User $Username)
        $Out.HomeCreated = (Test-Path $HomeDirectory)
        $Out.Failures = $Failures -join ';'
        $Out

        #Remove any variables created incase it causes a duplicate
        Remove-Variable -Name Username,HomeDirectory,Password,Failures,NewUserInfo -ErrorAction SilentlyContinue


    }#end for each user in CSV

}

#endregion

#region Execute creation of users

    Import-Csv $CSVFile | New-User @NewUserConfig | Export-Csv $ResultsFile -NoTypeInformation

#endregion
