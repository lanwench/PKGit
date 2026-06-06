# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |1.6.0|
|**Description**|Various functions / wrappers for git commands|
|**Date**|README.md file generated on Saturday, June 6, 2026 2:28:37 PM|

This module contains 12 PowerShell functions or commands

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
|<span style="white-space: nowrap">**Get-PKGitCommit**</span>|02.00|Get commit history from one or more git repositories with filtering, sorting, and formatting options|
|<span style="white-space: nowrap">**Get-PKGitEmail**</span>|03.00|Returns the git config email address on the local computer: global, local, system, or all|
|<span style="white-space: nowrap">**Get-PKGitInstall**</span>|07.00|Looks for copies of the git executable on the local computer, in the system path or by folder, returning a PSObject with details about the command and file|
|<span style="white-space: nowrap">**Get-PKGitRemoteOrigin**</span>|04.00|Get remote origin details from one or more git repositories|
|<span style="white-space: nowrap">**Get-PKGitStatus**</span>|04.00|Get the status of one or more git repositories, returning branch, origin, working tree state, and a count-based summary of uncommitted changes|
|<span style="white-space: nowrap">**Get-PKGitUpstream**</span>|01.00|Check for pending updates from remote origin on one or more git repositories|
|<span style="white-space: nowrap">**Invoke-PKGitPull**</span>|03.00|Pull changes from the remote origin in one or more git repositories with confirmation (basic git pull only; no fancy options)|
|<span style="white-space: nowrap">**New-PKGitReadmeFile**</span>|06.01|Generates a github markdown README.md file from the comment-based help in a PowerShell module, including module & function details (and versions if found)|
|<span style="white-space: nowrap">**Remove-PKGitEmail**</span>|01.00|Removes the git config user email address from global or local scope|
|<span style="white-space: nowrap">**Remove-PKGitLastCommit**</span>|02.00|Remove the last local commit from one or more git repositories, forcing confirmation|
|<span style="white-space: nowrap">**Set-PKGitEmail**</span>|04.00|Sets or changes the git config user email address in global or local scope|
|<span style="white-space: nowrap">**Test-PKGitRepo**</span>|03.00|Find git repositories in a path, returning an array of repo paths (or empty if none found)|
