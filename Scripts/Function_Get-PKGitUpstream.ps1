#requires -Version 4
Function Get-PKGitUpstream {
<#
.SYNOPSIS
    Check for pending updates from the remote origin on one or more git repositories

.DESCRIPTION
    Checks remote origin for pending changes that haven't been pulled locally, first performing a fetch to get the latest remote state
    Accepts pipeline input for file paths or direct path parameters
    Searches for git repositories in subdirectories if -Recurse is specified
    
    Requires git to be installed and available in the system path!

    Returns a PSCustomObject for each repo with: Path, Name, Branch, Upstream, AheadBy, BehindBy, PendingStatus, PullUrl, PushUrl, LastFetchDate

    PendingStatus indicates:
    - "In Sync" — local and remote are aligned
    - "Updates Available" — remote has unpulled commits
    - "Ahead" — local has unpushed commits
    - "Diverged" — both ahead and behind (merge conflict risk)

.NOTES
    Name    : Function_Get-PKGitUpstream.ps1
    Created : 2026-06-06
    Author  : Paula Kingsley
    Version : 01.01
    History :

        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2026-06-06 - Created script to check for pending remote updates
        v01.01 - 2026-09-17 - Cosmetic and consistency updates

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
    ScriptVersion    1.01
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
    IsPrivate       : False
    PullUrl         : https://github.com/jbloggs/kittens.git
    PushUrl         : https://github.com/jbloggs/kittens.git
    LastFetchDate   : 2026-06-06T14:30:22-07:00

    VERBOSE: [END: Get-PKGitUpstream] Check for pending upstream updates completed in 00h 00m 03s

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
    IsPrivate       : True
    PullUrl         : https://github.com/jbloggs/pythonstuff.git
    PushUrl         : https://github.com/jbloggs/pythonstuff.git
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
        [version]$Version = "01.01"

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

        #region Inner functions
        Function _IsPrivate {
            [CmdletBinding()]
            Param([Parameter(Mandatory, ValueFromPipeline)][string]$RepoPath)
            Try {
                Write-Verbose "[$RepoPath] Checking git repo privacy settings using GitHub CLI"
                Write-Verbose "[$RepoPath] Getting remote URL to extract owner information"
                $PullUrl = git -C "$RepoPath" config remote.origin.url 2>$null
                If ($PullUrl -match 'github\.com[:/]([^/]+)/(.+?)(?:\.git)?$') {
                    $GitHubPath = "$($matches[1])/$($matches[2])"
                    $GhInfo = gh repo view $GitHubPath --json isPrivate 2>$null | ConvertFrom-Json
                    Return $GhInfo.isPrivate
                }
                Else {
                    Write-Verbose "[$RepoPath] Not a GitHub repository"
                    Return $Null
                }
            }
            Catch {
                Write-Verbose "[$RepoPath] Failed to determine if repo is private using GitHub CLI: $($_.Exception.Message)"
                Return $Null            
            }
        } # end function
        
        $GetPrivacy = If (Get-Command gh -ErrorAction SilentlyContinue) {$True} Else {$False}

        #endregion Inner functions

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

        Foreach ($Item in $Path) {

            Try {
                If ($Item -is [string] -or $Item -is [System.IO.FileSystemInfo]) { $Label = $Item }
                ElseIf ($Item -is [System.Management.Automation.PathInfo]) { $Label = $Item.FullName }

                Write-Verbose "[$Label] Searching for git repos"
                [object[]]$GitRepos = Test-PKGitRepo -Path $Item -Recurse:$Recurse.IsPresent -Verbose:$False

                If ($GitRepos) {
                    $Msg = "$($GitRepos.Count) git repo(s) found"
                    Write-Verbose "[$Label] $Msg"

                    Foreach ($RepoPath in ($GitRepos | Sort-Object | Select-Object -Unique)) {
                        $Label = $RepoPath
                        Write-Verbose "[$Label] Fetching from origin"

                        Try {
                            $FetchJob = Start-Job { git -C $using:Repo fetch origin 2>&1 }
                            If (-not ($FetchJob | Wait-Job -Timeout 15)) {
                                $FetchJob | Stop-Job; $FetchJob | Remove-Job -Force
                                Write-Warning "[$Label] git fetch origin timed out after 15 seconds; skipping"
                                Continue
                            }
                            $FetchJob | Remove-Job -Force
                            $FetchTime = ([DateTime]::Now).ToString('s') + ([DateTime]::Now).ToString('zzz')

                            Write-Verbose "[$Label] Checking for pending updates"

                            $Branch   = ((git -C "$RepoPath" branch 2>&1 | Where-Object { $_ -match "\*" }) -replace ("\*", $Null)).Trim()
                            $Upstream = git -C "$RepoPath" rev-parse --abbrev-ref "@{u}" 2>$null

                            If (-not $Upstream -or $Upstream -eq "HEAD") {$Upstream = "origin/$Branch"}

                            $PullUrl = git -C "$RepoPath" config remote.origin.url 2>$null
                            $PushUrl = git -C "$RepoPath" config remote.origin.pushurl 2>$null
                            If (-not $PushUrl) { $PushUrl = $PullUrl }
                            $Name    = (Split-Path -Leaf $PullUrl).Replace(".git", $Null)

                            $AheadBy  = [int](git -C "$RepoPath" rev-list --count "$Upstream..$Branch" 2>$null)
                            $BehindBy = [int](git -C "$RepoPath" rev-list --count "$Branch..$Upstream" 2>$null)

                            $PendingStatus = switch ($true) {
                                ($AheadBy -gt 0 -and $BehindBy -gt 0) { "Diverged" }
                                ($BehindBy -gt 0) { "Updates Available" }
                                ($AheadBy -gt 0) { "Ahead" }
                                default { "In Sync" }
                            }

                            If ($GetPrivacy) {
                                $IsPrivate = _IsPrivate -RepoPath $RepoPath
                            }   

                            $Output = [PSCustomObject]@{
                                Path           = $RepoPath
                                Name           = $Name
                                Branch         = $Branch
                                Upstream       = $Upstream
                                AheadBy        = $AheadBy
                                BehindBy       = $BehindBy
                                PendingStatus  = $PendingStatus
                                IsPrivate      = $IsPrivate
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
        Write-Progress -Activity * -Completed
        $Stopwatch.Stop()
        Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
    }
} #end Get-PKGitUpstream
