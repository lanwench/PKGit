#requires -Version 3
Function Invoke-PKGitPull {
<#
.SYNOPSIS 
    Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy

.DESCRIPTION
    Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy
    Verifies git.exe is present
    Searches for hidden .git folder
    Returns remote origin and branch details
    Supports ShouldProcess
    Returns a string

.NOTES
    Name    : Function_Invoke-PKGitPull.ps1
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2021-04-14 - Created script
        v01.00.1000 - 2021-04-19 - Fixed erroneous name in Notes block, changed verbose to warning if no repo found
        
.LINK
    https://github.com/jbloggs/PKGit

.EXAMPLE
    PS C:\> C:\Repos | Invoke-PKGitPull -Verbose -Recurse

        VERBOSE: PSBoundParameters: 
	
        Key              Value                         
        ---              -----                         
        Verbose          True                          
        Recurse          True                          
        Path             C:\Repos
        ScriptName       Invoke-PKGitPull              
        ScriptVersion    1.0.0   
        PipelineInput    True                      


        VERBOSE: [C:\Repos] Get folder object
        VERBOSE: [C:\Repos] Perform recursive search for git repos
        VERBOSE: [C:\Repos] 14 git repo(s) found
        VERBOSE: [C:\Repos\Personal\profiles] Get remote origin info
        VERBOSE: [C:\Repos\Personal\profiles] Invoke 'git pull' from branch 'master' on Fetch URL https://gist.git.internal.mycorp.net/profiles.git
        [C:\Repos\Personal\profiles] Already up to date.
        VERBOSE: [C:\Repos\Personal\psmodules] Get remote origin info
        VERBOSE: [C:\Repos\Personal\psmodules] Invoke 'git pull' from branch 'main' on Fetch URL https://github.com/jbloggs/psmodules.git
        [C:\Repos\Personal\psmodules] From https://github.com/jbloggs/psmodules    1cdf508..7a91e58  main       -> origin/main Updating 1cdf508..7a91e58 Fast-forward  README.md     | 1 +  wmitest.ps1 | 3 ++-  2 file
        s changed, 3 insertions(+), 1 deletion(-)
        VERBOSE: [C:\Repos\Personal\capas] Get remote origin info
        VERBOSE: [C:\Repos\Personal\capas] Invoke 'git pull' from branch 'main' on Fetch URL https://github.com/jbloggs/capas.git
        [C:\Repos\Personal\capas] Already up to date.
        VERBOSE: [C:\Repos\Personal\gists\2472ef2e9c77v2beerfd927f991boo51] Get remote origin info
        VERBOSE: [C:\Repos\Personal\gists\2472ef2e9c77v2beerfd927f991boo51] Invoke 'git pull' from branch 'master' on Fetch URL https://gist.github.com/2472ef2e9c77v2beerfd927f991boo51.git
        [C:\Repos\Personal\gists\2472ef2e9c77v2beerfd927f991boo51] error: Your local changes to the following files would be overwritten by merge: 	search-files.ps1 Please commit your changes
        or stash them before you merge. Updating 88fc0c0..71392fe Aborting
        VERBOSE: [C:\Repos\Personal\testing] Get remote origin info
        VERBOSE: [C:\Repos\Personal\testing] Invoke 'git pull' from branch 'master' on Fetch URL https://github.com/jbloggs/testing.git
        [C:\Repos\Personal\testing] Already up to date.

.EXAMPLE
    PS C:\> Invoke-PKGitPull -Path c:\temp -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value           
        ---           -----           
        Path          c:\temp         
        Verbose       True            
        Recurse       False           
        ScriptName    Invoke-PKGitPull
        ScriptVersion 1.0.0           
        PipelineInput False           

        VERBOSE: [c:\temp] Get folder object
        VERBOSE: [c:\temp] Search current folder for git repos
        WARNING: [c:\temp] No git repo(s) found


.EXAMPLE
    PS C:\> Invoke-PKGitPull -Path c:\temp -Recurse

        Invoke-PKGitPull : Git.exe not found on 'LABVDI21'; please install from https://git-scm.com/download/win
        At line:1 char:1
        + Invoke-PKGitPull -Path c:\temp -Recurse
        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
            + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Invoke-PKGitPull

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        HelpMessage = "Folder or path",
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True
    )]
    [Alias("FullName")]
    $Path = $PWD,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Recurse through subfolders to find git repos in a hierarchy"
    )]
    [Switch] $Recurse

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.1000"

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path Variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Git.exe not found on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    If ($Recurse.IsPresent) {
        $Activity = "Recursively search directories for git repos and invoke a 'git pull' in folder if a git repo is found"
    }
    Else {
        $Activity = "Invoke a 'git pull' in folder if a git repo is found"
    }

    $StartingLocation = Get-Location

}
Process {    
    
    Foreach ($P in $Path) {
        
        Try {
            $Folder = $Null
            If (($P -is [string]) -or ($P -is [System.Management.Automation.PathInfo])) {
                $Msg = "Get folder object"
                Write-Verbose "[$P] $Msg"
                Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $P
                $Folder = Get-Item -Path $P -Verbose:$False 
            }
            Elseif ($P -is [System.IO.FileSystemInfo]) {
                $Folder = $P
            }
            Else {
                $Msg = "Unknown object type; please use a valid path string or directory object"
                Throw $Msg
            }
        
            If ($Folder) {
                Switch ($Recurse) {
                    $True {$Msg = "Perform recursive search for git repos"}
                    $False {$Msg = "Search current folder for git repos"}
                }
                Write-Verbose "[$P] $Msg"
                Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $P
                $Repo = $Folder | Get-Childitem -Recurse:$Recurse -Filter .git -Directory -Attributes H -ErrorAction Stop

                If ($Repo) {
                    $Msg = "$(($Repo -as [array]).Count) git repo(s) found"
                    Write-Verbose "[$P] $Msg"

                    Foreach ($R in $Repo) {
                        
                        $RepoLocation = $R.FullName | Split-Path -Parent
                        $Msg = "Get remote origin info"
                        Write-Verbose "[$RepoLocation] $Msg"

                        If ($PSCmdlet.ShouldProcess($RepoLocation,$Msg)) {
                            Set-Location $RepoLocation
                            $Origin = Invoke-Expression "git remote show origin 2>&1"
                            Set-Location $StartingLocation
                            $FetchURL = ($Origin | Select-String -Pattern "Fetch URL").ToString().Trim().Replace("Fetch URL: ",$Null)
                            $Branch = ($Origin | Select-String -Pattern "HEAD branch").ToString().Trim().Replace("HEAD branch: ",$Null)
                            $Msg = "Invoke 'git pull' from branch '$Branch' on Fetch URL $FetchURL"
                            Write-Verbose "[$RepoLocation] $Msg"
                        
                            If ($PSCmdlet.ShouldProcess($RepoLocation,$Msg)) {
                                
                                Set-Location $RepoLocation
                                $Pull = Invoke-Expression -Command "git pull 2>&1"
                                Write-Output "[$RepoLocation] $Pull"
                                Set-Location $StartingLocation
                            }
                            Else {
                                $Msg = "git pull operation cancelled by user"
                                Write-Verbose "[$RepoLocation] $Msg"
                            }
                        }
                        Else {
                            $Msg = "Operation cancelled by user"
                            Write-Verbose "[$RepoLocation] $Msg"
                        }
                    }
                }
                Else {
                    $Msg = "No git repo(s) found"
                    Write-Warning "[$P] $Msg"
                }
            } # end if folder
        }
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Throw $Msg
        }    
    }
}
End {
    Write-Progress -Activity * -Completed
}
} #end Invoke-PKGitPull

