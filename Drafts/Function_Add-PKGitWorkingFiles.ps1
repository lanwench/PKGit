#requires -version 3
Function Add-PKGitWorkingFiles {
<#
.SYNOPSIS
    Adds working files in a git repo

.DESCRIPTION
    Adds working files in a git repo
    Tests for posh-git module and checks that directory contains a git repo
    SupportsShouldProcess
    Accepts pipeline input
    Outputs a PSObject

.NOTES
    Name    : Function_Get-PKGitWorkingFiles.ps1 
    Created : 2019-03-11
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **
        
        v01.00.0000 - 2019-03-11 - Created script

.PARAMETER CurrentDirectoryOnly
    Display working files for current directory only

.PARAMETER Menu
    Prompt for selection of working files

.PARAMETER ReturnString
    Return files as string, separated by spaces (e.g., for use in `git add file1 file2 file3')

.PARAMETER SuppressconsoleOutput
    Suppress all non-verbose/non-error console output

.EXAMPLE


#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    
    [Parameter(
        Mandatory = $True,
        ValueFromPipeline = $True,
        HelpMessage = "Working files in current directory"
    )]
    [string[]]$Files,

    [Parameter(
        HelpMessage = "Suppress all non-verbose/non-error output"
    )]
    [switch]$SuppressConsoleOutput
)
Begin {


    # Version from comment block
    [version]$Version = "01.00.0000"

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

    If (-not ($Null = Get-Command git.exe -ErrorAction SilentlyContinue -Verbose:$False)) {
        $Msg = "Failed to find git.exe; make sure Git for Windows is installed and in the current path"
        $Host.UI.WriteErrorLine("ERROR  : [Prerequisites] $Msg")
        Break
    }
    Else {
        $Msg = "Verified git is installed and in system path"
        Write-Verbose "[Prerequisites] $Msg"
    }
    If (-not ($Mod = Get-Module -Name posh-git -ListAvailable -ErrorAction SilentlyContinue -Verbose:$False)) {
        $Msg = "Failed to find 'posh-git' module; if you have Chocolatey, you can install it using 'choco install poshgit'"
        $Host.UI.WriteErrorLine("ERROR  : [Prerequisites] $Msg")
        Break
    }
    Else {
        $Msg = "Verified 'posh-git' module is available"
        Write-Verbose "[Prerequisites] $Msg"
        If (-not (Get-Module $Mod -ErrorAction SilentlyContinue -Verbose:$False)) {
            $Null = Import-Module @StdParams
        }
    }

    #endregion Prerequisites

    $Activity = "Add git working files in current directory"   
    $Msg = "BEGIN  : $Activity"
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
        $Host.UI.WriteErrorLine("ERROR  : $Msg")
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