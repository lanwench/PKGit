#requires -Version 4
Function Get-PKGitStatus {
<#
.SYNOPSIS 
    Invokes git status on one or more git repos

.DESCRIPTION
    Uses invoke-expression and "git status" on one or more git repos
    Defaults to current directory
    First verifies that directory contains a repo & that branch is not up to date
    Supports ShouldProcess
    Requires git, of course
    Returns a PSObject

.NOTES
    Name    : Function_Get-PKGitStatus.ps1
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2021-04-19 - Created script
        v02.00.0000 - 2022-08-31 - Renamed from Invoke-PKGitStatus; other minor edits
        v02.01.0000 - 2022-09-20 - Updates/standardization
        
.LINK
    https://github.com/lanwench/PKGit

.EXAMPLE
    PS C:\> Get-PKGitstatus -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                             
        ---           -----                                             
        Verbose       True                                              
        Path          {C:\Repos\ModuleX}
        Recurse       False                                             
        ScriptName    Get-PKGitStatus                                   
        ScriptVersion 2.1.0                                             
        PipelineInput False                                             

        VERBOSE: [BEGIN: Get-PKGitStatus] Invoke git status in folder if git repo is found
        VERBOSE: [C:\Repos\ModuleX] Searching for git repos
        VERBOSE: [C:\Repos\ModuleX] 1 git repo(s) found
        VERBOSE: [C:\Repos\ModuleX] Get git status

        Path    : C:\Repos\ModuleX
        Name    : mediaactivedirectory
        Branch  : master
        Summary : Your branch is up to date with 'origin/master'.
        Status  : {On branch master, Your branch is up to date with 'origin/master'., , Changes not staged for commit:...}

        VERBOSE: [END: Get-PKGitStatus] Invoke git status in folder if git repo is found


.EXAMPLE
    PS C:\Git> Get-PKGitStatus -Recurse -Verbose | Format-Table -AutoSize

        VERBOSE: PSBoundParameters: 
	
        Key           Value                  
        ---           -----                  
        Recurse       True                   
        Verbose       True                   
        Path          {C:\git}
        ScriptName    Get-PKGitStatus        
        ScriptVersion 2.1.0                  
        PipelineInput False                  

        VERBOSE: [BEGIN: Get-PKGitStatus] Invoke git status in folder hierarchy if git repo is found
        VERBOSE: [C:\git] Searching for git repos (search subfolders recursively)
        VERBOSE: [C:\git] 11 git repo(s) found
        VERBOSE: [C:\git\gnops\powershell] Get git status

        VERBOSE: [C:\git\gists\0a1bbdf348eec659c4e5b3211c021d1e] Get git status
        VERBOSE: [C:\git\Gracenote\Infrastructure\PowerShell] Get git status
        VERBOSE: [C:\git\Work\ad] Get git status
        VERBOSE: [C:\git\Work\kittens] Get git status
        VERBOSE: [C:\git\Work\vmware] Get git status
        VERBOSE: [C:\git\Work\Snippets\2151677] Get git status
        VERBOSE: [C:\git\Other\OpenSSL] Get git status
        VERBOSE: [C:\git\Other\psPAS] Get git status
        VERBOSE: [C:\git\Other\PSTree] Get git status
        VERBOSE: [C:\git\Personal\34d08ae7d489b1e87d50c1614e6cabbb] Get git status
        VERBOSE: [C:\git\Personal\blah] Get git status
        VERBOSE: [C:\git\Personal\Sandbox] Get git status
        VERBOSE: [END: Get-PKGitStatus] Invoke git status in folder hierarchy if git repo is found

        Path                                                Name                               Branch   Summary                                                                       
        ----                                                ----                               ------   -------                                                                       
        C:\git\gists\0a1bbdf348eec659c4e5b3211c021d1e       0a1bbdf348eec659c4e5b3211c021d1e   master   Your branch is up to date with 'origin/master'.                               
        C:\git\Work\ad                                      ad                                 main     Your branch is up to date with 'origin/main'.                                 
        C:\git\Work\kittens                                 kittens                            master   Your branch is up to date with 'origin/master'.                               
        C:\git\Work\vmware                                  vmware                             main     Your branch is up to date with 'origin/main'.                                 
        C:\git\Work\Snippets\2151677                        2151677                            main     Your branch is up to date with 'origin/main'.                                 
        C:\git\Other\OpenSSL                                OpenSSL                            1.0.0    Your branch is up to date with 'origin/1.0.0'.                                
        C:\git\Other\psPAS                                  psPAS                              master   Your branch is up to date with 'origin/master'.                               
        C:\git\Other\PSTree                                 PSTree                             main     Your branch is up to date with 'origin/main'.                                 
        C:\git\Personal\34d08ae7d489b1e87d50c1614e6cabbb    34d08ae7d489b1e87d50c1614e6cabbb   master   Your branch is up to date with 'origin/master'.                               
        C:\git\Personal\blah                                blah                               main     Your branch is ahead of 'origin/main' by 3 commits.                           
        C:\git\Personal\Sandbox                             Sandbox                            master   Your branch is up to date with 'origin/master'.                               




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
        Mandatory = $False,
        HelpMessage = "Recurse through subfolders to find git repos in a hierarchy"
    )]
    [Switch] $Recurse

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.01.0000"

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path Variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Failed to find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

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


    # Track where we started out
    $StartLocation = Get-Location

    If ($Recurse.IsPresent) {
        $Activity = "Invoke git status in folder if a git repo is found"
    }
    Else {
        $Activity = "Invoke git status in folder hierarchy if a git repo is found"
    }
    Write-Verbose "[BEGIN: $ScriptName] $Activity"

}
Process {    
    
    $TotalPaths = $Path.Count
    $CurrentPath = 0
    
    Foreach ($Item in $Path) {
        
        Try {
            $Results = @()
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
                    Write-Verbose "[$Label] Get git status"

                    $Status = Invoke-Expression -Command "git status 2>&1"
                    $RepoName = (Split-Path -Leaf (git remote get-url origin)).Replace(".git",$Null)
                    $Branch = ((Invoke-Expression -Command "git branch 2>&1" | Where-Object {$_ -match "\*"}) -replace("\*",$Null)).Trim()

                    [PSCustomObject]@{
                        Path     = $GitFolder
                        Name     = $RepoName
                        Branch   = $Branch
                        #UpToDate = &{[bool]($Status -match "your branch is up to date")}
                        Summary  = ($Status | Select-String "your branch is").ToString()
                        Status   = $Status
                    }

                    Pop-Location
                } #end foreach repo
            } #end if git repo
            Else {
                $Msg = "Not a git repository"
                Write-Warning "[$Label] $Msg"
            }
        }
        Catch {}

    } #end foreach item in path

}
End {
    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] $Activity"
}
} #end Get-PKGitStatus
