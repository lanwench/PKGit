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
    Version : 2.0.0
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEPEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0 - 2017-02-10 - Adapted Mathieu Buisson's original module script (see link)
        v1.1.0 - 2017-02-10 - Changed formatting output/headers
        v2.0.0 - 2017-05-16 - Renamed from New-PKGitReadmeFromHelp, added rename for old file found
        v2.1.0 - 2017-08-22 - Added LabelName parameter, to choose Synopsis or Description for function content

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
        HelpMessage = "Name of module (must be in PSModule path)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName,

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
    [string]$ModuleFile,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Label to use (Synopsis or Description)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Synopsis","Description")]
    [string]$LabelName = "Synopsis",

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Full name of author"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Author = "Paula Kingsley",

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Force overwrite if readme.md already exists"
    )]
    [Switch]$Force

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "2.1.0"

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

    # For console output 
    $BGColor = $Host.UI.RawUI.BackgroundColor

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
}
Process {

    Switch($Source) {
        Module {
            If (-not ($ModuleObj = Get-Module -Name $ModuleName @StdParams)) {
                If ($ModuleObj = Get-Module -Name $Modulename -ListAvailable @StdParams | Import-Module -Force @StdParams) {
                    $Msg = "Found and imported module $($ModuleObj.Name), version $($ModuleObj.Version)"
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
                    $Msg = "Found module $($ModuleObj.Name), version $($Module.Version)"
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
            $Msg = "Overwrite existing readme.md file"
            Write-Verbose $Msg
            $NewName = "readme.md.backup$(Get-Date -f yyyy-MM-dd_hh-mm)"
            $Msg = "Rename $($Exists.FullName) to $NewName"
            If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
                Try {
                    $Rename = $Exists | Rename-Item -NewName $NewName -Force -PassThru -Confirm:$False -Verbose:$False
                    $Msg = "Renamed old file to '$NewName'"
                    Write-Verbose $Msg
                }
                Catch {
                    $Msg = "File rename failed"
                    $ErrorDetails = $_.Exception.Message
                    $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                    Break
                }
            }            
        }
    } #end if file already exists

    # Check for Requires statements
    $FirstLine = $ModuleObj.Definition -split "`n" | Select-Object -First 1
    If ($FirstLine -like "#Requires*") {
        $PSVersionRequired = $($FirstLine -split " " | Select-Object -Last 1)
    }
    Else {
        $PSVersionRequired = $ModuleObj.PowerShellVersion.ToString()
    }

    # Preparing a variable which will store strings making up the content of the README file
    $Readme = @()

    #region Module description
    $Commands = Get-Command -Module $ModuleObj @StdParams
    $CommandsCount = $($Commands.Count)

    $Msg = "Commands in this module : $(($Commands.Name | Sort) -join("`n * "))"
    Write-Verbose $Msg

    $Readme += "# Module $($ModuleObj.Name)"
    $Readme += "This file was generated on $(Get-Date  -f F)"

    $Readme += "$Spacer##About"
    $Readme += "$Spacer`Author    : $Author"
    $Readme += "Type      : $($ModuleObj.ModuleType)"
    $Readme += "Version   : $($ModuleObj.Version)"
    #$Readme += $Spacer

    $Readme += "$Spacer`This module contains $CommandsCount PowerShell function(s)"
    $Readme += "_Functions should be presumed to be authored by $Author unless otherwise specified (see the context help within each function for more information, including credits)._"
    #$Readme += $Spacer

    $Readme += "$Spacer`All functions should have reasonably detailed comment-based help, accessible via `Get-Help`, e.g., "
    $Readme += '  * `Get-Help Do-Something`'
    $Readme += '  * `Get-Help Do-Something -Examples`'
    $Readme += '  * `Get-Help Do-Something -ShowWindow`'
    #$Readme += $Spacer

    $Readme += "$Spacer## Prerequisites ##"
    $Readme += "$Spacer`Computers must:"
    $Readme += "  * be running PowerShell $PSVersionRequired or later"
    #$Readme += $Spacer

    $Readme += "$Spacer## Installation ##"
    $Readme += "$Spacer`Clone/copy entire module directory into a valid PSModules folder on your computer and run ``Import-Module $($ModuleObj.Name)``"
    #$Readme += $Spacer

    #endregion Module description

    $Readme += "$Spacer### Modules"
    #$Readme += $Spacer

    Foreach ($Command in ($Commands| Sort)) {

        Write-Verbose $Command.Name
        Try {
            If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                    $Host.UI.WriteErrorLine("No '$LabelName' or '$Alt' help found for $($Cmd.Name)")
                }
            }
            If ($Output) {
                $Readme += "$Spacer#### $($Command.Name) ####"
                $Readme += $Output
            }
        }
        Catch {
            $Msg = "Can't get/find help for $($Command.Name)"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
        }
    } #end foreach function/command

    <#

    Foreach ($Command in $Commands) {
        Write-Verbose $Command.Name
        
        Try {
            
            $HelpInfo = Get-Help $Command.Name -Full @StdParams

            $Name = $Command.Name
            $Readme += "##$Name"
            $Readme += "`n`r"
            $Readme += $HelpInfo.description
            $Readme += "`n`r"

            #region Parameters
            $Readme += "###Parameters :"
            $Readme += "`n`r"

            $CommandParams = $HelpInfo.parameters.parameter
            Write-Verbose "Command parameters for $Name : $($CommandParams.Name -join(", "))"

            Foreach ($CommandParam in $CommandParams) {
                $Readme += "**" + $($CommandParam.Name) + " :** " + $($CommandParam.description.Text) + "  "

                If ( $($CommandParam.defaultValue) ) {
                    $ParamDefault = $($CommandParam.defaultValue).ToString()
                    $Readme += "If not specified, it defaults to $ParamDefault ."
                }
                $Readme += "`n`r"
            }
            #endregion Parameters

            #region Examples
            $Readme += "###Examples :`n`r"
            $Readme += $HelpInfo.examples | Out-String

            #endregion Examples
        }
        Catch {
            $Msg = "Can't get/find help for $($Command.Name)"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
        }
    }

    #>

    # Output to file
    $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md"
    $Msg = "Save file as $ReadmeFilePath"
    Write-Verbose $Msg

    If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
        $Readme | Out-File -FilePath $ReadmeFilePath -Force @StdParams
        $Msg = "Operation completed successfuly"
        Write-Verbose $Msg
        Get-Content $ReadmeFilePath
    }
    Else {
        $Msg = "Operation cancelled by user"
        Write-Verbose $Msg
    }

    $Msg = "Remove module $($ModuleObj.Name)"
    Write-Verbose $Msg
    If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
        Try {
            $Null = Remove-Module $ModuleObj -Confirm:$False @StdParams
            $Msg = "Operation completed successfuly"
            Write-Verbose $Msg
        }
        Catch {
            $Msg = "Can't remove module"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
        }
    }
    Else {
        $Msg = "Operation cancelled by user"
        Write-Verbose $Msg
    }

}
End {}
} #end New-PKGitReadmeFromHelp


<#
# PKGit
"Version 1.0.1

PowerShell module containing various small helper functions for Git for Windows. 

Created for ease of autocomplete, parameter validation, standard verb-noun format consistency, and due to appalling short-term memory 
where git commands are concerned."

#>