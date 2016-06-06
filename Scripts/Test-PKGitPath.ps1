#requires -Module PKGit
Function Test-PKGitPath {
<#
.SYNOPSIS
    Looks for git in the local environment path

.DESCRIPTION
    Looks for git in the local environment path
    Tests validity of path
    Optional -BooleanOutput switch

.NOTES
    Name    : Test-PKGitPath
    Author  : Paula Kingsley
    Version : 1.0.1
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2016-05-29 - Moved to separate file, updated vebose output
        v1.0.2 - 2016-06-06 - Added requires statement for parent module,
                              link to github repo

.EXAMPLE
    PS C:\> Test-PKGitPath -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value          
        ---           -----          
        Verbose       True           
        BooleanOutput False          
        ComputerName  WORKSTATION14
        ScriptName    Test-PKGitPath 

        VERBOSE: Look for 'git' in WORKSTATION14 path
        Valid directory 'C:\Program Files (x86)\Git\cmd' found in path

.EXAMPLE
    PS C:\> Test-PKGitPath -BooleanOutput
    
        True

.EXAMPLE
    PS C:\> Test-PKGitPath -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value          
        ---           -----          
        Verbose       True           
        BooleanOutput False          
        ComputerName  WORKSTATION14
        ScriptName    Test-PKGitPath 

        VERBOSE: Look for 'git' in WORKSTATION14 path
        No path matching 'git' found in environment path

.EXAMPLE
    PS C:\> Test-PKGitPath -BooleanOutput
        
        False

.LINK
    https://github.com/lanwench/PKGit

#>
[CmdletBinding()]
Param(
    [switch]$BooleanOutput
)
Process {
    
    # Preference
    $ErrorActionPreference = "Stop"

    # Version from comment block
    [version]$Version = "1.0.2"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"
    
    # Save curent path as an array
    $CurrentPath = $Env:Path -split(";")
    
    # For messages
    $BGColor = $Host.UI.RawUI.BackgroundColor

    Write-Verbose "Look for 'git' in $Env:ComputerName path"
    Try {
        If ($LocalPath = $Env:Path -split(";") -match "git") {
            If ($Null = Test-Path $LocalPath -ErrorAction Stop -Verbose:$False) {
                If ($BooleanOutput.IsPresent) {$True}
                Else {
                    $Msg = "Valid directory '$LocalPath' found in path"
                    $FGColor = "Green"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
            }
            Else {
                If ($BooleanOutput.IsPresent) {$False}
                Else {
                    $Msg = "Invalid directory '$LocalPath' found in path"
                    $FGColor = "Red"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
            }
        }
        Else {
            If ($BooleanOutput.IsPresent) {$False}
            Else {
                $Msg = "No path matching 'git' found in environment path"
                $FGColor = "Red"
                $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
            }
        }
    }
    Catch {
        If ($BooleanOutput.IsPresent) {$False}
        Else {
            $Msg = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg")
        }
    }
}

} #end Test-PKGitPath