#requires -Version 5
Function Get-PKGitStatus {
<#
.SYNOPSIS
    Check one or more git repositories for name, origin, status, and a summary

.DESCRIPTION
    This function is a quick way to see at a glance whether your git repository has uncommitted changes or untracked files;
    it returns a simple summary: either "Working tree clean" or a human-readable count of what's pending (e.g., "2 unstaged changes, 1 untracked file")

    For comprehensive repo analysis with owner info, privacy status, branch tracking, commit history, and detailed dates,
    use Get-PKGitRepo -Full instead

    Commands used in this script...

        Command                                      | Description
        -------------------------------------------------------------------------------------------------
        git -C <path> status 2>&1                    | Get full status output
        git -C <path> config remote.origin.url       | Get remote URL for repo name
        git -C <path> status --porcelain             | Get machine-parseable status for counting changes

    SUMMARY FORMAT
        The Summary property displays the repository status as "Status (detail)" where:

        Clean:      No uncommitted changes, no untracked files, and no unpushed commits
        Dirty:      Uncommitted changes or untracked files present (shows counts)
        Unpushed:   Commits ready to push to remote (shows count)
        Behind:     Local branch behind remote tracking branch (shows count)
        Diverged:   Local and remote branches have diverged (shows both ahead and behind)

    Accepts pipeline input for paths, and offers -Recurse to check multiple repos at once

    Requires git to be installed and available in the system path, obviously

.NOTES
    Name    : Function_Get-PKGitStatus.ps1
    Created : 2021-04-19
    Author  : Paula Kingsley
    Version : 05.01
    History :

        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2021-04-19 - Created script
        v02.00 - 2022-08-31 - Renamed from Invoke-PSGitStatus; other minor edits
        v02.01 - 2022-09-20 - Updates/standardization
        v02.02 - 2023-02-02 - Added attribute for commit/staging status
        v03.00 - 2023-02-16 - Overhauled; renamed ReturnOriginPath to ShowOriginPath,
                                changed Recurse to NoRecurse, changed output, simplified search
        v03.01 - 2024-02-05 - Fixed issue with arraylist not showing all results, added -Extended
        v03.02 - 2024-02-05 - Added option to return only current/stale
        v04.00 - 2026-06-06 - Overhauled for consistency with others in module; added porcelain-derived details,
                                LastCommitDate, LastCommitter, LastSyncDate (FETCH_HEAD or clone date fallback)
        v04.01 - 2026-06-19 - Added last commit message to extended output
        v05.00 - 2026-09-15 - Overhauled and simplified; removed -Extended flag (use Get-PKGitRepo -Full)
        v05.01 - 2026-09-17 - Cosmetic and consistency updates

.LINK
    https://github.com/lanwench/pkgit

.PARAMETER Path
    Absolute path to one or more git repos (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.EXAMPLE
    PS /users/jane/repos/kittens> Get-PKGitStatus

    Check status of the current repository.

    Path           : /users/jane/repos/kittens
    Name           : kittens
    Origin         : https://github.com/jbloggs/kittens.git
    IsCurrent      : False
    Summary        : 1 unstaged change, 1 untracked file

.EXAMPLE
    PS /users/jane/repos> Get-PKGitStatus -Recurse | Format-Table -AutoSize

    Check status of all git repositories in the current folder and subfolders.

    Path                                  Name        Origin                                       IsCurrent  Summary
    ----                                  ----        ------                                       ---------  -------
    /users/jane/repos/pythonstuff   pythonstuff https://github.com/jbloggs/pythonstuff.git      True       Working tree clean
    /users/jane/repos/PSGit         PSGit       https://github.com/jbloggs/PSGit.git           False      3 unstaged changes
    /users/jane/repos/Helpers       Helpers     https://github.com/jbloggs/Helpers.git         False      2 untracked files

.EXAMPLE
    PS /users/shared> Get-Item /users/jane/repos | Get-PKGitStatus

    Returns status from a piped repository path.

    Path           : /users/jane/repos
    Name           : repos
    Origin         : https://github.com/jbloggs/repos.git
    IsCurrent      : True
    Summary        : Working tree clean

#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to git repos (default is current location)"
        )]
        [Alias("FullName", "Name")]
        [object[]]$Path = (Get-Location).Path,

        [Parameter(
            HelpMessage = "Recurse subfolders in path"
        )]
        [Switch]$Recurse,

        [Parameter(
            DontShow,
            HelpMessage = "Return extended details (deprecated; use Get-PKGitRepo -Full instead)"
        )]
        [switch]$Extended,

        [Parameter(
            DontShow,
            HelpMessage = "Return collection properties as strings (deprecated; use Get-PKGitRepo -Full instead)"
        )]
        [Switch]$CollectionsToStrings
    )
    Begin {

        # Current version (please keep up to date from comment block)
        [version]$Version = "05.01"

        If ($PSBoundParameters.ContainsKey("Extended") -or $PSBoundParameters.ContainsKey("CollectionsToStrings")) {
            Throw "-Extended and -CollectionsToStrings have been removed; try Get-PKGitRepo -Full"
        }

        # Stopwatch
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Check for redundant recursion (pipeline input + -Recurse)
        [switch]$PipelineInput = $MyInvocation.ExpectingInput
        If ($PipelineInput -and $Recurse.IsPresent) {
            $Msg = "Pipeline input detected with -Recurse flag. This may cause redundant recursion and duplicate results. Continue?"
            If (-not $PSCmdlet.ShouldProcess($Msg, "Recursive search with pipeline input")) {
                Return
            }
        }

        # How did we get here?
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

        If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
        }


        #region Helper Functions
        Function _FormatSummary {
            param(
                [bool]$HasUncommittedWork,
                [bool]$HasUntrackedFiles,
                [int]$NumUncommitted,
                [int]$NumUntracked,
                [bool]$HasUnpushedCommits,
                [int]$NumUnpushed,
                [int]$AheadBy = 0,
                [int]$BehindBy = 0
            )
            Try {
                $Details = @()

                If ($HasUncommittedWork) {
                    $Details += "$NumUncommitted unstaged change$(If ($NumUncommitted -ne 1) {'s'})"
                }
                If ($HasUntrackedFiles) {
                    $Details += "$NumUntracked untracked file$(If ($NumUntracked -ne 1) {'s'})"
                }
                If ($HasUnpushedCommits) {
                    $Details += "$NumUnpushed unpushed commit$(If ($NumUnpushed -ne 1) {'s'})"
                }

                If ($AheadBy -gt 0 -and $BehindBy -gt 0) {
                    Return "Diverged ($AheadBy ahead, $BehindBy behind)"
                }
                ElseIf ($HasUncommittedWork -or $HasUntrackedFiles) {
                    $DetailStr = $Details -join ", "
                    Return "Dirty ($DetailStr)"
                }
                ElseIf ($HasUnpushedCommits) {
                    Return "Unpushed ($($Details -join ', '))"
                }
                ElseIf ($BehindBy -gt 0) {
                    Return "Behind ($BehindBy behind)"
                }
                Else {
                    Return "Clean (no uncommitted changes)"
                }
            }
            Catch {
                Write-Verbose "Failed to format summary: $($_.Exception.Message)"
                Return "(unavailable)"
            }
        } # end _FormatSummary

        Function _GetSummary {
            param([string]$RepoPath)
            Try {
                $Porcelain      = git -C "$RepoPath" status --porcelain 2>$null
                $StagedCount    = ($Porcelain | Where-Object { $_ -match '^[MADRC]' }).Count
                $UnstagedCount  = ($Porcelain | Where-Object { $_ -match '^[ MADRC][MD]' }).Count
                $UntrackedCount = ($Porcelain | Where-Object { $_ -match '^\?\?' }).Count
                $ConflictCount  = ($Porcelain | Where-Object { $_ -match '^[UA][AU]|^DD' }).Count
                $IsClean        = ($StagedCount + $UnstagedCount + $UntrackedCount + $ConflictCount) -eq 0

                $HasUncommittedWork = ($StagedCount + $UnstagedCount + $ConflictCount) -gt 0
                $HasUntrackedFiles  = $UntrackedCount -gt 0
                $TotalUncommitted   = $StagedCount + $UnstagedCount + $ConflictCount

                $FormattedSummary = _FormatSummary -HasUncommittedWork $HasUncommittedWork -HasUntrackedFiles $HasUntrackedFiles -NumUncommitted $TotalUncommitted -NumUntracked $UntrackedCount -HasUnpushedCommits $False -NumUnpushed 0

                Return [PSCustomObject]@{
                    IsClean = $IsClean
                    Summary = $FormattedSummary
                }
            }
            Catch {
                Write-Verbose "[$RepoPath] Failed to get status: $($_.Exception.Message)"
                Return $Null
            }
        } # end _GetSummary
        #endregion Helper Functions

        $Activity = "Get git status"
        If ($Recurse.IsPresent) { $Activity += " for all repos found in subfolders" }
        Write-Verbose "[BEGIN: $ScriptName] $Activity"

    }
    Process {

        Foreach ($Item in $Path) {
            $Current = $Item.ToString()
            $Msg = "Searching for git repos"
            If ($Recurse.IsPresent) { $Msg = "Searching tree for git repos" }
            Write-Verbose "[$Current] $Msg"
            Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current

            Try {
                $FolderObj = Get-Item -Path $Item -Verbose:$False
                [object[]]$GitRepos = Test-PKGitRepo -Path $FolderObj.FullName -Recurse:$Recurse.IsPresent -Verbose:$False

                If ($GitRepos) {
                    $TotalRepos = ($GitRepos | Sort-Object -Unique).Count
                    $DupeCount = $GitRepos.Count - $TotalRepos
                    $CurrentRepo = 0

                    If ($DupeCount -gt 0) {
                        $Msg = "$($GitRepos.Count) git repo paths found; removing $DupeCount duplicated paths"
                    }
                    Else {
                        $Msg = "$TotalRepos git repo(s) found"
                    }
                    Write-Verbose "[$Current] $Msg"

                    Foreach ($RepoPath in ($GitRepos | Sort-Object -Unique)) {
                        $CurrentRepo++
                        Write-Verbose "[$RepoPath] Get git status"
                        Write-Progress -Activity $Activity -CurrentOperation $RepoPath -Status Working -PercentComplete ($CurrentRepo / $TotalRepos * 100)

                        Try {
                            $Origin = git -C "$RepoPath" config remote.origin.url 2>$null
                            $Name   = (Split-Path -Leaf $Origin).Replace(".git", $Null)
                            $StatusInfo = _GetSummary -RepoPath $RepoPath

                            [PSCustomObject]@{
                                Path      = $RepoPath
                                Name      = $Name
                                IsCurrent = $StatusInfo.IsClean
                                Summary   = $StatusInfo.Summary
                                Origin    = $Origin
                            }
                        }
                        Catch {
                            Write-Warning "[$RepoPath] Operation failed; $($_.Exception.Message)"
                        }
                    } # end foreach repo
                }
                Else {
                    $Msg = "No git repositories found in path"
                    If (-not $Recurse.IsPresent) { $Msg += " (try -Recurse)" }
                    Write-Warning "[$Current] $Msg"
                }
            }
            Catch {
                Write-Warning "[$Item] Operation failed; $($_.Exception.Message)"
            }
        } #end foreach path
        Write-Progress -Activity * -Completed
    }
    End {
        Write-Progress -Activity * -Completed
        $Stopwatch.Stop()
        Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
    }
} #end Get-PKGitStatus
