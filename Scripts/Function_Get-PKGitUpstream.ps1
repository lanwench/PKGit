#requires -Version 4
Function Get-PKGitUpstream {
    <#
    .SYNOPSIS
        Check for pending updates from remote origin on one or more git repositories

    .DESCRIPTION
        Checks remote origin for pending changes that haven't been pulled locally
        Performs a fetch first to get latest remote state
        Accepts pipeline input for file paths or direct path parameters
        Searches for git repositories in subdirectories if -Recurse is specified
        Requires git to be installed and available in the system path

        Returns a PSCustomObject for each repo with: Path, Name, Branch, Upstream, AheadBy, BehindBy, PendingStatus, PullUrl, PushUrl, LastFetchDate

        PendingStatus indicates:
        - "In Sync" — local and remote are aligned
        - "Updates Available" — remote has unpulled commits
        - "Ahead" — local has unpushed commits
        - "Diverged" — both ahead and behind (merge conflict risk)

    .NOTES
        Name    : Function_Get-PKGitUpstream.ps1
        Author  : Paula Kingsley
        Version : 01.00
        History :

            ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

            v01.00 - 2026-06-06 - Created script to check for pending remote updates

    .LINK
        https://github.com/lanwench/pkgit

    .PARAMETER Path
        Absolute path to one or more git repos (default is current location)

    .PARAMETER Recurse
        Recurse subfolders in path

    .EXAMPLE
        PS /users/jane/repos/kittens> Get-PKGitUpstream -Verbose

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Verbose          True
        Path             {/users/jane/repos/kittens}
        Recurse          False
        ComputerName     mackie.local
        ScriptName       Get-PKGitUpstream
        ScriptVersion    1.0
        PipelineInput    False

        VERBOSE: [BEGIN: Get-PKGitUpstream] Check for pending upstream updates
        VERBOSE: [/users/jane/repos/kittens] Searching for git repos
        VERBOSE: [/users/jane/repos/kittens] 1 git repo(s) found
        VERBOSE: [/users/jane/repos/kittens] Fetching from origin
        VERBOSE: [/users/jane/repos/kittens] Checking for pending updates

        Path            : /users/jane/repos/kittens
        Name            : kittens
        Branch          : main
        Upstream        : origin/main
        AheadBy         : 0
        BehindBy        : 3
        PendingStatus   : Updates Available
        LastFetchDate   : 2026-06-06T14:30:22-07:00

    .EXAMPLE
        PS /users/shared> Get-PKGitUpstream -Path /users/jane/junkdrawer -Recurse | Where-Object {$_.BehindBy -gt 0}
        Returns only repos that have unpulled changes from remote

        Path            : /users/jane/junkdrawer/pythonstuff
        Name            : pythonstuff
        Branch          : main
        Upstream        : origin/main
        AheadBy         : 0
        BehindBy        : 5
        PendingStatus   : Updates Available
        LastFetchDate   : 2026-06-06T14:30:15-07:00

    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to git repos (default is current location)"
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
        [version]$Version = "01.00"

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
            Fetch       = 'git -C <path> fetch origin'
            GetBranch   = 'git -C <path> branch'
            GetUpstream = 'git -C <path> rev-parse --abbrev-ref "@{u}"'
            GetPullUrl  = 'git -C <path> config remote.origin.url'
            GetPushUrl  = 'git -C <path> config remote.origin.pushurl'
            AheadBy     = 'git -C <path> rev-list --count <upstream>..<branch>'
            BehindBy    = 'git -C <path> rev-list --count <branch>..<upstream>'
        }

        $Activity = "Check for pending upstream updates"
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
                        Write-Verbose "[$Label] Fetching from origin"

                        Try {
                            $Null = git -C "$Repo" fetch origin 2>$null
                            $FetchTime = ([DateTime]::Now).ToString('s') + ([DateTime]::Now).ToString('zzz')

                            Write-Verbose "[$Label] Checking for pending updates"

                            $Branch   = ((git -C "$Repo" branch 2>&1 | Where-Object { $_ -match "\*" }) -replace ("\*", $Null)).Trim()
                            $Upstream = git -C "$Repo" rev-parse --abbrev-ref "@{u}" 2>$null

                            If (-not $Upstream -or $Upstream -eq "HEAD") {
                                $Upstream = "origin/$Branch"
                            }

                            $PullUrl = git -C "$Repo" config remote.origin.url 2>$null
                            $PushUrl = git -C "$Repo" config remote.origin.pushurl 2>$null
                            If (-not $PushUrl) { $PushUrl = $PullUrl }
                            $Name    = (Split-Path -Leaf $PullUrl).Replace(".git", $Null)

                            $AheadBy  = [int](git -C "$Repo" rev-list --count "$Upstream..$Branch" 2>$null)
                            $BehindBy = [int](git -C "$Repo" rev-list --count "$Branch..$Upstream" 2>$null)

                            $PendingStatus = switch ($true) {
                                ($AheadBy -gt 0 -and $BehindBy -gt 0) { "Diverged" }
                                ($BehindBy -gt 0) { "Updates Available" }
                                ($AheadBy -gt 0) { "Ahead" }
                                default { "In Sync" }
                            }

                            $Output = [PSCustomObject]@{
                                Path           = $Repo
                                Name           = $Name
                                Branch         = $Branch
                                Upstream       = $Upstream
                                AheadBy        = $AheadBy
                                BehindBy       = $BehindBy
                                PendingStatus  = $PendingStatus
                                PullUrl        = $PullUrl
                                PushUrl        = $PushUrl
                                LastFetchDate  = $FetchTime
                            }

                            Write-Output $Output
                        }
                        Catch {
                            Write-Warning "[$Label] Operation failed; $($_.Exception.Message)"
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
                Write-Warning "[$P] Operation failed; $($_.Exception.Message)"
            }

        } # end foreach path

    }
    End {
        Write-Verbose "[END: $ScriptName] $Activity"
    }
} #end Get-PKGitUpstream
