#requires -Version 4
Function Get-PKGitCommit {
<#
.SYNOPSIS 
    Uses invoke-expression and "git log --name-status" (with additional parameters) to return commit history for one or more git repos

.DESCRIPTION
    Uses invoke-expression and "git log --name-status" (with additional parameters) to return commit history for one or more git repos
    Returns only latest commit, unless -ByDate is specified (permits start / end date range)
    Defaults to current directory
    Searches only one folder unless -Recurse is specified
    First verifies the directory contains a repo
    Requires git, of course

.NOTES
    Name    : Function_Get-PKGitCommit.ps1
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2022-08-31 - Created script
   
.LINK
    https://github.com/lanwench/PKGit

.PARAMETER Path
    Absolute path to git repo (default is current location)

.PARAMETER Recurse
    Recurse subfolders in path

.PARAMETER All
    Return all available commits

.PARAMETER Earliest
    Return only earliest commit

.PARAMETER Latest
    Return only latest commit

.PARAMETER ByDate
    Return all commits made between datesinstead of only latest commit (default with this parameter is all prior to today)

.PARAMETER NotBefore
    Return only commits made after this date (default without this parameter is all)

.PARAMETER NotAfter
    Return only commits made before this date (default with this parameter is all prior to today)

.PARAMETER ExpandActions
    Break out file changes by action into separate properties, such as Modified, Added, Deleted, Renamed (by default all files are returned in a single property)

.PARAMETER ExpandCollections
    Break out individual files into strings separated by line breaks; easier to read than property collections


.EXAMPLE
    PS C:\repos\moduleX> Get-PKGitCommit -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value                                
        ---              -----                                
        Verbose          True                                 
        Path             {C:\repos\moduleX}
        Recurse          False                                
        All              False                                
        Earliest         False                                
        Latest           False                                
        ByDate           False                                
        NotBefore                                             
        NotAfter         2022-09-19 2:02:45 PM                
        ExpandActions    False                                
        ExpandFiles      False                                
        ScriptName       Get-PKGitCommit                      
        ParameterSetName NoDate                               
        ScriptVersion    1.0.0                                
        PipelineInput    False                                

        VERBOSE: Setting -Latest to TRUE
        VERBOSE: [BEGIN: Get-PKGitCommit] Get latest commit
        VERBOSE: [C:\repos\moduleX] Searching for git repos
        VERBOSE: [C:\repos\moduleX] 1 git repo(s) found
        VERBOSE: [C:\repos\moduleX] Looking for matching commit(s)
        VERBOSE: [C:\repos\moduleX] 1 matching hash(es) found
        VERBOSE: [C:\repos\moduleX] 129eb184061c3094efd53b6b2af4aac3fcb42123

        Path           : C:\repos\moduleX
        Date           : 2022-09-19T13:52:26-07:00
        Message        : v01.02.0000
        Hash           : 129eb184061c3094efd53b6b2af4aac3fcb42123
        Author         : Joe Bloggs (jbloggs@users.noreply.github.com)
        Committer      : Joe Bloggs (jbloggs@users.noreply.github.com)
        NumFileChanges : 3
        ChangedFiles   : {M	moduleX.psd1, M	moduleX.psm1, M	README.md}

        VERBOSE: [END: Get-PKGitCommit] Get latest commit

.EXAMPLE
    PS C:\> Get-PKGitCommit -Path D:\sandbox -NotAfter 2018-01-01 -ExpandActions -ExpandFiles -BasicOutput

        Path      : D:\sandbox
        Date      : 2017-12-01T09:58:35-08:00
        Message   : v1.6.0
        Committer : Joe Bloggs (jbloggs@users.noreply.github.com
        Modified  : sandbox.psd1
                    README.md
        Added     : Scripts/Show-ObjectDemo.ps1
        Deleted   : Scripts/Untitled4.ps1
                    Scripts/kittens.ps1


        Path      : D:\sandbox
        Date      : 2017-11-30T17:18:46-08:00
        Message   : v1.5.1
        Committer : Joe Bloggs (jbloggs@users.noreply.github.com
        Modified  : sandbox.psd1
                    README.md
                    Scripts/Get-ComputerMiniReport.ps1
                    Scripts/Get-OUDetails.ps1
                    Scripts/New-CommandSnippet.ps1
                    
        VERBOSE: [END: Get-PKGitCommit] Get all commits before 2018-01-01 12:00:00 AM, expanding file activity into separate properties 

#>
[CmdletBinding(
    DefaultParameterSetName = "NoDate"
)]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName,
        HelpMessage = "Absolute path to git repo (default is current location)"
    )]
    [Alias("FullName")]
    [object[]]$Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [switch]$Recurse,

    [Parameter(
        ParameterSetName = "All",
        HelpMessage = "Return all available commits"
    )]
    [switch]$All,

    [Parameter(
        ParameterSetName = "NoDate",
        HelpMessage = "Return only earliest commit"
    )]
    [switch]$Earliest,

    [Parameter(
        ParameterSetName = "NoDate",
        HelpMessage = "Return only latest commit"
    )]
    [switch]$Latest,

    [Parameter(
        ParameterSetName = "ByDate",
        HelpMessage = "Return all commits made between datesinstead of only latest commit (default with this parameter is all prior to today)"
    )]
    [switch]$ByDate,

    [Parameter(
        ParameterSetName = "ByDate",
        HelpMessage = "Return only commits made after this date (default without this parameter is all)"
    )]
    [ValidateNotNullOrEmpty()]
    [object]$NotBefore,

    [Parameter(
        ParameterSetName = "ByDate",
        HelpMessage = "Return only commits made before this date (default with this parameter is all prior to today)"
    )]
    [ValidateNotNullOrEmpty()]
    [object]$NotAfter = [datetime]::Now,

    [Parameter(
        HelpMessage = "Break out file changes by action into separate properties, such as Modified, Added, Deleted, Renamed (by default all files are returned in a single property)"
    )]
    [switch]$ExpandActions,

    [Parameter(
        HelpMessage = "Break out individual files into strings separated by line breaks; easier to read than property collections"
    )]
    [switch]$ExpandFiles,

    [Parameter(
        HelpMessage = "Doesn't return all details (hash, number of files changed, author info)"
    )]
    [switch]$BasicOutput
    

)
Begin {    
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

    # How did we get here
    $Source = $PSCmdlet.ParameterSetName
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput

    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path Variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Can't find git.exe on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    Switch ($Source) {
        All     {
            $EndDate = [datetime]::Now
        
        }
        NoDate {
            If (-not $Earliest.IsPresent -and -not $Latest.IsPresent) {
                $Msg = "Setting -Latest to TRUE"
                Write-Verbose $Msg
                $Latest = $True
            }
            Elseif ($Earliest.IsPresent -and $Latest.IsPresent) {
                $Msg = "You can't select both -Earliest and -Latest ... pick one!"
                Throw $Msg
            }
        }
        ByDate {
            If (-not $NotAfter -as [datetime]) {
                Throw "Invalid date/time '$($NotAfter)' for -NotAfter; please enter a valid date/time object or string"
            }
            Else {
                $EndDate = Get-Date $NotAfter
                If ($CurrentParams.NotBefore) {
                    If (-not $NotBefore -as [datetime]) {
                        Throw "Invalid date/time '$($NotBefore)' for -NotBefore; please enter a valid date/time object or string"
                    }
                    Else {
                        $StartDate = Get-Date $NotBefore
                        If ($StartDate -gt $EndDate) {
                            Throw "Start date is '$($StartDate.ToString())'; must be after end date '$($EndDate.ToString())'"
                        }
                    }
                }
            }           
        } # end if by date
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

    # Track where we started out
    $StartLocation = Get-Location

    # Console/write-progress
    Switch ($Source) {
        All    {$Activity = "Get all available commits"}
        NoDate {
            If ($Earliest.IsPresent) {$Activity = "Get earliest commit"}
            Elseif ($Latest.IsPresent) {$Activity = "Get latest commit"}
        }
        ByDate     {
            If ($CurrentParams.NotBefore) {$Activity = "Get git commits between $($StartDate.ToString()) and $($EndDate.ToString())"}
            Else {$Activity = "Get all commits before $($EndDate.ToString())"}    
        }
    }
    If ($ExpandActions.IsPresent) {$Activity += ", expanding file activity into separate properties"}
    
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

                    $Msg = "Looking for matching commit(s)"
                    Write-Verbose "[$Label] $Msg"
                    Write-Progress -Id 2 -Activity $Msg -CurrentOperation $GitFolder -Status Working -PercentComplete ($CurrentRepo/$TotalRepos*100)

                    Switch ($Source) {
                        All    {
                            [object[]]$Hashes = git log --until "$((Get-Date $EndDate -f 'MMM d yyyy').ToUpper())" --format='%H' 2>&1
                        }
                        NoDate {
                            If ($Earliest.IsPresent) {
                                [object[]]$Hashes = git rev-list --max-parents=0 HEAD 2>&1
                            }
                            Elseif ($Latest.IsPresent) {
                                [object[]]$Hashes = git log -n 1 --format="%H" 2>&1
                            }
                        }
                        ByDate {
                            If ($StartDate) {
                                [object[]]$Hashes = git log --since "$((Get-Date $StartDate -f 'MMM d yyyy').ToUpper())" --until "$((Get-Date $EndDate -f 'MMM d yyyy').ToUpper())" --format='%H' 2>&1
                            }
                            Else {
                                [object[]]$Hashes = git log --until "$((Get-Date $EndDate -f 'MMM d yyyy').ToUpper())" --format='%H' 2>&1
                            }
                        }
                    }


                    If ($Hashes) {
                    
                        $TotalHashes = $Hashes.Count
                        $CurrentHash = 0

                        $Msg = "$TotalHashes matching hash(es) found"
                        Write-Verbose "[$Label] $Msg"

                        Foreach ($Hash in $Hashes) {

                            $CurrentHash ++
                            $Msg = "Get commit data and file activity"
                            Write-Verbose "[$Label] $Hash"
                            Write-Progress -Id 3 -Activity $Msg -CurrentOperation $Hash -Status Working -PercentComplete ($CurrentHash/$TotalHashes*100)

                            
                            # Get the commit data
                            $Commit = git log -1 $Hash --format="%cI`t%s`t%H`t%an (%ae)`t%cn (%ce)" 2>&1

                            # Get the changed files only
                            [object[]]$Files = git log -1 $Hash --pretty=format:'%h-%f' --name-status  2>&1
                            [object[]]$Files = $Files | Select-Object -Skip 1

                            # Create a psobject with the commit data & number of files
                            $Output = $Commit | ConvertFrom-Csv -Delimiter "`t" -Header ("Date","Message","Hash","Author","Committer") | 
                                Select-Object -Property @{N="Path";E={$GitFolder}},*,@{N="NumFileChanges";E={$Files.Count}}
        
                            # Group the activity by type & add a property for each, containing the filenames
                            If ($ExpandActions.IsPresent) {

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
                                    If ($ExpandFiles.IsPresent){$Output | Add-Member -MemberType NoteProperty -Name $_.Name -Value $($_.Group.Filename -join("`n"))}
                                    Else {$Output | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Group.Filename}
                                    
                                }
                            }
                            Else {
                                If ($ExpandFiles.IsPresent){$Output | Add-Member -MemberType NoteProperty -Name ChangedFiles -Value ($Files -join("`n"))}
                                Else {$Output | Add-Member -MemberType NoteProperty -Name ChangedFiles -Value $Files}
                            }

                            $Results += $Output

                        } # end foreach commit
                    
                    } # end if hashes/commits
                    Else {
                        $Msg = "No matching commits found"
                        Write-Warning "[$Label] $Msg"
                    }

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

        If ($BasicOutput.IsPresent) {
            Write-Output ($Results | Select-Object -Property * -ExcludeProperty Hash,Author,NumFileChanges)
        }
        Else {
            Write-Output $Results
        }

    } #end foreach path 
}
End {

    Write-Verbose "[END: $ScriptName] $Activity"
    Write-Progress -Activity * -Completed
}
} #end Get-PKGitCommit
