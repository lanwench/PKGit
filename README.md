# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |1.18.1|
|**Date**|README.md file generated on Friday, May 28, 2021 5:01:03 PM|

This module contains 10 PowerShell functions or commands

All functions should have reasonably detailed comment-based help, accessible via Get-Help ... e.g., 
  * `Get-Help Do-Something`
  * `Get-Help Do-Something -Examples`
  * `Get-Help Do-Something -ShowWindow`

## Prerequisites

Computers must:

  * be running PowerShell 4.0.0 or later

## Installation

Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module PKGit`

## Notes

_All code should be presumed to be written by Paula Kingsley unless otherwise specified (see the context help within each function for more information, including credits)._

_Changelogs are generally found within individual functions, not per module._

## Commands

|**Command**|**Version**|**Synopsis**|
|---|---|---|
|**Get-PKGitEmail**|01.01.0000|Returns the git config email address on the local computer: global, local, or both|
|**Get-PKGitInstall**|04.00.0000|Looks for git.exe on the local computer, in the system path or by folder|
|**Get-PKGitRemoteOrigin**|03.00.0000|Uses invoke-expression and "git remote show origin" in a folder hierarchy to create a PSCustomObject|
|**Get-PKGitRepos**|01.00.0000|Searches a directory for directories containing hidden .git files, with option for recurse / depth|
|**Get-PKGitWorkingFiles**|01.01.000|Returns the working files for a git repo, optionally allowing for selection of files from a menu, and/or limiting files to those in current directory only|
|**Invoke-PKGitCommit**|02.00.0000|Uses invoke-expression and "git commit" with optional parameters|
|**Invoke-PKGitPull**|01.00.1000|Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy|
|**Invoke-PKGitStatus**|01.00.0000|Uses invoke-expression and "git status" with optional parameters in a folder hierarchy|
|**Set-PKGitEmail**|03.00.0000|Sets or changes a git global or local repo email address|
|**Test-PKGitRepo**|02.00.0000|Verifies that the current directory is managed by git|
