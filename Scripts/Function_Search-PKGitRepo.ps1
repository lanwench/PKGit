  #requires -Version 3
Function Search-PKGitRepo {
<#
.SYNOPSIS 
    Searches a directory for directories containing hidden .git files, with option for recurse / depth

.DESCRIPTION
    Searches a directory for directories containing hidden .git files, with option for recurse / depth
    Defaults to current directory
    Verfies current directory holds a git repo and displays push URL.
    Requires git, of course.

.NOTES
    Name    : Function_Search-PKGitRepo.ps1
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2019-06-26 - Created script
        v02.00.0000 - 2022-09-20 - Renamed from Get-PKGitRepos/Get-PKGitRepoPath, 
                                   overhauled

.PARAMETER Path
    Starting path for search (default is current directory)

.PARAMETER Recurse
    Recurse subfolders in path

.PARAMETER ExpandPaths
    Break out individual paths into strings separated by line breaks; easier to read than property collections

.EXAMPLE
    PS C:\git> Search-PKGitRepo -Recurse -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key              Value                         
        ---              -----                         
        Recurse          True                          
        Verbose          True                          
        Path             c:\git
        ExpandPaths      False                         
        PipelineInput    False                         
        ParameterSetName Recurse                       
        ComputerName     UST028036292753               
        ScriptName       Get-PKGitRepos                
        ScriptVersion    2.0.0                         

        VERBOSE: [BEGIN: Search-PKGitRepo] Get git repos in path
        VERBOSE: [c:\git] Searching for git repos (search subfolders recursively)
        VERBOSE: [c:\git] 16 git repo(s) found

        VERBOSE: [END: Search-PKGitRepo] Get git repos in path

        Parent  NumRepos  Repos                                                                                                                                                
        ------  --------  -----                                                                                                                                                
        c:\git        16  {c:\git\34d08ae7d489b1e87d50c1614e6cabbb, c:\git\blah, c:\git\blah2, C:\Us...

.EXAMPLE
    PS C:\Users\jbloggs\files> Search-PKGitRepo -Recurse -ExpandPaths | Format-List


        Parent   : c:\users\jbloggs\files
        NumRepos : 8
        Repos    : c:\users\jbloggs\files\ADACLScanner
                   c:\users\jbloggs\files\ADAudit
                   c:\users\jbloggs\files\Boe Prox\PowerShell_Scripts
                   c:\users\jbloggs\files\DnsCmdletFixes
                   c:\users\jbloggs\files\Gists\08ea6def8fea6b8a303867926fbb589e
                   c:\users\jbloggs\files\OpenSSL
                   c:\users\jbloggs\files\psPAS
                   c:\users\jbloggs\files\PSTree

#>
[Cmdletbinding(DefaultParameterSetName = "Recurse")]
Param(
    [Parameter(
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Starting path for search (default is current directory)"
    )]
    [Alias("Name","FullName")]
    [ValidateNotNullOrEmpty()]
    $Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Recurse subfolders in path"
    )]
    [switch]$Recurse,
    
    [Parameter(
        HelpMessage = "Break out individual files into strings separated by line breaks; easier to read than property collections"
    )]
    [switch]$ExpandPaths
   
)
Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region functions

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

    #endregion Function

    $Results = @()

    # Start
    $Activity = "Get git repos in path"
    Write-Verbose "[BEGIN: $ScriptName] $Activity"

}
Process {
    
    $TotalPaths = $Path.Count
    $CurrentPath = 0

    Foreach ($Item in $Path) {
        
        Try {
            $Results = @()
            $CurrentPath ++
        
            If ($Item -is [string]) {$Label = $Item}
            ElseIf ($Item -is [System.IO.FileSystemInfo]) {$Label = $Item.FullName}
            ElseIf ($Item -is [System.Management.Automation.PathInfo]) {$Label = $Item.FullName}
        
            $Msg = "Searching for git repos"
            If ($Recurse.IsPresent) {$Msg += " (search subfolders recursively)"}
            Write-Verbose "[$Label] $Msg"
            Write-Progress  -Id 1 -Activity $Activity -CurrentOperation $Msg -Status $Item -PercentComplete ($CurrentPath/$TotalPaths*100)
            
            $Output = [pscustomobject]@{
                Parent   = $Label
                NumRepos = $Null
                Repos    = $Null
            }

            If ([object[]]$GitRepos = GetRepoPath -P $Item) {
            
                $TotalRepos = $GitRepos.Count
                $CurrentRepo = 0
                $Msg = "$TotalRepos git repo(s) found"
                Write-Verbose "[$Label] $Msg"

                $Output.NumRepos = $TotalRepos
                If ($ExpandPaths.IsPresent) {
                    $Output.Repos = ($GitRepos | Sort-Object) -join("`n")
                }
                Else {
                    $Output.Repos = ($GitRepos | Sort-Object)
                }

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

        $Results += $Output

    } #end foreach path 

    Write-Output $Results

}
End {
    Write-Progress -Activity $Activity -Complete
    Write-Verbose "[END: $ScriptName] $Activity"
}
} # end Search-PKGitRepo