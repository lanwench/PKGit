#requires -Version 3
Function Invoke-PKGitPush {
<#
.SYNOPSIS 
    Invokes git push in the current directory

.DESCRIPTION
    Uses invoke-expression and "git push" with optional parameters.
    Verfies current directory holds a git repo and displays push URL.
    Requires git, of course.

.NOTES
    Name    : Function_Invoke-PKGitPush.ps1
    Author  : Paula Kingsley
    Version : 1.0.2
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-06-06 - Added requires statement for parent
                              module, link to github repo
        v1.0.2 - 2016-08-01 - Renamed with Function_ prefix

    To do: add more parameters once I figure out what I want to use, suppress warnings from posh-git?
        

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPush -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                  
        ---           -----                                  
        Verbose       True                                   
        Quiet         False                                  
        Path          C:\Users\lsimpson\git\homework
        ComputerName  WORKSTATION1     
        ScriptName    Invoke-PKGitPush                       
        ScriptVersion 1.0.0                                  

        Push URL: https://github.com/lsimpson/homework.git
        VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
        VERBOSE: Redirecting output streams.
        WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.
        To https://github.com/lsimpson/homework.git
           39760e5..20bbf99  master -> master

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPush -Verbose
    # Invokes git-push in the current directory

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                  
        ---           -----                                  
        Verbose       True                                   
        Quiet         False                                  
        Path          C:\Users\lsimpson\git\homework
        ComputerName  WORKSTATION1     
        ScriptName    Invoke-PKGitPush                       
        ScriptVersion 1.0.0                                  

        Push URL: https://github.com/lsimpson/homework.git

        VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
        VERBOSE: Redirecting output streams.
        WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.
        
        Already up-to-date.

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPush -Quiet
    # Invokes git-push in the current directory, with -quiet
     
        WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPush
    # Invokes git-push in the current directory and cancels when prompted to confirm

        Push URL: https://github.com/lsimpson/homework.git
        VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
        Operation cancelled

.LINK
    https://github.com/lanwench/PKGit
    
#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        HelpMessage = "Quiet"
    )]
    [Switch]$Quiet = $False
)
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.2"

    # Preference
    $ErrorActionPreference = "Stop"

    # Where we are
    $CurrentPath = (Get-Location).Path

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("Path",$CurrentPath)
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Colors
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Make sure this is actually a repo
    If (($Null = Test-PKGitRepo -ErrorAction Stop -Verbose:$False) -ne $True) {
        $Msg = "Folder '$CurrentPath' not managed by git"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }
    
    # Show the origin
    Try {
        $Origin = Get-PKGitRemoteOrigin -OutputType PushURLOnly -Verbose:$False -ErrorAction Stop
        If ($Origin -notlike "ERROR:*") {
            $FGColor = "Cyan"
            If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"Push URL: $Origin")}
        }
        Else {
            $FGColor = "Red"
            $Msg = "Can't find remote origin"
            $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
            Break
        }
    }
    Catch {
        $FGColor = "Red"
        $Msg = "Can't check remote origin"
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteLine($BGColor,$FGColor,"$Msg`n$ErrorDetails")
        Break
    }

    # If we found it, continue
    Try {
        
        # Command
        $Push = "git push"

        # Parameters to modify command
        If ($CurrentParams.Quiet) {
            $Push = $Push +" -q"
        }
        If ($CurrentParams.Verbose) {
            $Push = "git push -v"
        }
        
        # Redirect output
        $Cmd = $Push + " 2>&1"

        Write-Verbose "Invoke '$Push' from the current repo '$CurrentPath' to remote origin '$Origin'?"

        If ($PSCmdlet.ShouldProcess($CurrentPath,"Invoke '$Push' to remote origin '$Origin'")) {
            $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False -WarningAction SilentlyContinue
            $Results
        }
        Else {
            $FGColor = "Yellow"
            $Msg = "Operation canceled"
            $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
        }
    }
    Catch {
        $Msg = "General error"
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
    }
}
} #end Invoke-PKGitPush
