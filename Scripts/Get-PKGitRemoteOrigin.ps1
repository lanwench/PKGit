
Function Get-PKGitRemoteOrigin {
<#
.SYNOPSIS
    Gets the remote origin for a git repo, using the current path.

.DESCRIPTION
    Gets the remote origin for a git repo, using the current path.
    Uses invoke-expression and "git remote show origin."
    Requires git.

.Notes
    Name    : Get-PKGitRemoteOrigin.ps1
    Author  : Paula Kingsley
    Version : 1.0.1
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-05-29 - Moved to separate file, 
                              renamed from Get-PKGitRepoOrigin,
                              updated verbose output 

.EXAMPLE
    PS C:\Users\lsimpson\projects\history> Get-PKGitRemoteOrigin -Verbose

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects\history'
        * remote origin
          Fetch URL: https://github.com/lsimpson/history.git
          Push  URL: https://github.com/lsimpson/history.git
          HEAD branch: master
          Remote branch:
            master tracked
          Local branch configured for 'git pull':
            master merges with remote master
          Local ref configured for 'git push':
            master pushes to master (local out of date)

.EXAMPLE
    PS C:\Users\lsimpson\music> Get-PKGitRemoteOrigin -Verbose
        
        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\music'
        fatal: Not a git repository (or any of the parent directories): .git

#>

[cmdletbinding()]
Param()
Process{
    
    # Version from comment block
    [version]$Version = "1.0.1"

    # Preferences
    $ErrorActionPreference = "Stop"

    # For messages
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Current path
    $CurrentPath = (Get-Location).Path
    
    Write-Verbose "Find Git remote origin for '$CurrentPath'"
    Try {
        $Cmd = "git remote show origin 2>&1"
        $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False
        If ($Results -like "*remote origin*") {
            $FGColor = "Green"
            $Host.UI.WriteLine($FGColor,$BGColor,$Results)
        }
        ElseIf ($Results -like "*fatal*") {
            $FGColor = "Red"
            $Host.UI.WriteLine($FGColor,$BGColor,$Results.ToString())
        }
        Else {
            $FGColor = "Red"
            $Host.UI.WriteLine($FGColor,$BGColor,"Error getting origin")
        }
    }
    Catch {
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $ErrorDetails")   
    }
  
}
} #end Get-PKGitRemoteOrigin

