Function Invoke-PKGitPull {
<#
.SYNOPSIS 
    Invokes git pull

.DESCRIPTION
    Uses invoke-expression and "git pull" with optional parameters
    Requires git, of course.

.NOTES
    Name    : Invoke-PKGitPull.ps1
    Author  : Paula Kingsley
    Version : 1.0.0
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPull -Verbose
    # Invokes git-pull in the current directory

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                  
        ---           -----                                  
        Verbose       True                                   
        Quiet         False                                  
        Rebase        NoRebase                               
        Path          C:\Users\lsimpson\git\homework
        ComputerName  WORKSTATION1
        ScriptName    Invoke-PKGitPull                       
        ScriptVersion 1.0.0                                  

        Pull URL: https://github.com/lsimpson/homework.git

        VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?

        VERBOSE: Redirecting output streams.
        WARNING: Ignoring known Git command 'pull'. The process timeout will be disabled and may cause the ISE to hang.
        Updating 20bbf99..e7b5419
        Fast-forward
         .../Reports/kittens.csv   | 241 -------
         .../Essays/HeideggerAndKittens.docx | 757 ---------------------
         3 files changed, 998 deletions(-)
        From https://github.com/lsimpson/homework.git
           20bbf99..e7b5419  master     -> origin/master

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPull -Verbose
    # Invokes git-pull in the current directory

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                  
        ---           -----                                  
        Verbose       True                                   
        Quiet         False                                  
        Rebase        NoRebase                               
        Path          C:\Users\lsimpson\git\homework
        ComputerName  WORKSTATION1
        ScriptName    Invoke-PKGitPull                       
        ScriptVersion 1.0.0                                  

        Pull URL: https://github.com/lsimpson/homework.git

        VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?

        VERBOSE: Redirecting output streams.
        WARNING: Ignoring known Git command 'pull'. The process timeout will be disabled and may cause the ISE to hang.
        
        Already up-to-date.

.EXAMPLE
    PS C:\Users\lsimpson\git\homework> Invoke-PKGitPull -Verbose
    # Invokes git-pull in the current directory; cancels

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                  
        ---           -----                                  
        Verbose       True                                   
        Quiet         False                                  
        Rebase        NoRebase                               
        Path          C:\Users\lsimpson\git\homework
        ComputerName  WORKSTATION1
        ScriptName    Invoke-PKGitPull                       
        ScriptVersion 1.0.0                                  

        Pull URL: https://github.com/lsimpson/homework.git

        VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?
        Operation cancelled
#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        HelpMessage = "Quiet"
    )]
    [Switch]$Quiet = $False,

    [Parameter(
        HelpMessage = "Quiet"
    )]
    [ValidateSet("NoRebase","Interactive","Preserve")]
    [String]$Rebase = "NoRebase"
)
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.0"

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
        $Origin = Get-PKGitRemoteOrigin -OutputType PullURLOnly -Verbose:$False -ErrorAction Stop
        If ($Origin -notlike "ERROR:*") {
            $FGColor = "Cyan"
            If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"Pull URL: $Origin")}
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
        $Pull = "git pull"

        # Parameters to modify command
        If ($CurrentParams.Quiet) {
            $Pull = $Pull +" -q"
        }
        If ($CurrentParams.Verbose) {
            $Pull = "git pull -v"
        }
        
        # Danger Will Robinson
        If ($CurrentParams.Rebase -ne "NoRebase") {
            Write-Warning "You chose '$($Rebase.tolower())' rebase. Be sure you know what you're doing."
            Write-Warning "HAHAHA We aren't actually goind to use this yet."
            #$Pull = $Pull + "-r $Rebase"
        }

        # Redirect output
        $Cmd = $Pull + " 2>&1"

        Write-Verbose "Invoke '$Pull' to the current repo '$CurrentPath' from remote origin '$Origin'?"

        If ($PSCmdlet.ShouldProcess($CurrentPath,"Invoke '$Pull' from remote origin '$Origin'")) {
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
} #end Invoke-PKGitPull
