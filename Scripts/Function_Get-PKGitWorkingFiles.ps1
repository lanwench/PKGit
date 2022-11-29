#requires -version 3
Function Get-PKGitWorkingFiles {
<#
.SYNOPSIS
    Returns the git status and working files for one or more git repos

.DESCRIPTION
    Returns the git status and working files for one or more git repos
    Requires Get-GitStatus from posh-git module
    Requires git, of course
    Accepts pipeline input
    Outputs a PSObject

.NOTES
    Name    : Function_Get-PKGitWorkingFiles.ps1 
    Created : 2018-03-21
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **
        
        v01.00.0000 - 2018-03-21 - Created script
        v01.01.0000 - 2018-03-21 - Added regex to include subfolder paths when using -CurrentDirectoryOnly, added -ExpandFiles
        v02.00.0000 - 2022-09-19 - Overhauled and standardized

.PARAMETER Path
    Absolute path to git repo (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.PARAMETER ExpandFiles
    Break out individual files into strings separated by line breaks; easier to read than property collections

.EXAMPLE
    PS C:\Repos\MyRepo> Get-PKGitWorkingFiles -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                 
        ---           -----                                 
        Verbose       True                                  
        Path          {C:\Repos\MyRepo}
        Recurse       False                                 
        ExpandFiles   False                                 
        PipelineInput False                                 
        ScriptName    Get-PKGitWorkingFiles                 
        ScriptVersion 2.0.0                                 

        VERBOSE: [BEGIN: Get-PKGitWorkingFiles] Get git working files
        VERBOSE: [C:\Repos\MyRepo] Searching for git repos
        VERBOSE: [C:\Repos\MyRepo] 1 git repo(s) found
        VERBOSE: [C:\Repos\MyRepo] 7 working file(s) found

        Path         : C:\Repos\MyRepo
        RepoName     : myrepo
        Upstream     : origin/master
        Branch       : master
        AheadBy      : 0
        BehindBy     : 0
        HasUntracked : True
        HasWorking   : True
        NumFiles     : 7
        Files        : {Scripts/do-something.ps1, Files/config.txt, Scripts/do-somethingelse...}

        VERBOSE: [END: Get-PKGitWorkingFiles] Get git working files

.EXAMPLE
    PS C:\> "d:\git","d:\modules" | Get-PKGitWorkingFile -Recurse -ExpandFiles

        Path         : D:\git\blah
        RepoName     : blah
        Upstream     : origin/main
        Branch       : main
        AheadBy      : 3
        BehindBy     : 3
        HasUntracked : False
        HasWorking   : False
        NumFiles     : 
        Files        : 

        Path         : D:\git\gists\1832ef8e9c77d2beccfd921g882faa23
        RepoName     : 1832ef8e9c77d2beccfd921g882faa23
        Upstream     : origin/master
        Branch       : master
        AheadBy      : 0
        BehindBy     : 0
        HasUntracked : False
        HasWorking   : True
        NumFiles     : 1
        Files        : pw-expiry.ps1

        Path         : D:\modules\Helpers
        RepoName     : Helpers
        Upstream     : origin/main
        Branch       : main
        AheadBy      : 0
        BehindBy     : 0
        HasUntracked : False
        HasWorking   : True
        NumFiles     : 3
        Files        : Helpers.psd1
                       README.md
                       Scripts/AllFunctions.ps1

#>
[CmdletBinding()]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Absolute path to git repo (default is current location)"
    )]
    [Alias("FullName","RepoPath")]
    [object[]]$Path = (Get-Location).Path,
    
    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [switch]$Recurse,

    [Parameter(
        HelpMessage = "Break out individual files into strings separated by line breaks; easier to read than property collections"
    )]
    [switch]$ExpandFiles

)
Begin {


    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.000"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Can't find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }
    If (-not ((($PoshCmd = Get-Command Get-GitStatus -ErrorAction SilentlyContinue) -and ($PoshCmd.Source -eq "posh-git")))) {
        $Msg = "This script requires Get-GitStatus from the Posh-Git module; try 'Install-Module posh-git -Repository psgallery'"
        Write-Error $Msg
        Break
    }

    $StartLocation = Get-Location

    #region Functions

    # Function to verify/get repo path fullname
    Function GetRepoPath([Parameter(Position=0)]$P){
        Try {
            If ($P -is [string]) {
                $FolderObj = Get-Item -Path $P -Verbose:$False   
            }
            ElseIf ($P -is [System.Management.Automation.PathInfo]) {
                $FolderObj = Get-Item -Path $P.FullName -Verbose:$False                   
            }
            Elseif ($P -is [System.IO.FileSystemInfo]) {
                $FolderObj = $P
            }
            Else {
                $Msg = "Unknown object type; please use a valid path string or directory object"
                Throw $Msg
            }

            If ($FolderObj) {
                If ([object[]]$GitRepos = $FolderObj | Get-Childitem -Recurse:$Recurse -Filter .git -Directory -Attributes H -ErrorAction Stop) {
                    $GitRepos.FullName | Split-Path -Parent
                }
            }
        }
        Catch {Throw $_.Exception.Message}
    } #end getrepopath

    #endregion Functions

    $Results = @()

    $Activity = "Get git working files"
    If ($CurrentDirectoryOnly.IsPresent) {$Activity += " in current directory"}
    If ($Menu.IsPresent) {$Activity += ", bringing up a selection menu"}
    Write-Verbose "[BEGIN: $ScriptName] $Activity"
 
}
Process {
    
    $TotalPaths = $Path.Count
    $CurrentPath = 0

    Foreach ($Item in $Path) {
        
        Try {
            $CurrentPath ++
        
            If ($Item -is [string] -or $Item -is [System.IO.FileSystemInfo]) {$Label = $Item}
            ElseIf ($Item -is [System.Management.Automation.PathInfo]) {$Label = $Item.FullName}
        
            $Msg = "Searching for git repos"
            If ($Recurse.IsPresent) {$Msg += " (search subfolders recursively)"}
            Write-Verbose "[$Label] $Msg"
            Write-Progress  -Id 1 -Activity $Activity -CurrentOperation $Msg -Status $Item -PercentComplete ($CurrentPath/$TotalPaths*100)
        
            If ([object[]]$GitRepos = GetRepoPath -P $Item) {
            
                $TotalRepos = $GitRepos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"

                Foreach ($GitFolder in ($GitRepos | Sort-Object | Select-Object -Unique)) {

                    $CurrentRepo ++
                    Push-Location -Path $GitFolder
                    $Label = $GitFolder

                    $GitStatus = Get-GitStatus -ErrorAction Stop -Verbose:$False
                    
                    $Output = [PSCustomObject]@{
                        Path         = $GitFolder
                        RepoName     = $GitStatus.RepoName
                        Upstream     = $GitStatus.Upstream
                        Branch       = $GitStatus.Branch
                        AheadBy      = $GitStatus.AheadBy
                        BehindBy     = $GitStatus.AheadBy
                        HasUntracked = $GitStatus.HasUntracked
                        HasWorking   = $GitStatus.HasWorking
                        NumFiles     = $Null
                        Files        = $Null
                    }

                    
                    $Pattern = "^\.+\/\w" # (anything beginning with ..\ isn't in this directory
                    If ([array]$WorkingFiles = $GitStatus.Working | Where-Object {($_ -notmatch $Pattern) -or ($_ -match [Regex]::Escape($GitFolder))}) {
                        
                        $Msg = "$($WorkingFiles.Count) working file(s) found"
                        Write-Verbose "[$Label] $Msg"
                        $Output.NumFiles = $($WorkingFiles.Count)

                        If ($ExpandFiles.IsPresent) {
                            $Output.Files = $WorkingFiles -join("`n")
                        }
                        Else {
                            $Output.Files = $WorkingFiles
                        }
                    }
                    Else {
                        $Msg = "No working files found"
                        Write-Verbose "[$Label] $Msg"
                    }

                    $Results += $Output
                    
                    Pop-Location

                } # end foreach repo

            } #end if repo
            Else {
                $Msg = "No Git repo found"
                If (-not $Recurse.IsPresent) {$Msg += " (try -Recurse)"}
                Write-Warning "[$Label] $Msg"
            }

        } #end try
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)" }
            Write-Warning "[$Label] $Msg"
        }

        Write-Output $Results

    }# end foreach path
}
End {
    Write-Progress -Activity $Activity -Completed
     Write-Verbose "[END: $ScriptName] $Activity"
}
}