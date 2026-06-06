#requires -Version 4
Function Get-PKGitInstall {
<#
.SYNOPSIS
    Looks for copies of the git executable on the local computer, in the system path or by folder, returning a PSObject with details about the command and file

.DESCRIPTION
    Searches for git executable(s) on the local computer using one of two modes:
    - Default (system path): Searches the system PATH environment variable using Get-Command
    - Folder search: Recursively searches one or more specified directories (or OS-specific defaults)

    For each match found, runs 'git --version' to retrieve the actual git version string.

    Returns a PSCustomObject for each match with the following properties:
    - ComputerName: Local computer name
    - Name: Executable filename (typically 'git')
    - Path: Full path to the git executable
    - Type: File type (e.g., 'SymbolicLink' on Unix, 'Unknown/Error' on Windows where UnixStat unavailable)
    - Version: Git version string from 'git --version'
    - CommandType: PowerShell command type (Application)
    - FileDate: File creation date in yyyy-MM-dd format

    Platform-aware: Uses Windows Program Files paths on Windows; uses /usr/local/bin, /opt/homebrew/bin, /usr/bin, /opt on macOS/Linux.

.NOTES
    Name    : Function_Get-PKGitInstall.ps1
    Created : 2016-05-29
    Author  : Paula Kingsley
    Version : 07.00
    History :

        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v01.00 - 2016-05-29 - Created script
        v02.00 - 2016-06-06 - Renamed, added alias, added requires statement for parent module, link to github repo
        v03.00 - 2017-02-10 - Total overhaul and simplification
        v04.00 - 2019-07-24 - Renamed function from Test-PKGitInstall, removed boolean output, simplified
        v05.00 - 2022-09-19 - Overhauled, simplified, standardized
        v06.00 - 2024-06-01 - Overhaul to simplify and standardize, change versioning format
        v07.00 - 2026-06-03 - Total overhaul, returns item type, platform-aware defaults, includes git --version

.LINK
    https://github.com/lanwench/PKGit

.PARAMETER Search
    Search for git in specific folders (default is to search system path)

.PARAMETER Path
    One or more specific paths to search. Alias: FilePath. Defaults vary by OS:
    - Windows: Program Files, program files (x86), shared user profile directories
    - macOS/Linux: /usr/local/bin, /opt/homebrew/bin, /usr/bin, /opt

.EXAMPLE
    PS C:\> Get-PKGitInstall -Verbose
    VERBOSE: PSBoundParameters:

    Key              Value
    ---              -----
    Verbose          True
    Path
    Search           False
    ComputerName     LAPTOP14
    ParameterSetName SystemPath
    ScriptName       Get-PKGitInstall
    ScriptVersion    7.0

    VERBOSE: [BEGIN: Get-PKGitInstall] Search for git in system path
    VERBOSE: [LAPTOP14] Searching for git in system paths
    VERBOSE: [LAPTOP14] 1 match(es) found

    ComputerName : LAPTOP14
    Name         : git
    Path         : C:\Program Files\Git\cmd\git
    Type         : Unknown/Error
    Version      : git version 2.37.3.windows.1
    CommandType  : Application
    FileDate     : 2022-09-14

    VERBOSE: [END: Get-PKGitInstall] Script ran successfully

.EXAMPLE
    PS /Users/jbloggs> Get-PKGitInstall -Search -Path /usr/local/bin -Verbose
    VERBOSE: PSBoundParameters:

    Key              Value
    ---              -----
    Verbose          True
    Path             /usr/local/bin
    Search           True
    ComputerName     Mapple.local
    ParameterSetName Search
    ScriptName       Get-PKGitInstall
    ScriptVersion    7.0

    VERBOSE: [BEGIN: Get-PKGitInstall] Search for git in specific folders
    VERBOSE: [Mapple.local] Searching folders for git
    VERBOSE: [Mapple.local] 1 match(es) found

    ComputerName : Mapple.local
    Name         : git
    Path         : /usr/local/bin/git
    Type         : SymbolicLink
    Version      : git version 2.44.0
    CommandType  : Application
    FileDate     : 2024-02-29

    VERBOSE: [END: Get-PKGitInstall] Script ran successfully


#>

[CmdletBinding(DefaultParameterSetName = "SystemPath")]
Param(
    [Parameter(
        ParameterSetName = "Search",
        HelpMessage = "Search for command in specific folders (default is to look for command in path)"
    )]
    [switch]$Search,

    [Parameter(
        ParameterSetName = "Search",
        HelpMessage = "One or more specific paths to search (if not specified, defaults to user's home directory and other common locations)"
    )]
    [Alias("FilePath")]
    [string[]]$Path
)

Begin {

    # Version from comment block
    [version]$Version = "07.00"

    # Set OS-specific default paths if not provided
    

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    $ScriptName = $MyInvocation.MyCommand.Name
    $CurrentParams = $PSBoundParameters
    If ($Source -eq "SystemPath") {$CurrentParams.Path = $Null}
    Elseif ($Source -eq "Search" -and -not $Path) {
        If ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {$Path = @("$Env:ProgramFiles","${env:ProgramFiles(x86)}","$Env:AllUsersProfile")}
        Else {$Path = @("/usr/local/bin","/opt/homebrew/bin","/usr/bin","/opt")}
    }
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path variable:$_} | ForEach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $ComputerName = [System.Net.Dns]::GetHostName()
    $CurrentParams.Add("ComputerName",$ComputerName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Functions

    # Get the command or the file object
    Function _GetDetails {
        Switch ($Source) {
            Search {
                $Command = Get-Command -Name $Item.FullName -CommandType Application -ErrorAction SilentlyContinue
                Try {
                    $GitVersion = & $Item.FullName --version 2>$Null
                }
                Catch {
                    $GitVersion = $Null
                }
                $FileType = If ($Item.UnixStat.ItemType) { $Item.UnixStat.ItemType } Else { "Unknown/Error" }
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    Name         = $Item.Name
                    Path         = $Item.FullName
                    Type         = $FileType
                    Version      = $GitVersion
                    CommandType  = $Command.CommandType
                    FileDate     = (Get-Date $Item.CreationTime).ToString("yyyy-MM-dd")
                }
            }
            SystemPath {
                $File = Get-Item $Item.Path -ErrorAction SilentlyContinue
                Try {
                    $GitVersion = & $Item.Path --version 2>$Null
                }
                Catch {
                    $GitVersion = $Null
                }
                $FileType = If ($File.UnixStat.ItemType) { $File.UnixStat.ItemType } Else { "Unknown/Error" }
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    Name         = $File.Name
                    Path         = $File.FullName
                    Type         = $FileType
                    Version      = $GitVersion
                    CommandType  = $Item.CommandType
                    FileDate     = (Get-Date $File.CreationTime).ToString("yyyy-MM-dd")
                }
            }
        }
    } #end _GetDetails

    #endregion Functions

    $Activity = "Search for git"
    If ($Search.IsPresent) {
        If ($CurrentParams.ContainsKey('Path')) {
            $Activity += " in specific folders"
        }
        Else {
            $Activity += " in default folders"
        }
    }
    Else {
        $Activity += " in system path"
    }

    $Msg = "[BEGIN: $ScriptName] $Activity"
    Write-Verbose $Msg

}
Process {

    # Search specified folders
    If ($Search.IsPresent) {
        $Msg = "Searching folders for git"
        Write-Verbose "[$ComputerName] $Msg"

        Try {
            $TopLevelFolders = Get-Item -Force -Path (($Path | Where-Object {$_} |
                Where-Object {Test-Path -Path "$_" -PathType Container})) -ErrorAction SilentlyContinue
            Try {
                If (-not ([object[]]$Found = $TopLevelFolders | Get-ChildItem -Filter git -Recurse -Force -File -ErrorAction SilentlyContinue)) {
                    $Msg = "Failed to find git in specified folder path(s)"
                    Write-Warning "[$ComputerName] $Msg"
                }
            }
            Catch {
                $Msg = "Failed to find git in specified folder path(s)"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                Write-Warning "[$ComputerName] $Msg"
            }
        }
        Catch {
            $Msg = "Failed to get folder path"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Write-Warning "[$ComputerName] $Msg"
        }
    }

    # Test whether command is found in path
    Else {
        $Msg = "Searching for git in system paths"
        Write-Verbose "[$ComputerName] $Msg"
        Try {
            If (-not ([array]$Found = Get-Command -Name git -ErrorAction SilentlyContinue -Verbose:$False)) {
                $Msg = "Failed to find git in system path"
                Write-Warning "[$ComputerName] $Msg"
            }
        }
        Catch {
            $Msg = "Failed to find git in specified folder path(s)"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Write-Warning "[$ComputerName] $Msg"
        }
    }

    If ($Found) {
        $Msg = "$($Found.Count) match(es) found"
        Write-Verbose "[$ComputerName] $Msg"
        Foreach ($Item in $Found) {
            _GetDetails
        }
    }
}
End {
    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] Script ran successfully"

}
} #end Get-PKGitInstall


$Null = New-Alias Test-PKGitInstall -Value Get-PKGitInstall -Confirm:$False -Force -EA SilentlyContinue -Description "Backwards compatibility after rename"
