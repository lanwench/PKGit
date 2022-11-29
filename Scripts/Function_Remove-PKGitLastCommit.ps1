#requires -Version 4
Function Remove-PKGitLastCommit {
<#
.SYNOPSIS 
    Uses invoke-expression and "git reset --soft HEAD^" to remove the last unmerged commit in one or more git repos 

.DESCRIPTION
    Uses invoke-expression and "git reset --soft HEAD^" to remove the last unmerged commit in one or more git repos
    Defaults to current directory
    First verifies that directory contains a repo & that branch is not up to date
    Supports ShouldProcess
    Requires git, of course
    Returns a string, or a PSCustomObject if operation is cancelled

.NOTES
    Name    : Function_Remove-PKGitLastCommit.ps1
    Author  : Paula Kingsley
    Version : 01.01.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2022-08-31 - Created script because I can never remember this
        v01.01.0000 - 2022-09-13 - Updated to match Get-PKGitCommit
        
.LINK
    https://github.com/lanwench/PKGit

.EXAMPLE
    PS C:\repos\moduleX> Remove-PKGitLastCommit -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                            
        ---           -----                                            
        Verbose       True                                             
        RepoPath      {c:\repos\moduleX}
        Recurse       False                                            
        ScriptName    Remove-PKGitLastCommit                           
        ScriptVersion 1.0.0                                            
        PipelineInput False                                            

        VERBOSE: [BEGIN: Remove-PKGitLastCommit] Remove last git commit
        VERBOSE: [c:\repos\moduleX] Get folder object
        VERBOSE: [c:\repos\moduleX] 1 git repo(s) found
        VERBOSE: [c:\repos\moduleX] Getting git status
        VERBOSE: [c:\repos\moduleX] Looking for last commit

        Path    : c:\repos\moduleX
        Hash    : ef88be57fbc894af2b4f9e2b1259c7d5ef46abde
        Date    : Wed Aug 31 15:25:59 2022 -0700
        Author  : Joe Bloggs
        Email   : jbloggs@users.noreply.github.com
        Message : misc cosmetic and minor updates
        Actions : Modified: Scripts/Functions.ps1

        VERBOSE: [c:\repos\moduleX] Remove the last commit by jbloggs@users.noreply.github.com, dated Wed Aug 31 15:25:59 2022 -0700?
        VERBOSE: [c:\repos\moduleX] Removing commit ef88be57fbc894af2b4f9e2b1259c7d5ef46abde
        VERBOSE: [c:\repos\moduleX] Getting current status

        Your branch is up to date with 'origin/main'.
        
        VERBOSE: [END: Remove-PKGitLastCommit] Remove last git commit

.EXAMPLE
    PS C:\> Remove-PKGitLastCommit -Path c:\repos -Recurse -Verbose -WhatIf

        VERBOSE: PSBoundParameters: 
	
        Key           Value                           
        ---           -----                           
        Recurse       True                            
        Verbose       True                            
        WhatIf        True                            
        Path          {C:\Repos}
        ScriptName    Remove-PKGitLastCommit          
        ScriptVersion 1.1.0                           
        PipelineInput False                           

        VERBOSE: [BEGIN: Remove-PKGitLastCommit] Remove last unmerged git commit
        VERBOSE: [C:\Repos] Searching for git repos (search subfolders recursively)
        VERBOSE: [C:\Repos] 16 git repo(s) found
        WARNING: [C:\Repos\34d08ae7d489b1e87d50c1614e6cabbb] No unmerged commits found!
        VERBOSE: [C:\Repos\blah] Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash
        VERBOSE: [C:\Repos\blah] Getting commit data for b3d8a543ea8a446732c33d4c7dd40fec10368e07
        VERBOSE: [C:\Repos\blah] Getting changed files for b3d8a543ea8a446732c33d4c7dd40fec10368e07
        VERBOSE: [C:\Repos\blah] Displaying commit details

        Path           : C:\Repos\blah
        Date           : 2021-01-14T13:47:50-08:00
        Message        : Merge branch 'main' of https://github.com/lanwench/blah into main
        Hash           : b3d8a543ea8a446732c33d4c7dd40fec10368e07
        Author         : Kingsley (paula.kingsley@nielsen.com)
        Committer      : Kingsley (paula.kingsley@nielsen.com)
        NumFileChanges : 0

        VERBOSE: [C:\Repos\blah] Do you want to run 'git reset --soft HEAD^'?
        What if: Performing the operation "Removing last commit from 2021-01-14T13:47:50-08:00 by Kingsley (paula.kingsley@nielsen.com)" on target "C:\Repos\blah".
        VERBOSE: [C:\Repos\blah] Operation cancelled by user
        WARNING: [C:\Repos\blah2] No unmerged commits found!
        VERBOSE: [C:\Repos\capas] Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash
        VERBOSE: [C:\Repos\capas] Getting commit data for bad5f63d52904d2209e4cd9a989b79e8f5406311
        VERBOSE: [C:\Repos\capas] Getting changed files for bad5f63d52904d2209e4cd9a989b79e8f5406311
        VERBOSE: [C:\Repos\capas] Displaying commit details
        Path           : C:\Repos\capas
        Date           : 2021-04-22T17:17:49-07:00
        Message        : Updated account list
        Hash           : bad5f63d52904d2209e4cd9a989b79e8f5406311
        Author         : Paula Kingsley (paula.kingsley@nielsen.com)
        Committer      : Paula Kingsley (paula.kingsley@nielsen.com)
        NumFileChanges : 1
        Added          : Scripts/CyberArkSafeAccountList.ps1

        VERBOSE: [C:\Repos\capas] Do you want to run 'git reset --soft HEAD^'?
        What if: Performing the operation "Removing last commit from 2021-04-22T17:17:49-07:00 by Paula Kingsley (paula.kingsley@nielsen.com)" on target "C:\Repos\capas".
        VERBOSE: [C:\Repos\capas] Operation cancelled by user
        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash
        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Getting commit data for 88fc0c0fc398fe8b318a5630d6f76aa55a27969f
        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Getting changed files for 88fc0c0fc398fe8b318a5630d6f76aa55a27969f
        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Displaying commit details
        Path           : C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64
        Date           : 2018-04-12T10:42:19-05:00
        Message        : 
        Hash           : 88fc0c0fc398fe8b318a5630d6f76aa55a27969f
        Author         : meoso (meoso@users.noreply.github.com)
        Committer      : GitHub (noreply@github.com)
        NumFileChanges : 1
        Modified       : Password-Expiration-Notifications.ps1

        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Do you want to run 'git reset --soft HEAD^'?
        What if: Performing the operation "Removing last commit from 2018-04-12T10:42:19-05:00 by GitHub (noreply@github.com)" on target "C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64".
        VERBOSE: [C:\Repos\gists\3488ef8e9c77d2beccfd921f991faa64] Operation cancelled by user
        WARNING: [C:\Repos\gists\49872c849650bbceb9a8ef02d89f59ed] No unmerged commits found!
        WARNING: [C:\Repos\gists\debfe17390a14e639b7f65db9252e2d4] No unmerged commits found!
        WARNING: [C:\Repos\PKAD] No unmerged commits found!
        WARNING: [C:\Repos\PKChef] No unmerged commits found!
        VERBOSE: [C:\Repos\PKGit] Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash
        VERBOSE: [C:\Repos\PKGit] Getting commit data for 6bf51cbc48a742d0d4ae7fe8933940219ff9b839
        VERBOSE: [C:\Repos\PKGit] Getting changed files for 6bf51cbc48a742d0d4ae7fe8933940219ff9b839
        VERBOSE: [C:\Repos\PKGit] Displaying commit details
        Path           : C:\Repos\PKGit
        Date           : 2021-05-24T18:07:22-07:00
        Message        : v01.18.0000
        Hash           : 6bf51cbc48a742d0d4ae7fe8933940219ff9b839
        Author         : Paula Kingsley (lanwench@users.noreply.github.com)
        Committer      : Paula Kingsley (lanwench@users.noreply.github.com)
        NumFileChanges : 5
        Modified       : README.md
                         Scripts/Function_Get-PKGitEmail.ps1
                         Scripts/Function_New-PKGitReadmeFile.ps1
                         Scripts/Function_Set-PKGitEmail.ps1
                         pkgit.psd1

        VERBOSE: [C:\Repos\PKGit] Do you want to run 'git reset --soft HEAD^'?
        What if: Performing the operation "Removing last commit from 2021-05-24T18:07:22-07:00 by Paula Kingsley (lanwench@users.noreply.github.com)" on target "C:\Repos\PKGit".
        VERBOSE: [C:\Repos\PKGit] Operation cancelled by user
        WARNING: [C:\Repos\PKHelpers] No unmerged commits found!
        WARNING: [C:\Repos\PKPlaster] No unmerged commits found!
        VERBOSE: [C:\Repos\PKTools] Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash
        VERBOSE: [C:\Repos\PKTools] Getting commit data for 39937aac8afc557010b38d5e59d92736b3617992
        VERBOSE: [C:\Repos\PKTools] Getting changed files for 39937aac8afc557010b38d5e59d92736b3617992
        VERBOSE: [C:\Repos\PKTools] Displaying commit details
        Path           : C:\Repos\PKTools
        Date           : 2021-02-17T16:41:13-08:00
        Message        : v01.38.0000
        Hash           : 39937aac8afc557010b38d5e59d92736b3617992
        Author         : Kingsley (lanwench@users.noreply.github.com)
        Committer      : Kingsley (lanwench@users.noreply.github.com)
        NumFileChanges : 3
        Modified       : PKTools.psd1
                         README.md
        Added          : Scripts/Function_Get-PKVMIPConfig.ps1

        VERBOSE: [C:\Repos\PKTools] Do you want to run 'git reset --soft HEAD^'?
        What if: Performing the operation "Removing last commit from 2021-02-17T16:41:13-08:00 by Kingsley (lanwench@users.noreply.github.com)" on target "C:\Repos\PKTools".
        VERBOSE: [C:\Repos\PKTools] Operation cancelled by user
        WARNING: [C:\Repos\PKVMware] No unmerged commits found!
        WARNING: [C:\Repos\Profiles] No unmerged commits found!
        WARNING: [C:\Repos\Sandbox] No unmerged commits found!
        VERBOSE: [END: Remove-PKGitLastCommit] Remove last unmerged git commit


    

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
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
    [switch]$Recurse

)
Begin {    
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.01.0000"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
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
        $Msg = "Can't find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    # Look up human-readable action from commit
    $Lookup = @{
        "A"    = "Added"
        "M"    = "Modified"
        "D"    = "Deleted"
        "??"   = "Unknown (??)"
        "R096" = "Renamed"
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

    $Activity = "Remove last unmerged git commit"
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

                    If (($Status = git status 2>&1) -match "your branch is up to date") {
                        $Msg = "No unmerged commits found!"
                        Write-Warning "[$Label] $Msg"
                    }
                    Else {
                        $Msg = "Invoking 'git log -n 1 --format='%H' 2>&1 to get last commit hash"
                        Write-Verbose "[$Label] $Msg"
                        Write-Progress -Id 2 -Activity $Msg -CurrentOperation $GitFolder -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)

                        If ([object]$Hash = git log -n 1 --format="%H" 2>&1) {
                            
                            $Msg = "Getting commit data for $Hash"
                            Write-Verbose "[$Label] $Msg"
                            Write-Progress -Id 2 -Activity $Msg -CurrentOperation $Msg -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)
        
                            # Get the commit data
                            $Commit = git log -1 $Hash --format="%cI`t%s`t%H`t%an (%ae)`t%cn (%ce)" 2>&1

                            # Get the changed files only
                            $Msg = "Getting changed files"
                            Write-Verbose "[$Label] $Msg for $Hash"
                            Write-Progress -Id 2 -Activity $Msg -CurrentOperation $Msg -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)

                            [object[]]$Files = git log -1 $Hash --pretty=format:'%h-%f' --name-status  2>&1
                            [object[]]$Files = $Files | Select-Object -Skip 1

                            # Create a psobject with the commit data & number of files
                            $Output = $Commit | ConvertFrom-Csv -Delimiter "`t" -Header ("Date","Message","Hash","Author","Committer") | 
                                Select-Object -Property @{N="Path";E={$GitFolder}},*,@{N="NumFileChanges";E={$Files.Count}}
        
                            
                            # Get the files/changes, and loop through them to create a PSObject with an eyeball-friendly lookup for the activity type
                            $ActivityArr = Foreach ($File in $Files) {
                            
                                $Action = $($Lookup[$File.split("`t")[0]])
                                If (-not $Action) {$Action = $File.split("`t")[0]}                            
                                If ($Action -eq "Rename") {
                                    $FileName = "$(($File.split("`t") | Select-Object -Skip 1)[1])=>$(($File.split("`t") | Select-Object -Skip 1)[0])"
                                }
                                Else {
                                    $Filename = ($File -split("`t"))[1]
                                }
                                [PSCustomObject]@{Activity = $Action;Filename = $FileName}
                            
                            } #end foreach file
                                
                            # Add each activity type as a new property with the filenames in a collection
                            $ActivityArr | Group-Object -Property Activity | Foreach-Object {
                                $Output | Add-Member -MemberType NoteProperty -Name $_.Name -Value ($_.Group.Filename -join("`n"))
                            }
                        
                            $Msg = "Displaying commit details"
                            Write-Verbose "[$Label] $Msg"
                            Write-Output $Output

                            $Msg = "Do you want to run 'git reset --soft HEAD^'?"
                            Write-Verbose "[$Label] $Msg"
                            $Msg = "Removing last commit  made on $($Output.Date) by $($Output.Committer)"
                            Write-Progress -Id 2 -Activity $Msg -CurrentOperation $Msg -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)
                            
                            If ($PSCmdlet.ShouldProcess($Gitfolder,$Msg)) {
                                $Msg = "Removing commit $($Output.Hash)"
                                Write-Verbose "[$Label] $Msg"
                                $Remove = git reset --soft HEAD^ 2>&1

                                $Msg = "Invoking 'git status 2>&1' to get current status"
                                Write-Verbose "[$Label] $Msg"
                                $Status = git status 2>&1
                                ($Status | Select-String "your branch is").ToString()
                            }
                            Else {
                                $Msg = "Operation cancelled by user"
                                Write-Verbose "[$Label] $Msg"
                            }
                           
                        } # end if commit hash found
                        Else {
                            $Msg = "No matching commits found"
                            Write-Warning "[$Label] $Msg"
                        }
                    } #end if unmerged found

                    Pop-Location 

                } # end for each repo folder
            } #end if git repo found
            Else {
                $Msg = "No Git repo found"
                If (-not $Recurse.IsPresent) {$Msg += " (try -Recurse)"}
                Write-Warning "[$Label] $Msg"
            }
        } # end try
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += "; $ErrorDetails"}
            Write-Warning "[$Item] $Msg"
        }

    } #end foreach path 

}
End {

    Write-Verbose "[END: $ScriptName] $Activity"

    # Revert to original location
    #Set-Location $StartLocation
    Write-Progress -Activity * -Completed
}
} #end Remove-PKGitLastCommit
