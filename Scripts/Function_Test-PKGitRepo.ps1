#requires -Version 4
Function Test-PKGitRepo {
    <#
    .SYNOPSIS
        Find git repositories in a path, returning an array of repo paths (or empty if none found)

    .DESCRIPTION
        Finds and returns the paths of git repositories within one or more starting paths
        Uses `git rev-parse --git-dir` via git -C to verify repos (not filesystem-only detection)
        Accepts pipeline input for file paths or direct path parameters
        Searches for git repositories in subdirectories if -Recurse is specified
        Requires git to be installed and available in the system path

        By default, returns repo paths from the specified path or current directory. Use -Recurse to search subdirectories.
        Returns an array of repo paths (empty array if none found).

    .NOTES
        Name    : Function_Test-PKGitRepo.ps1
        Author  : Paula Kingsley
        Version : 03.00
        History :

            ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

            v01.00 - 2016-05-29 - Created script
            v02.01 - 2019-07-22 - General updates/standardization
            v03.00 - 2026-06-06 - Overhauled as shared discovery utility; returns repo paths array; uses git -C; removed structured output

    .LINK
        https://github.com/lanwench/pkgit

    .PARAMETER Path
        Absolute path to search for git repos (default is current location)

    .PARAMETER Recurse
        Recurse subfolders in path

    .EXAMPLE
        PS /users/jane/repos> Test-PKGitRepo
        Returns the paths of git repositories found in the current directory.

        /users/jane/repos

    .EXAMPLE
        PS /users/jane> Test-PKGitRepo -Path /users/jane/src -Recurse
        Returns all git repositories found in the path and subdirectories.

        /users/jane/src/pythonstuff
        /users/jane/src/PSGit
        /users/jane/src/subdir/Helpers

    .EXAMPLE
        PS /users> Test-PKGitRepo -Path /tmp
        Returns nothing when no git repositories are found.

    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to search for git repos (default is current location)"
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

        If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
        }

        $Commands = [PSCustomObject]@{
            FindRecurse = 'Get-ChildItem -Path <path> -Recurse -Filter .git -Directory -Attributes H'
            TestPath    = 'Test-Path -Path <path>/.git'
        }

        $Activity = "Find git repositories"
        Write-Verbose "[BEGIN: $ScriptName] $Activity"
        Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

    }
    Process {

        Foreach ($P in $Path) {
            Try {
                If ($P -is [string] -or $P -is [System.IO.FileSystemInfo]) { $Label = $P }
                ElseIf ($P -is [System.Management.Automation.PathInfo]) { $Label = $P.FullName }

                $Msg = "Searching for git repositories"
                If ($Recurse.IsPresent) { $Msg = "Searching tree for git repositories" }
                Write-Verbose "[$Label] $Msg"

                # Find git repos: recurse if -Recurse, otherwise just test the path itself
                If ($Recurse.IsPresent) {
                    Get-ChildItem -Path $P -Recurse -Filter .git -Directory -Attributes H -ErrorAction SilentlyContinue |
                        Split-Path -Parent | Sort-Object -Unique
                }
                Else {
                    If (Test-Path -Path $P -PathType Container -ErrorAction SilentlyContinue) {
                        If (Test-Path -Path "$P/.git" -ErrorAction SilentlyContinue) {
                            $P
                        }
                    }
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
} #end Test-PKGitRepo
