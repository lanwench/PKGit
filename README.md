# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |2.1|
|**Description**|Various functions / wrappers for git commands|
|**Date**|README.md file generated on Friday, September 25, 2026 3:14:01 PM|

This module contains 13 PowerShell functions or commands

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

__Per-function change details are generally found within each function's Notes, but a CHANGELOG.md file contains a summary of changes across all module functions.__

## Commands

|**Command**|**Version**|**Synopsis**|
|---|---|---|
|<span style="white-space: nowrap">**Get-PKGitCommit**</span>|02.01|Get commit history from one or more git repositories with filtering, sorting, and formatting options|
|<span style="white-space: nowrap">**Get-PKGitEmail**</span>|03.01|Returns the git config email address on the local computer: global, local, system, or all|
|<span style="white-space: nowrap">**Get-PKGitInstall**</span>|07.01|Looks for copies of the git executable on the local computer, in the system path or by folder, returning a PSObject with details about the command and file|
|<span style="white-space: nowrap">**Get-PKGitRemoteOrigin**</span>|04.01|Get remote origin details from one or more git repositories|
|<span style="white-space: nowrap">**Get-PKGitRepo**</span>|01.01|Check the status and details of one or more git repositories without having to memorize annoying git syntax|
|<span style="white-space: nowrap">**Get-PKGitStatus**</span>|05.01|Check one or more git repositories for name, origin, status, and a summary|
|<span style="white-space: nowrap">**Get-PKGitUpstream**</span>|01.01|Check for pending updates from the remote origin on one or more git repositories|
|<span style="white-space: nowrap">**Invoke-PKGitPull**</span>|04.00|Pull changes from the remote origin in one or more git repositories with confirmation (basic git pull only; no fancy options)|
|<span style="white-space: nowrap">**New-PKGitReadmeFile**</span>|06.01|Generates a github markdown README.md file from the comment-based help in a PowerShell module, including module & function details (and versions if found)|
|<span style="white-space: nowrap">**Remove-PKGitEmail**</span>|01.01|Removes the git config user email address from global or local scope|
|<span style="white-space: nowrap">**Remove-PKGitLastCommit**</span>|02.01|Remove the last local commit from one or more git repositories, forcing confirmation|
|<span style="white-space: nowrap">**Set-PKGitEmail**</span>|04.01|Sets or changes the email address for the git global or local scope|
|<span style="white-space: nowrap">**Test-PKGitRepo**</span>|03.01|Find git repositories in a path, returning an array of repo paths (or, empty if none found)|
