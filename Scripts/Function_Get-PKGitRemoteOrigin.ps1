#requires -Version 3
Function Get-PKGitRemoteOrigin {
<#
.SYNOPSIS
    Gets the remote origin for a git repo, using the current path.

.DESCRIPTION
    Gets the remote origin for a git repo, using the current path.
    Uses invoke-expression and "git remote show origin."
    Requires git.

.Notes
    Name    : Function_Get-PKGitRemoteOrigin.ps1
    Author  : Paula Kingsley
    Version : 1.1.2
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-05-29 - Moved to separate file, 
                              renamed from Get-PKGitRepoOrigin,
                              updated verbose output 
        v1.1.0 - 2016-05-30 - Changed output to multidimensional array, added 
                              -OutputType parameter
        v1.1.1 - 2016-06-06 - Added requires statement for parent module,
                              link to github repo
        v1.1.2 - 2016-08-01 - Renamed with Function_ prefix


.EXAMPLE
    PS C:\Users\lsimpson\Projects > Get-PKGitRemoteOrigin -Verbose
    # Returns the full remote origin details for the current repo

        VERBOSE: PSBoundParameters: 
	
        Key          Value                
        ---          -----                
        Verbose      True                 
        OutputType   Full                 
        ComputerName WORKSTATION1     
        ScriptName   Get-PKGitRemoteOrigin
        Version      1.1.0                

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'

        Fetch URL                              : https://github.com/lsimpson/projects.git
        Push URL                               : https://github.com/lsimpson/projects.git
        HEAD branch                            : master
        Remote branch                          : master tracked
        Local branch configured for 'git pull' : master merges with remote master
        Local ref configured for 'git push'    : master pushes to master (local out of date)


.EXAMPLE
PS C:\Users\lsimpson\Projects > Get-PKGitRemoteOrigin  -OutputType PullURLOnly -Verbose
    # Returns the pull URL only for the current repo

        VERBOSE: PSBoundParameters: 
	
        Key          Value                
        ---          -----                
        OutputType   PullURLOnly          
        Verbose      True                 
        ComputerName WORKSTATION1      
        ScriptName   Get-PKGitRemoteOrigin
        Version      1.1.0                

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'
        https://github.com/lsimpson/projects.git

.EXAMPLE
    PS C:\Users\lsimpson\Projects > Get-PKGitRemoteOrigin -OutputType PushURLOnly -Verbose
    # Returns the push URL only for the current repo

        VERBOSE: PSBoundParameters: 
	
        Key          Value                
        ---          -----                
        OutputType   PushURLOnly          
        Verbose      True                 
        ComputerName WORKSTATION1      
        ScriptName   Get-PKGitRemoteOrigin
        Version      1.1.0                

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'

        https://github.com/lsimpson/projects.git


.EXAMPLE
    PS C:\Users\lsimpson\catvideos> Get-PKGitRemoteOrigin -Verbose
    # Returns an error in a directory not managed by git

        VERBOSE: PSBoundParameters: 
	
        Key          Value                
        ---          -----                
        OutputType   Full          
        Verbose      True                 
        ComputerName WORKSTATION1      
        ScriptName   Get-PKGitRemoteOrigin
        Version      1.1.0                

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\catvideos'
        
        fatal: Not a git repository (or any of the parent directories): .git

.LINK
    https://github.com/lanwench/PKGit

#>

[cmdletbinding()]
Param(
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Type of output to return: full (default), push URL only, pull URL only"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet ("Full","PushURLOnly","PullURLOnly")]
    [string] $OutputType = "Full"

)
Process{
    
    # Version from comment block
    [version]$Version = "1.1.2"

    # Preferences
    $ErrorActionPreference = "Stop"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("Version",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Current path
    $CurrentPath = (Get-Location).Path
    
    # Do it
    Write-Verbose "Find Git remote origin for '$CurrentPath'"
    Try {
        $Cmd = "git remote show origin 2>&1"
        $Origin = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False
        If ($Origin -like "*remote origin*") {
            # Convert from ugly strings to semi-ugly array
            $TempArr = ( ( $Origin -replace(":`n",": ") ) -replace("`n",",") ).split(",").TrimStart().replace("* remote origin",$Null) | Where-Object {$_}
            
            # Create nicer multidimensional array
            $HT = [ordered]@{}
            $TempArr | ForEach-Object {
                $HT.Add($(($_ -split(": "))[0].replace("  "," ")),$((($_ -split(": "))[1]).TrimStart()))
            }
            [array]$Results = New-Object PSObject -Property $HT

            # Return object based on outputtype selection
            Switch ($OutputType) {
                Full {Write-Output $Results}
                PushURLOnly {Write-Output $($Results."Push URL")}
                PullURLOnly {Write-Output $($Results."Fetch URL")}
            }
        }
        ElseIf ($Origin -like "*fatal*") {
            Write-Output "ERROR: $($Origin.ToString())"
        }
        Else {
            Write-Output "ERROR: General error"
        }
    }
    Catch {
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $ErrorDetails")   
    }
  
}
} #end Get-PKGitRemoteOrigin

