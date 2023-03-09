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
    Version : 03.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2021-04-19 - Created script
        v02.00.0000 - 2022-08-31 - Renamed from Invoke-PKGitStatus; other minor edits
        v02.01.0000 - 2022-09-20 - Updates/standardization
        v02.02.0000 - 2023-02-02 - Added attribute for commit/staging status
        v03.00.0000 - 2023-02-16 - Overhauled; renamed ReturnOriginPath to ShowOriginPath, 
                                   changed Recurse to NoRecurse, changed output, simplified search
        
.LINK
    https://github.com/lanwench/PKGit

.EXAMPLE
    PS C:\> Get-PKGitStatus -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                              
        ---           -----                              
        Verbose       True                               
        Path          {C:\Users\jbloggs\repos}
        ShowOrigin    False                              
        NoRecurse     False                              
        ScriptName    Get-PKGitStatus                    
        ScriptVersion 3.0.0                              
        PipelineInput False                              



        VERBOSE: [BEGIN: Get-PKGitStatus] Invoke git status in folder if a git repo is found
        VERBOSE: [C:\Users\jbloggs\repos] Searching for git repos (search subfolders recursively)
        VERBOSE: [C:\Users\jbloggs\repos] 2 git repo(s) found
        VERBOSE: [C:\Users\jbloggs\repos\admodule] Get git status
        VERBOSE: [C:\Users\jbloggs\repos\sandbox] Get git status

        Path           : C:\Users\jbloggs\repos\admodule
        Name           : admodule
        Origin         : -
        Branch         : main
        IsCurrent      : True
        PendingUpdates : Nothing to commit
        OriginStatus   : Your branch is up to date with 'origin/main'.
        Message        : On branch master
                         Your branch is up to date with 'origin/main'.
                 
                         nothing to commit, working tree clean

        Path           : C:\Users\jbloggs\repos\sandbox
        Name           : sandbox
        Origin         : -
        Branch         : main
        IsCurrent      : False
        PendingUpdates : Untracked files present
        OriginStatus   : Your branch is up to date with 'origin/main'.
        Message        : On branch master
                         Your branch is up to date with 'origin/main'.
                 
                         Changes not staged for commit:
                           (use "git add <file>..." to update what will be committed)
                           (use "git restore <file>..." to discard changes in working directory)
                 	        modified:   testing disabled user report.ps1
                 	        modified:   disabled.csv
                 
                         Untracked files:
                           (use "git add <file>..." to include in what will be committed)
                 	       old\add-description.ps1
                 
                         no changes added to commit (use "git add" and/or "git commit -a")                 
