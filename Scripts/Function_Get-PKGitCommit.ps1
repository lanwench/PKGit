#requires -Version 4
Function Get-PKGitCommit {
<#
.SYNOPSIS
    Get commit history from one or more git repositories with filtering, sorting, and formatting options

.DESCRIPTION
    Retrieves commit history from one or more git repositories using git log, with support for filtering, sorting, and formatting options.
    Created because git syntax is frankly unintuitive to all but the most seasoned git users!
    Accepts pipeline input for file paths or direct path parameters, and can search for git repositories in subdirectories if -Recurse is specified.
    Requires git to be installed and available in the system path, of course

    For output: by default, returns the latest commit from the specified repository or current directory.
    The behavior can be customized using the following options:

    - Use -NumCommits to return multiple commits (or 0 for all commits)
    - Use -Ascending to sort by oldest-first instead of the default newest-first
    - Use -NotBefore and/or -NotAfter to filter commits by date range
    - Use -ExpandFiles to format file changes as newline-separated strings for readability
    - Use -Full to include detailed information (hash, author, file count)

    The function verifies that directories contain valid git repositories before processing.

.NOTES
    Name    : Function_Get-PKGitCommit.ps1
    Created : 2022-08-31
    Author  : Paula Kingsley
    Version : 02.01
    History :
        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2022-08-31 - Created script
        v02.00 - 2026-06-03 - Overhauled for consistency with others in module, additional features added
        v02.01 - 2026-09-17 - Cosmetic and consistency updates

.LINK
    https://github.com/lanwench/PKGit

.PARAMETER Path
    Absolute path to git repo (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.PARAMETER NumCommits
    Number of commits to return (default is 1; set to 0 for all commits)

.PARAMETER Ascending
    Sort commits in ascending order (oldest first); default is newest first

.PARAMETER NotBefore
    Return only commits made after this date (optional)

.PARAMETER NotAfter
    Return only commits made before this date (optional)

.PARAMETER Full
    Include hash, author info, file change count, and file listing in output 

.PARAMETER ExpandFiles
    In Full output, display the Files property as newline-separated strings for readability, instead of collection 

.EXAMPLE
    PS C:\repos\moduleX> Get-PKGitCommit -Verbose
    Returns the latest commit from the current directory with basic output showing parameter details and search process.

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Verbose          True
        Path             {C:\repos\moduleX}
        Recurse          False
        NumCommits       1
        Ascending        False
        NotBefore
        NotAfter
        Full             False
        ScriptName       Get-PKGitCommit
        ScriptVersion    2.01
        PipelineInput    False

        VERBOSE: [BEGIN: Get-PKGitCommit] Get commit
        VERBOSE: [C:\repos\moduleX] Searching for git repos
        VERBOSE: [C:\repos\moduleX] 1 git repo(s) found
        VERBOSE: [C:\repos\moduleX] Looking for matching commit(s)
        VERBOSE: [C:\repos\moduleX] 1 matching hash(es) found
        VERBOSE: [C:\repos\moduleX] 129eb184061c3094efd53b6b2af4aac3fcb42123

        Path       : C:\repos\moduleX
        Date       : 2022-09-19T13:52:26-07:00
        Message    : v01.02.0000
        Committer  : Jane Bloggs (jbloggs@users.noreply.github.com)

        VERBOSE: [END: Get-PKGitCommit] Script ran successfully

.EXAMPLE
    PS /Users/paula/git/GitHub/PKAD> Get-PKGitCommit -NumCommits 3 -Ascending -Full -ExpandFiles
    Returns the 3 oldest commits in ascending order (oldest first) with full properties and files listed on separate lines for readability.

        ComputerName   : PKAD
        Path           : /Users/jane/repoman
        Date           : 2022-06-27T14:18:35-07:00
        Message        : Initial commit
        Hash           : a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
        Author         : GitHub (noreply@github.com)
        Committer      : GitHub (noreply@github.com)
        NumFileChanges : 2
        Files          : A        LICENSE
                         A        README.md

        ComputerName   : PKAD
        Path           : /Users/jane/repoman
        Date           : 2022-07-27T16:50:17-07:00
        Message        : v01.00.0000
        Hash           : b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7
        Author         : Jane Bloggs (jb@noneyabusiness.com)
        Committer      : Jane Bloggs (jb@noneyabusiness.com)
        NumFileChanges : 5
        Files          : A        samplemodulemanifest.psd1
                         M        README.md
                         A        sushi_demo.ps1
                         A        littletree.ps1
                         A        test/testing123.ps1

        ComputerName   : PKAD
        Path           : /Users/jane/repoman
        Date           : 2022-07-27T16:53:14-07:00
        Message        : deleted test file
        Hash           : c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8
        Author         : Jane Bloggs (jb@noneyabusiness.com)
        Committer      : Jane Bloggs (jb@noneyabusiness.com)
        NumFileChanges : 2
        Files          : M README.md
                         D test/testing123.ps1     

.EXAMPLE
    PS C:\> Get-PKGitCommit -Path D:\sandbox -NotAfter 2018-01-01 -Full -ExpandFiles
    Returns the latest commit from any git repos in D:\sandbox made before January 1, 2018, with full properties and files listed as newline-separated strings

        ComputerName   : WORKSTATION
        Path           : D:\sandbox
        Date           : 2017-12-01T09:58:35-08:00
        Message        : v1.6.0
        Hash           : d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9
        Author         : Jane Bloggs (jbloggs@users.noreply.github.com)
        Committer      : Jane Bloggs (jbloggs@users.noreply.github.com)
        NumFileChanges : 4
        Files          : M Files/originalnotes.txt
                         A Scripts/Show-ObjectDemo.ps1
                         D Scripts/Untitled4.ps1
                         D Scripts/kittens.ps1

#>
[CmdletBinding(DefaultParameterSetName = "Basic")]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Absolute path to git repo (default is current location)"
    )]
    [Alias("FullName")]
    [object[]]$Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [switch]$Recurse,

    [Parameter(
        HelpMessage = "Number of commits to return (default is 1; set to 0 for all)"
    )]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$NumCommits = 1,

    [Parameter(
        HelpMessage = "Sort commits in ascending order (oldest first); default is newest first"
    )]
    [switch]$Ascending,

    [Parameter(
        HelpMessage = "Return only commits made after this date (optional)"
    )]
    [datetime]$NotBefore,

    [Parameter(
        HelpMessage = "Return only commits made before this date (optional)"
    )]
    [datetime]$NotAfter,

    [Parameter(
        ParameterSetName = "Full",
        HelpMessage = "Include hash, author info, file change count, and file listing in output"
    )]
    [switch]$Full,
    
    [Parameter(
        ParameterSetName = "Full",
        HelpMessage = "In Full output, display the Files property as newline-separated strings for readability, instead of collection"
    )]
    [switch]$ExpandFiles

)
Begin {    
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.01"

    # Start the clock
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = @{} + $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path Variable:$_}| Foreach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $ComputerName = [System.Net.Dns]::GetHostName()
    $CurrentParams.Add("ComputerName",$ComputerName)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites

    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
    }

    #endregion Prerequisites

    # Validate date order if both provided
    If (($NotBefore -and $NotAfter) -and ($NotBefore -gt $NotAfter)) {
        Throw "No time travel; -NotBefore ($NotBefore) must be before -NotAfter ($NotAfter)"
    }
    # Build activity description
    $Direction = If ($Ascending.IsPresent) { "oldest" } Else { "latest" }
    If ($NumCommits -eq 0) {$Activity = "Return $Direction commits (all)"} 
    ElseIf ($NumCommits -eq 1) {$Activity = "Return $Direction commit"} 
    Else {$Activity = "Return $NumCommits $Direction commits"}
    If ($Recurse.IsPresent) { $Activity += " for all repos found in subfolders" }
    If ($NotBefore -or $NotAfter) { $Activity += " in date range" }
    If ($ExpandFiles.IsPresent) { $Activity += " with expanded file listing" }
    If ($Full.IsPresent) { $Activity += " with full details" }

    $Commands = [PSCustomObject]@{
        TestRepo        = 'git -C <path> rev-parse --is-inside-work-tree'
        GetHashes       = 'git -C <path> log --format=%H [--reverse] [--since] [--until] [-n]'
        GetCommitData   = 'git -C <path> log -1 <hash> --format=%cI%s%H%an(%ae)%cn(%ce)'
        GetFiles        = 'git -C <path> log -1 <hash> --pretty=format:%h-%f --name-status'
    }

    Write-Verbose "[BEGIN: $ScriptName] $Activity"
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"
}

