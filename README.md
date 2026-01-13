# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |1.5.0|
|**Description**|Various functions / wrappers for git commands|
|**Date**|README.md file generated on Tuesday, January 13, 2026 10:37:54 AM|

This module contains 15 PowerShell functions or commands

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
|**Get-PKGitCommit**|01.00.0000|Uses invoke-expression and "git log --name-status" (with additional parameters) to return commit history for one or more git repos|
|**Get-PKGitEmail**|01.01.0000|Returns the git config email address on the local computer: global, local, or both|
|**Get-PKGitInstall**|05.00.0000|Looks for git.exe on the local computer, in the system path or by folder|
|**Get-PKGitRemoteOrigin**|03.00.0000|Uses invoke-expression and "git remote show origin" in a folder hierarchy to create a PSCustomObject|
|**Get-PKGitStatus**|03.02.0000|Invokes git status on one or more git repos|
|**Get-PKGitWorkingFiles**|02.00.000|Returns the git status and working files for one or more git repos|
|**Invoke-PKGitPull**|02.01.0000|Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy|
|**New-PKGitReadmeFile**|-|Generates a github markdown README.md file from the comment-based help contained in the specified PowerShell module file|
|**Remove-PKGitLastCommit**|01.01.0000|Uses invoke-expression and "git reset --soft HEAD^" to remove the last unmerged commit in one or more git repos|
|**Search-PKGitRepo**|02.00.0000|Searches a directory for directories containing hidden .git files, with option for recurse / depth|
|**Set-PKGitEmail**|03.00.0000|Sets or changes a git global or local repo email address|
|**Test-PKGitRepo**|02.00.0000|Verifies that the current directory is managed by git|
