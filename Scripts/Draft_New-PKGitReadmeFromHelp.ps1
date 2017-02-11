#Requires -Version 3
function New-PKGitReadmeFromHelp {
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
    Name    : Function_New-PKGitReadmeFromHelp.ps1
    Version : 1.0.0
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEPEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0 - 2017-02-10 - Adapted Mathieu Buisson's original module script (see link)

.LINK
    https://github.com/MathieuBuisson/Powershell-Utility/tree/master/ReadmeFromHelp


.PARAMETER ModuleFile
    To specify the path to the module file you wish to create a README file for.

.EXAMPLE
    New-ReadmeFromHelp -ModuleFile ".\Example.psm1"

    Creates a README file for the script module Example.psm1, in the same directory.
#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]

Param(
    [Parameter(
        ParameterSetName = "File",
        Mandatory=$True,
        Position=0,
        HelpMessage = "Full path to module (e.g., c:\users\jbloggs\modules\modulename.ps1"
    )]
    [validatescript({ Test-Path $_ })]
    [string]$ModuleFile,

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
        Mandatory = $False,
        HelpMessage = "Force overwrite if readme.md already exists"
    )]
    [Switch]$Force

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "1.0.0"

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

}
Process {

    Switch($Source) {
        ModuleName {
            If (-not ($Module = Get-Module -Name $ModuleName @StdParams)) {
                If ($Module = Get-Module -Name $Modulename -ListAvailable @StdParams | Import-Module -Force @StdParams) {
                    $Msg = "Found and imported module $($Module), version $($Module.Version)"
                }
                Else {
                    $Msg = "Module '$ModuleName' not found in any PSModule directory on $Env:ComputerName"
                    $Host.Ui.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }
            Else {
                $Msg = "Found module $($Module), version $($Module.Version)"
                $FullModulePath = $Module.Path
                $ParentDirectory = (Get-Item $FullModulePath @StdParams).DirectoryName

            }
            Write-Verbose $Msg
        }
        ModuleFile {
            Try {
                If ($Module = Import-Module $ModuleFile -Force @StdParams) {
                    $Msg = "Found module $($Module), version $($Module.Version)"
                    $Msg = "Found module $($Module), version $($Module.Version)"
                    $FullModulePath = $Module.Path
                    $ParentDirectory = (Get-Item $FullModulePath @StdParams).DirectoryName
                    Write-Verbose $Msg
                }
                Else {
                    $Msg = "Can't import module"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }
            Catch {
                $Msg = "Can't import module"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            }

        }
    }

    # Check for existing file
    If ($Exists = Get-ChildItem -Path $ParentDirectory -Filter 'readme.md') {
        $Found = New-Object PSObject -Property ([ordered]@{
            Name       = $Exists.Name
            Path       = $Exists.FullName
            SizeKB     = ($Exists.Length / 1Kb).ToString("00.00")
            ReadOnly   = $Exists.IsReadOnly
            CreateDate = $Exists.CreationTime
            LastWrite  = $Exists.LastWriteTime
        })
        If (-not $Force.IsPresent) {
            $Msg = "Found existing readme.md; -Force not specified"
            $Host.UI.WriteErrorLine("ERROR: $Msg")
            Write-Output $Found
            Break
        }
        Else {
            $Msg = "Found existing readme.md"
            Write-Verbose $Msg
            Write-Output $Found
        }
    }

    # Check for Requires statements
    $FirstLine = $Module.Definition -split "`n" | Select-Object -First 1
    If ($FirstLine -like "#Requires*") {
        $PSVersionRequired = $($FirstLine -split " " | Select-Object -Last 1)
    }

    # Preparing a variable which will store strings making up the content of the README file
    $Readme = @()

    #region Module description
    $Commands = Get-Command -Module $Module @StdParams
    $Msg = "Commands in the module : $($Commands.Name -join(", "))"
    Write-Verbose $Msg

    $Readme += "##Description :"
    $Readme += "`n`r"

    $CommandsCount = $($Commands.Count)
    If ($CommandsCount -gt 1) {

        # At the end of the following string, there are 2 spaces
        # This is how we do a new line in the same paragraph in GitHub flavored markdown
        $Readme += "This module contains $CommandsCount cmdlets :  "
        Foreach ($Command in $Commands) {
            $Readme += "**$($Command.Name)**  "
        }            
    }
    Else {
        $Readme += "This module contains one cmdlet : **$($Commands.Name)**.  "
    }
    If ($PSVersionRequired) {
        $Readme += "It requires PowerShell version $PSVersionRequired (or later)."
    }
    $Readme += "`n`r"
    #endregion Module description

    Foreach ($Command in $Commands) {
        Write-Verbose $Command.Name
        
        Try {
            
            $HelpInfo = Get-Help $Command.Name -Full @StdParams

            $Name = $Command.Name
            $Readme += "##$Name :"
            $Readme += "`n`r"
            $Readme += $HelpInfo.description

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

    $Msg = "Remove module $($Module.Name)"
    Write-Verbose $Msg
    If ($PScmdlet.ShouldProcess($Env:ComputerName,$Msg)) {
        Try {
            $Null = Remove-Module $Module -Confirm:$False @StdParams
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