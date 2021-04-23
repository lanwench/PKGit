#requires -Version 4
Function Invoke-PKGitCommit {
<#
.SYNOPSIS 
    Uses invoke-expression and "git commit" with optional parameters

.DESCRIPTION
    Uses invoke-expression and "git commit" with optional parameters
    Defaults to current directory
    If -Recurse is specified, searches for all git repos in subfolders and loops through them
    Verifies that directory contains a repo
    Supports ShouldProcess
    Requires git, of course

.NOTES
    Name    : Function_Invoke-PKGitCommit.ps1
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0      - 2016-06-05 - Created script
        v1.0.1      - 2016-08-01 - Renamed with Function_ prefix
        v02.00.0000 - 2021-04-22 - Overhauled to match other functions in repo
        
.LINK
    https://github.com/lanwench/PKGit

.EXAMPLE
    PS C:\MyRepos\TestRepo> Invoke-PKGitCommit -AddAllTrackedChanges -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                 
        ---                  -----                                 
        AddAllTrackedChanges True                                  
        Verbose              True                                  
        RepoPath             C:\MyRepos\TestRepo                                 
        WhatIf               False                                 
        ScriptName           Invoke-PKGitCommit                    
        ScriptVersion        2.0.0                                 
        PipelineInput        False                                 


        VERBOSE: [C:\MyRepos\TestRepo] Get folder object
        VERBOSE: [C:\MyRepos\TestRepo] Git repo found
        On branch master
        Your branch is up to date with 'origin/master'.

        Changes not staged for commit:
          (use "git add <file>..." to update what will be committed)
          (use "git restore <file>..." to discard changes in working directory)
	        modified:   Scripts/2018-04-18 - SQL service startname changes.ps1

        no changes added to commit (use "git add" and/or "git commit -a")
        Commit message: Added ShouldProcess
        VERBOSE: [C:\MyRepos\TestRepo] Add all changes/stage all tracked files, and invoke 'git commit -a -m "Added ShouldProcess" 2>&1'
        [master 0d09d71] Testing commit message function
         1 file changed, 10 insertions(+), 2 deletions(-)

.EXAMPLE
    PS C:\> Invoke-PKGitCommit -RepoPath c:\temp\demo -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                 
        ---                  -----                                 
        Verbose              True                                  
        RepoPath             {c:\temp\demo}
        Recurse              False                                 
        AddAllTrackedChanges False                                 
        WhatIf               False                                 
        ScriptName           Invoke-PKGitCommit                    
        ScriptVersion        2.0.0                                 
        PipelineInput        False                                 

        VERBOSE: [c:\temp\demo] Get folder object
        VERBOSE: [c:\temp\demo] 1 Git repo(s) found
        VERBOSE: [c:\temp\demo] Check Git status
        On branch main
        Your branch is up to date with 'origin/main'.

        Changes to be committed:
          (use "git restore --staged <file>..." to unstage)
	        new file:   Scripts/SafeAccountList.ps1

        Commit message: Updated account list
        VERBOSE: [c:\temp\demo] Invoke 'git commit -m "Updated account list" 2>&1'
        [main bad5f63] Updated account list
         1 file changed, 1 insertion(+)
         create mode 100644 Scripts/AccountList.ps1


.EXAMPLE
    PS C:\> $Arr | Invoke-PKGitCommit -Recurse -AddAllTrackedChanges -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                  Value                  
        ---                  -----                  
        Recurse              True                   
        AddAllTrackedChanges True                   
        Verbose              True                   
        RepoPath             
        WhatIf               False                  
        ScriptName           Invoke-PKGitCommit     
        ScriptVersion        2.0.0                  
        PipelineInput        True                   

        VERBOSE: [d:\repos] 20 Git repo(s) found
        VERBOSE: [d:\repos\prod\gists\0a1bbdf348eec659c4e5b3211c021d1e] Check Git status
        WARNING: [d:\repos\prod\gists\0a1bbdf348eec659c4e5b3211c021d1e] Nothing to commit!
        VERBOSE: [d:\repos\prod\Infrastructure\] Check Git status
        On branch master
        Your branch is up to date with 'origin/master'.

        Changes not staged for commit:
          (use "git add <file>..." to update what will be committed)
          (use "git restore <file>..." to discard changes in working directory)
	        modified:   AD/Scripts/Function_Get-WUStatus.ps1
	        modified:   VMware/Scripts/VMInventory.ps1

        no changes added to commit (use "git add" and/or "git commit -a")
        Commit message: 
        WARNING: [d:\repos\prod\Infrastructure\PowerShell] Commit message is mandatory!
        VERBOSE: d:\repos\test\kittens] Check Git status
        WARNING: d:\repos\test\kittens] Nothing to commit!
        VERBOSE: [d:\repos\Sandbox] Check Git status
        WARNING: [d:\repos\Sandbox] Nothing to commit!

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        ValueFromPipeline,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Git repo path (default is current location)"
    )]
    [Alias("FullName")]
    [object[]]$RepoPath = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse through subfolders for git repos"
    )]
    [switch]$Recurse,

    [Parameter(
        HelpMessage = "Add all tracked changes during commmit (git commit -a)"
    )]
    [Switch] $AddAllTrackedChanges

)
Begin {    
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

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

    $StartLocation = Get-Location
    $Activity = "Create git commit message"
    If ($AddAllTrackedChanges.IsPresent) {$Activity += " (with option to add untracked files)"}
}