Process {
    
    $TotalPaths = $Path.Count
    $CurrentPath = 0

    Foreach ($Item in $Path) {
        
        Try {
            $Results = @()
            $CurrentPath ++
            $Label = $Item.ToString()
        
            $Msg = "Searching for git repos"
            If ($Recurse.IsPresent) {$Msg = "Searching tree for git repos"}
            Write-Verbose "[$Label] $Msg"
            Write-Progress  -Id 1 -Activity $Activity -CurrentOperation $Msg -Status $Item -PercentComplete ($CurrentPath/$TotalPaths*100)

            [object[]]$GitRepos = Test-PKGitRepo -Path $Item -Recurse:$Recurse.IsPresent -Verbose:$False

            If ($GitRepos) {
                $TotalRepos = $GitRepos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"
                
                Foreach ($RepoPath in ($GitRepos | Sort-Object | Select-Object -Unique)) {
                    $CurrentRepo ++
                    $Label = $RepoPath

                    $Msg = "Looking for matching commit(s)"
                    Write-Verbose "[$Label] $Msg"
                    Write-Progress -Id 2 -Activity $Msg -CurrentOperation $RepoPath -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)

                    # Build git command
                    $GitCmd = "git -C `"$RepoPath`" log --format='%H'"
                    If ($Ascending.IsPresent) { $GitCmd += " --reverse" }
                    If ($NotBefore) { $GitCmd += " --since `"$((Get-Date $NotBefore -f 'MMM d yyyy').ToUpper())`"" }
                    If ($NotAfter)  { $GitCmd += " --until `"$((Get-Date $NotAfter  -f 'MMM d yyyy').ToUpper())`"" }
                    If ($NumCommits -gt 0 -and -not $Ascending.IsPresent) { $GitCmd += " -n $NumCommits" }

                    [object[]]$AllHashes = Invoke-Expression "$GitCmd 2>&1"
                    If ($NumCommits -gt 0 -and $Ascending.IsPresent) {
                        [object[]]$Hashes = $AllHashes | Select-Object -First $NumCommits
                    } Else {
                        [object[]]$Hashes = $AllHashes
                    }

                    If ($Hashes) {
                        $TotalHashes = $Hashes.Count
                        $CurrentHash = 0
                        $Msg = "$TotalHashes matching hash(es) found"
                        Write-Verbose "[$Label] $Msg"

                        Foreach ($Hash in $Hashes) {
                            $CurrentHash ++
                            $Msg = "Get commit data and file activity"
                            Write-Verbose "[$Label] $Hash"
                            Write-Progress -Id 3 -Activity $Msg -CurrentOperation $Hash -Status Working -PercentComplete ($CurrentHash/$TotalHashes*100)

                            # Get the commit data
                            $Commit = git -C $RepoPath log -1 $Hash --format="%cI`t%s`t%H`t%an (%ae)`t%cn (%ce)" 2>&1

                            # Get the changed files only
                            [object[]]$Files = git -C $RepoPath log -1 $Hash --pretty=format:'%h-%f' --name-status  2>&1
                            [object[]]$Files = $Files | Select-Object -Skip 1

                            # Create a psobject with the commit data & number of files
                            $Output = $Commit | ConvertFrom-Csv -Delimiter "`t" -Header ("Date","Message","Hash","Author","Committer") | 
                                Select-Object -Property @{N="ComputerName";E={$ComputerName}},@{N="Path";E={$RepoPath}},*,@{N="NumFileChanges";E={$Files.Count}}
        
                            If ($ExpandFiles.IsPresent) {
                                $Output | Add-Member -MemberType NoteProperty -Name Files -Value ($Files -join("`n"))
                            } 
                            Else {
                                $Output | Add-Member -MemberType NoteProperty -Name Files -Value $Files
                            }

                            $Results += $Output

                        } # end foreach commit

                    } # end if hashes/commits
                    Else {
                        $Msg = "No matching commits found"
                        Write-Warning "[$Label] $Msg"
                        $Results += [PSCustomObject]@{
                            ComputerName   = $ComputerName
                            Path           = $RepoPath
                            Date           = $Null
                            Message        = "(no matching commits)"
                            Hash           = $Null
                            Author         = $Null
                            Committer      = $Null
                            NumFileChanges = 0
                            Files          = @()
                        }
                    }

                } # end for each repo folder
            } #end if git repo found
            Else {
                $Msg = "No git repo found"
                If (-not $Recurse.IsPresent) {$Msg += " (try -Recurse)"}
                Write-Warning "[$Label] $Msg"
            }
        } # end try
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += "; $ErrorDetails"}
            Write-Warning "[$Item] $Msg"
        }

        If ($Full.IsPresent) {
            Write-Output $Results
        }
        Else {
            Write-Output ($Results | Select-Object -Property * -ExcludeProperty Hash,Author,NumFileChanges,Files)
        }

    } #end foreach path 
}
End {
    Write-Progress -Activity * -Completed
    $Stopwatch.Stop()
    Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
}
} #end Get-PKGitCommit
