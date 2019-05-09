#requires -Version 4
Function Set-PKGitEmail {
<#
.SYNOPSIS
    Change a global or local git repo email address (such as to obfuscate contact info in a public repo)

.DESCRIPTION
    Change a global or local git repo email address (such as to obfuscate contact info in a public repo)
    Verifies that git is installed/available in the path, and that the current working directory contains a git repo
    Supports ShouldProcess
    Returns a PSObject or Boolean (if -Quiet)

.NOTES
    Name    : Function_Set-PKGitEmail.ps1 
    Created : 2018-08-13
    Author  : Paula Kingsley
    Version : 01.01.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2018-08-13 - Created script
        v01.01.0000 - 2019-04-09 - Created script

.EXAMPLE
    PS C:\Repos\Repo1> Set-PKGitEmail -Scope Local -EmailAddress "jbloggs@users.noreply.github.com" -Verbose

       VERBOSE: PSBoundParameters: 
        Key           Value                            
        ---           -----                            
        Scope         Local                            
        EmailAddress  lanwench@users.noreply.github.com
        Verbose       True                             
        Quiet         False                            
        ScriptName    Set-PKGitEmail                   
        ScriptVersion 1.0.0                            

        Set local config user email address
        Local config user email address is not currently specified in C:\Repos\Repo1
        Successfully set local config user email address to 'jbloggs@users.noreply.github.com' in C:\Repos\Repo1


        Scope      : Local
        IsChanged  : True
        OldAddress : (none)
        NewAddress : jbloggs@users.noreply.github.com
        Target     : C:\Repos\Repo1
        Messages   : 

.EXAMPLE
    PS C:\Users\Jbloggs\CurrentWork\Design> Set-PKGitEmail -Scope Local -EmailAddress foo@bar.com -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key           Value         
        ---           -----         
        Scope         Local         
        EmailAddress  foo@bar.com   
        Verbose       True          
        Quiet         False         
        ScriptName    Set-PKGitEmail
        ScriptVersion 1.0.0         

        Set local config user email address
        Local config user email address is currently set to 'jbloggs@users.noreply.github.com' in C:\Users\Jbloggs\CurrentWork\Design
        Successfully changed local config user email address from 'jbloggs@users.noreply.github.com' to 'foo@bar.com' in C:\Users\Jbloggs\CurrentWork\Design
        
        Scope      : Local
        IsChanged  : True
        OldAddress : jbloggs@users.noreply.github.com
        NewAddress : foo@bar.com
        Target     : C:\Users\Jbloggs\CurrentWork\Design
        Messages   : 

.EXAMPLE
    PS C:\Projects\RocketLauncher> Set-PKGitEmail -Scope Local -EmailAddress jbloggs@users.noreply.github.com -Quiet -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                            
        ---           -----                            
        Scope         Local                            
        EmailAddress  jbloggs@users.noreply.github.com
        Quiet         True                             
        ScriptName    Set-PKGitEmail                   
        ScriptVersion 1.0.0                            



        VERBOSE: Set local config user email address
        VERBOSE: Local config user email address is currently set to 'foo@bar.com' in C:\Projects\RocketLauncher
        VERBOSE: Successfully changed local config user email address from 'foo@bar.com' to 'jbloggs@users.noreply.github.com' in C:\Projects\RocketLauncher
        True

.EXAMPLE
    PS C:\Users\JBloggs> Set-PKGitEmail -Scope Global -EmailAddress lanwench@users.noreply.github.com

        Set global config user email address
        ERROR: C:\Users\JBloggs is not a git repository

        Scope      : Global
        IsChanged  : False
        OldAddress : Error
        NewAddress : lanwench@users.noreply.github.com
        Target     : WORKSTATION14
        Messages   : C:\Users\JBloggs is not a git repository

#>

[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(

    [Parameter(
        Mandatory = $True,
        Position = 0,
        HelpMessage="Set email address globally on computer or at local repo level"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Global","Local")]
    [string]$Scope,

    [Parameter(
        Mandatory = $True,
        Position = 1,
        HelpMessage="Email address for reporting"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_ -as [mailaddress]})]
    [string]$EmailAddress,

    [Parameter(
        HelpMessage = "Suppress non-verbose console output"
    )]
    [Switch]$Quiet
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.01.0000"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    
    # Display our parameters
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    $WarningPreference = "Continue"

    # Prerequisites
    If (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

    # Output object
    $Output = New-Object PSObject -Property ([ordered]@{
        Scope      = $Scope
        IsChanged  = $False
        OldAddress = "Error"
        NewAddress = $EmailAddress
        Target     = $Null
        Messages   = "Error"
    })
    Switch ($Scope) {
        Local  {$Output.Target = $PWD.Path}
        Global {$Output.Target = $Env:ComputerName}
    }
    
    $Activity = "Set $($Scope.ToLower()) config user email address"
    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = $Activity
    $FGColor = "Yellow"
    If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}
    
}
Process {
    
    # Set the flag
    [switch]$Continue = $False

    # Make sure we're in a git repo
    Try {
    
        $TestCmd = $Null                
        $TestCmd = "git rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($TestCmd)

        If (($Null = Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True) {
            $Continue = $True
        }
        Else {
            $Msg = "$($PWD.Path) is not a git repository"
            If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
            Else {Write-Verbose $Msg}

            #$Output.IsChanged = $False
            $Output.Messages = $Msg
        }
    }
    Catch {
        $Msg = "Failed to confirm $($PWD.Path) is a git repository"
        If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}
        If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
        Else {Write-Verbose $Msg}
        
        $Output.Messages = $Msg
    }
    
    # If we are...
    If ($Continue.IsPresent) {
                
        # Reset flag
        $Continue = $False
        
        #Initialize/empty variables
        $CurrentEmail = $NewEmail = $Null

        # For the confirmation prompts
        Switch ($Scope)  {
            Local  {
                $Target = $($PWD.Path)
                $TargetStr = "in $Target"
            }
            Global {
                $Target = $Env:ComputerName
                $TargetStr = "on $Target"
            }
        }

        # Command to get the current email address
        $GetEmailCmd = $Null
        $GetEmailCmd = "git config --$($Scope.ToLower()) --get user.email"
                
        # Command to set the new email address
        $SetEmailCmd = $Null
        $SetEmailCmd = "git config --$($Scope.ToLower()) user.email $EmailAddress"
                    
        # Get the current email address, if any
        $ScriptBlock = [scriptblock]::Create($GetEmailCmd)
        $CurrentEmail = Invoke-Command -ScriptBlock $ScriptBlock

        # If there is one...
        If ($CurrentEmail) {
            
            $Output.OldAddress = $CurrentEmail        

            # ..if it matches, exit
            If ($CurrentEmail -eq $EmailAddress) {
                        
                $Msg = "$Scope config user email address is already set to '$EmailAddress' $TargetStr; no change needed"
                $FGColor = "Red"
                If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg} 
                
                $Msg = "No change needed"
                $Output.IsChanged = $False
                $Output.Messages = $Msg   
            }
                    
            # Or create console output & confirmation prompts
            Else {
                $Msg = "$Scope config user email address is currently set to '$CurrentEmail' $TargetStr"
                $ConfirmMsg = "`n`n`tReplace $($Scope.ToLower()) config user email address`n`t'$CurrentEmail'`n`twith '$EmailAddress'`n`n"
                $FGColor = "White"
                If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}
                $Continue = $True
            }

        } # end if current address
        Else {
            $Msg = "$Scope config user email address is not currently specified $TargetStr"
            $ConfirmMsg = "`n`n`tSet $($Scope.ToLower()) config user email address `n`tto '$EmailAddress'`n`n"

            $FGColor = "White"
            If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}
            $Continue = $True

            $Output.OldAddress = $Null
        }

        # Prompt to change the email address
        If ($Continue.IsPresent) {
    
            If ($PSCmdlet.ShouldProcess($Target,$ConfirmMsg)) {
                        
                Try {
                    $ScriptBlock = [scriptblock]::Create($SetEmailCmd)
                    $Null = Invoke-Command -ScriptBlock $ScriptBlock -Verbose:$False -ErrorAction Stop
                            
                    #Verify it
                    $ScriptBlock = [scriptblock]::Create($GetEmailCmd)
                    $NewEmail = Invoke-Command -ScriptBlock $ScriptBlock
                    
                    # If it worked...                            
                    If ($NewEmail -eq $EmailAddress) {
                        
                        
                        If ($CurrentEmail) {$Msg = "Successfully changed $($Scope.ToLower()) config user email address from '$CurrentEmail' to '$NewEmail' $TargetStr"}
                        Else {$Msg = "Successfully set $($Scope.ToLower()) config user email address to '$NewEmail' $TargetStr"}    
                        
                        $FGColor = "Green"
                        If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                        Else {Write-Verbose $Msg}
                        
                        $Output.IsChanged = $True
                        $Output.Messages = $Null
                        
                    }
                    Else {
                        If ($CurrentEmail) {$Msg = "Failed to change email address from '$CurrentEmail' to '$NewMail' $TargetStr"}
                        Else {$Msg = "Failed to set email address to '$NewMail' $TargetStr"}
                        If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}

                        If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
                        Else {Write-Verbose $Msg}
                        
                        $Output.IsChanged = $False
                        $Output.Messages = $Msg
                    }
                }
                Catch {
                    $Msg = "Failed to invoke command '$ScriptBlock'`n$($_.Exception.Message)"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}
                    If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
                    Else {Write-Verbose $Msg}
                    
                    $Output.IsChanged = $True
                    $Output.Messages = $Msg

                }
            
            } #end if confirm

            Else {
                $Msg = "Operation cancelled by user"
                $FGColor = "Red"
                If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}
                
                $Output.IsChanged = $True
                $Output.Messages = $Msg
            }

        } #end if continue

    } #end if continue after testing for repo

    If ($Quiet.IsPresent) {Write-Output $Output.IsChanged}
    Else {Write-Output $Output}


} #end process

}