#Requires -Version 3
function New-PKGitReadmeFile {
<#
.SYNOPSIS
    Generates a README.md file from the comment-based help contained in the specified PowerShell module file.

.DESCRIPTION
    Generates a README.md file from the help contained in the specified Powershell module file.
    The generated README.md file's purpose is to serve as a brief documentation for the module on GitHub.  
    This README file is created in the same directory as the module file.  
    It uses GitHub Flavored Markdown, so the GitHub website will format it nicely.

    This works with any PowerShell module (script or compiled) and any help (comment-based or XML-based) as long as it is accessible via Get-Help.

.NOTES 
    Name    : Function_New-PKGitReadmeFile.ps1
    Created : 2017-02-10
    Version : 02.02.0000
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEPEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0      - 2017-02-10 - Adapted Mathieu Buisson's original module script (see link)
        v1.1.0      - 2017-02-10 - Changed formatting output/headers
        v2.0.0      - 2017-05-16 - Renamed from New-PKGitReadmeFromHelp, added rename for old file found
        v2.1.0      - 2017-08-22 - Added LabelName parameter, to choose Synopsis or Description for function content
        v02.02.0000 - 2017-10-30 - Added 'Description', minor cosmetic changes

.LINK
    https://github.com/MathieuBuisson/Powershell-Utility/tree/master/ReadmeFromHelp


.PARAMETER ModuleFile
    To specify the path to the module file you wish to create a README file for.

.EXAMPLE
    New-ReadmeFromHelp -ModuleFile ".\Example.psm1"

    Creates a README file for the script module Example.psm1, in the same directory.



#>
[CmdletBinding(
    DefaultParameterSetName = "Module",
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]

Param(
    
    [Parameter(
        ParameterSetName = "Module",
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "PowerShell module object or name"
    )]
    [ValidateNotNullOrEmpty()]
    [object]$ModuleName,

    [Parameter(
        ParameterSetName = "File",
        Mandatory=$True,
        Position=0,
        HelpMessage = "Full path to module's .psm1 file (e.g., c:\users\jbloggs\modules\modulename.psm1"
    )]
    [validatescript({
         If (Test-Path $_) {
            If ($_ -match ".psm*") {$True}
         } 
    })]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleFile,

    [Parameter(
        Mandatory=$False,
        HelpMessage = "Text to add after boilerplate 'This module contains x PowerShell function(s) and tools' in the About section (defaults to description in module's .psd1 file, if found)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleDescription,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Label to use (Synopsis or Description; default Synopsis)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Synopsis","Description")]
    [string]$LabelName = "Synopsis",

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Full name of author (by default will use Author property from .psd1 if populated)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Author, # = "Paula Kingsley",

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Force overwrite if readme.md already exists (rename old file and move)"
    )]
    [Switch]$Force,

    [Parameter(
        Mandatory=$false,
        HelpMessage="Suppress non-verbose console output"
    )]
    [Switch] $SuppressConsoleOutput
)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

    # Show our settings
    $Source = $PScmdlet.ParameterSetName
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }

    # In case there isn't one...we will try the other
    # and line spacing might be different
    Switch ($LabelName) {
        Synopsis {
            $Alt = "Description"
            $Spacer = "`n"
        }
        Description {
            $Alt = "Synopsis"
            $Spacer = ""
        }
    }
    
    # Console output
    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = "Action: Create new Github-markdown format README.md file from PowerShell module '$ModuleName'"
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}

}
Process {

    # Check for module
    Switch($Source) {
        Module {
            If (-not ($ModuleObj = Get-Module -Name $ModuleName @StdParams)) {
                If ($ModuleObj = Get-Module -Name $Modulename -ListAvailable @StdParams | Import-Module -Force @StdParams) {
                    $Msg = "Found and imported module $($ModuleObj.Name), version $($ModuleObj.Version)"
                    $ParentDirectory = $ModuleObj.ModuleBase
                }
                Else {
                    $Msg = "Module '$ModuleName' not found in any PSModule directory on $Env:ComputerName"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }
            Else {
                $ParentDirectory = $ModuleObj.ModuleBase
                $Msg = "Found module '$($ModuleObj.Name)' version $($ModuleObj.Version) in $ParentDirectory"
                Write-Verbose $Msg   
            }
        }
        File {
            Try {
                If ($ModuleObj = Import-Module $ModuleFile -Force @StdParams) {
                    $Msg = "Found module $($ModuleObj.Name), version $($ModuleObj.Version)"
                    $FullModulePath = $Module.Path
                    $ParentDirectory = (Get-Item $FullModulePath @StdParams).DirectoryName
                    Write-Verbose $Msg
                }
                Else {
                    $Msg = "Module import failed"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }
            Catch {
                $Msg = "Module import failed"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            }

        }
    }

    # Check for existing file
    If ($Exists = Get-ChildItem -Path $ParentDirectory -Filter 'readme.md') {
        
        $Lines = (Get-Content $Exists.FullName | Measure-Object -Line).Lines

        $Found = New-Object PSObject -Property ([ordered]@{
            Name       = $Exists.Name
            Path       = $Exists.FullName
            LineCount  = $Lines
            SizeKB     = ($Exists.Length / 1Kb).ToString("00.00")
            ReadOnly   = $Exists.IsReadOnly
            CreateDate = $Exists.CreationTime
            LastWrite  = $Exists.LastWriteTime
        })
        Write-Verbose ($Found | Out-String)

        If (-not $Force.IsPresent) {
            $Msg = "Found existing readme.md file (you must specify -Force to overwrite)"
            $Host.UI.WriteErrorLine("$Msg")
            Break
        }
        Else {
            $Msg = "Rename and move existing readme.md file"
            Write-Verbose $Msg
            $NewName = "$($ModuleObj.Name)_$(Get-Date -f yyyy-MM-dd_hh-mm)_backup_readme.md"
            $Msg = "`n`n`tMove existing file: $($Exists.FullName)`n`tto new file: $Env:Temp\$NewName`n`n"
            If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
                Try {
                    $RenameFile = Rename-Item -path $Exists.FullName -NewName $NewName -PassThru -Force -Confirm:$False @StdParams
                    $MoveFile = Get-Item $Renamefile | Move-Item -Destination $Env:Temp -PassThru -Force @StdParams
                    $BackupFile = Get-Item "$Env:Temp\$NewName" @StdParams
                    $Msg = "Moved existing file to $($BackupFile.FullName)"
                    Write-Verbose $Msg
                }
                Catch {
                    $Msg = "File rename/move failed"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg = "$Msg`n$ErrorDetails"}
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }            
        }
    } #end if file already exists

    # Get the author (if not provided)
    If (-not $Author) {
        If ($ModuleObj.Author) {$Author = $ModuleObj.author}
        Else {$Author = "the author"}
    }

    # Get the description (if not provided)
    If (-not $ModuleDescription) {
        If ($ModuleObj.Description) {$ModuleDescription = $ModuleObj.Description}
    }
    
    # Check for Requires statements
    $FirstLine = $ModuleObj.Definition -split "`n" | Select-Object -First 1
    If ($FirstLine -like "#Requires*") {
        $PSVersionRequired = $($FirstLine -split " " | Select-Object -Last 1)
    }
    Else {
        If ($ModuleObj.PowerShellVersion) {
            $PSVersionRequired = $ModuleObj.PowerShellVersion.ToString()
        }
    }

    # Check module dependencies
    If ([array]$ReqModules = $ModuleObj.RequiredModules.Name) {
        If ($ReqModules.Count -gt 1) {$RequiredModules = $($ReqModules -join(", "))}
        Else {$RequiredModules = $ReqModules}
    }

    # Initialize variable to which we will add lines of strings
    $Readme = @()

    #region Module description
    $Commands = Get-Command -Module $ModuleObj @StdParams | Where-Object {$_.CommandType -ne "Alias"}
    $CommandsCount = $($Commands.Count)
    $Msg = "Commands in this module :`n * $(($Commands.Name | Sort) -join("`n * "))"
    Write-Verbose $Msg

    # Name/Title
    $Readme += "# Module $($ModuleObj.Name)"
    
    # About
    $Readme += "$Spacer## About"

    #$Readme += "|Item|Value|"
    $Readme += "|||"
    $Readme += "|---|---|"
    $Readme += "|**Name** |$($ModuleObj.Name)|"
    $Readme += "|**Author** |$Author|"
    $Readme += "|**Type** |$($ModuleObj.ModuleType)|"
    $Readme += "|**Version** |$($ModuleObj.Version)|"
    If ($ModuleDescription) {$Readme += "|**Description**|$ModuleDescription|"}
    $Readme += "|**Date**|README.md file generated on $($(Get-Date  -f F))|"

    <#

    $Readme += "$Spacer`  * Name       : $($ModuleObj.Name)"
    $Readme += "  * Author     : $Author"
    $Readme += "  * Type       : $($ModuleObj.ModuleType)"
    $Readme += "  * Version    : $($ModuleObj.Version)"
    $Readme += "  * FileDate   : $(Get-Date  -f F)"
    If ($ModuleDescription) {
        $Readme += "  * Description: $ModuleDescription"
    }
    #$Readme += $Spacer
    #>

    $Readme += "$Spacer`This module contains $CommandsCount PowerShell functions or commands"
    $Readme += "$Spacer`All functions should have reasonably detailed comment-based help, accessible via `Get-Help` ... e.g., "
    $Readme += '  * `Get-Help Do-Something`'
    $Readme += '  * `Get-Help Do-Something -Examples`'
    $Readme += '  * `Get-Help Do-Something -ShowWindow`'

    # Prerequisites
    $Readme += "$Spacer## Prerequisites"
    $Readme += "$Spacer`Computers must:"
    $Readme += "$Spacer  * be running PowerShell $PSVersionRequired or later"
    If ($ReqModules) {
        $Readme += "$Spacer  * have module(s) $ReqModules installed"
    }

    # Installation
    $Readme += "$Spacer## Installation"
    $Readme += "$Spacer`Clone/copy entire module directory into a valid PSModules folder on your computer and run ``Import-Module $($ModuleObj.Name)``"

    # Notes
    $Readme += "$Spacer## Notes"
    $Readme += "$Spacer`_All code should be presumed to be written by $Author unless otherwise specified (see the context help within each function for more information, including credits)._"
    
    # Commands
    $Readme += "$Spacer## Commands"
    $Readme += "$Spacer|**Command**|**$LabelName**|"
    $Readme += "|---|---|"

    # Get commands
    Foreach ($Command in ($Commands| Sort)) {

        Write-Verbose $Command.Name
        Try {
            If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                    $Host.UI.WriteErrorLine("No '$LabelName' or '$Alt' help found for $($Cmd.Name)")
                }
            }
            If ($Output) {
                $Readme += "|**$($Command.Name)**|$($Output -replace("`n","<br/>"))|"
            }
        }
        Catch {
            $Msg = "Can't get/find help for $($Command.Name)"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
        }
    } #end foreach function/command

    # Output to file
    $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md"
    $Msg = "Save file as $ReadmeFilePath"
    Write-Verbose $Msg
    If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
        $Host.UI.WriteLine()
        $Readme | Out-File -FilePath $ReadmeFilePath -Force @StdParams
        $Msg = "Operation completed successfuly`n"
        Write-Verbose $Msg
        Get-Content $ReadmeFilePath
    }
    Else {
        $Msg = "Operation cancelled by user (if you chose -Force you will probably want to restore your backup file from $("$Env:Temp\$NewName")"
        Write-Verbose $Msg
    }
   
}
End {}
} #end New-PKGitReadmeFile
