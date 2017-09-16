# Module PKGit

## About
| | | |
|-|-|-|
Module name | PKGit
Author  | Paula Kingsley
Module version | 1.05.0000
Module type | Script
Minimum PowerShell version | 3.0.0
README.md generated | Saturday, September 16 09:39:07 

This module contains 8 PowerShell function(s)

_Functions should be presumed to be authored by Paula Kingsley unless otherwise specified (see the context help within each function for more information, including credits)._

All functions should have reasonably detailed comment-based help, accessible via Get-Help, e.g.,
  * `Get-Help Do-Something`
  * `Get-Help Do-Something -Examples`
  * `Get-Help Do-Something -ShowWindow`

## Prerequisites ##

Computers must:
  * be running PowerShell 3.0.0 or later

## Installation ##

Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module PKGit`

## Functions

#### Get-PKGitModuleReadme ####
Creates markdown-formatted output suitable for a Git readme.md by running Get-Help against a module, 
using either the Synopsis or Description label

#### Get-PKGitRemoteOrigin ####
Gets the remote origin for a git repo, using the current path.

#### Invoke-PKGitCommit ####
Uses invoke-expression and "git commit" with optional parameters in the current directory

#### Invoke-PKGitPull ####
Invokes git pull

#### Invoke-PKGitPush ####
Invokes git push in the current directory

#### New-PKGitReadmeFile ####
Generates a README.md file from the comment-based help contained in the specified PowerShell module file.

#### Set-PKGitRepoEmail ####
Sets the configured email address for an individual git repo

#### Test-PKGitInstall ####
Looks for git.exe on the local computer

#### Test-PKGitRepo ####
Verifies that the current directory is managed by Git.
