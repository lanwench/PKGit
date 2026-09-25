#requires -Version 4
Function Get-PKGitRepo {
<#
.SYNOPSIS
    Check the status and details of one or more git repositories without having to memorize annoying git syntax

.DESCRIPTION
    This function makes it easy to see what's going on with your git repos and returns a PSCustomObject with details
    about the repository, including the current branch, remote URL, and status

    Specify -Full to get more properties, such as owner, privacy settings, what branch you're tracking,
    how many commits ahead/behind, and when it was last touched

    It accepts paths from the pipeline (strings or DirectoryInfo objects) and offers a -Recurse parameter to search subdirectories for git repositories; requires git to be installed, duh 

    SUMMARY FORMAT
        The Summary property displays the repository status as "Status (detail)" where:

        Clean:      No uncommitted changes, no untracked files, and no unpushed commits
        Dirty:      Uncommitted changes or untracked files present (shows counts)
        Unpushed:   Commits ready to push to remote (shows count)
        Behind:     Local branch behind remote tracking branch (shows count)
        Diverged:   Local and remote branches have diverged (shows both ahead and behind)

.OUTPUTS
    System.Management.Automation.PSCustomObject
    PSCustomObject with repo information. Default output includes Path, Name, LocalBranch, Fetch_URL, and Summary.
    Full output adds Owner, Visibility, CommitEmail, branch tracking info, commit counts, and dates.

.INPUTS
    System.String
    Absolute path to a git repository or directory. Can be piped from Get-Item or Get-ChildItem.

.NOTES
    Name    : Function_Get-PKGitRepo.ps1
    Created : 2026-09-15
    Author  : Paula Kingsley
    Version : 01.01
    History :
        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2026-09-15 - Created script with comprehensive repo analysis
        v01.01 - 2026-09-17 - Cosmetic updates for consistency, added warning if gh not found 

.LINK
    https://github.com/lanwench/PKGit

.PARAMETER Path
    Absolute path to one or more git repositories; default is current location

.PARAMETER Recurse
    Search subdirectories for git repositories

.PARAMETER Full
    Return comprehensive information including owner, visibility, email, branch details, commit status, and dates

.EXAMPLE
    PS /users/jane/repos/kittens> Get-PKGitRepo

        ...Returns basic details for the git repository in the current folder

        Path          : /users/jane/repos/kittens
        Name          : kittens
        LocalBranch   : main
        Fetch_URL     : https://github.com/jbloggs/kittens.git
        Summary       : Clean (no uncommitted changes)

.EXAMPLE
    PS /users/jane/repos> Get-PKGitRepo -Recurse -Full

        ...Returns comprehensive details for all git repositories found under the current folder

        Path                : /users/jane/git/GitHub/flotsam
        Name                : flotsam
        Owner               : jbloggs
        Fetch_URL           : https://github.com/jbloggs/flotsam.git
        Push_URL            : git@github.com:jbloggs/flotsam.git
        LocalBranch         : feature/auth-refactor
        TrackingBranch      : origin/feature/auth-refactor
        DefaultBranch       : main
        IsOnDefaultBranch   : False
        HasUncommittedWork  : True
        NumUncommitted      : 2
        HasUntrackedFiles   : False
        NumUntracked        : 0
        HasUnpushedCommits  : True
        NumUnpushed         : 8
        AheadBy             : 8
        BehindBy            : 5
        Summary             : Diverged (8 ahead, 5 behind)
        Visibility          : Private
        CommitEmail         : jbloggs@users.noreply.github.com
        LastCommitDate      : 2026-09-14T11:33:44-07:00
        LastPushDate        : 2026-09-12T16:18:07-07:00
        LastFetchDate       : 2026-09-15T14:29:50-07:00

.EXAMPLE
    PS /repos> Get-PKGitRepo -Recurse | Format-Table -AutoSize

        ...Returns basic details for all git repositories found in the current folder and subfolders

        Path                        Name        LocalBranch Fetch_URL                               Summary
        ----                        ----        ----------- ---------                               -------
        /users/jane/repos/ephemera  Ephemera    dev         https://github.com/jbloggs/ephemera.git Dirty (2 unstaged changes)
        /users/jane/repos/kittens   kittens     main        https://github.com/jbloggs/kittens.git  Clean (no uncommitted changes)

.EXAMPLE
    PS /repos> Get-PKGitRepo -Recurse | Where-Object {$_.Summary -notlike "Clean*"}

        ...Returns only repositories that are not in a Clean state

        Path                        Name        LocalBranch Fetch_URL                               Summary
        ----                        ----        ----------- ---------                               -------
        /users/jane/repos/ephemera  Ephemera    dev         https://github.com/jbloggs/ephemera.git Dirty (2 unstaged changes)

#>
[CmdletBinding()]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Absolute path to git repositories; default is current location"
    )]
    [Alias("FullName")]
    [object[]]$Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Search subfolders for git repositories"
    )]
    [Switch]$Recurse,

    [Parameter(
        HelpMessage = "Return comprehensive information including privacy, email, dates, and branch details"
    )]
    [Switch]$Full
)
Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "01.01"

    # Start the clock
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # How did we get here?
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = @{} + $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path Variable:$_} | ForEach-Object {$CurrentParams.Add($_, (Get-Variable $_).value)}
    $ComputerName = [System.Net.Dns]::GetHostName()
    $CurrentParams.Add("ComputerName", $ComputerName)
    $CurrentParams.Add("ScriptName", $ScriptName)
    $CurrentParams.Add("ScriptVersion", $Version)
    $CurrentParams.Add("PipelineInput", $PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites
    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path!"
    }
    [switch]$HasGh = $Null -ne (Get-Command gh -ErrorAction SilentlyContinue) 
    #endregion Prerequisites

    #region Select Properties
    If ($Full.IsPresent) {
        [string[]]$Select = @(
            "Path", "Name", "Owner",
            "Fetch_URL", "Push_URL", "Summary",
            "LocalBranch", "TrackingBranch", "DefaultBranch", "IsOnDefaultBranch",
            "HasUncommittedWork", "NumUncommitted", "HasUntrackedFiles", "NumUntracked",
            "HasUnpushedCommits", "NumUnpushed",
            "AheadBy", "BehindBy",
            "Visibility", "CommitEmail",
            "LastCommitDate", "LastPushDate", "LastFetchDate"
        )
    }
    Else {
        [string[]]$Select = @(
            "Path", "Name", "LocalBranch", "Fetch_URL", "Summary"
        )
    }
    #endregion Select Properties

    #region Helper Functions

    Function _GetRemote {
        param([string]$RepoPath)
        Try {
            $FetchUrl = git -C "$RepoPath" config remote.origin.url 2>$null
            $PushUrl = git -C "$RepoPath" config remote.origin.pushurl 2>$null
            If (-not $PushUrl) { $PushUrl = $FetchUrl }
            $Name = (Split-Path -Leaf $FetchUrl).Replace(".git", "")

            Return [PSCustomObject]@{
                Fetch_URL = $FetchUrl
                Push_URL  = $PushUrl
                Name      = $Name
            }
        }
        Catch {
            Write-Verbose "[$RepoPath] Failed to get remote info: $($_.Exception.Message)"
            Return $Null
        }
    } #end _GetRemote

    If ($HasGH) {
        Function _GetPrivacy {
            param([string]$RepoPath)
            Try {
                Write-Verbose "[$RepoPath] Checking privacy via GitHub CLI"
                $PullUrl = git -C "$RepoPath" config remote.origin.url 2>$null
                If ($PullUrl -match 'github\.com[:/]([^/]+)/(.+?)(?:\.git)?$') {
                    $GitHubPath = "$($matches[1])/$($matches[2])"
                    $GhInfo = gh repo view $GitHubPath --json isPrivate 2>$null | ConvertFrom-Json
                    If ($GhInfo.isPrivate) { Return "Private" } Else { Return "Public" }
                }
                Else {
                    Write-Verbose "[$RepoPath] Not a GitHub repository"
                    Return "(unavailable)"
                }
            }
            Catch {
                Write-Verbose "[$RepoPath] Failed to get privacy via gh: $($_.Exception.Message)"
                Return "(unavailable)"
            }
        } # end _GetPrivacy
    } #end if gh

    Function _GetStatus {
        param([string]$RepoPath)
        Try {
            $Status = git -C "$RepoPath" status --porcelain 2>$null
            $HasUncommitted = $False
            $HasUntracked = $False
            $NumUncommitted = 0
            $NumUntracked = 0
            If ($Status) {
                ForEach ($Line in $Status) {
                    If ($Line -match '^\?\?') {
                        $HasUntracked = $True
                        $NumUntracked++
                    }
                    Else {
                        $HasUncommitted = $True
                        $NumUncommitted++
                    }
                }
            }
            $CurrentBranch = ((git -C "$RepoPath" branch 2>&1 | Where-Object {$_ -match "\*"}) -replace "\*", "").Trim()
            $TrackingBranch = git -C "$RepoPath" rev-parse --abbrev-ref "@{u}" 2>$null
            If (-not $TrackingBranch -or $TrackingBranch -eq "HEAD") {$TrackingBranch = "origin/$CurrentBranch"}
            $UnpushedCount = [int](git -C "$RepoPath" rev-list --count "$TrackingBranch..$CurrentBranch" 2>$null)
            $HasUnpushed = $UnpushedCount -gt 0
            Return [PSCustomObject]@{
                Branch                 = $CurrentBranch
                TrackingBranch         = $TrackingBranch
                HasUncommittedWork     = $HasUncommitted
                NumUncommitted       = $NumUncommitted
                HasUntrackedFiles      = $HasUntracked
                NumUntracked     = $NumUntracked
                HasUnpushedCommits     = $HasUnpushed
                NumUnpushed    = $UnpushedCount
            }
        }
        Catch {
            Write-Verbose "[$RepoPath] Failed to get status: $($_.Exception.Message)"
            Return $Null
        }
    } # end _GetStatus

    Function _GetEmail {
        param([string]$RepoPath)
        Try {
            $LocalEmail = git -C "$RepoPath" config --local --get user.email 2>$null
            If ($LocalEmail) {
                Return $LocalEmail
            }
            Else {
                $GlobalEmail = git config --global --get user.email 2>$null
                Return $GlobalEmail
            }
        }
        Catch {
            Write-Verbose "[$RepoPath] Failed to get email: $($_.Exception.Message)"
            Return $Null
        }
    } # end _GetEmail

    Function _GetDates {
        param([string]$RepoPath, [switch]$HasGh)
        Try {
            $LastCommitDate = git -C "$RepoPath" log -1 --format=%aI 2>$null
            $LastFetchDate = If (Test-Path "$RepoPath/.git/FETCH_HEAD") {
                ([System.IO.FileInfo]"$RepoPath/.git/FETCH_HEAD").LastWriteTime.ToString('s') + ([System.IO.FileInfo]"$RepoPath/.git/FETCH_HEAD").LastWriteTime.ToString('zzz')
            }
            Else {
                If ($HasGh) { "(none)" } Else { "(unavailable)" }
            }
            $LastPushDate = git -C "$RepoPath" log -1 --format=%aI --grep="^Merge\|^auto" 2>$null
            If (-not $LastPushDate) {$LastPushDate = $LastCommitDate}
            Return [PSCustomObject]@{
                LastCommitDate = $LastCommitDate
                LastPushDate   = $LastPushDate
                LastFetchDate  = $LastFetchDate
            }
        }
        Catch {
            Write-Verbose "[$RepoPath] Failed to get dates: $($_.Exception.Message)"
            Return [PSCustomObject]@{
                LastCommitDate = $Null
                LastPushDate   = $Null
                LastFetchDate  = $Null
            }
        }
    } # end _GetDates

    Function _GetBranchInfo {
        param([string]$RepoPath, [string]$CurrentBranch, [string]$TrackingBranch)
        Try {
            $DefaultBranch = git -C "$RepoPath" ls-remote --symref origin HEAD 2>$null | ForEach-Object {
                If ($_ -match 'ref: refs/heads/(.+?)\s') {$matches[1]}
            }
            $IsOnDefault = $CurrentBranch -eq $DefaultBranch
            $AheadBy = [int](git -C "$RepoPath" rev-list --count "$TrackingBranch..$CurrentBranch" 2>$null)
            $BehindBy = [int](git -C "$RepoPath" rev-list --count "$CurrentBranch..$TrackingBranch" 2>$null)
            Return [PSCustomObject]@{
                DefaultBranch     = $DefaultBranch
                IsOnDefaultBranch = $IsOnDefault
                AheadBy           = $AheadBy
                BehindBy          = $BehindBy
            }
        }
        Catch {
            Write-Verbose "[$RepoPath] Failed to get branch info: $($_.Exception.Message)"
            Return [PSCustomObject]@{
                DefaultBranch     = $Null
                IsOnDefaultBranch = $Null
                AheadBy           = $Null
                BehindBy          = $Null
            }
        }
    } # end _GetBranchInfo

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
            If ($HasUncommittedWork) {$Details += "$NumUncommitted unstaged change$(If ($NumUncommitted -ne 1) {'s'})"}
            If ($HasUntrackedFiles) {$Details += "$NumUntracked untracked file$(If ($NumUntracked -ne 1) {'s'})"}
            If ($HasUnpushedCommits) {$Details += "$NumUnpushed unpushed commit$(If ($NumUnpushed -ne 1) {'s'})"}
            If ($AheadBy -gt 0 -and $BehindBy -gt 0) {Return "Diverged ($AheadBy ahead, $BehindBy behind)"}
            ElseIf ($HasUncommittedWork -or $HasUntrackedFiles) {$DetailStr = $Details -join ", ";Return "Dirty ($DetailStr)"}
            ElseIf ($HasUnpushedCommits) {Return "Unpushed ($($Details -join ', '))"}
            ElseIf ($BehindBy -gt 0) {Return "Behind ($BehindBy behind)"}
            Else {Return "Clean (no uncommitted changes)"}
        }
        Catch {
            Write-Verbose "Failed to format summary: $($_.Exception.Message)"
            Return "(unavailable)"
        }
    } # end _FormatSummary

    Function _GetSummary {
        param([object]$Status, [object]$BranchInfo)
        Try {
            $FormattedSummary = _FormatSummary `
                -HasUncommittedWork $Status.HasUncommittedWork `
                -HasUntrackedFiles $Status.HasUntrackedFiles `
                -NumUncommitted $Status.NumUncommitted `
                -NumUntracked $Status.NumUntracked `
                -HasUnpushedCommits $Status.HasUnpushedCommits `
                -NumUnpushed $Status.NumUnpushed `
                -AheadBy $BranchInfo.AheadBy `
                -BehindBy $BranchInfo.BehindBy
            Return $FormattedSummary
        }
        Catch {
            Write-Verbose "Failed to get summary: $($_.Exception.Message)"
            Return "(unavailable)"
        }
    } # end _GetSummary

    #endregion Helper Functions

    $Activity = "Get repository information"
    If ($Recurse.IsPresent) { $Activity += " for all repo found in subfolders" }
    Write-Verbose "[BEGIN: $ScriptName] $Activity"

    If (-not $HasGH) {
        Write-Warning "GitHub CLI (gh) not found in path; some information may be unavailable (ignore if not using GitHub)"
    }           

}
Process {

    Foreach ($Item in $Path) {

        $Current = $Item.ToString()
        $Msg = "Searching for git repo"
        If ($Recurse.IsPresent) { $Msg = "Searching tree for git repos" }
        Write-Verbose "[$Current] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current

        Try {
            $FolderObj = Get-Item -Path $Item -Verbose:$False
            [object[]]$GitRepos = Test-PKGitRepo -Path $FolderObj.FullName -Recurse:$Recurse.IsPresent -Verbose:$False

            If ($GitRepos) {
                $TotalRepos = $GitRepos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Current] $Msg"

                Foreach ($RepoPath in ($GitRepos | Sort-Object | Select-Object -Unique)) {

                    $CurrentRepo++
                    If ((git -C "$RepoPath" rev-parse --is-inside-work-tree 2>$null) -ne "true") {
                        Write-Warning "[$RepoPath] Not a git repository"
                        Continue
                    }

                    Write-Verbose "[$RepoPath] Getting repository information"
                    Write-Progress -Activity $Activity -CurrentOperation $RepoPath -Status Working -PercentComplete ($CurrentRepo / $TotalRepos * 100)

                    Try {
                        $Remote = _GetRemote -RepoPath $RepoPath
                        $Status = _GetStatus -RepoPath $RepoPath

                        If ($Remote.Fetch_URL -match 'github\.com[:/]([^/]+)/(.+?)(?:\.git)?$') {
                            $Owner = $matches[1]
                        }
                        Else {$Owner = "(unavailable)"}

                        $BranchInfo = _GetBranchInfo -RepoPath $RepoPath -CurrentBranch $Status.Branch -TrackingBranch $Status.TrackingBranch
                        $Summary = _GetSummary -Status $Status -BranchInfo $BranchInfo

                        If ($Full.IsPresent) {
                            If ($HasGh) {
                                $Visibility = _GetPrivacy -RepoPath $RepoPath
                            }
                            Else {$Visibility = "(unavailable)"}
                            $Email = _GetEmail -RepoPath $RepoPath
                            $Dates = _GetDates -RepoPath $RepoPath -HasGh:$HasGh
                        }
                        Else {
                            $Visibility = $Null
                            $Email = $Null
                            $Dates = [PSCustomObject]@{ LastCommitDate = $Null; LastPushDate = $Null; LastFetchDate = $Null }
                        }

                        [PSCustomObject]@{
                            Path                = $RepoPath
                            Name                = $Remote.Name
                            LocalBranch         = $Status.Branch
                            Fetch_URL           = $Remote.Fetch_URL
                            Push_URL            = $Remote.Push_URL
                            Summary             = $Summary
                            HasUncommittedWork  = $Status.HasUncommittedWork
                            NumUncommitted      = $Status.NumUncommitted
                            HasUntrackedFiles   = $Status.HasUntrackedFiles
                            NumUntracked        = $Status.NumUntracked
                            HasUnpushedCommits  = $Status.HasUnpushedCommits
                            NumUnpushed         = $Status.NumUnpushed
                            Owner               = $Owner
                            Visibility          = $Visibility
                            CommitEmail         = $Email
                            DefaultBranch       = $BranchInfo.DefaultBranch
                            IsOnDefaultBranch   = $BranchInfo.IsOnDefaultBranch
                            TrackingBranch      = $Status.TrackingBranch
                            AheadBy             = $BranchInfo.AheadBy
                            BehindBy            = $BranchInfo.BehindBy
                            LastCommitDate      = $Dates.LastCommitDate
                            LastPushDate        = $Dates.LastPushDate
                            LastFetchDate       = $Dates.LastFetchDate
                        } | Select-Object -Property $Select
                    }
                    Catch {
                        $Msg = "Operation failed"
                        If ($ErrorDetails = $_.Exception.Message) { $Msg += "; $ErrorDetails" }
                        Write-Warning "[$RepoPath] $Msg"
                    }
                }
            }
            Else {
                $Msg = "No git repo found"
                If (-not $Recurse.IsPresent) { $Msg += " (try -Recurse)" }
                Write-Warning "[$Current] $Msg"
            }
        }
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) { $Msg += "; $ErrorDetails" }
            Write-Warning "[$Current] $Msg"
        }
    }
}
End {
    Write-Progress -Activity * -Completed
    $Stopwatch.Stop()
    Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
}
} # end Get-PKGitRepo
