#requires -version 3
Function Get-PKGitWorkingFiles {
<#
.SYNOPSIS
    Returns the working files for a git repo, optionally allowing for selection of files from a menu, and/or limiting files to those in current directory only

.DESCRIPTION
    Returns the working files for a git repo, optionally allowing for selection of files from a menu, and/or limiting files to those in current directory only
    Tests for posh-git module and checks that directory contains a git repo
    Outputs a PSObject

.NOTES
    Name    : Function_Get-PKGitWorkingFiles.ps1 
    Created : 2018-03-21
    Author  : Paula Kingsley
    Version : 01.01.0000
    History :
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **
        
        v01.00.0000 - 2018-03-21 - Created script
        v01.01.0000 - 2018-03-21 - Added regex to include subfolder paths when using -CurrentDirectoryOnly, added -ReturnString

.PARAMETER CurrentDirectoryOnly
    Display working files for current directory only

.PARAMETER Menu
    Prompt for selection of working files

.PARAMETER ReturnString
    Return files as string, separated by spaces (e.g., for use in `git add file1 file2 file3')

.PARAMETER SuppressconsoleOutput
    Suppress all non-verbose/non-error console output

.EXAMPLE
    PS C:\Repos> Get-PKGitWorkingFiles -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                  Value                     
        ---                  -----                     
        Verbose              True                      
        CurrentDirectoryOnly False                     
        Menu                 False                     
        ScriptName           Get-PKGitWorkingFiles     
        ScriptVersion        1.0.0                     

        VERBOSE: Prerequisites
        VERBOSE: Verified git is installed and in system path
        VERBOSE: Verified 'posh-git' module is available

        Action: Get git working files

        VERBOSE: Verify directory contains git repo(s)
        VERBOSE: Get all git working files
        VERBOSE: 21 file(s) found

        RepoMan/Drafts/
        RepoMan/Scripts/Draft_Function_Test-MeltdownSpectre.ps1
        RepoMan/Scripts/Function_ConvertTo-HTMLTable.ps1
        RepoMan/Scripts/Function_Get-WindowsMeltdownPatch.ps1
        RepoMan/Scripts/Sandbox/Untitled12.ps1
        RepoMan/Scripts/Sandbox/Draft_Function_Get-WindowsMeltdownRegKey.ps1
        Chef/Scripts/Function_New-ChefClientConfig.ps1
        VMwareStuff/Scripts/Function_Get-PKVMDatacenter.ps1
        VMwareStuff/Scripts/Function_Get-PKVMTemplate.ps1
        VMwareStuff/Scripts/Function_Get-PKVirtualPortGroup.ps1
        VMwareStuff/Scripts/Function_Get-PKVMwareStuffReport.ps1
        VMwareStuff/Scripts/Function_New-PKVMwareStuff.ps1
        RepoMan/Scripts/Function_Get-PKWindowsAdmins.ps1
        RepoMan/Scripts/Draft_Function-New-PKWSUSServer.ps1
        RepoMan/Scripts/Draft_Function_Clear-PKWindowsRecycleBin.ps1
        RepoMan/Scripts/ConvertTo-HTMLTable.ps1
        RepoMan/Scripts/Draft_Function_Get-PKDirectorySize.ps1
        RepoMan/Scripts/Draft_Function_Get-PKWindowsDirSize.ps1
        RepoMan/Scripts/Draft_Function_Get-PKWindowsUpdateEvents.ps1
        RepoMan/Scripts/Draft_Function_Invoke-PKWinUp.ps1
        RepoMan/Scripts/Draft_Function_Remove-PKWindowsProfile.ps1

.EXAMPLE
    PS C:\TempRepo> Get-PKGitWorkingFiles -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                  Value                     
        ---                  -----                     
        Verbose              True                      
        CurrentDirectoryOnly False                     
        Menu                 False                     
        Debug                Get datacenter information
        ScriptName           Get-PKGitWorkingFiles     
        ScriptVersion        1.0.0                     

        VERBOSE: Prerequisites
        VERBOSE: Verified git is installed and in system path
        VERBOSE: Verified 'posh-git' module is available

        Action: Get git working files

        VERBOSE: Verify directory contains git repo(s)
        VERBOSE: Get all git working files

        No git working files found

.EXAMPLE
    PS C:\ProdRepo\main> Get-PKGitWorkingFiles -CurrentDirectoryOnly -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                     
        ---                   -----                     
        Verbose               True          
        CurrentDirectoryOnly  True                      
        Menu                  False                     
        SuppressConsoleOutput False                     
        ScriptName            Get-PKGitWorkingFiles     
        ScriptVersion         1.0.0                     
        
        VERBOSE: Prerequisites
        VERBOSE: Verified git is installed and in system path
        VERBOSE: Verified 'posh-git' module is available

        Action: Get git working files in current directory

        VERBOSE: Verify directory contains git repo(s)
        VERBOSE: Get git working files in current directory
        VERBOSE: 7 file(s) found

        ../main/Scripts/Function_Get-PKTempFile.ps1
        ../main/Scripts/Draft_Function_Get-PKEvents.ps1
        ../main/Scripts/Draft_Function_Get-PKDriveSpace.ps1
        ../main/Scripts/Draft_Function_Get-PKWindowsUpdateEvents.ps1
        ../main/Scripts/Draft_Function_Invoke-PKJob.ps1
        ../main/Scripts/Draft_Function_Stop-PKSpoolerSvc.ps1

.EXAMPLE
    PS C:\ProdRepo\main> Get-PKGitWorkingFiles -CurrentDirectoryOnly -Menu -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                     
        ---                   -----                     
        Verbose               True          
        CurrentDirectoryOnly  True                      
        Menu                  True                      
        SuppressConsoleOutput False                     
        ScriptName            Get-PKGitWorkingFiles     
        ScriptVersion         1.0.0                     

        VERBOSE: Prerequisites
        VERBOSE: Verified git is installed and in system path
        VERBOSE: Verified 'posh-git' module is available

        Action: Get git working files in current directory, bringing up a selection menu

        VERBOSE: Verify directory contains git repo(s)
        VERBOSE: Get git working files in current directory
        VERBOSE: 1 file(s) selectd
        ../main/Scripts/Draft_Function_Stop-PKSpoolerSvc.ps1

.EXAMPLE
    PS C:\RepoMan> Get-PKGitWorkingFiles -CurrentDirectoryOnly -ReturnString -SuppressConsoleOutput

        Scripts/Function_Get-PKInfo.ps1 Scripts/Function_Add-PKUpdates.ps1 Scripts/New-PKVMTemplate.ps1

.EXAMPLE
    PS C:\temp> Get-PKGitWorkingFiles -Menu -SuppressConsoleOutput

        Directory 'C:\temp' is not a git repo

#>
[CmdletBinding()]
Param(
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Display working files for current directory only"
    )]
    [switch]$CurrentDirectoryOnly,
    
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Prompt for selection of working files"
    )]
    [switch]$Menu,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Return files as string, separated by spaces (e.g., for use in `git add file1 file2 file3')"
    )]
    [switch]$ReturnString,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Suppress all non-verbose/non-error output"
    )]
    [switch]$SuppressConsoleOutput
)
Begin {


    # Version from comment block
    [version]$Version = "01.01.000"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preference
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    
    # General purpose splat
    $StdParams = @{
        ErrorAction = "stop"
        Verbose = $false
    }

    #region Functions
    # Is the current directory a git repository/working copy?
    function isCurrentDirectoryGitRepository {
        # https://gist.github.com/markembling/180853#file-gitutils-ps1
        if ((Test-Path ".git") -eq $TRUE) {
            return $TRUE
        }
        # Test within parent dirs
        $checkIn = (Get-Item .).parent
        while ($checkIn -ne $NULL) {
            $pathToTest = $checkIn.fullname + '/.git'
            if ((Test-Path $pathToTest) -eq $TRUE) {
                return $TRUE
            } else {
                $checkIn = $checkIn.parent
            }
        }
        return $FALSE
    }

    # Test directory, courtesy Mark Embling (not using yet)
    function TestRepoPath {
        [CmdletBinding()]
        Param()
        If (($Null = Test-Path ".git" -ErrorAction SilentlyContinue -Verbose:$False) -eq $true) {
            $Msg = "Directory '$PWD' is a git repo"
            Write-Verbose $Msg
            Return $True
        }
        Else {
            $Msg = "Directory' $PWD' is not a git repo"
            Write-Verbose $Msg
            Return $False
        }
    } #end function

    #endregion Functions

    #region Prerequisites

    $Msg = "Prerequisites"
    Write-Progress -Activity $Msg
    Write-Verbose $Msg

    If (-not ($Null = Get-Command git -ErrorAction SilentlyContinue -Verbose:$False)) {
        $Msg = "Failed to find git; make sure Git for Windows is installed and in the current path"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }
    Else {
        $Msg = "Verified git is installed and in system path"
        Write-Verbose $Msg
    }
    If (-not ($Mod = Get-Module -Name posh-git -ListAvailable -ErrorAction SilentlyContinue -Verbose:$False)) {
        $Msg = "Failed to find 'posh-git' module; if you have Chocolatey, you can install it using 'choco install poshgit'"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }
    Else {
        $Msg = "Verified 'posh-git' module is available"
        Write-Verbose $Msg
        If (-not (Get-Module $Mod -ErrorAction SilentlyContinue -Verbose:$False)) {
            $Null = Import-Module @StdParams
        }
    }

    #endregion Prerequisites


    $Activity = "Get git working files"   
    If ($CurrentDirectoryOnly.IsPresent) {$Activity += " in current directory"}
    If ($Menu.IsPresent) {$Activity += ", bringing up a selection menu"}
    $Msg = "Action: $Activity"
    $BGColor    = $Host.UI.RawUI.BackgroundColor
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}

    

}
Process {
    
    # Verifity this is a Git directory
    $Msg = "Verify directory contains git repo(s)"
    $Activity = $Msg
    Write-Verbose $Msg    
    Write-Progress -Activity $Activity
    
    [switch]$IsRepo = isCurrentDirectoryGitRepository

    If (-not $IsRepo.IsPresent) {
        $Msg = "Directory '$PWD' is not a git repo"
        $Host.UI.WriteErrorLine($Msg)
        Break
    }
    
    Else {
    
        Try {
        
            [array]$WorkingFiles = [array]$SelectedFiles = @()
        
            If ($currentDirectoryOnly.IsPresent) {
                $Msg = "Get git working files in current directory"
                $Activity = $Msg
                Write-Verbose $Msg    
                Write-Progress -Activity $Activity
    
                $GitStatus = Get-GitStatus @StdParams
                $CurrDir = "$((Get-Item $PWD.Path).Name)/"
                $Pattern = "^\.+\/\w" # (anything beginning with ..\ isn't in this directory
                [array]$WorkingFiles = $GitStatus.Working | Where-Object {($_ -notmatch $Pattern) -or ($_ -match [Regex]::Escape($CurrDir))}
            }
            Else {
                $Msg = "Get all git working files"
                Write-Verbose $Msg    
                Write-Progress -Activity $Activity
    
                $GitStatus = Get-GitStatus @StdParams      
                [array]$WorkingFiles = $GitStatus.Working
            }
        
            If ($WorkingFiles.Count -gt 0) {
            
                If ($Menu.IsPresent) {
                    $Msg = "$($WorkingFiles.Count) file(s) found; please select one or more files"
                    If ([array]$SelectedFiles = $WorkingFiles | Out-GridView -OutputMode Multiple -Title $Msg -ErrorAction SilentlyContinue -Verbose:$False) {
                        $Msg = "$($SelectedFiles.Count) file(s) selectd"
                        Write-Verbose $Msg
                    }
                    Else {
                        $Msg = "No files selected"
                        $Host.UI.WriteErrorLine($Msg)
                        Break
                    
                    }
                }
                Else {
                    [array]$SelectedFiles = $WorkingFiles
                    $Msg = "$($SelectedFiles.Count) file(s) found"
                    Write-Verbose $Msg    
                }
            }
            Else {
                $Msg = "No git working files found"
                If ($CurrentDirectoryOnly.IsPresent) {$Msg += " directly in root directory (consider changing to subfolder)"}
                $Host.UI.WriteErrorLine($Msg) 
            }
        }
        Catch {
            $Msg = "Failed to get git working files"
            If ($ErrorDetails = $_.Exception.Message) {$msg += "`n$ErrorDetails"}
            $Host.UI.WriteErrorLine("ERROR: $Msg")
        }

        If ($SelectedFiles) {
            If ($ReturnString.IsPresent) {
                Write-Output ($SelectedFiles -join(" "))
            }
            Else {
                Write-Output $SelectedFiles
            }
        }  
    
    } #end if git repo directory

}
End {
    Write-Progress -Activity $Activity -Completed
}
}