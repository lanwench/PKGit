#requires -Version 4
Function Get-PKGitRemoteOrigin {
<#
.SYNOPSIS
    Get remote origin details from one or more git repositories

.DESCRIPTION
    Retrieves remote origin information from one or more git repositories using `git remote show origin`
    Created because git is unintuitive to all but the most seasoned git users and remembering the exact syntax is often a pain
    Accepts pipeline input for file paths or direct path parameters, and can search for git repositories in subdirectories if -Recurse is specified
    Returns a pscustomobject with spaces replaced by underscores in property names, and includes the path to the repository for context
    By default, returns remote fetch/push URLs, branch tracking, and merge status for the repository

    - Use -Recurse to search for all git repositories in subdirectories
    - When auth fails, local .git/config provides the remote URLs only
    - Returns a PSCustomObject for each repository with Fetch_URL, Push_URL, and branch tracking details

    The function verifies that git is installed/available and that file paths contain valid git repositories
    
.NOTES
    Name    : Function_Get-PKGitRemoteOrigin.ps1
    Author  : Paula Kingsley
    Version : 04.00
    History :
        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2016-05-29 - Created script
        v02.00 - 2019-06-06 - General improvements & standardization
        v03.00 - 2021-04-22 - Overhauled and standardized, added pipeline support
        v04.00 - 2026-06-04 - Overhauled for consistency with others in module

.LINK
    https://github.com/jbloggs/PKGit

.PARAMETER Path
    Absolute path to git repo (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.EXAMPLE
    PS C:\repos\moduleX> Get-PKGitRemoteOrigin -Verbose
    Returns remote origin details from the current directory with verbose output showing parameter details and search process.

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Verbose          True
        Path             {C:\repos\moduleX}
        Recurse          False
        ComputerName     LAPTOP14
        ScriptName       Get-PKGitRemoteOrigin
        ScriptVersion    4.0
        PipelineInput    False

        VERBOSE: [BEGIN: Get-PKGitRemoteOrigin] Get remote origin
        VERBOSE: Commands:

        TestRepo  : git -C <path> rev-parse --is-inside-work-tree
        GetOrigin : git -C <path> remote show origin

        VERBOSE: [C:\repos\moduleX] Searching for git repo
        VERBOSE: [C:\repos\moduleX] 1 git repo(s) found
        VERBOSE: [C:\repos\moduleX] Get remote origin

        Path                                 : C:\repos\moduleX
        Fetch_URL                            : https://github.com/jbloggs/moduleX.git
        Push_URL                             : https://github.com/jbloggs/moduleX.git
        HEAD_branch                          : main
        Remote_branch                        : main tracked
        Local_branch_configured_for_git_pull : main merges with remote main
        Local_ref_configured_for_git_push    : main pushes to main (up to date)

        VERBOSE: [END: Get-PKGitRemoteOrigin] Script ran successfully

.EXAMPLE
    PS C:\repos> Get-PKGitRemoteOrigin -Path c:\demos\ -Recurse -Verbose
    Returns remote origin details from all git repositories in the named directory and subdirectories.

.EXAMPLE
    PS /repos/modulex Get-PKGitRemoteOrigin
    Returns basic remote origin information when no access is granted

        WARNING: [c:\demos\example  ] Authorization failed; falling back to local .git/config (minimum information only)                    
                                                                                                                                
        Path                                 : /repos/moduleX                                                   
        Fetch_URL                            : https://github.com/jbloggs/moduleX.git                                             
        Push_URL                             : https://github.com/jbloggs/moduleX.git                                             
        HEAD_branch                          : ERROR                                                                            
        Remote_branch                        : ERROR                                                                            
        Local_branch_configured_for_git_pull : ERROR                                                                            
        Local_ref_configured_for_git_push    : ERROR   

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
    [Switch]$Recurse

)
Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "04.00"

    # How did we get here?
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput

    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path Variable:$_} | ForEach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $ComputerName = [System.Net.Dns]::GetHostName()
    $CurrentParams.Add("ComputerName",$ComputerName)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites

    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path!"
    }

    #endregion Prerequisites

    # Build activity description
    $Activity = "Get remote origin"
    If ($Recurse.IsPresent) { $Activity += " for all repos found in subfolders" }

    $Commands = [PSCustomObject]@{
        TestRepo  = 'git -C <path> rev-parse --is-inside-work-tree'
        GetOrigin = 'git -C <path> remote show origin'
    }

    Write-Verbose "[BEGIN: $ScriptName] $Activity"
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

}

