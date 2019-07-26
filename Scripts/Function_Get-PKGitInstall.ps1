#requires -Version 3
Function Get-PKGitInstall {
<#
.SYNOPSIS    
    Looks for git.exe on the local computer, in the system path or by folder

.DESCRIPTION
    Looks for git.exe on the local computer, in the system path or by folder
    Returns a PSObject

.Notes
    Name    : Function_Get-PKGitInstall.ps1
    Created : 2016-05-29
    Author  : Paula Kingsley
    Version : 04.00.0000
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

.LINK
    https://github.com/gmacluskiench/PKGit

.PARAMETER SearchFolders
    Search for command in specific folders (default is to look for command in path)

.PARAMETER FilePath
    One or more specific paths to search (default is user profile, program files, shared user profile directories)

.PARAMETER Quiet
    Suppress non-verbose console output

.EXAMPLE
    PS C:\>  Get-PKGitInstall -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value                                                                     
        ---              -----                                                                     
        Verbose          True                                                                      
        SearchFolders    False                                                                     
        FilePath         
        Quiet            False                                                                     
        ComputerName     LAPTOP2                                                                     
        ParameterSetName Path                                                                      
        ScriptName       Get-PKGitInstall                                                          
        ScriptVersion    4.0.0                                                                     

        BEGIN: Search for git.exe in system path

        [LAPTOP2] Search system paths for git.exe
        [LAPTOP2] 1 matches found

        ComputerName : LAPTOP2
        Name         : git.exe
        Path         : C:\Program Files\Git\cmd\git.exe
        Version      : 2.22.0.1
        Language     : English (United States)
        CommandType  : Application
        FileDate     : 11/21/2018 8:03:41 PM

        END  : Search for git.exe in system path

.EXAMPLE
    PS C:\> Get-PKGitInstall -SearchFolders -Verbose | Format-Table -AutoSize

        VERBOSE: PSBoundParameters: 
	
        Key              Value                                                                     
        ---              -----                                                                     
        SearchFolders    True                                                                      
        Verbose          True                                                                      
        FilePath         {C:\Users\gmacluskie, C:\Program Files, C:\Program Files (x86), C:\ProgramData}
        Quiet            False                                                                     
        ComputerName     LAPTOP2                                                                     
        ParameterSetName Search                                                                    
        ScriptName       Get-PKGitInstall                                                          
        ScriptVersion    4.0.0                                                                     

        BEGIN: Search for git.exe in specific folders

        [LAPTOP2] Search folders for git.exe
        [LAPTOP2] 5 matches found

        END  : Search for git.exe in specific folders

        ComputerName   Name    Path                                                  Version  Language                CommandType FileDate             
        ------------   ----    ----                                                  -------  --------                ----------- --------             
        LAPTOP2        git.exe C:\Users\gmacluskie\Desktop\gitbackup\git.exe         2.20.0.4 English (United States) Application 7/25/2019 1:39:08 PM 
        LAPTOP2        git.exe C:\Program Files\Git\bin\git.exe                      2.22.0.1 English (United States) Application 7/22/2019 10:37:56 AM
        LAPTOP2        git.exe C:\Program Files\Git\cmd\git.exe                      2.22.0.1 English (United States) Application 11/21/2018 8:03:41 PM
        LAPTOP2        git.exe C:\Program Files\Git\mingw64\bin\git.exe              2.22.0.1 English (United States) Application 7/22/2019 10:37:57 AM
        LAPTOP2        git.exe C:\Program Files\Git\mingw64\libexec\git-core\git.exe 2.22.0.1 English (United States) Application 7/22/2019 10:38:02 AM

.EXAMPLE
    PS C:\> Get-PKGitInstall -SearchFolders -FilePath C:\Temp

        BEGIN: Search for git.exe in specific folders

        [WKSTA] Search folders for git.exe
        [WKSTA] Failed to find git.exe in specified folder path(s)

        END  : Search for git.exe in specific folders


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
    [string[]]$FilePath = @("$Env:UserProfile","$Env:ProgramFiles","${env:ProgramFiles(x86)}","$Env:AllUsersProfile"),
        
    [Parameter(
        HelpMessage = "Suppress non-verbose console output"
    )]
    [switch]$Quiet
)
Begin{

    # Version from comment block
    [version]$Version = "04.00.0000"

    # Preference
    $ErrorActionPreference = "Stop"

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    $CurrentParams = $PSBoundParameters
    If ($Source -eq "Path") {$CurrentParams.FilePath = $Null}
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Functions

    # Function to write a console message or a verbose message
    Function Write-MessageInfo {
        Param([Parameter(ValueFromPipeline)]$Message,$FGColor,[switch]$Title)
        $BGColor = $host.UI.RawUI.BackgroundColor
        If (-not $Quiet.IsPresent) {
            If ($Title.IsPresent) {$Message = "`n$Message`n"}
            $Host.UI.WriteLine($FGColor,$BGColor,"$Message")
        }
        Else {Write-Verbose "$Message"}
    }

    # Function to write an error or a verbose message
    Function Write-MessageError {
        [CmdletBinding()]
        Param([Parameter(ValueFromPipeline)]$Message)
        $BGColor = $host.UI.RawUI.BackgroundColor
        If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("$Message")}
        Else {Write-Verbose "$Message"}
    }

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
    "BEGIN: $Activity" | Write-MessageInfo -FGColor Yellow -Title

}
Process {

    # Search specified folders
    If ($SearchFolders.IsPresent) {
        
        $Msg = "Search folders for git.exe"
        "[$Env:ComputerName] $Msg"  | Write-MessageInfo -FGColor White
        Write-Progress -Activity $Activity -CurrentOperation $Msg

        Try {
            $TopLevelFolders = Get-Item -Force -Path (($FilePath | Where-Object {$_} | 
                Where-Object {Test-Path -Path "$_" -PathType Container})) @StdParams
            
            Try {
                If (-not ([array]$ItemsFound = $TopLevelFolders | Get-Childitem -Filter git.exe -Recurse -Force -File -ErrorAction SilentlyContinue)) {
                    $Msg = "Failed to find git.exe in specified folder path(s)"
                    "[$Env:ComputerName] $Msg" | Write-MessageError
                }
            }
            Catch {
                $Msg = "Failed to find git.exe in specified folder path(s)"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                "[$Env:ComputerName] $Msg" | Write-MessageError
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
        "[$Env:ComputerName] $Msg"  | Write-MessageInfo -FGColor White
        Write-Progress -Activity $Activity -CurrentOperation $Msg

        Try {
            If (-not ([array]$ItemsFound = Get-Command -Name git.exe -EA SilentlyContinue -Verbose:$False)) {
                $Msg = "Failed to find git.exe in system path"
                "[$Env:ComputerName] $Msg" | Write-MessageError
            }
            #Else {$ItemsFound = $ItemsFound | Select Name,@{N="Path";E={$_.Source}},Version}
        }
        Catch {
            $Msg = "Failed to find git.exe in specified folder path(s)"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            "[$Env:ComputerName] $Msg" | Write-MessageError
        }
    }
    
    If ($ItemsFound) {
        
        $Total = $ItemsFound.Count
        $Current = 0
        $Msg = "$Total matches found"
        "[$Env:ComputerName] $Msg" | Write-MessageInfo -FGColor Green

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
    
    Write-Progress -Activity * -Completed
    "END  : $Activity" | Write-MessageInfo -FGColor Yellow -Title

}
} #end Get-PKGitInstall


$Null = New-Alias Test-PKGitInstall -Value Get-PKGitInstall -Confirm:$False -Force -EA SilentlyContinue -Description "Backwards compatibility after rename"

