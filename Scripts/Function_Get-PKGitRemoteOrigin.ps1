#requires -Version 3
Function Get-PKGitRemoteOrigin {
<#
.SYNOPSIS 
    Uses invoke-expression and "git remote show origin" in a folder hierarchy to create a PSCustomObject

.DESCRIPTION
    Uses invoke-expression and "git remote show origin" in a folder hierarchy to create a PSCustomObject
    Verifies git.exe is present and looks for hidden .git folder
    Returns remote origin and branch details
    Returns a PSObject

.NOTES
    Name    : Get-PKGitRemoteOrigin.ps1
    Author  : Paula Kingsley
    Version : 03.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0      - 2016-05-29 - Created script
        v1.0.1      - 2016-05-29 - Moved to separate file, renamed from Get-PKGitRepoOrigin,
                                   updated verbose output 
        v1.1.0      - 2016-05-30 - Changed output to multidimensional array, added 
                                   -OutputType parameter
        v1.1.1      - 2016-06-06 - Added requires statement for parent module,
                                   link to github repo
        v1.1.2      - 2016-08-01 - Renamed with Function_ prefix
        v02.00.0000 - 2019-06-06 - General improvements & standardization
        v03.00.0000 - 2021-04-22 - Overhauled and standardized, added pipeline support
        
.LINK
    https://github.com/jbloggs/PKGit

.EXAMPLE
    PS C:\Users\JBloggs\Repos> Get-PKGitRemoteOrigin -Recurse -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                  
        ---           -----                  
        Recurse       True                   
        Verbose       True                   
        RepoPath      {C:\Users\JBloggs\Repos}
        WhatIf        False                  
        ScriptName    Get-PKGitRemoteOrigin  
        ScriptVersion 3.0.0                  
        PipelineInput False                  

        VERBOSE: [C:\Users\JBloggs\Repos] Get folder object
        VERBOSE: [C:\Users\JBloggs\Repos] 4 Git repo(s) found

        VERBOSE: [C:\Users\JBloggs\Repos\Gists\0a1bbdf348eec659c4e5b3211c021d1e] Get remote origin
        InputPath                              : C:\Users\JBloggs\Repos\Gists\0a1bbdf348eec659c4e5b3211c021d1e
        Fetch URL                              : https://gist.ghe.domain.local/0a1bbdf348eec659c4e5b3211c021d1e.git
        Push URL                               : https://gist.ghe.domain.local/0a1bbdf348eec659c4e5b3211c021d1e.git
        HEAD branch                            : master
        Remote branch                          : master tracked
        Local branch configured for 'git pull' : master merges with remote master
        Local ref configured for 'git push'    : master pushes to master (up to date)

        VERBOSE: [C:\Users\JBloggs\Repos\ITOps\Policies] Get remote origin
        InputPath                              : C:\Users\JBloggs\Repos\ITOps\Policies
        Fetch URL                              : https://gitlab.com/megacorp/ITOps/Policies.git
        Push URL                               : https://gitlab.com/megacorp/ITOps/Policies.git
        HEAD branch                            : master
        Remote branch                          : master tracked
        Local branch configured for 'git pull' : master merges with remote master
        Local ref configured for 'git push'    : master pushes to master (up to date)

        VERBOSE: [C:\Users\JBloggs\Repos\ITOps\PowerShell] Get remote origin
        InputPath                              : C:\Users\JBloggs\Repos\ITOps\PowerShell
        Fetch URL                              : https://ghe.domain.local/itops/PowerShell.git
        Push URL                               : https://ghe.domain.local/itops/PowerShell.git
        HEAD branch                            : master
        Remote branches                        : master tracked
        Local branch configured for 'git pull' : master merges with remote master
        Local ref configured for 'git push'    : master pushes to master (up to date)

        VERBOSE: [C:\Users\JBloggs\Repos\Personal\Sandbox] Get remote origin
        InputPath                              : C:\Users\JBloggs\Repos\Personal\Sandbox
        Fetch URL                              : https://github.com/jbloggs/Sandbox.git
        Push URL                               : https://github.com/jbloggs/Sandbox.git
        HEAD branch                            : master
        Remote branch                          : master tracked
        Local branch configured for 'git pull' : master merges with remote master
        Local ref configured for 'git push'    : master pushes to master (fast-forwardable)


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
    [Alias("FullName")]
    [object[]]$RepoPath = (Get-Location).Path,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Recurse through subfolders to find git repos in a hierarchy"
    )]
    [Switch] $Recurse

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "03.00.0000"

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
        $Msg = "Git.exe not found on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    If ($Recurse.IsPresent) {
        $Activity = "Recursively search directories for git repos and invoke a 'git remote show origin' in folder if a git repo is found"
    }
    Else {
        $Activity = "Invoke a 'git remote show origin' in folder if a git repo is found"
    }

    $StartingLocation = Get-Location

}
Process {    
    
    Foreach ($Item in $RepoPath) {

        $Current = $Null
        If (-not ($Item -is [System.IO.FileSystemInfo])) {
            If ($Item -is [string]) {
                $Current = $Item
            }
            If ($Item -is [System.Management.Automation.PathInfo]) {
                $Current = $Item.Path
            }
            $Msg = "Get folder object"
            Write-Verbose "[$Current] $Msg"
            Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $Current
            $FolderObj = Get-Item -Path $Item -Verbose:$False 
        }
        Elseif ($Item -is [System.IO.FileSystemInfo]) {
            $Current = $Item.FullName
            $FolderObj = $Item
        }
        Else {
            $Msg = "Unknown object type; please use a valid path string or directory object"
            Throw $Msg
        }

        If ($FolderObj) {
        
            $Msg = "Look for git repo"
            If ($Recurse.IsPresent) {$Msg += " (search subfolders recursively)"}
            $Status = $Msg
            Write-Progress -Activity $Activity -CurrentOperation $FolderObj.FullName -Status $Status
            If ($GitRepos = $FolderObj | Get-Childitem -Recurse:$Recurse -Filter .git -Directory -Attributes H -ErrorAction Stop) {
            
                $Msg = "$($GitRepos.Count) Git repo(s) found"
                Write-Verbose "[$($Folder.FullName)] $Msg"

                Foreach ($GitFolder in $GitRepos) {
                    
                    $GitFolder = ($GitFolder.FullName | Split-Path -Parent)
                    Set-Location -Path $GitFolder
                    $Msg = "Get remote origin"
                    $Status = $Msg
                    Write-Verbose "[$($GitFolder)] $Msg"
                    Write-Progress -Activity $Activity -CurrentOperation $Gitfolder -Status $Status

                    Try {
                        $Remote = ((Invoke-Expression "git remote show origin 2>&1") | Select-Object -Skip 1).Trim()
                        
                        If ($Remote -notmatch "fatal") {
                            $HashTable = [ordered]@{}
                            $Hashtable.Add("InputPath",$GitFolder)
                            for ($i = 0; $i -lt $Remote.count; $i++) {
                                $Line = $remote[$i].trim().replace("  "," ")
                                if ($Line -match ":") {
                                    $Split = $Line -split ":", 2
                                    If ($Split[1]) {
                                        $Hashtable.add($Split[0], $Split[1].Trim())
                                    }
                                    else {
                                        $data = @()
                                        while ( $remote[$i+1] -notmatch ":" -AND $i -lt $remote.count-1) {
                                            $i++
                                            $Data = $remote[$i].trim()
                                        }
                                        $Hashtable.add($split[0],$data)
                                    }
                                }
                            }
                            New-Object psobject -Property $HashTable
                        }
                        Else {
                            Write-Warning "[$($GitFolder)] $($Remote.ToString())"
                        }
                    }
                    Catch {}

                } # end foreach folder
            }

        Else {
            $Msg = "No Git repo(s) found"
            Write-Warning "[$($GitFolder)] $Msg"
        }    
    }
        Else {
            $Msg = "No folder obect(s) found"
            Write-Warning "[$Item] $Msg"
        }
    } #end foreach input
}
End {
    Set-Location $StartingLocation
    Write-Progress -Activity * -Completed
}
} #end Get-PKGitRemoteOrigin


