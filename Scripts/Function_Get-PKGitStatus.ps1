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
    Name    : Function_Get-PSGitStatus.ps1
    Author  : Paula Kingsley
    Version : 03.01.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00.0000 - 2021-04-19 - Created script
        v02.00.0000 - 2022-08-31 - Renamed from Invoke-PSGitStatus; other minor edits
        v02.01.0000 - 2022-09-20 - Updates/standardization
        v02.02.0000 - 2023-02-02 - Added attribute for commit/staging status
        v03.00.0000 - 2023-02-16 - Overhauled; renamed ReturnOriginPath to ShowOriginPath, 
                                   changed Recurse to NoRecurse, changed output, simplified search
        v03.01.0000 - 2024-02-05 - Fixed issue with arraylist not showing all results, added -Extended                                   
        
.LINK
    https://github.com/lanwench/pkgit


.PARAMETER Path
    Absolute path to one or more git repos (default is current location)

.PARAMETER NoRecurse
    Don't recurse through subfolders (default is to search all subfolders for hidden .git file)

.PARAMETER Extended
    Include extended and chattier properties such as message & origin status

.PARAMETER ShowOrigin
    Return origin path using 'git remote show origin 2>&1'    

.EXAMPLE
    PS C:\Users\jbloggs\git\personal> Get-PSGitStatus  -Verbose                                                           
        VERBOSE: PSBoundParameters: 

        Key           Value
        ---           -----
        Verbose       True
        Path          {C:\Users\jbloggs\git\personal}
        NoRecurse     False
        Extended      False
        ShowOrigin    False
        ScriptName    Get-PSGitStatus
        ScriptVersion 3.1.0
        PipelineInput False

        VERBOSE: [PREREQUISITES] Found C:\Program Files\Git\cmd\git.exe (version 2.42.0.1)
        VERBOSE: [BEGIN: Get-PSGitStatus] Invoke git status in folder if a git repo is found
        VERBOSE: [C:\Users\jbloggs\git\personal] Searching for git repos
        VERBOSE: [C:\Users\jbloggs\git\personal] 7 git repo(s) found
        VERBOSE: [C:\Users\jbloggs\git\personal\ADNET] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\PSGit] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\Helpers] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\Tools] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\WindowsAdmin] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\Profiles] Get git status
        VERBOSE: [C:\Users\jbloggs\git\personal\Sandbox] Get git status
        VERBOSE: [END: Get-PSGitStatus]                  

        Path                                          Name          IsCurrent   PendingUpdates                     
        ----                                          ----          ---------   --------------                     
        C:\Users\jbloggs\git\personal\ADNET           ADNET              True   Nothing to commit                  
        C:\Users\jbloggs\git\personal\PSGit           PSGit             False   Changes not yet staged             
        C:\Users\jbloggs\git\personal\Helpers         Helpers           False   Changes not yet staged             
        C:\Users\jbloggs\git\personal\Tools           Tools             False   Untracked files present            
        C:\Users\jbloggs\git\personal\WindowsAdmin    WindowsAdmin      False   Untracked files present            
        C:\Users\jbloggs\git\personal\Profiles        Profiles           True   Nothing to commit                  
        C:\Users\jbloggs\git\personal\Sandbox         Sandbox            True   Nothing to commit  

        .EXAMPLE
        PS C:\> Get-PSGitStatus "$Home\git\personal\Tools" -Extended -ShowOrigin

            Path           : C:\Users\jbloggs\git\personal\Tools                                                             
            Name           : Tools                                                                                                
            Origin         : {https://github.com/jbloggs/Tools.git (fetch), https://github.com/jbloggs/Tools.git (push)}      
            Branch         : master                                                                                                 
            IsCurrent      : False                                                                                                  
            PendingUpdates : Untracked files present                                                                                
            OriginStatus   : Your branch is up to date with 'origin/master'.                                                        
            Message        : On branch master                                                                                       
                            Your branch is up to date with 'origin/master'.                                                        
                                                                                                                                
                            Changes not staged for commit:                                                                         
                            (use "git add <file>..." to update what will be committed)                                           
                            (use "git restore <file>..." to discard changes in working directory)                                
                                modified:   Scripts/GetDisabledDate.ps1                                       
                                                                                                                                
                            Untracked files:
                            (use "git add <file>..." to include in what will be committed)
                                Scripts/Function_Get-DownloadFileInfo.ps1

                            no changes added to commit (use "git add" and/or "git commit -a")

#>


    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Absolute path to one or more git repos (default is current location)"
        )]
        [Alias("FullName", "RepoPath")]
        [object[]]$Path = (Get-Location).Path,

        [Parameter(
            HelpMessage = "Don't recurse through subfolders (default is to search all subfolders for hidden .git file)"
        )]
        [Switch]$NoRecurse,

        [Parameter(
            HelpMessage = "Include extended and chattier properties such as message & origin status"
        )]
        [switch]$Extended,

        [Parameter(
            HelpMessage = "Return origin path using 'git remote show origin 2>&1'"
        )]
        [Switch]$ShowOrigin

    )
    Begin {
    
        # Current version (please keep up to date from comment block)
        [version]$Version = "03.01.0000"

        # How did we get here?
        [switch]$PipelineInput = $MyInvocation.ExpectingInput
        $CurrentParams = $PSBoundParameters
        $ScriptName = $MyInvocation.MyCommand.Name
        $MyInvocation.MyCommand.Parameters.keys | Where-Object { $CurrentParams.keys -notContains $_ } | 
        Where-Object { Test-Path Variable:$_ } | Foreach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
        $CurrentParams.Add("ScriptName", $ScriptName)
        $CurrentParams.Add("ScriptVersion", $Version)
        $CurrentParams.Add("PipelineInput", $PipelineInput)
        Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

        # We need git, obviously
        If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
            $Msg = "Failed to find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
            Write-Error "[PREREQUISITES] $Msg"
            Break
        }
        Else {
            $Msg = "Found $($GitCmd.Path) (version $($GitCmd.Version))"  
            Write-Verbose "[PREREQUISITES] $Msg"
        }

        # Function to get git repo paths
        #[switch]$Recurse = (-not $NoRecurse.IsPresent)
        $Subtree = (-not $NoRecurse.IsPresent)
        Function GetRepo ([Parameter(Mandatory, Position = 0)]$Dir, $Recurse = $Subtree) {
            Try {
                If ($R = Get-ChildItem -path $Dir -Recurse:$Recurse -Hidden -filter .git -ErrorAction Stop) {
                    $R.FullName | Split-Path -Parent
                }
            }
            Catch { $False }
        }

        # Track where we started out
        $StartLocation = Get-Location

        # Start arraylist
        $Results = [System.Collections.ArrayList]::new()
        
        # Display options
        #Switch ($OutputType) {
        #    Standard { $Select = "Path,Name,Origin,IsCurrent,PendingUpdates" -split (",") }
        #    Extended { $Select = "Path,Name,Origin,Branch,IsCurrent,PendingUpdates,OriginStatus,Message" -split (",") }
        #}
        
        If ($Extended.IsPresent) { $Select = "Path,Name,Origin,Branch,IsCurrent,PendingUpdates,OriginStatus,Message" -split (",") }
        Else { $Select = "Path,Name,Origin,IsCurrent,PendingUpdates" -split (",") }
        If ( -not $ShowOrigin.IsPresent) { $Select = $Select | Where-Object { $_ -notmatch "Origin" } }

        # Let's go
        If ($Subtree) { $Activity = "Invoke git status in folder if a git repo is found" }
        Else { $Activity = "Invoke git status in folder hierarchy if a git repo is found" }
        Write-Verbose "[BEGIN: $ScriptName] $Activity"

    }
    Process {    
    
        $TotalPaths = $Path.Count
        $CurrentPath = 0
    
        Foreach ($P in $Path) {
        
            $CurrentPath ++
            
            Try {
                If ($P -is [string] -or $P -is [System.IO.FileSystemInfo]) { $Label = $P }
                ElseIf ($P -is [System.Management.Automation.PathInfo]) { $Label = $P.FullName }
        
                $Msg = "Searching for git repos"
                If ($Recurse.IsPresent) { $Msg += " (search subfolders recursively)" }
                Write-Verbose "[$Label] $Msg"
                Write-Progress  -Id 1 -Activity $Activity -CurrentOperation $Msg -Status $P -PercentComplete ($CurrentPath / $TotalPaths * 100)
            
                $Repos = GetRepo -Dir $P
                $TotalRepos = $Repos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"
                
                Foreach ($Repo in ($Repos | Sort-Object Name)) { 
                
                    $CurrentRepo ++
                    Set-Location $Repo
                    $Label = $Repo
                    Write-Verbose "[$Label] Get git status"

                    If ($Status = Invoke-Expression -Command "git status 2>&1" -ErrorAction SilentlyContinue) {

                        $Name = (Split-Path -Leaf (git remote get-url origin)).Replace(".git", $Null)
                        $Branch = ((Invoke-Expression -Command "git branch 2>&1"  -ErrorAction SilentlyContinue | Where-Object { $_ -match "\*" }) -replace ("\*", $Null)).Trim()
                        If ($ShowOrigin.IsPresent) {
                            If ($Remote = (Invoke-Expression "git remote -v 2>&1" -ErrorAction SilentlyContinue)) { $Remote = $Remote -Replace ("origin\s+", $Null) }
                            Else { $Remote = "ERROR" }
                        }
                        
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
                        $Results.Add(($Output | Select-Object $Select)) | Out-Null
                    }

                } # end for each repo
            }
            Catch {}

        } #end foreach item in path

        If ($Results) { Write-Output $Results }
    }
    End {

        Set-Location -Path $StartLocation
        Write-Progress -Activity * -Completed
        Write-Verbose "[END: $ScriptName]"
    }
} #end Get-PSGitStatus
