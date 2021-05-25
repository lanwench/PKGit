#Requires -Version 4
function New-PKGitReadmeFile {
<#
.SYNOPSIS
    Generates a github markdown README.md file from the comment-based help contained in the specified PowerShell module file

.DESCRIPTION
    Generates a github markdown README.md file from the comment-based help contained in the specified PowerShell module file
    Allows for a module name or absolute path to a .psm1 file
    Unless otherwise specified, looks for [version]$Version value in function content and adds a Version column to the command table
    Creates README.md file in the same directory as the module file
    Unless -Force is specified, will not overwrite existing file
    If -Force is specified will copy existing file to a datestamped file in the user's temp directory
    It uses GitHub Flavored Markdown, so the GitHub website will format it nicely.
    Works with any PowerShell module (script or compiled) and any help (comment-based or XML-based) as long as it is accessible via Get-Help

.NOTES 
    Name    : Function_New-PKGitReadmeFile.ps1
    Created : 2017-02-10
    Author  : Paula Kingsley
    Version : 04.01.0000
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0      - 2017-02-10 - Adapted Mathieu Buisson's original module script (see link)
        v1.1.0      - 2017-02-10 - Changed formatting output/headers
        v2.0.0      - 2017-05-16 - Renamed from New-PKGitReadmeFromHelp, added rename for old file found
        v2.1.0      - 2017-08-22 - Added LabelName parameter, to choose Synopsis or Description for function content
        v02.02.0000 - 2017-10-30 - Added 'Description', minor cosmetic changes
        v03.00.0000 - 2019-07-22 - General updates, help/examples
        v04.00.0000 - 2021-04-19 - Added parameter to include function version, if found (may not always work!)
        v04.01.0000 - 2021-04-26 - Changed function version check to opt-out, cosmetic changes

.LINK
    https://github.com/MathieuBuisson/Powershell-Utility/tree/master/ReadmeFromHelp

.LINK
    https://help.github.com/en/categories/writing-on-github

.PARAMETER ModuleName
    PowerShell module object or name (if not providing abolute path to .psm1 file)

.PARAMETER ModuleFile
    Absolute path to module's .psm1 file (e.g., c:\users\jbloggs\modules\modulename.psm1) if not providing module name

.PARAMETER ModuleDescription
    Text to add after boilerplate; e.g., 'This module contains x PowerShell function(s) and tools' in the About section (defaults to description in module's .psd1 file, if found)

.PARAMETER LabelName
    Label to use: Synopsis or Description (default is Synopsis)

.PARAMETER Author
    Full name of author (by default will use Author property from .psd1 if populated)

.PARAMETER SkipVersionCheck
    Don't search function content for a version number to add to table

.PARAMETER Force
    Force overwrite if README.md already exists (will rename old file and move to user's temp directory)

.PARAMETER Quiet
    Suppress non-verbose console output

.EXAMPLE
    PS C:\> 

.EXAMPLE
    PS C:\> 



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
    [Alias("Module","Name")]
    [object]$ModuleName,

    [Parameter(
        ParameterSetName = "File",
        Mandatory = $True,
        Position = 0,
        HelpMessage = "Full path to module's .psm1 file (e.g., c:\users\jbloggs\modules\modulename.psm1)"
    )]
    [validatescript({
         If ((Test-Path $_) -and ($_ -match ".psm*")) {$True}
    })]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleFile,

    [Parameter(
        HelpMessage = "Text to add after boilerplate; e.g., 'This module contains x PowerShell function(s) and tools' in the About section (defaults to description in module's .psd1 file, if found)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleDescription,

    [Parameter(
        HelpMessage = "Label to use: Synopsis or Description (default is Synopsis)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Synopsis","Description")]
    [string]$LabelName = "Synopsis",

    [Parameter(
        HelpMessage = "Full name of author (by default will use Author property from .psd1 if populated)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Author,

    [Parameter(
        HelpMessage = "Don't search function content for a version number to add to table"
    )]
    [Switch]$SkipVersionCheck,

    [Parameter(
        HelpMessage = "Force overwrite if README.md already exists (will rename old file and move to user's temp directory)"
    )]
    [Switch]$Force,

    [Parameter(
        HelpMessage = "Suppress non-verbose console output"
    )]
    [Alias("SuppressConsoleOutput")]
    [Switch] $Quiet
)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "04.01.0000"

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $ScriptName = $MyInvocation.MyCommand.Name
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    #region Functions

    # Function to write a console message or a verbose message
    Function Script:Write-MessageInfo {
        Param([Parameter(ValueFromPipeline)]$Message,$FGColor,[switch]$Title)
        $BGColor = $host.UI.RawUI.BackgroundColor
        If (-not $Quiet.IsPresent) {
            If ($Title.IsPresent) {$Message = "`n$Message`n"}
            $Host.UI.WriteLine($FGColor,$BGColor,"$Message")
        }
        Else {Write-Verbose "$Message"}
    }

    # Function to write an error as a string (no stacktrace)
    Function Script:Write-MessageError {
        [CmdletBinding()]
        Param([Parameter(ValueFromPipeline)]$Message)
        $Host.UI.WriteErrorLine("$Message")
    }

    # Function to look through a function definition and grab the version 
    Function Script:GetVersion(){
        Param([Parameter(ValueFromPipeline,Mandatory)]$Command)
        Begin{}
        Process{
        $VersionLine = ((Get-Command $Command -all | Select -ExpandProperty Definition) -split("`n") | 
            Select-String '[version]$Version' -SimpleMatch).ToString().Trim()
        [regex]::Matches($VersionLine, '(?<=\").+?(?=\")').Value
        }
    }
    #endregion Functions

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
    $Activity = "Create new Github-flavored markdown README.md file for PowerShell module '$ModuleName'"
    If (-not $SkipVersionCheck.IsPresent) {$Activity += " (attempt to look up function versions)"}
    $Msg = "BEGIN: $Activity"
    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Yellow -Title
}
Process {
    
    # Switch
    [switch]$Continue = $False

    # Check for module
    $Msg = "Get or verify module object" 
    "[$ModuleName] $Msg" | Write-MessageInfo -FGColor "White"   
    Write-Progress -Activity $Activity -CurrentOperation $Msg
    Switch($Source) {
        Module {
            Try {
                If (-not ($ModuleObj = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue -Verbose:$False)) {
                    If ($ModuleObj = Get-Module -Name $Modulename -ListAvailable @StdParams | Import-Module -Force @StdParams) {
                        $ParentDirectory = $ModuleObj.ModuleBase
                        $Msg = "Found and imported module $($ModuleObj.Name), version $($ModuleObj.Version)"
                        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                        $Continue = $True   
                    }
                    Else {
                        $Msg = "Module '$ModuleName' not found in any PSModule directory on $Env:ComputerName"
                        "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                    }
                }
                Else {
                    $ParentDirectory = $ModuleObj.ModuleBase
                    $Msg = "Found module '$($ModuleObj.Name)' version $($ModuleObj.Version) in $ParentDirectory"
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                    $Continue = $True
                }
            }
            Catch {
                $Msg = "Failed to get or import module '$ModuleName'"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                "[$($ModuleObj.Name)] $Msg" | Write-MessageError
            }
        }
        File {
            Try {
                If ($ModuleObj = Import-Module $ModuleFile -Force @StdParams) {
                    $FullModulePath = $Module.Path
                    $ParentDirectory = (Get-Item $FullModulePath @StdParams).DirectoryName
                    $Msg = "Found module $($ModuleObj.Name) version $($ModuleObj.Version), in '$($ModuleObj.Path | Split-Path -Parent)'"
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                    $Continue = $True
                }
                Else {
                    $Msg = "Failed to import module '$ModuleFile'"
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                }
            }
            Catch {
                $Msg = "Failed to import module '$ModuleFile'"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                "[$($ModuleObj.Name)] $Msg" | Write-MessageError
            }
        }
    }

    # Check for existing file
    If ($Continue.IsPresent) {
        
        $Msg = "Look for existing README.md file" 
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor "White"   
        Write-Progress -Activity $Activity -CurrentOperation $Msg
    
        # Reset flag
        $Continue = $False

        # Check for existing file
        If ($ExistingFile = Get-ChildItem -Path $ParentDirectory -Filter 'readme.md') {
            
            If (-not $Force.IsPresent) {
                $Msg = "Existing '$($ExistingFile.Name)' file found; -Force not specified"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageError
            }
            Else {
                $Msg = "Existing '$($ExistingFile.Name)' file found; -Force specified"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                $Continue = $True
            }

            $Lines = (Get-Content $ExistingFile.FullName | Measure-Object -Line).Lines

            $Found = [PSCustomObject]@{
                Name       = $ExistingFile.Name
                Path       = $ExistingFile.FullName
                LineCount  = $Lines
                SizeKB     = ($ExistingFile.Length / 1Kb).ToString("00.00")
                ReadOnly   = $ExistingFile.IsReadOnly
                CreateDate = $ExistingFile.CreationTime
                LastWrite  = $ExistingFile.LastWriteTime
            }
            ($Found | Out-String) | Write-MessageInfo -FGColor White

        } #end if file already exists
        Else {
            $Msg = "No existing README.md file found"
            "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
            $Continue = $True
        }
    } #end if continue

    # Get the author, etc
    If ($Continue.IsPresent) {
        
        # reset flag
        $Continue = $False

        $Msg = "Get general module information"
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White

        If ($ModuleObj.Author) {
            If ($CurrentParams.Author) {
                $Msg = "Author name '$Author' specified for README.md will conflict with '$($ModuleObj.Author)' specified in module"
                Write-Warning $Msg
            }
            Else {
                $Author = $ModuleObj.author
                $Msg = "Found author name '$Author' in module"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
            }
            $Continue = $True
        }
        Else {
            If ($CurrentParams.Author) {
                $Msg = "No author name specified in module; -Author specified as '$Author'"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                $Continue = $True
            }
            Else {
                $Msg = "No author name specified in module; please re-run with -Author"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageError
            }
        }

        # Get the description
        If ($ModuleObj.Description) {
            If (-not $ModuleDescription) {
                $Msg = "Got module description"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
            }
            Else {
                $Msg = "Parameter -ModuleDescription will override inclusion of native module description"
                Write-Warning $Msg
            }
        }
        Else {
            If (-not $ModuleDescription) {
                $Msg = "No native module description found; -ModuleDescription not specified"
                Write-Warning $Msg
            }
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
        $Msg = "Found Requires statements and/or PowerShell version requirements"
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green

        # Check module dependencies
        If ([array]$ReqModules = $ModuleObj.RequiredModules.Name) {
            If ($ReqModules.Count -gt 1) {$RequiredModules = $($ReqModules -join(", "))}
            Else {$RequiredModules = $ReqModules}
        }
        $Msg = "Found required modules list"
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
    }
        
    # Create readme content
    If ($Continue.IsPresent) { 
        
        $Msg = "Create README.md content" 
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor "White"   
        Write-Progress -Activity $Activity -CurrentOperation $Msg
    
        # Initialize variable to which we will add lines of strings
        $Readme = @()

        #region Module description
        $Commands = @()
        $Commands = Get-Command -Module $ModuleObj @StdParams | Where-Object {$_.CommandType -ne "Alias"}
        $CommandsCount = $($Commands.Count)
        $Msg = "Found $Commandscount functions in module" # :`n * $(($Commands.Name | Sort) -join("`n * "))"
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green

        # Name/Title
        $Readme += "# Module $($ModuleObj.Name)"
    
        # About
        $Readme += "$Spacer## About"
        $Readme += "|||"
        $Readme += "|---|---|"
        $Readme += "|**Name** |$($ModuleObj.Name)|"
        $Readme += "|**Author** |$Author|"
        $Readme += "|**Type** |$($ModuleObj.ModuleType)|"
        $Readme += "|**Version** |$($ModuleObj.Version)|"
        If ($ModuleDescription) {$Readme += "|**Description**|$ModuleDescription|"}
        $Readme += "|**Date**|README.md file generated on $($(Get-Date  -f F))|"

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
        $Readme += "$Spacer`_Changelogs are generally found within individual functions, not per module._"
        
        If ($SkipVersionCheck.IsPresent) {
            # Commands
            $Readme += "$Spacer## Commands"
            $Readme += "$Spacer|**Command**|**$LabelName**|"
            $Readme += "|---|---|"

            # Get commands
            Foreach ($Command in ($Commands| Sort)) {

                "* $($Command.Name)" | Write-MessageInfo -FGColor White
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                        }
                    }
                    If ($CommandHelp) {
                        $Readme += "|**$($Command.Name)**|$($CommandHelp -replace("`n","<br/>"))|"
                    }
                }
                Catch {
                    $Msg = "Failed to get comment-based help for '$($Command.Name)'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                }
            } #end foreach function/command
        }

        Else {
            # Commands
            $Readme += "$Spacer## Commands"
            $Readme += "$Spacer|**Command**|**Version**|**$LabelName**|"
            $Readme += "|---|---|---|"

            # Get commands
            Foreach ($Command in ($Commands| Sort)) {

                "* $($Command.Name)" | Write-MessageInfo -FGColor White
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                        }         
                    }
                    
                    If ($CommandHelp) {
                        If (-not ($VerInfo = GetVersion -Command $Command)) {$VerInfo = "(n/a)"} 
                        $Readme += "|**$($Command.Name)**|$VerInfo|$($CommandHelp -replace("`n","<br/>"))|"
                    }
                }
                Catch {
                    $Msg = "Failed to get comment-based help for '$($Command.Name)'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                }
            } #end foreach function/command
        }

        $Msg = "Successfully created README.md content for module"
        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
        $Continue = $True

        # Move existing file, if one exists
        If ($ExistingFile) {
            
            $Msg = "Rename and move existing README.md file"
            "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
            Write-Progress -Activity $Activity -CurrentOperation $Msg
    
            # Reset flag
            $Continue = $False        
            
            $NewName = "$($ModuleObj.Name)_$(Get-Date -f yyyy-MM-dd_hh-mm)_backup_readme.md"
            $NewPath = $Env:Temp
            $ConfirmMsg = "`n`n`tMove existing file:`n`t`t$($ExistingFile.FullName)`n`tto new file:`n`t`t$NewPath\$NewName`n`n"
            
            If ($PScmdlet.ShouldProcess($Env:ComputerName,$ConfirmMsg)) {
                Try {
                    $Newfile = $ExistingFile | Rename-Item -NewName $NewName -Force -Confirm:$False -PassThru @StdParams |
                        Move-Item -Destination $NewPath\$NewName -Force -Passthru -Confirm:$False @StdParams
                    $Msg = "Moved '$($ExistingFile.FullName)' to $($NewFile.FullName)"
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                    $Continue = $True
                }
                Catch {
                    $Msg = "Failed to rename/move file '$($ExistingFile.FullName)' to '$NewPath\$NewName'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                }
            }
            Else {
                $Msg = "Operation cancelled by user"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
            }
        } #end if an existing file needs to be moved

        # Output to file
        If ($Continue.IsPresent) {

            $Msg = "Save output to new README.md file"
            "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
            $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md" @StdParams
            
            $ConfirmMsg = "`n`n`t$Msg`n`n"
            If ($PScmdlet.ShouldProcess($ReadmeFilePath,$ConfirmMsg)) {
                $Host.UI.WriteLine()
                $Readme | Out-File -FilePath $ReadmeFilePath -Force @StdParams
                $Msg = "Operation completed successfuly`n"
                "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                Get-Content $ReadmeFilePath
            }
            Else {
                $Msg = "Operation cancelled by user"
                If ($Force.IsPresent -and ($NewFile)) {
                    
                    $Msg = "; restore original README.md file"
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
                    $ConfirmMsg = "`n`n`t$Msg`n`n"
                    If ($PScmdlet.ShouldProcess($ExistingFile.Name,$ConfirmMsg)) {
                        
                         Try {
                            $RestoreFile = $NewFile | Rename-Item -NewName $ExistingFile.Name -Force -Confirm:$False -PassThru @StdParams |
                                Move-Item -Destination $ExistingFile.FullName -Force -Passthru -Confirm:$False @StdParams
                            $Msg = "Moved '$($NewFile.FullName)' to $($RestoreFile.FullName)"
                            "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Green
                            $Continue = $True
                        }
                        Catch {
                            $Msg = "Failed to restore '$($NewFile.FullName)' to $($RestoreFile.FullName)"
                            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                            "[$($ModuleObj.Name)] $Msg" | Write-MessageError
                        }
                    }
                    Else {
                        $Msg = "Operation cancelled by user"
                        "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
                    }
                }
                Else {
                    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor White
                }
            } # end if cancel
        } # end if continue
   }
}
End {
    
    Write-Progress -Activity $Activity -Completed
    $Msg = "END  : $Activity"
    "[$($ModuleObj.Name)] $Msg" | Write-MessageInfo -FGColor Yellow -Title
}
} #end New-PKGitReadmeFile