Process {

    Foreach ($Item in $Path) {

        $Current = $Null
        If (-not ($Item -is [System.IO.FileSystemInfo])) {
            If ($Item -is [string]) {
                $Current = $Item
            }
            If ($Item -is [System.Management.Automation.PathInfo]) {
                $Current = $Item.Path
            }
            $Msg = "Searching for git repo"
            If ($Recurse.IsPresent) {$Msg = "Searching tree for git repos"}
            Write-Verbose "[$Current] $Msg"
            Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current
            $FolderObj = Get-Item -Path $Item -Verbose:$False
        }
        ElseIf ($Item -is [System.IO.FileSystemInfo]) {
            $Current = $Item.FullName
            $FolderObj = $Item
        }
        Else {
            $Msg = "Unknown object type; please use a valid path string or directory object"
            Throw $Msg
        }

        If ($FolderObj) {

            [object[]]$GitRepos = Test-PKGitRepo -Path $FolderObj.FullName -Recurse:$Recurse.IsPresent -Verbose:$False

            If ($GitRepos) {
                $TotalRepos = $GitRepos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Current] $Msg"

                Foreach ($GitFolder in ($GitRepos | Sort-Object | Select-Object -Unique)) {
                    $CurrentRepo ++
                    $Msg = "Get remote origin"
                    Write-Verbose "[$GitFolder] $Msg"
                    Write-Progress -Activity $Activity -CurrentOperation $GitFolder -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)

                    Try {
                        $RemoteOutput = @(git -C "$GitFolder" remote show origin 2>&1)
                        $GitExitCode = $LASTEXITCODE
                        $RemoteOutput = $RemoteOutput | ForEach-Object {$_.ToString()}

                        # Check for error indicators in output
                        $HasErrorLine = $RemoteOutput | Where-Object {$_ -match "^(fatal|error|failed)"}

                        If ($GitExitCode -ne 0 -or $HasErrorLine) {
                            If ($GitExitCode -match "^-?128$" -or $HasErrorLine -imatch "failed|fail||error|fatal|permission|denied|could not read|authentication|access") {
                                Write-Warning "[$GitFolder] Authorization failed; falling back to local .git/config (minimum information only)"
                                # Try to read local config as fallback
                                $ConfigPath = "$GitFolder/.git/config"
                                If (Test-Path $ConfigPath) {
                                    $ConfigLines = Get-Content $ConfigPath
                                    $InOriginSection = $False
                                    $FetchUrl = $Null
                                    ForEach ($Line in $ConfigLines) {
                                        If ($Line -match '\[remote "origin"\]') {$InOriginSection = $True}
                                        ElseIf ($Line -match '^\[') {$InOriginSection = $False}
                                        If ($InOriginSection -and $Line -match '^\s*url\s*=\s*(.+)') {
                                            $FetchUrl = $Matches[1].Trim()
                                        }
                                    }
                                    If ($FetchUrl) {
                                        [PSCustomObject]@{
                                            'Path' = $GitFolder
                                            'Fetch_URL' = $FetchUrl
                                            'Push_URL' = $FetchUrl
                                            'HEAD_branch' = "ERROR"
                                            'Remote_branch' = "ERROR"
                                            'Local_branch_configured_for_git_pull' = "ERROR"
                                            'Local_ref_configured_for_git_push' = "ERROR"
                                        }
                                    }
                                }
                            } Else {
                                Write-Warning "[$GitFolder] Operation failed (unknown error)"
                            }
                        }
                        ElseIf ($RemoteOutput.Count -gt 0 -and ($RemoteOutput -match "remote origin")) {
                                $Remote = $RemoteOutput | Select-Object -Skip 1
                                $HashTable = [ordered]@{}
                                $Hashtable.Add("Path",$GitFolder)
                                for ($i = 0; $i -lt $Remote.count; $i++) {
                                    $Line = $remote[$i].trim().replace("  "," ")
                                    if ($Line -match ":") {
                                        $Split = $Line -split ":", 2
                                        $PropName = $Split[0].replace(" ", "_")
                                        If ($Split[1]) {
                                            $Hashtable.add($PropName, $Split[1].Trim())
                                        }
                                        else {
                                            $data = @()
                                            while ( $remote[$i+1] -notmatch ":" -AND $i -lt $remote.count-1) {
                                                $i++
                                                $Data = $remote[$i].trim()
                                            }
                                            $Hashtable.add($PropName,$data)
                                        }
                                    }
                                }
                                New-Object psobject -Property $HashTable
                            }
                        }
                    Catch {
                        $Msg = "Operation failed"
                        If ($_.Exception.Message -match "fatal|error") {
                            $Msg = "Authentication or connection failed"
                        } ElseIf ($ErrorDetails = $_.Exception.Message) {
                            $Msg += "; $ErrorDetails"
                        }
                        Write-Warning "[$GitFolder] $Msg"
                    }

                } # end foreach repo

            }
            Else {
                $Msg = "No git repo found"
                If (-not $Recurse.IsPresent) {$Msg += " (try -Recurse)"}
                Write-Warning "[$Current] $Msg"
            }
        }
        Else {
            $Msg = "Invalid directory path"
            Write-Warning "[$Item] $Msg"
        }
    } #end foreach path
}
End {
    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] Script ran successfully"
}
} #end Get-PKGitRemoteOrigin

