
Function Get-PKGitInstall {
<#
.SYNOPSIS    
    Looks for git.exe on the local computer

.DESCRIPTION
    Looks for git.exe on the local computer. Accepts full path to executable
    or drive/directory path and searches recursively until it finds the first match.
    Uses invoke-expression and "git rev-parse --is-inside-work-tree"
    Optional -BooleanOutput returns true/false instead of path.

.Notes
    Name    : Get-PKGitInstall.ps1
    Author  : Paula Kingsley
    Version : 1.0.2
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **
        
        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2-16-05-29 - Moved to individual file from main psm1 file; 
                              made path mandatory, added help
        v1.0.2 - 2016-05-29 - Changed true output for directory input 
                              to include full path to file
                                 

.EXAMPLE
    PS C:\>$ Get-PKGitInstall -GitPath 'C:\Program Files (x86)\' -Verbose
    
        VERBOSE: PSBoundParameters: 
	
        Key           Value                                             
        ---           -----                                             
        GitPath       C:\Program Files (x86)\
        Verbose       True                                              
        BooleanOutput False                                             
        ComputerName  WORKSTATION1                                
        ScriptName    Get-PKGitInstall                                  
        ScriptVersion 1.0.0                                            


        VERBOSE: Search 'C:\Program Files (x86)\'
        Git.exe was not found in 'C:\Program Files (x86)\Git\bin'

.EXAMPLE
    PS C:\> Get-PKGitInstall -GitPath "C:\Users\jbloggs\Dropbox\Portable\GitWindows\bin\git.exe" -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                                     
        ---           -----                                                     
        GitPath       C:\Users\jbloggs\Dropbox\Portable\GitWindows\bin\git.exe
        Verbose       True                                                      
        BooleanOutput False                                                     
        ComputerName  WORKSTATION7                                        
        ScriptName    Get-PKGitInstall                                          
        ScriptVersion 1.0.0                                                     
    
        VERBOSE: Validate path 'C:\Users\jbloggs\Dropbox\Portable\GitWindows\bin\git.exe'
        Valid path 'C:\Users\jbloggs\Dropbox\Portable\GitWindows\bin\git.exe'

.EXAMPLE
    PS C:\> Get-PKGitInstall -GitPath 'C:\Program Files (x86)' -BooleanOutput
                                                       
        False
#>

[cmdletbinding()]
Param(
    [Parameter(
        Mandatory   = $True,
        HelpMessage = "Full path to git.exe"
    )]
    [string]$GitPath, 

    [Parameter(
        Mandatory = $False
    )]
    [switch]$BooleanOutput
)
Process{

    # Version from comment block
    [version]$Version = "1.0.2"

    # Preference
    $ErrorActionPreference = "Stop"

    # Colors
    $BGColor = $Host.UI.RawUI.BackgroundColor
    
    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If ($GitPath -match ".exe") {
        Write-Verbose "Validate path '$Gitpath'"
        Try {
            If (-not ($Null = Test-Path $GitPath -ErrorAction Stop)){
                
                If (-not $BooleanOutput.IsPresent) {
                    $FGColor = "Red"
                    $Msg = "Invalid path '$Gitpath'"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
                Else {$False}
            }
            Else {
                If (-not $BooleanOutput.IsPresent) {
                    $FGColor = "Green"
                    $Msg = "Valid path '$GitPath'"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
                Else {$True}
            }
        }
        Catch {
            $Msg = "Git not found"
            $ErrorDetails = $_.Exception.Message
            If (-not $BooleanOutput.IsPresent) {
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
            }
            Else {$False}
            Break
        }
    }
    Else {
        Write-Verbose "Search '$GitPath'"
        If ($Null = Test-Path $GitPath -ErrorAction Stop) {
            If ($Results = (Get-ChildItem -Path $GitPath -Filter "git.exe" -Recurse -ErrorAction Stop -Verbose:$False | Select -First 1)) {
                If (-not $BooleanOutput.IsPresent) {
                    $FGColor = "Green"
                    $Msg = "Git.exe was found in '$($Results.FullName)'"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
                else {$True}
            }
            Else {
                If (-not $BooleanOutput.IsPresent) {
                    $FGColor = "Red"
                    $Msg = "Git.exe was not found in '$GitPath'"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                }
                Else {$False}
            }
        }
        Else {
            If (-not $BooleanOutput.IsPresent) {
                $Msg = "Invalid path '$GitPath'"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
            }
            Else {$False}
        }
    } 
}
} #end Get-PKGitInstall
