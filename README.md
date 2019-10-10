# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |1.13.1000|
|**Date**|README.md file generated on Thursday, October 10, 2019 12:19:53 PM|

This module contains 8 PowerShell functions or commands

All functions should have reasonably detailed comment-based help, accessible via Get-Help ... e.g., 
  * `Get-Help Do-Something`
  * `Get-Help Do-Something -Examples`
  * `Get-Help Do-Something -ShowWindow`

## Prerequisites

Computers must:

  * be running PowerShell 3.0.0 or later

## Installation

Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module PKGit`

## Notes

_All code should be presumed to be written by Paula Kingsley unless otherwise specified (see the context help within each function for more information, including credits)._

_Changelogs are generally found within individual functions, not per module._

## Commands

|**Command**|**Synopsis**|
|---|---|
|**Get-PKGitEmail**|Returns the git config email address on the local computer: global, local, or both|
|**Get-PKGitInstall**|Looks for git.exe on the local computer, in the system path or by folder|
|**Get-PKGitRepos**|Searches a directory for directories containing hidden .git files, with option for recurse / depth|
|**Get-PKGitWorkingFiles**|Returns the working files for a git repo, optionally allowing for selection of files from a menu, and/or limiting files to those in current directory only|
|**Invoke-PKGitCommit**|Uses invoke-expression and "git commit" with optional parameters in the current directory|
|**Set-PKGitEmail**|Sets or changes a git global or local repo email address|
|**Set-PKGitModuleReadmeContent**|Creates markdown-formatted output suitable for a git readme.md by running Get-Help against a module, <br/>using either the Synopsis or Description label|
|**Test-PKGitRepo**|Verifies that the current directory is managed by git|
