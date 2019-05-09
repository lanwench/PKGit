# Module PKGit

## About
|||
|---|---|
|**Name** |PKGit|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |1.10.0|
|**Description**|Various functions / wrappers for git commands|
|**Date**|README.md file generated on Thursday, May 9, 2019 02:29:59 PM|

This module contains 12 PowerShell functions or commands

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

## Commands

|**Command**|**Synopsis**|
|---|---|
|**Get-GitConfig**|Get git configuration settings|
|**Get-PKGitEmail**|Returns the git config email address on the local computer: global, local, or both|
|**Get-PKGitRemoteOrigin**|Gets the remote origin for a git repo, using the current path.|
|**Get-PKGitWorkingFiles**|Returns the working files for a git repo, optionally allowing for selection of files from a menu, and/or limiting files to those in current directory only|
|**Invoke-PKGitCommit**|Uses invoke-expression and "git commit" with optional parameters in the current directory|
|**Invoke-PKGitPull**|Invokes git pull|
|**Invoke-PKGitPush**|Invokes git push in the current directory|
|**New-PKGitReadmeFile**|Generates a README.md file from the comment-based help contained in the specified PowerShell module file.|
|**Set-PKGitEmail**|Change a global or local git repo email address (such as to obfuscate contact info in a public repo)|
|**Set-PKGitModuleReadmeContent**|Creates markdown-formatted output suitable for a Git readme.md by running Get-Help against a module, <br/>using either the Synopsis or Description label|
|**Test-PKGitInstall**|Looks for git.exe on the local computer|
|**Test-PKGitRepo**|Verifies that the current directory is managed by Git.|
