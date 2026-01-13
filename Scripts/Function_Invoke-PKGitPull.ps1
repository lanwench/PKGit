#requires -Version 3
Function Invoke-PKGitPull {
<#
.SYNOPSIS 
    Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy

.DESCRIPTION
    Uses invoke-expression and "git pull" with optional parameters in a folder hierarchy
    Verifies git.exe is present
    Searches for hidden .git folder
    Returns remote origin and branch details
    Supports ShouldProcess
    Returns a string

.NOTES
    Name    : Function_Invoke-PKGitPull.ps1
    Author  : Paula Kingsley
    Version : 02.01.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2021-04-14 - Created script
        v01.00.1000 - 2021-04-19 - Fixed erroneous name in Notes block, changed verbose to warning if no repo found
        v02.00.1000 - 2022-09-20 - Standardized with other functions
        v02.01.0000 - 2025-08-13 - Minor cosmetic changes for standardization
        
.LINK
    https://github.com/jbloggs/PKGit

.EXAMPLE
    PS C:\Repos> Invoke-PKGitPull -Recurse -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                        
        ---           -----                        
        Recurse       True                         
        Verbose       True                         
        Path          {C:\Repos}
        ScriptName    Invoke-PKGitPull             
        ScriptVersion 2.0.0                        
        PipelineInput False                        

        VERBOSE: [BEGIN: Invoke-PKGitPull] Invoke git pull in one or more git repos
        VERBOSE: [C:\Repos] Searching for git repos (search subfolders recursively)
        VERBOSE: [C:\Repos] 8 git repo(s) found
        VERBOSE: [C:\Repos\ADAudit] Invoke 'git pull' from branch 'main' on Fetch URL https://github.com/azauditor/ADAudit.git
        From https://github.com/azauditor/ADAudit
            * [new branch]      main       -> origin/main
        Your configuration specifies to merge with the ref 'refs/heads/master'
        from the remote, but no such ref was fetched.
        VERBOSE: [C:\Repos\DnsCmdletFixes] Get remote origin info
        VERBOSE: [C:\Repos\DnsCmdletFixes] Invoke 'git pull' from branch 'master' on Fetch URL https://github.com/briantist/DnsCmdletFixes.git
        Already up to date.
        VERBOSE: [C:\Repos\ADACLScanner] Get remote origin info
        VERBOSE: [C:\Repos\ADACLScanner] Invoke 'git pull' from branch 'master' on Fetch URL https://github.com/canix1/ADACLScanner.git
        From https://github.com/canix1/ADACLScanner
            fca74ca..6e4f7c4  master     -> origin/master
         * [new tag]         7.2        -> 7.2
         * [new tag]         7.1        -> 7.1
        Updating fca74ca..6e4f7c4
        Fast-forward
            ADACLScan.ps1 | 1733 +++++++++++++++++++++++++++++++++++----------------------
            README.md     |   14 +-
            2 files changed, 1069 insertions(+), 678 deletions(-)
        
        VERBOSE: [END: Invoke-PKGitPull] Invoke git pull in one or more git repos

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        HelpMessage = "Folder or path",
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True
    )]
    [Alias("FullName""RepoPath")]
    [object[]]$Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [switch]$Recurse

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.01.0000"

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} | 
        Where-Object {Test-Path Variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Git.exe not found on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Throw $Msg
    }

    #region Functions

    # Function to verify/get repo path fullname
    Function GetRepoPath([Parameter(Position=0)]$P){
        Try {
            If ($P -is [string]) {$FolderObj = Get-Item -Path $P -Verbose:$False   }
            ElseIf ($P -is [System.Management.Automation.PathInfo]) {$FolderObj = Get-Item -Path $P.FullName -Verbose:$False                   }
            Elseif ($P -is [System.IO.FileSystemInfo]) {$FolderObj = $P}
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

    $Activity = "Invoke git pull in one or more git repos"
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

                    $Msg = "Get remote origin info"
                    Write-Verbose "[$Label] $Msg"
    
                    $Origin = Invoke-Expression "git remote show origin 2>&1"
                    $FetchURL = ($Origin | Select-String -Pattern "Fetch URL").ToString().Trim().Replace("Fetch URL: ",$Null)
                    $Branch = ($Origin | Select-String -Pattern "HEAD branch").ToString().Trim().Replace("HEAD branch: ",$Null)
                        
                    $Msg = "Invoke 'git pull' from branch '$Branch' on Fetch URL $FetchURL"
                    Write-Verbose "[$Label] $Msg"
                        
                    If ($PSCmdlet.ShouldProcess($Label,$Msg)) {  
                        Invoke-Expression -Command "git pull 2>&1"
                            
                    }
                    Else {
                        $Msg = "Operation cancelled by user"
                        Write-Verbose "[$Label] $Msg"
                    }
                    
                    Pop-Location
                }
            } # end if repo
        }
        Catch {}
    } #end foreach

}
End {
    Write-Verbose "[END: $ScriptName] $Activity"
    Write-Progress -Activity * -Completed
}
} #end Invoke-PKGitPull



