#requires -Version 4
Function Remove-PKGitLastCommit {
<#
.SYNOPSIS
    Remove the last local commit from one or more git repositories, forcing confirmation

.DESCRIPTION
    Removes the last commit from one or more git repositories using `git reset --soft HEAD^` and
        displays the commit details (hash, author, message, files) before asking for confirmation 

    SupportsShouldProcess for safe operation with -WhatIf and -Confirm
    Checks whether the repo has local commits ahead of the remote before proceeding
    Accepts pipeline input for file paths or direct path parameters

    By default, operates on the specified repository or current directory; use -Recurse to search subdirectories

    Requires git to be installed and available in the system path! 
    
    Returns a PSCustomObject with commit details and operation result for each repo processed

.NOTES
    Name    : Function_Remove-PKGitLastCommit.ps1
    Created : 2022-08-31
    Author  : Paula Kingsley
    Version : 02.01
    History :

        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2022-08-31 - Created script because I can never remember this
        v01.01 - 2022-09-13 - Updated to match Get-PKGitCommit
        v02.00 - 2026-06-06 - Overhauled for consistency with others in module; uses Test-PKGitRepo and git -C; fixed ahead-check; structured Files output; removed Write-Progress
        v02.01 - 2026-09-17 - Cosmetic and consistency updates

.LINK
    https://github.com/lanwench/pkgit

.PARAMETER Path
    Absolute path to git repo (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.EXAMPLE
    PS /users/jane/repos/kittens> Remove-PKGitLastCommit -Verbose

    VERBOSE: PSBoundParameters:

    Key           Value
    ---           -----
    Verbose       True
    Path          {/users/jane/repos/kittens}
    Recurse       False
    ComputerName  mackie.local
    ScriptName    Remove-PKGitLastCommit
    ScriptVersion 2.01
    PipelineInput False

    VERBOSE: [BEGIN: Remove-PKGitLastCommit] Remove last git commit
    VERBOSE: [/users/jane/repos/kittens] Searching for git repo
    VERBOSE: [/users/jane/repos/kittens] 1 git repo(s) found
    VERBOSE: [/users/jane/repos/kittens] Getting last commit

    Path          : /users/jane/repos/kittens
    Hash          : ef88be57fbc894af2b4f9e2b1259c7d5ef46abde
    Date          : 2026-06-05T10:30:00-07:00
    Author        : Jane Bloggs (jbloggs@github.com)
    Committer     : Jane Bloggs (jbloggs@github.com)
    Message       : Fix typo in README
    NumFileChanges: 1
    Files         : {@{Action=Modified; Filename=README.md}}

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Remove last commit ef88be57fbc894af2b4f9e2b1259c7d5ef46abde by Jane Bloggs (jbloggs@github.com)" on target "/users/jane/repos/kittens".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

    ResetResult : Commit removed
    BranchStatus: Your branch is ahead of 'origin/main' by 0 commits.

    VERBOSE: [END: Remove-PKGitLastCommit] Remove last git commit

.EXAMPLE
    PS /users/jane> Remove-PKGitLastCommit -Path /users/jane/repos/main -WhatIf

    Path          : /users/jane/repos/main
    Hash          : a3b5c8d1e9f2g4h6i8j9k0l1m2n3o4p5
    Date          : 2026-06-05T14:15:00-07:00
    Author        : Jane Bloggs (jbloggs@github.com)
        Committer     : Jane Bloggs (jbloggs@github.com)
        Message       : Update documentation
        NumFileChanges: 2
        Files         : {@{Action=Modified; Filename=docs/guide.md}, @{Action=Added; Filename=docs/examples.md}}

        What if: Performing the operation "Remove last commit a3b5c8d1e9f2g4h6i8j9k0l1m2n3o4p5 by Jane Bloggs (jbloggs@github.com)" on target "/users/jane/repos/main".

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Absolute path to git repo (default is current location)"
    )]
    [Alias("FullName", "RepoPath")]
    [object[]]$Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [Switch]$Recurse
)
Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "02.01"

    # Start the clock
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = @{} + $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where-Object { $CurrentParams.keys -notContains $_ } |
    Where-Object { Test-Path Variable:$_ } | ForEach-Object {
        $CurrentParams.Add($_, (Get-Variable $_).value)
    }
    $ComputerName = [System.Net.Dns]::GetHostName()
    $CurrentParams.Add("ComputerName", $ComputerName)
    $CurrentParams.Add("ScriptName", $ScriptName)
    $CurrentParams.Add("ScriptVersion", $Version)
    $CurrentParams.Add("PipelineInput", $PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites

    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
    }

    #endregion Prerequisites

    $Commands = [PSCustomObject]@{
        CheckAhead = 'git -C <path> rev-list --count "@{u}..HEAD"'
        GetHash    = 'git -C <path> log -n 1 --format="%H"'
        GetDetails = 'git -C <path> log -1 <hash> --format="%cI`t%s`t%an (%ae)`t%cn (%ce)"'
        GetFiles   = 'git -C <path> show --pretty=format: --name-status <hash>'
        Reset      = 'git -C <path> reset --soft HEAD^'
        Status     = 'git -C <path> status --porcelain --branch'
    }

    $Activity = "Remove last git commit"
    Write-Verbose "[BEGIN: $ScriptName] $Activity"
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

}
Process {

    Foreach ($Item in $Path) {

        Try {
            
            $Label = $Item.ToString()
            Write-Verbose "[$Label] Searching for git repos"
            [object[]]$GitRepos = Test-PKGitRepo -Path $Item -Recurse:$Recurse.IsPresent -Verbose:$False

            If ($GitRepos) {
                Write-Verbose "[$Label] $($GitRepos.Count) git repo(s) found"

                Foreach ($RepoPath in ($GitRepos | Sort-Object | Select-Object -Unique)) {
                    Try {
                        Write-Verbose "[$RepoPath] Getting last commit"

                        # Get last commit hash
                        $Hash = git -C "$RepoPath" log -n 1 --format="%H" 2>$null
                        If (-not $Hash) {
                            Write-Warning "[$RepoPath] No commits found"
                            Continue
                        }

                        # Check if there are commits ahead of remote (safety check: prevent removing already-pushed commits)
                        $AheadBy = [int](git -C "$RepoPath" rev-list --count "@{u}..HEAD" 2>$null)
                        If ($AheadBy -le 0) {
                            Write-Warning "[$RepoPath] No local commits ahead of remote"
                            Continue
                        }

                        # Get commit details
                        $CommitData = git -C "$RepoPath" log -1 $Hash --format="%cI`t%s`t%an (%ae)`t%cn (%ce)" 2>$null
                        $Parts = $CommitData -split "`t"
                        $Date = $Parts[0]
                        $Message = $Parts[1]
                        $Author = $Parts[2]
                        $Committer = $Parts[3]

                        # Get changed files
                        [object[]]$FileLines = git -C "$RepoPath" show --pretty=format: --name-status $Hash 2>$null | Where-Object { $_ }
                        $Files = @()
                        Foreach ($FileLine in $FileLines) {
                            $Status, $FileName = $FileLine -split "`t", 2
                            $Files += [PSCustomObject]@{
                                Action   = $Status
                                Filename = $FileName
                            }
                        }

                        $Output = [PSCustomObject]@{
                            Path           = $RepoPath
                            Hash           = $Hash
                            Date           = $Date
                            Author         = $Author
                            Committer      = $Committer
                            Message        = $Message
                            NumFileChanges = $Files.Count
                            Files          = $Files
                            ResetResult    = $Null
                            ExecutedDate   = $Null
                            BranchStatus   = $Null
                        }

                        Write-Verbose "[$RepoPath] Displaying commit details"
                        Write-Output $Output

                        $ConfirmMsg = "Remove last commit $($Hash.Substring(0,7)) by $Committer"
                        If ($PSCmdlet.ShouldProcess($RepoPath, $ConfirmMsg)) {
                            Write-Verbose "[$RepoPath] Removing commit $Hash"
                            $Output.ExecutedDate = ([DateTime]::Now).ToString('s') + ([DateTime]::Now).ToString('zzz')
                            git -C "$RepoPath" reset --soft HEAD^ 2>&1 | Out-Null

                            If ($LASTEXITCODE -eq 0) {
                                $Output.ResetResult = "Commit removed"

                                # Get updated branch status
                                $BranchStatus = git -C "$RepoPath" status --porcelain --branch 2>$null | Select-Object -First 1
                                $Output.BranchStatus = $BranchStatus

                                Write-Verbose "[$RepoPath] Commit successfully removed"
                                Write-Output $Output
                            }
                            Else {
                                Write-Warning "[$RepoPath] Reset failed with exit code $LASTEXITCODE"
                            }
                        }
                    }
                    Catch {
                        Write-Warning "[$RepoPath] Operation failed; $($_.Exception.Message)"
                    }
                } # end foreach repo
            }
            Else {
                $Msg = "No git repos found"
                If (-not $Recurse.IsPresent) { $Msg += " (try -Recurse)" }
                Write-Warning "[$Label] $Msg"
            }
        }
        Catch {
            Write-Warning "[$Item] Operation failed; $($_.Exception.Message)"
        }
    } # end foreach path
}
End {
    Write-Progress -Activity * -Completed
    $Stopwatch.Stop()
    Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
}
} #end Remove-PKGitLastCommit