Process {
    
    Foreach ($Item in $RepoPath) {
        $Current = $Null
        If (-not ($Item -is [System.IO.FileSystemInfo])) {
            If ($Item -is [string]) {
                $Current = $Item
            }
            If ($Item -is [System.Management.Automation.PathInfo]) {
                $Current = $Item.Path
            }
            $Msg = "Get folder object"
            Write-Verbose "[$Current] $Msg"
            Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current
            $FolderObj = Get-Item -Path $Item -Verbose:$False 
        }
        Elseif ($Item -is [System.IO.FileSystemInfo]) {
            $Current = $Item.FullName
            $FolderObj = $Item
        }
        Else {
            $Msg = "Unknown object type; please use a valid path string or directory object"
            Throw $Msg
        }

        If ($FolderObj) {
        
            $Msg = "Look for git repo"
            If ($Recurse.IsPresent) {$Msg += " (search subfolders recursively)"}
            Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current
            If ($GitRepos = $FolderObj | Get-Childitem -Recurse:$Recurse -Filter .git -Directory -Attributes H -ErrorAction Stop) {
            
                $Msg = "$($GitRepos.Count) Git repo(s) found"
                Write-Verbose "[$($Folder.FullName)] $Msg"

                Foreach ($GitFolder in $GitRepos) {
                    
                    $GitFolder = ($GitFolder.FullName | Split-Path -Parent)
                    Set-Location -Path $GitFolder
                    $Msg = "Check Git status"
                    Write-Verbose "[$($GitFolder)] $Msg"

                    Try {
                        $Status = Invoke-Expression "git status 2>&1"
                    }
                    Catch {}

                    If ($Status -match "nothing to commit") {
                        $Msg = "Nothing to commit!"
                        Write-Warning "[$($GitFolder)] $Msg"
                    }
                    Else {
                        Write-Output $Status
                        
                        $Regex1 = [regex]::Escape('nothing added to commit but untracked files present (use "git add" to track)')
                        $Regex2 = [regex]::Escape('(use "git add <file>..." to include in what will be committed)')
                        If ($Status -match $Regex1 -or $Status -match $Regex2) {
                            $Msg = "Nothing to commmit but untracked files found; invoke 'git add *' before commit"
                            Write-Verbose "[$($GitFolder)] $Msg"
                            $ConfirmMsg = "Untracked files found; run 'git add *' to add all untracked files before commit"
                            If ($PSCmdlet.ShouldProcess($GitFolder,$ConfirmMsg)) {
                                Try {
                                    Invoke-Expression "git add * 2>&1"
                                }
                                Catch {}
                            }
                        }
                        $Regex = [regex]::Escape('no changes added to commit (use "git add" and/or "git commit -a")')
                        If ($Status -match $Regex -and (-not ($AddAllTrackedChanges.IsPresent))) {
                            $ConfirmMsg = "Untracked files found; prompt to reset -AddAllTrackedChanges for this repo"
                            Write-Verbose "[$($GitFolder)] $Msg"
                            [switch]$Revert = $False
                            If ($PSCmdlet.ShouldProcess($GitFolder,$ConfirmMsg)) {
                                $Revert = $True
                                $AddAllTrackedChanges = $True
                            }
                        }


                        If (($Message = Read-Host -Prompt "Commit message").length -gt 0) {
                            
                            If ($AddAllTrackedChanges.IsPresent) {
                                $Commit = "git commit -a -m ""$Message"" 2>&1"
                                $ConfirmMsg = "Add all changes/stage all tracked files, and invoke '$Commit'"
                            }
                            Else {
                                $Commit = "git commit -m ""$Message"" 2>&1"    
                                $ConfirmMsg = "Invoke '$Commit'"
                            }
                
                            Write-Verbose "[$($GitFolder)] $ConfirmMsg"
                            Write-Progress -Activity $Activity -CurrentOperation $ConfirmMsg -Status $Current
                            If ($PSCmdlet.ShouldProcess($GitFolder.FullName,$ConfirmMsg)) {
                                Try {
                                    Invoke-Expression $Commit 
                                }
                                Catch {}
                            }
                            Else {
                                $Msg = "Operation cancelled by user"
                                Write-Warning "[$($GitFolder)] $Msg"
                            }
                        }
                        Else {
                            $Msg = "Commit message is mandatory!"
                            Write-Warning "[$($GitFolder)] $Msg"
                        }
                    }

                    If ($Revert.IsPresent) {$AddAllTrackedChanges = $False}

                } # end for each folder
            }
            Else {
                $Msg = "No Git repo found"
                If (-not $Recurse.IsPresent) {$Msg += " (try -Recurse)"}
                Write-Warning "[$($Folder.FullName)] $Msg"
            }

        } #end if folder object
    
    } #end foreach path 
}
End {
    Set-Location $StartLocation
    Write-Progress -Activity * -Completed
}
} #end Invoke-PKGitCommit
