<#
#requires -Module PKGit
Function Add-PKGitFile {

.SYNOPSIS 
    Invokes git pull

.DESCRIPTION
    Uses invoke-expression and "git pull" with optional parameters,
    displaying the origin master URL.
    Requires git, of course.

.NOTES
    Name    : Add-PKGitFile.ps1
    Author  : Paula Kingsley
    Version : 1.0.1
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-06-06 - Added requires statement for parent
                              module, link to github repo

    To do: Rebase options (parameter currently does nothing)        

.EXAMPLE
 

.LINK
    https://github.com/lanwench/PKGit


[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        HelpMessage = "Quiet"
    )]
    [Switch]$AllFiles = $False,

    [Parameter(
        HelpMessage = "Quiet"
    )]
    [Switch]$Quiet = $False


)
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.1"

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
} #end Add-PKGitFile



#

function Save-OpenFile {
    $Files = @()

    foreach ($Tab in $psISE.PowerShellTabs)
    {
        foreach ($File in ($Tab.Files | Where-Object { !$_.IsUntitled }))
        {
            $Files += $File.FullPath
        }
    }

    $Files | Out-File -FilePath $SavePath
}





##>