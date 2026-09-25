#requires -Version 4
Function Test-PKGitRepo {
<#
.SYNOPSIS
    Find git repositories in a path, returning an array of repo paths (or, empty if none found)

.DESCRIPTION
    Finds and returns the paths of git repositories within one or more starting paths with optional
    -Recurse parameter to search subdirectories.  Uses git -C to verify repos (not filesystem-only detection)

    Accepts pipeline input for file paths or direct path parameters

    Requires git to be installed and available in the system path

.NOTES
    Name    : Function_Test-PKGitRepo.ps1
    Created : 2016-05-29
    Author  : Paula Kingsley
    Version : 03.01
    History :

        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2016-05-29 - Created script
        v02.01 - 2019-07-22 - General updates/standardization
        v03.00 - 2026-06-06 - Overhauled as shared discovery utility; returns repo paths array; uses git -C; removed structured output
        v03.01 - 2026-09-17 - Cosmetic and consistency updates

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
    [version]$Version = "03.01"

    # Start the clock
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = @{} + $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where-Object { $CurrentParams.keys -notContains $_ } |
    Where-Object { Test-Path Variable:$_ } | ForEach-Object {$CurrentParams.Add($_, (Get-Variable $_).value)}
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

    Foreach ($Item in $Path) {
        Try {
            $Label = $Item.ToString()
            If ($Item -is [string] -or $Item -is [System.IO.FileSystemInfo]) { $Label = $Item }
            ElseIf ($Item -is [System.Management.Automation.PathInfo]) { $Label = $Item.FullName }

            $Msg = "Searching for git repositories"
            If ($Recurse.IsPresent) { $Msg = "Searching tree for git repositories" }
            Write-Verbose "[$Label] $Msg"

            # Find git repos: recurse if -Recurse, otherwise just test the path itself
            If ($Recurse.IsPresent) {
                Get-ChildItem -Path $Item -Recurse -Filter .git -Directory -Attributes H -ErrorAction SilentlyContinue |
                    Split-Path -Parent | Sort-Object -Unique
            }
            Else {
                If (Test-Path -Path $Item -PathType Container -ErrorAction SilentlyContinue) {
                    If (Test-Path -Path "$Item/.git" -ErrorAction SilentlyContinue) {
                        $Item
                    }
                    Else {
                        Write-Verbose "[$Label] No git repository found in path"
                    }
                }
            }
        }
        Catch {
            Write-Warning "[$Item] Operation failed; $($_.Exception.Message)"
        }
    } # end foreach path
}
End {
    $Stopwatch.Stop()
    Write-Verbose "[END: $ScriptName] Script completed in $(("{0:hh'h 'mm'm 'ss's'}" -f $Stopwatch.Elapsed))"
}
} #end Test-PKGitRepo