.EXAMPLE
    PS C:\> Get-PKGitStatus -path C:\Users\jbloggs\repos\itscripts -ShowOrigin

        Path           : C:\Users\jbloggs\repos\ITScripts
        Name           : ITScripts
        Origin         : {https://github.com/jbloggs/itscripts.git (fetch), https://github.com/jbloggs/itscripts.git (push)}
        Branch         : main
        IsCurrent      : False
        PendingUpdates : Uncommitted changes
        OriginStatus   : Your branch is up to date with 'origin/main'.
        Message        : On branch main
                         Your branch is up to date with 'origin/main'.
                 
                         Changes to be committed:
                           (use "git restore --staged <file>..." to unstage)
                 	        modified:   README.md
                 	        modified:   NewFileReport.ps1    

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
        HelpMessage = "Return origin path using 'git remote show origin 2>&1'"
    )]
    [Switch]$ShowOrigin,

    [Parameter(
        HelpMessage = "Don't recurse through subfolders (default is to search all subfolders for hidden .git file)"
    )]
    [Switch]$NoRecurse


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

    # We need git, obviously
    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Failed to find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    # Function to get git repo paths
    [switch]$Recurse = (-not $NoRecurse.IsPresent)
    Function GetRepo ([Parameter(Mandatory,Position=0)]$Dir) {
        Try {
            If ($R = Get-ChildItem -path $Dir -Recurse:$Recurse -Hidden -filter .git -ErrorAction Stop) {
                $R.FullName | Split-Path -Parent
            }
        }
        Catch {$False}
    }

    # Track where we started out
    $StartLocation = Get-Location
    
    # Let's go
    If ($Recurse.IsPresent) {$Activity = "Invoke git status in folder if a git repo is found"}
    Else {$Activity = "Invoke git status in folder hierarchy if a git repo is found"}
    Write-Verbose "[BEGIN: $ScriptName] $Activity"

}
Process {    
    
    $TotalPaths = $Path.Count
    $CurrentPath = 0
    
    Foreach ($P in $Path) {
        
        $CurrentPath ++
        $Results = [System.Collections.ArrayList]::new()

        Try {
            
            If ($P -is [string] -or $P -is [System.IO.FileSystemInfo]) {$Label = $P}
            ElseIf ($P -is [System.Management.Automation.PathInfo]) {$Label = $P.FullName}
        
            $Msg = "Searching for git repos"
            If ($Recurse.IsPresent) {$Msg += " (search subfolders recursively)"}
            Write-Verbose "[$Label] $Msg"
            Write-Progress  -Id 1 -Activity $Activity -CurrentOperation $Msg -Status $P -PercentComplete ($CurrentPath/$TotalPaths*100)
            
            If ($Repos = GetRepo -Dir $P) {
            
                $TotalRepos = $Repos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"
                
                Foreach ($Repo in ($Repos | Sort-Object | Select-Object -Unique)) {
                    
                    $CurrentRepo ++
                    Set-Location $Repo
                    $Label = $Repo
                    Write-Verbose "[$Label] Get git status"

                    $Status = Invoke-Expression -Command "git status 2>&1"
                    $Name = (Split-Path -Leaf (git remote get-url origin)).Replace(".git",$Null)
                    $Branch = ((Invoke-Expression -Command "git branch 2>&1" | Where-Object {$_ -match "\*"}) -replace("\*",$Null)).Trim()

                    If ($ShowOrigin.IsPresent) {
                        If ($Remote = (Invoke-Expression " git remote -v 2>&1")) {$Remote = $Remote -Replace("origin\s+",$Null)}
                        Else {$Remote = "ERROR"}
                    }
                    Else {$Remote = "-"}

                    Switch -Regex ($Status) {
                        "Nothing to commit|working tree clean" {
                            $Current = $True
                            $FileStatus = "Nothing to commit"
                        }
                        "changes staged to commit" {
                            $Current = $False
                            $FileStatus = "Changes staged"
                        }
                        "changes not staged for commit" {
                            $Current = $False
                            $FileStatus = "Changes not yet staged"
                        }
                        "untracked files" {
                            $Current = $False
                            $FileStatus = "Untracked files present"
                        }
                        "Changes to be committed" {
                            $Current = $False
                            $FileStatus = "Uncommitted changes"
                        }
                    }

                    $Output = [PSCustomObject]@{
                        Path           = $Repo
                        Name           = $Name
                        Origin         = $Remote
                        Branch         = $Branch
                        IsCurrent      = $Current
                        PendingUpdates = $FileStatus
                        OriginStatus   = ($Status | Select-String "your branch is").ToString()
                        Message        = $Status | Out-String
                    }
                    
                    $Results.Add($Output) | Out-Null
                    
                    Set-Location $StartLocation

                } # end for each repo

            } #end if git repo
            Else {
                $Msg = "Not a git repository"
                Write-Warning "[$Label] $Msg"
            }
        }
        Catch {}

        If ($Results) {Write-Output $Results}

    } #end foreach item in path

}
End {
    Set-Location -Path $StartLocation
    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] $Activity"
}
} #end Get-PKGitStatus


              


<#
            }


            If ([object[]]$Repos = GetRepoPath -P $P) {
            
                $TotalRepos = $Repos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"

                Foreach ($GitFolder in ($Repos | Sort-Object | Select-Object -Unique)) {

                    $CurrentRepo ++
                    Push-Location -Path $GitFolder
                    $Label = $GitFolder
                    Write-Verbose "[$Label] Get git status"

                    $Status = Invoke-Expression -Command "git status 2>&1"
                    $Name = (Split-Path -Leaf (git remote get-url origin)).Replace(".git",$Null)
                    $Branch = ((Invoke-Expression -Command "git branch 2>&1" | Where-Object {$_ -match "\*"}) -replace("\*",$Null)).Trim()

                    If ($ReturnOriginPath.IsPresent) {
                        $Remote = (Invoke-Expression " git remote -v 2>&1") -Replace("origin\s+",$Null)
                    }
                    Else {$Remote = "-"}

                    Switch -Regex ($Status) {
                        "Nothing to commit|working tree clean" {
                            $Current = $True
                            $FileStatus = "Nothing to commit"
                        }
                        "changes staged to commit" {
                            $Current = $False
                            $FileStatus = "Changes staged"
                        }
                        "changes not staged for commit" {
                            $Current = $False
                            $FileStatus = "Changes not yet staged"
                        }
                        #"no changes added to commit" {}
                        "untracked files" {
                            $Current = $False
                            $FileStatus = "Untracked files present"
                        }
                    }

                    [PSCustomObject]@{
                        Path           = $GitFolder
                        Name           = $Name
                        Origin         = $Remote
                        Branch         = $Branch
                        IsCurrent      = $Current
                        PendingUpdates = $FileStatus
                        OriginStatus   = ($Status | Select-String "your branch is").ToString()
                        Message        = $Status | Out-String
                    }

                    Pop-Location
                } #end foreach repo

                Write-Output $Results


                #>
