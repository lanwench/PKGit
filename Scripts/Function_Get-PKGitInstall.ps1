#requires -Version 3
Function Get-PKGitInstall {
<#
.SYNOPSIS    
    Looks for git.exe on the local computer, in the system path or by folder

.DESCRIPTION
    Looks for git.exe on the local computer, in the system path or by folder
    Returns a PSObject

.NOTES
    Name    : Function_Get-PKGitInstall.ps1
    Created : 2016-05-29
    Author  : Paula Kingsley
    Version : 05.00.0000
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **
        
        v1.0.0     - 2016-05-29 - Created script
        v1.0.1     - 2016-05-29 - Moved to individual file from main psm1 file; 
                                  made path mandatory, added help
        v1.0.2     - 2016-05-29 - Changed true output for directory input 
                                  to include full path to file
        v2.0.0     - 2016-06-06 - Renamed from Test-PKGitInstall, added alias,
                                  added requires statement for parent module,
                                  link to github repo
        v2.0.1     - 2016-08-01 - Renamed with Function_ prefix
        v3.0.0     - 2017-02-10 - Total overhaul and simplification
        v4.00.0000 - 2019-07-24 - Renamed from Test-PKGitInstall, removed boolean output,
                                  simplified, general updates and standardization
        v5.00.0000 - 2022-09-19 - Overhauled, simplified, standardized

.LINK
    https://github.com/lanwench/PKGit

.PARAMETER SearchFolders
    Search for command in specific folders (default is to look for command in path)

.PARAMETER FilePath
    One or more specific paths to search (default is user profile, program files, shared user profile directories)

.EXAMPLE
    PS C:\> Get-PKGitInstall -Verbose
    VERBOSE: PSBoundParameters: 
	
    Key              Value           
    ---              -----           
    Verbose          True            
    FilePath                         
    SearchFolders    False           
    ComputerName     LAPTOP14 
    ParameterSetName Path            
    ScriptName       Get-PKGitInstall
    ScriptVersion    5.0.0           

    VERBOSE: [BEGIN: Get-PKGitInstall] Search for git.exe in system path
    VERBOSE: [LAPTOP14] Search system paths for git.exe
    VERBOSE: [LAPTOP14] 1 matches found


    ComputerName : LAPTOP14
    Name         : git.exe
    Path         : C:\Program Files\Git\cmd\git.exe
    Version      : 2.37.3.1
    Language     : English (United States)
    CommandType  : Application
    FileDate     : 2019-08-14 10:52:23 AM

    VERBOSE: [END: Get-PKGitInstall] Search for git.exe in system path


#>

[cmdletbinding(DefaultParameterSetName = "Path")]
Param(
    [Parameter(
        ParameterSetName = "Search",
        HelpMessage = "Search for command in specific folders (default is to look for command in path)"
    )]
    [switch]$SearchFolders,
    
    [Parameter(
        ParameterSetName = "Search",
        HelpMessage = "One or more specific paths to search (default is user profile, program files, shared user profile directories)"
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$FilePath = @("$Env:UserProfile","$Env:ProgramFiles","${env:ProgramFiles(x86)}","$Env:AllUsersProfile")
 
)
Begin{

    # Version from comment block
    [version]$Version = "05.00.0000"


    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    $ScriptName = $MyInvocation.MyCommand.Name
    $CurrentParams = $PSBoundParameters
    If ($Source -eq "Path") {$CurrentParams.FilePath = $Null}
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$Scriptname)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Functions


    # Get the command or the file object
    Function GetDetails {
        Switch ($Source) {
            Search {
                # We have the file object; get the command info
                $Command = Get-Command -Name $Item.Name -CommandType Application -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    ComputerName = $Env:ComputerName
                    Name         = $Item.Name
                    Path         = $Item.FullName
                    Version      = $Command.Version
                    Language     = $Command.FileVersionInfo.Language
                    CommandType  = $Command.CommandType
                    FileDate     = $Item.CreationTime
                }
            }
            Path {
                # We have the command object; get the file info
                $File = Get-Item $Item.Path  -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    ComputerName = $Env:ComputerName
                    Name         = $File.Name
                    Path         = $File.FullName
                    Version      = $Item.Version
                    Language     = $Item.FileVersionInfo.Language
                    CommandType  = $Item.CommandType
                    FileDate     = $File.CreationTime
                }
            }
        }
    } #end GetDetails

    #endregion Functions
    
    $Activity = "Search for git.exe"
    If ($SearchFolders.IsPresent) {
        If ($DefaultFolders.IsPresent) {
            $Activity += " in default folders"
        }
        Elseif ($CurrentParams.FilePath) {
            $Activity += " in specific folders"
        }
    }
    Else {
        $Activity += " in system path"
    }
    
    # Console output
    $Msg = "[BEGIN: $Scriptname] $Activity" 
    Write-Verbose $Msg

}
Process {

    # Search specified folders
    If ($SearchFolders.IsPresent) {
        
        $Msg = "Search folders for git.exe"
        Write-Verbose "[$Env:ComputerName] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg

        Try {
            $TopLevelFolders = Get-Item -Force -Path (($FilePath | Where-Object {$_} | 
                Where-Object {Test-Path -Path "$_" -PathType Container})) @StdParams
            
            Try {
                If (-not ([array]$ItemsFound = $TopLevelFolders | Get-Childitem -Filter git.exe -Recurse -Force -File -ErrorAction SilentlyContinue)) {
                    $Msg = "Failed to find git.exe in specified folder path(s)"
                    Write-Warning "[$Env:ComputerName] $Msg"
                }
            }
            Catch {
                $Msg = "Failed to find git.exe in specified folder path(s)"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                Write-Warning "[$Env:ComputerName] $Msg"
            }
        }
        Catch {
            $Msg = "Failed to get folder path"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            "[$Env:ComputerName] $Msg" | Write-MessageError
        }
    }

    # Test whether command is found in path
    Else {

        $Msg = "Search system paths for git.exe"
        Write-Verbose "[$Env:ComputerName] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg

        Try {
            If (-not ([array]$ItemsFound = Get-Command -Name git.exe -EA SilentlyContinue -Verbose:$False)) {
                $Msg = "Failed to find git.exe in system path"
                Write-Warning "[$Env:ComputerName] $Msg"
            }
        }
        Catch {
            $Msg = "Failed to find git.exe in specified folder path(s)"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Write-Warning "[$Env:ComputerName] $Msg"
        }
    }
    
    If ($ItemsFound) {
        
        $Total = $ItemsFound.Count
        $Current = 0
        $Msg = "$Total matches found"
        Write-Verbose "[$Env:ComputerName] $Msg"
        
        Foreach ($Item in $ItemsFound) {
                        
            $Current++ 
            [int]$percentComplete = ($Current/$Total* 100)
            $Msg = $Item.FullName
            Write-Progress -Activity $Activity -CurrentOperation $Item.Path -PercentComplete $percentComplete -Status "$percentComplete%"

            GetDetails 
        }
    }   
}
End {
    
    $Msg = "[END: $Scriptname] $Activity" 
    Write-Verbose $Msg

    Write-Progress -Activity * -Completed
    
}
} #end Get-PKGitInstall


$Null = New-Alias Test-PKGitInstall -Value Get-PKGitInstall -Confirm:$False -Force -EA SilentlyContinue -Description "Backwards compatibility after rename"

