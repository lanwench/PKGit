#requires -Version 4
Function Invoke-PKGitPull {
    <#
    .SYNOPSIS
        Pull changes from the remote origin in one or more git repositories with confirmation (basic git pull only; no fancy options)

    .DESCRIPTION
        Pulls changes from the remote on one or more git repositories using `git pull`
        Accepts pipeline input for file paths or direct path parameters
        Searches for git repositories in subdirectories if -Recurse is specified
        Supports ShouldProcess for confirmation before pulling
        Returns a PSCustomObject with detailed pull results, parsed summary, pull type, and changed files for each repo
        Requires git to be installed and available in the system path

        Default output includes: Path, Name, Branch, Upstream, PullSuccess, PullType, ExecutedDate, Summary, FilesChanged, ParsedSummary, and Message (git pull output)

        The behavior can be customized using the following options:

        - Use -Recurse to search for all git repositories in subdirectories
        - Use -CollectionsToStrings (Extended ParameterSet) to format FilesChanged and Message as newline-separated strings instead of arrays
        - Use -Simple (Simple ParameterSet) to return minimal output: Path, Name, Branch, PullSuccess, Summary

        The function verifies that git is installed/available and that file paths contain valid git repositories

    .NOTES
        Name    : Function_Invoke-PKGitPull.ps1
        Author  : Paula Kingsley
        Version : 03.00
        History :

            ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

            v01.00 - 2021-04-14 - Created script
            v02.01 - 2025-08-13 - Minor cosmetic changes for standardization
            v03.00 - 2026-06-06 - Overhauled for consistency with others in module; removed duplication; uses git -C; structured output with PullSuccess, Summary, Message, other updates

    .LINK
        https://github.com/lanwench/pkgit

    .PARAMETER Path
        Absolute path to one or more git repos (default is current location)

    .PARAMETER Recurse
        Recurse subfolders in path

    .PARAMETER CollectionsToStrings
        Format collection-valued properties (FilesChanged, Message) as newline-separated strings instead of arrays
        Only valid in Extended ParameterSet (incompatible with -Simple)

    .PARAMETER Simple
        Return minimal output: Path, Name, Branch, PullSuccess, Summary only
        Incompatible with -CollectionsToStrings

    .EXAMPLE
        PS /users/jane/repos/kittens> Invoke-PKGitPull -Verbose
        Prompts for confirmation and invokes git pull for the current directory with full output

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Verbose          True
        Path             {/users/jane/repos/kittens}
        Recurse          False
        ShowMessage      False
        CollectionsToStrings False
        ComputerName     mackie.local
        ScriptName       Invoke-PKGitPull
        ScriptVersion    3.0
        PipelineInput    False

        VERBOSE: [BEGIN: Invoke-PKGitPull] Pull changes from remote repos
        VERBOSE: [/users/jane/repos/kittens] Searching for git repo
        VERBOSE: [/users/jane/repos/kittens] 1 git repo(s) found
        VERBOSE: [/users/jane/repos/kittens] Pull from origin/main

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Pull from origin/main" on target "/users/jane/repos/kittens".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):Y

        Path           : /users/jane/repos/kittens
        Name           : kittens
        Branch         : main
        Upstream       : origin/main
        PullSuccess    : True
        PullType       : AlreadyUpToDate
        Summary        : Already up to date
        FilesChanged   : {}
        ParsedSummary  :
        Message        :

        VERBOSE: [END: Invoke-PKGitPull] Pull changes from remote repos

    .EXAMPLE
        PS /users/shared> Invoke-PKGitPull -Path /users/jane/junkdrawer -Recurse -Confirm:$False -Simple | Format-Table -AutoSize
        Pulls from all git repositories with minimal output, skipping confirmation

        Path                                 Name         Branch   PullSuccess   Summary
        ----                                 ----         ------   -----------   -------
        /users/jane/junkdrawer/pythonstuff   pythonstuff  main             True   Already up to date
        /users/jane/junkdrawer/PSGit         PSGit        master          False   Pull failed
        /users/jane/junkdrawer/Helpers       Helpers      main             True   5 files changed, 3 insertions

    .EXAMPLE
        PS /users/jane/repos> Invoke-PKGitPull -Path /users/jane/repos/active -Confirm:$False
        Pulls with full output including parsed summary and changed files list

        Path           : /users/jane/repos/active
        Name           : active
        Branch         : main
        Upstream       : origin/main
        PullSuccess    : True
        PullType       : FastForward
        Summary        : 17 files changed, 3880 insertions(+), 1172 deletions(-)
        FilesChanged   : {README.md, src/main.ps1, src/utils.ps1, docs/guide.md...}
        ParsedSummary  : @{FileCount=17; Insertions=3880; Deletions=1172}
        Message        :

    .EXAMPLE
        PS /users/jane/repos> Invoke-PKGitPull -Path /users/jane/repos/broken -ShowMessage -CollectionsToStrings
        Attempts to pull from a repo with a merge conflict; shows the raw error message as a single string

        Path           : /users/jane/repos/broken
        Name           : broken
        Branch         : main
        Upstream       : origin/main
        PullSuccess    : False
        PullType       : Conflict
        Summary        : Pull succeeded with merge conflicts
        FilesChanged   : (empty)
        ParsedSummary  :
        Message        : error: Your local changes to 'src/config.yml' would be overwritten by merge
                         hint: commit your changes or stash them before you merge
                         hint: Updating 8ef32a1..c1a4f8e
                         fatal: Unable to create '/users/jane/repos/broken/.git/index.lock': File exists

    #>
    [CmdletBinding(
        DefaultParameterSetName = "Default",
        SupportsShouldProcess = $True,
        ConfirmImpact = "High"
    )]
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
        [Parameter(
            ParameterSetName = "Simple",
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
        [Parameter(
            ParameterSetName = "Simple",
            HelpMessage = "Recurse subfolders in path"
        )]
        [Switch]$Recurse,

        [Parameter(
            ParameterSetName = "Extended",
            HelpMessage = "Format collection-valued properties (FilesChanged, Message) as newline-separated strings"
        )]
        [Switch]$CollectionsToStrings,

        [Parameter(
            ParameterSetName = "Simple",
            HelpMessage = "Return minimal output only"
        )]
        [Switch]$Simple

    )
    Begin {

        # Current version (please keep up to date from comment block)
        [version]$Version = "03.00"

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

        #region Prerequisites

        If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
        }

        #endregion Prerequisites

        $Commands = [PSCustomObject]@{
            GetConfig    = 'git -C <path> config remote.origin.url'
            GetBranch    = 'git -C <path> branch'
            GetUpstream  = 'git -C <path> rev-parse --abbrev-ref "@{u}"'
            Pull         = 'git -C <path> pull'
            GetDiff      = 'git -C <path> diff --name-only FETCH_HEAD... (Extended only)'
            Status       = 'git -C <path> status --porcelain --branch'
        }

        # Build activity description and determine output properties
        $Activity = "Pull changes from remote repos"
        If ($PSCmdlet.ParameterSetName -eq "Extended") { $Activity += " with detailed summary" }
        If ($PSCmdlet.ParameterSetName -eq "Simple") { $Activity += " (minimal output)" }
        If ($CollectionsToStrings.IsPresent) { $Activity += " (collections as strings)" }

        # Determine which properties to return based on ParameterSet
        If ($PSCmdlet.ParameterSetName -eq "Simple") {
            $Select = "Path", "Name", "Branch", "PullSuccess", "Summary"
        }
        Else {
            $Select = "Path", "Name", "Branch", "Upstream", "PullSuccess", "PullType", "ExecutedDate", "Summary", "FilesChanged", "ParsedSummary", "Message"
        }

        Write-Verbose "[BEGIN: $ScriptName] $Activity"
        Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

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
                        Write-Verbose "[$Label] Get remote info"

                        Try {
                            $Origin   = git -C "$Repo" config remote.origin.url 2>$null
                            $Name     = (Split-Path -Leaf $Origin).Replace(".git", $Null)
                            $Branch   = ((git -C "$Repo" branch 2>&1 | Where-Object { $_ -match "\*" }) -replace ("\*", $Null)).Trim()
                            $Upstream = git -C "$Repo" rev-parse --abbrev-ref "@{u}" 2>$null

                            If (-not $Upstream -or $Upstream -eq "HEAD") {
                                $Upstream = "origin/$Branch"
                            }

                            $Msg = "Pull from $Upstream"
                            Write-Verbose "[$Label] $Msg"

                            $PullSuccess = $False
                            $Summary = $Null
                            $Message = $Null
                            $PullType = $Null
                            $FilesChanged = @()
                            $ParsedSummary = @{}
                            $ExecutedDate = $Null

                            If ($PSCmdlet.ShouldProcess($Label, $Msg)) {
                                $ExecutedDate = ([DateTime]::Now).ToString('s') + ([DateTime]::Now).ToString('zzz')
                                $PullOutput = git -C "$Repo" pull 2>&1
                                $ExitCode = $LASTEXITCODE

                                If ($ExitCode -eq 0) {
                                    $PullSuccess = $True

                                    # Determine pull type
                                    If ($PullOutput -match "Already up to date") {
                                        $PullType = "AlreadyUpToDate"
                                        $Summary = "Already up to date"
                                    }
                                    ElseIf ($PullOutput -match "Fast-forward") {
                                        $PullType = "FastForward"
                                        $Summary = ($PullOutput | Select-String "files? changed" | Select-Object -First 1).ToString().Trim()
                                    }
                                    ElseIf ($PullOutput -match "Merge made|CONFLICT") {
                                        If ($PullOutput -match "CONFLICT") {
                                            $PullType = "Conflict"
                                            $Summary = "Pull succeeded with merge conflicts"
                                        }
                                        Else {
                                            $PullType = "Merge"
                                            $Summary = ($PullOutput | Select-String "files? changed" | Select-Object -First 1).ToString().Trim()
                                        }
                                    }
                                    Else {
                                        $PullType = "Success"
                                        If ($PullOutput -match "(\d+) files? changed") {
                                            $Summary = ($PullOutput | Select-String "files? changed" | Select-Object -First 1).ToString().Trim()
                                        }
                                        Else {
                                            $Summary = "Pull succeeded"
                                        }
                                    }

                                    # Parse summary for file count, insertions, deletions
                                    If ($Summary -match "(\d+)\s+files?\s+changed") {
                                        $ParsedSummary.FileCount = [int]$Matches[1]
                                    }
                                    If ($Summary -match "(\d+)\s+insertions?") {
                                        $ParsedSummary.Insertions = [int]$Matches[1]
                                    }
                                    If ($Summary -match "(\d+)\s+deletions?") {
                                        $ParsedSummary.Deletions = [int]$Matches[1]
                                    }

                                    # Get list of changed files (not needed for Simple output)
                                    If ($PSCmdlet.ParameterSetName -ne "Simple") {
                                        If ($PullType -ne "AlreadyUpToDate") {
                                            # Get files from the last commit (what was pulled/merged)
                                            $FilesChanged = @(git -C "$Repo" log -1 --pretty=format: --name-only 2>$null | Where-Object { $_ })
                                        }
                                    }
                                }
                                Else {
                                    $PullSuccess = $False
                                    $PullType = "Failed"
                                    $Summary = "Pull failed"
                                    If ($PullOutput -match "CONFLICT") {
                                        $PullType = "Conflict"
                                    }
                                }

                                # Always populate Message; format based on CollectionsToStrings
                                $Message = If ($CollectionsToStrings.IsPresent) {
                                    $PullOutput -join "`n"
                                }
                                Else {
                                    $PullOutput
                                }
                            }
                            Else {
                                $Summary = "Operation cancelled by user"
                                $PullType = "Cancelled"
                            }

                            # Format collections if requested
                            $FilesOut = If ($CollectionsToStrings.IsPresent) { ($FilesChanged -join "`n") } Else { $FilesChanged }

                            $Output = [PSCustomObject]@{
                                Path          = $Repo
                                Name          = $Name
                                Branch        = $Branch
                                Upstream      = $Upstream
                                PullSuccess   = $PullSuccess
                                PullType      = $PullType
                                ExecutedDate  = $ExecutedDate
                                Summary       = $Summary
                                FilesChanged  = $FilesOut
                                ParsedSummary = If ($ParsedSummary.Count -gt 0) { $ParsedSummary } Else { $Null }
                                Message       = $Message
                            }

                            Write-Output ($Output | Select-Object $Select)
                        }
                        Catch {
                            Write-Warning "[$Label] Operation failed; $($_.Exception.Message)"
                        }
                    } # end foreach repo
                }
                Else {
                    $Msg = "No git repo found"
                    If (-not $Recurse.IsPresent) { $Msg += " (try -Recurse)" }
                    Write-Warning "[$Label] $Msg"
                }
            }
            Catch {
                Write-Warning "[$P] Operation failed; $($_.Exception.Message)"
            }
        } # end foreach path
    }
    End {
        Write-Verbose "[END: $ScriptName] Script ran successfully"
    }
} #end Invoke-PKGitPull
