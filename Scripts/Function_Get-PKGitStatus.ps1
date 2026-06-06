#requires -Version 4
Function Get-PKGitStatus {
    <#
    .SYNOPSIS
        Get the status of one or more git repositories, returning branch, origin, working tree state, and a count-based summary of uncommitted changes

    .DESCRIPTION
        Retrieves git repository status from one or more git repositories using native git commands
        Accepts pipeline input for file paths or direct path parameters; use -Recurse to search subdirectories for repos
        Requires git to be installed and available in the system path

        Default output (Path, Name, Origin, IsCurrent, Summary):
            - Origin is always returned from git config remote.origin.url
            - IsCurrent is a boolean derived from git status --porcelain
            - Summary is a human-readable count of uncommitted changes, e.g. "3 unstaged changes, 2 untracked files",
                or "Working tree clean" if the repo has no local changes; counts cover staged changes, unstaged
                modifications, untracked files, and merge conflicts

        When -Extended is specified, adds Branch, Upstream, AheadBy, BehindBy, NumStaged, NumUnstaged, NumUntracked, NumConflicts, LastSyncDate, LastCommitDate, LastCommitter, Files, OriginStatus, Message ...
            - AheadBy and BehindBy are integer counts from git rev-list (ahead/behind remote)
            - NumStaged, NumUnstaged, NumUntracked, NumConflicts are integer counts of changes by type
            - LastSyncDate is the timestamp of the most recent sync with remote (from .git/FETCH_HEAD if available, else clone or create date)
            - LastCommitDate is the timestamp of the most recent commit
            - LastCommitter is the committer name and email from the most recent commit
            - Files is a collection of porcelain status lines for all working and untracked files
            - Message is the full git status output as a string array
            - Use -CollectionsToStrings (Extended ParameterSet only) to join Files and Message with newlines
                instead of returning them as arrays

    .NOTES
        Name    : Function_Get-PKGitStatus.ps1
        Author  : Paula Kingsley
        Version : 04.03
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
            v04.00 - 2026-06-06 - Overhauled for consistency with others in module; added porcelain-derived details, LastCommitDate, LastCommitter, LastSyncDate (FETCH_HEAD or clone date fallback)

    .LINK
        https://github.com/lanwench/pkgit

    .PARAMETER Path
        Absolute path to one or more git repos (default is current location)

    .PARAMETER Recurse
        Recurse subfolders in path

    .PARAMETER Extended
        Include extended properties: branch, upstream, ahead/behind counts, working file details, origin status, full status message

    .PARAMETER CollectionsToStrings
        Format collection-valued properties (Files, Message) as newline-separated strings; requires -Extended

    .EXAMPLE
        PS /users/jane/repos/kittens> Get-PKGitStatus -Verbose
        Returns git status from the current directory with verbose output showing parameter details and search process.

        VERBOSE: PSBoundParameters:

        Key                  Value
        ---                  -----
        Verbose              True
        Path                 {/users/jane/repos/kittens}
        Recurse              False
        Extended             False
        CollectionsToStrings False
        ComputerName         mackie.local
        ScriptName           Get-PKGitStatus
        ScriptVersion        4.0
        PipelineInput        False

        VERBOSE: [BEGIN: Get-PKGitStatus] Get git status
        VERBOSE: Commands:

        GetStatus      : git -C <path> status 2>&1
        GetBranch      : git -C <path> branch 2>&1
        GetConfig      : git -C <path> config remote.origin.url
        GetPorcelain   : git -C <path> status --porcelain
        GetAheadBehind : git -C <path> rev-list --count (Extended only)

        VERBOSE: [/users/jane/repos/kittens] Searching for git repo
        VERBOSE: [/users/jane/repos/kittens] 1 git repo(s) found
        VERBOSE: [/users/jane/repos/kittens] Get git status
        VERBOSE: [END: Get-PKGitStatus] Script ran successfully

        Path           : /users/jane/repos/kittens
        Name           : kittens
        Origin         : https://github.com/jbloggs/kittens.git
        IsCurrent      : False
        Summary        : 1 unstaged change, 1 untracked file

    .EXAMPLE
        PS /users/shared> Get-PKGitStatus -Path /users/jane/junkdrawer -Recurse -Verbose | Format-Table -AutoSize
        Returns a summary status from all git repositories in the named directory and subdirectories

        Path                                       Name         Origin                                      IsCurrent   Summary
        ----                                       ----         ------                                      ---------   -------
        /users/jane/junkdrawer/pythonstuff  pythonstuff  https://github.com/jbloggs/pythonstuff.git       True   Working tree clean
        /users/jane/junkdrawer/PSGit        PSGit        https://github.com/jbloggs/PSGit.git            False   3 unstaged changes
        /users/jane/junkdrawer/Helpers      Helpers      https://github.com/jbloggs/Helpers.git          False   2 untracked files

    .EXAMPLE
        PS C:\> Get-PKGitStatus -Path C:\Users\jbloggs\git\personal\Tools -Extended -CollectionsToStrings
        Returns full extended status with all working file data, fetch and commit info; Files and Message formatted as strings.

        Path           : C:\Users\jbloggs\git\personal\Tools
        Name           : Tools
        Origin         : https://github.com/jbloggs/Tools.git
        IsCurrent      : False
        Branch         : main
        Upstream       : origin/main
        AheadBy        : 0
        BehindBy       : 0
        NumStaged      : 0
        NumUnstaged    : 1
        NumUntracked   : 1
        NumConflicts   : 0
        LastFetchDate  : 2026-06-05T11:15:42-07:00
        LastCommitDate : 2026-06-05T14:22:17-07:00
        LastCommitter  : Jane Bloggs (jbloggs@github.com)
        Files          : M Scripts/GetDisabledDate.ps1
                         ?? Scripts/Function_Get-DownloadFileInfo.ps1
        OriginStatus   : Your branch is up to date with 'origin/main'.
        Message        : On branch main
                         Your branch is up to date with 'origin/main'.
                         Changes not staged for commit:
                         modified:   Scripts/GetDisabledDate.ps1
                         Untracked files:
                         Scripts/Function_Get-DownloadFileInfo.ps1

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
        [Parameter(
            ParameterSetName = "Default",
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to git repos (default is current location)"
        )]
        [Parameter(
            ParameterSetName = "Extended",
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to git repos (default is current location)"
        )]
        [Alias("FullName", "RepoPath")]
        [object[]]$Path = (Get-Location).Path,

        [Parameter(
            ParameterSetName = "Default",
            HelpMessage = "Recurse subfolders in path"
        )]
        [Parameter(
            ParameterSetName = "Extended",
            HelpMessage = "Recurse subfolders in path"
        )]
        [Switch]$Recurse,

        [Parameter(
            ParameterSetName = "Extended",
            HelpMessage = "Include extended properties: branch, upstream, ahead/behind counts, working file details, origin status, full status message"
        )]
        [switch]$Extended,

        [Parameter(
            ParameterSetName = "Extended",
            HelpMessage = "Format collection-valued properties (Files, Message) as newline-separated strings; requires -Extended"
        )]
        [Switch]$CollectionsToStrings

    )
    Begin {

        # Current version (please keep up to date from comment block)
        [version]$Version = "04.00"

        # How did we get here?
        [switch]$PipelineInput = $MyInvocation.ExpectingInput
        $CurrentParams = $PSBoundParameters
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

        # Build activity description
        $Activity = "Get git status"
        If ($Recurse.IsPresent) { $Activity += " for all repos found in subfolders" }
        If ($Extended.IsPresent) { $Activity += " with extended properties" }
        If ($CollectionsToStrings.IsPresent) { $Activity += " (collections as strings)" }

        $Commands = [PSCustomObject]@{
            GetStatus      = 'git -C <path> status 2>&1'
            GetBranch      = 'git -C <path> branch 2>&1'
            GetConfig      = 'git -C <path> config remote.origin.url'
            GetPorcelain   = 'git -C <path> status --porcelain'
            GetAheadBehind = 'git -C <path> rev-list --count (Extended only)'
            GetLastSync    = 'Get-Item <path>/.git/FETCH_HEAD or git log --all --reverse (Extended only)'
            GetLastCommit  = 'git -C <path> log -1 --format=%cI%cn (%ce) (Extended only)'
        }

        Write-Verbose "[BEGIN: $ScriptName] $Activity"
        Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

        # Build $Select for what properties to return
        If ($Extended.IsPresent) {
            $Select = "Path", "Name", "Origin", "IsCurrent", "Branch", "Upstream", "AheadBy", "BehindBy", "NumStaged", "NumUnstaged", "NumUntracked", "NumConflicts", "LastSyncDate", "LastCommitDate", "LastCommitter", "Files", "OriginStatus", "Message"
        }
        Else {
            $Select = "Path", "Name", "Origin", "IsCurrent", "Summary"
        }

    }
    Process {

        Foreach ($P in $Path) {
            Try {
                If ($P -is [string] -or $P -is [System.IO.FileSystemInfo]) { $Label = $P }
                ElseIf ($P -is [System.Management.Automation.PathInfo]) { $Label = $P.FullName }

                Write-Verbose "[$Label] Searching for git repos"

                [object[]]$Repos = Test-PKGitRepo -Path $P -Recurse:$Recurse.IsPresent -Verbose:$False
                If ($Repos) {
                    $Msg = "$($Repos.Count) git repo(s) found"
                    Write-Verbose "[$Label] $Msg"

                    Foreach ($Repo in ($Repos | Sort-Object | Select-Object -Unique)) {
                        $Label = $Repo
                        Write-Verbose "[$Label] Get git status"

                        Try {
                            $Status = git -C "$Repo" status 2>&1
                            $ExitCode = $LASTEXITCODE

                            If ($ExitCode -eq 0 -and $Status) {
                                $Origin   = git -C "$Repo" config remote.origin.url 2>$null
                                $Name     = (Split-Path -Leaf $Origin).Replace(".git", $Null)
                                $Branch   = ((git -C "$Repo" branch 2>&1 | Where-Object { $_ -match "\*" }) -replace ("\*", $Null)).Trim()

                                # Porcelain for counts (we always run this, as it's also used for Summary and IsCurrent)
                                $Porcelain      = git -C "$Repo" status --porcelain 2>$null
                                $StagedCount    = ($Porcelain | Where-Object { $_ -match '^[MADRC]' }).Count
                                $UnstagedCount  = ($Porcelain | Where-Object { $_ -match '^[ MADRC][MD]' }).Count
                                $UntrackedCount = ($Porcelain | Where-Object { $_ -match '^\?\?' }).Count
                                $ConflictCount  = ($Porcelain | Where-Object { $_ -match '^[UA][AU]|^DD' }).Count
                                $Current        = ($StagedCount + $UnstagedCount + $UntrackedCount + $ConflictCount) -eq 0

                                If ($Current) {
                                    $Summary = "Working tree clean"
                                }
                                Else {
                                    $Parts = @()
                                    If ($ConflictCount -gt 0)  { $Parts += "$ConflictCount conflict$(If ($ConflictCount -ne 1) {'s'})" }
                                    If ($StagedCount -gt 0)    { $Parts += "$StagedCount staged change$(If ($StagedCount -ne 1) {'s'})" }
                                    If ($UnstagedCount -gt 0)  { $Parts += "$UnstagedCount unstaged change$(If ($UnstagedCount -ne 1) {'s'})" }
                                    If ($UntrackedCount -gt 0) { $Parts += "$UntrackedCount untracked file$(If ($UntrackedCount -ne 1) {'s'})" }
                                    $Summary = $Parts -join ", "
                                }

                                If ($Extended.IsPresent) {
                                    $Upstream = git -C "$Repo" rev-parse --abbrev-ref "@{u}" 2>$null
                                    $AheadBy  = 0
                                    $BehindBy = 0
                                    If ($Upstream -and $Upstream -ne "HEAD") {
                                        $AheadBy  = [int](git -C "$Repo" rev-list --count "$Upstream..$Branch" 2>$null)
                                        $BehindBy = [int](git -C "$Repo" rev-list --count "$Branch..$Upstream" 2>$null)
                                    }

                                    # Get last sync date: FETCH_HEAD if available, else clone date from .git/config
                                    $FetchHeadPath = "$Repo/.git/FETCH_HEAD"
                                    If (Test-Path $FetchHeadPath) {
                                        $SyncTime = (Get-Item $FetchHeadPath -ErrorAction SilentlyContinue).LastWriteTime
                                        $LastSyncDate = $SyncTime.ToString('s') + $SyncTime.ToString('zzz')
                                    }
                                    Else {
                                        # Fall back to clone date (.git/config creation time)
                                        $ConfigPath = "$Repo/.git/config"
                                        If (Test-Path $ConfigPath) {
                                            $ConfigTime = (Get-Item $ConfigPath -ErrorAction SilentlyContinue).LastWriteTime
                                            $LastSyncDate = $ConfigTime.ToString('s') + $ConfigTime.ToString('zzz')
                                        }
                                        Else {
                                            $LastSyncDate = $Null
                                        }
                                    }

                                    # Get last commit info
                                    $LastCommitInfo = git -C "$Repo" log -1 --format="%cI`t%cn (%ce)" 2>$null
                                    If ($LastCommitInfo) {
                                        $LastCommitParts = $LastCommitInfo -split "`t"
                                        $LastCommitDate = $LastCommitParts[0]
                                        $LastCommitter = $LastCommitParts[1]
                                    }
                                    Else {
                                        $LastCommitDate = $Null
                                        $LastCommitter = $Null
                                    }

                                    $WorkingFiles = @($Porcelain -split "`n" | Where-Object { $_ })
                                    $Files        = If ($CollectionsToStrings.IsPresent) { ($WorkingFiles | ForEach-Object { $_.TrimStart() }) -join "`n" } Else { $WorkingFiles }
                                    $MsgOut       = If ($CollectionsToStrings.IsPresent) { $Status -join "`n" } Else { $Status }
                                }
                                Else {
                                    $Upstream = $Null; $AheadBy = $Null; $BehindBy = $Null
                                    $StagedCount = $Null; $UnstagedCount = $Null; $UntrackedCount = $Null; $ConflictCount = $Null
                                    $LastSyncDate = $Null; $LastCommitDate = $Null; $LastCommitter = $Null
                                    $Files = $Null; $MsgOut = $Null
                                }

                                $Output = [PSCustomObject]@{
                                    Path           = $Repo
                                    Name           = $Name
                                    Origin         = $Origin
                                    Branch         = $Branch
                                    Upstream       = $Upstream
                                    IsCurrent      = $Current
                                    Summary        = $Summary
                                    AheadBy        = $AheadBy
                                    BehindBy       = $BehindBy
                                    NumStaged      = $StagedCount
                                    NumUnstaged    = $UnstagedCount
                                    NumUntracked   = $UntrackedCount
                                    NumConflicts   = $ConflictCount
                                    LastSyncDate   = $LastSyncDate
                                    LastCommitDate = $LastCommitDate
                                    LastCommitter  = $LastCommitter
                                    Files          = $Files
                                    OriginStatus   = ($Status | Select-String "your branch is").ToString()
                                    Message        = $MsgOut
                                }
                                Write-Output ($Output | Select-Object $Select)
                            }
                            ElseIf ($ExitCode -ne 0) {
                                Write-Warning "[$Label] Operation failed; $($Status -join ' ')"
                            }
                        }
                        Catch {
                            Write-Warning "[$Label] Operation failed; $($_.Exception.Message)"
                        }
                    } # end foreach repo
                }
                Else {
                    $Msg = "No git repositories found in path"
                    If (-not $Recurse.IsPresent) { $Msg += " (try -Recurse)" }
                    Write-Warning "[$Label] $Msg"
                }
            }
            Catch {
                Write-Warning "[$P] Operation failed; $($_.Exception.Message)"
            }
        } #end foreach path
    }
    End {
        Write-Verbose "[END: $ScriptName] Script ran successfully"
    }
} #end Get-PKGitStatus
