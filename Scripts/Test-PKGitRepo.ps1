Function Test-PKGitRepo {
<#
.SYNOPSIS 
    Verifies that the current directory is managed by Git.

.DESCRIPTION
    Uses invoke-expression and "git rev-parse --is-inside-work-tree"
    to verify that the current directory is managed by Git.
    Returns a boolean.
    Requires git, of course.

.NOTES
    Name    : Test-PKGitRepo.ps1
    Author  : Paula Kingsley
    Version : 1.0.1
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-05-29 - Moved into separate file,
                              updated verbose output

.EXAMPLE
    PS C:\Users\lsimpson\projects> Test-PKGitRepo -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key          Value          
        ---          -----          
        Verbose      True           
        ComputerName PKINGSLEY-06398
        ScriptName   Test-PKGitRepo 

        VERBOSE: Check whether 'C:\Users\lsimpson\projects' contains a Git repo
        True

.EXAMPLE
    PS C:\Users\bsimpson\catvideos> Test-PKGitRepo -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key          Value          
        ---          -----          
        Verbose      True           
        ComputerName WORKSTATION14
        ScriptName   Test-PKGitRepo 

        VERBOSE: Check whether 'C:\Users\bsimpson\catvideos' contains a Git repo
        False
#>
[CmdletBinding()]
Param()
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.1"

    # Preference
    $ErrorActionPreference = "Stop"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    Try {
        $CurrentPath = (Get-Location).Path
        Write-Verbose "Check whether '$CurrentPath' contains a Git repo"
        $Cmd = "git rev-parse --is-inside-work-tree  2>&1"
        $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False
        If ($Results -eq $True) {$True}
        Else {$False}
    }
    Catch {
        $_.Exception.Message
    }
}
} #end Test-PKGitRepo
