#requires -Version 3
Function Get-PKGitStatus {
<#
.SYNOPSIS
    Gets the status for a git repo, using the current path

.DESCRIPTION
    Gets the status for a git repo, using the current path
    Uses invoke-expression and "git status"
    Switches change output
    Requires git, duh

.Notes
    Name    : Function_Get-PKGitRemoteOrigin.ps1
    Author  : Paula Kingsley
    Version : 1.0.0
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-08-01 - Created script

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
        HelpMessage = "Type of output to return: full (default), or eventually something else"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet ("Full")]
    [string] $OutputType = "Full"

)
Process{
    
    # Version from comment block
    [version]$Version = "1.0.0"

    # Preferences
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    $WarningPreference = "SilentlyContinue"
    
    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose     = $False
    }

    # Current path
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
    $CurrentParams.Add("Version",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Make sure this is actually a repo
    If (($Null = Test-PKGitRepo -ErrorAction Stop -Verbose:$False) -ne $True) {
        $Msg = "Folder '$CurrentPath' not managed by git"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

    # Do it
    Write-Verbose "Get Git status for '$CurrentPath'"
    Try {
        $Cmd = "git status 2>&1"
        $Status = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False
        
        # Need to convert results into a psobject but for now just return the string
        Write-Output $Status

        <#
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
        #>

    }
    Catch {
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $ErrorDetails")   
    }
  
}
} #end Get-PKGitRemoteOrigin

