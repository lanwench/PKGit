#Requires -Version 5.1
Function New-PKGitReadmeFile {
<#
.SYNOPSIS
    Generates a github markdown README.md file from the comment-based help in a PowerShell module, including module & function details (and versions if found)

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
    Version : 06.00
    History:

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **

        v01.00	2017-02-10	Adapted Mathieu Buisson's original module script (see link)
        v01.01	2017-02-10	Changed formatting output/headers
        v02.00	2017-05-16	Renamed from New-ToolboxReadmeFromHelp, added rename for old file found
        v02.01	2017-08-22	Added LabelName parameter, to choose Synopsis or Description for function content
        v02.02	2017-10-30	Added 'Description', minor cosmetic changes
        v03.00	2019-07-22	General updates, help/examples
        v04.00	2021-04-19	Added parameter to include function version, if found (may not always work!)
        v04.01	2021-04-26	Changed function version check to opt-out, cosmetic changes
        v05.00	2021-05-24	Simplified, removed custom console output functions, removed Quiet, added switch to output file content rather than defaulting to same
        v05.01	2021-06-21	Fixed erroneous rename
        v05.02	2022-04-28	Fixed function version check (was generating errors if not found)
        v05.03	2022-09-19	Minor updates to author/description, cleanup
        v06.00	2026-05-28	PS7/macOS compatibility fixes; cross-platform path handling; bumped #Requires to 5.1; dropped build component from version format; removed unused inner function; multiline regex for version extraction from Begin block
.LINK
    https://github.com/MathieuBuisson/Powershell-Utility/tree/master/ReadmeFromHelp

.LINK
    https://help.github.com/en/categories/writing-on-github

.PARAMETER ModuleName
    PowerShell module object or name (if not providing abolute path to .psm1 file)

.PARAMETER ModuleFile
    Absolute path to module's .psm1 file (e.g., c:\users\jbloggs\modules\modulename.psm1) if not providing module name

.PARAMETER Description
    Text to add after boilerplate; e.g., 'This module contains x PowerShell function(s) and tools' in the About section (defaults to description in module's .psd1 file, if found)

.PARAMETER LabelName
    Label to use: Synopsis or Description (default is Synopsis)

.PARAMETER Author
    Full name of author (by default will use Author property from .psd1 if populated)

.PARAMETER SkipVersionCheck
    Don't search function content for a version number to add to table

.PARAMETER Force
    Force overwrite if README.md already exists (will rename old file and move to user's temp directory)

.PARAMETER DisplayFileContent
    If new README.md file created, output content to console (default is to output new file object)

.EXAMPLE
    PS> New-PKGitReadmeFile -ModuleName Toolbox -Author "Jane Blogs" -Force -Verbose

        VERBOSE: PSBoundParameters:

        Key                Value
        ---                -----
        ModuleName         Toolbox
        Force              True
        Verbose            True
        ModuleFile
        ModuleDescription
        LabelName          Synopsis
        Author             Jane Blogs
        SkipVersionCheck   False
        DisplayFileContent False
        ParameterSetName   Module
        PipelineInput      False
        ScriptName         New-PKGitReadmeFile
        ScriptVersion      06.01

        VERBOSE: [BEGIN: New-PKGitReadmeFile] Create new Github-flavored markdown README.md file for PowerShell module 'Toolbox' (look for function versions)
        VERBOSE: [Toolbox] Get or verify module object
        VERBOSE: [Toolbox] Found module 'Toolbox' version 1.18.0 in /Users/jbloggs/repos/Toolbox
        VERBOSE: [Toolbox] Look for existing README.md file
        VERBOSE: [Toolbox] Existing 'README.md' file found; -Force specified
        VERBOSE:

        Name       : README.md
        Path       : /Users/jbloggs/repos/Toolbox/README.md
        LineCount  : 35
        SizeKB     : 04.38
        ReadOnly   : False
        CreateDate : 2021-04-22 5:31:39 PM
        LastWrite  : 2026-05-28 5:49:17 PM

        VERBOSE: [Toolbox] Get general module information
        VERBOSE: [Toolbox] Got module description
        VERBOSE: [Toolbox] Found author name 'Jane Blogs' in module
        VERBOSE: [Toolbox] Found Requires statements and/or PowerShell version requirements
        VERBOSE: [Toolbox] Found required modules list
        VERBOSE: [Toolbox] Create README.md content
        VERBOSE: [Toolbox] Found 4 functions in module
        VERBOSE: * Get-ToolboxEmail
        VERBOSE: * Get-SQLServices
        VERBOSE: * Get-WorkingFiles
        VERBOSE: * Invoke-CustomCommand
        VERBOSE: * Test-Repo
        VERBOSE: [Toolbox] Successfully created README.md content for module
        VERBOSE: [Toolbox] Rename and move existing README.md file
        VERBOSE: [Toolbox] Moved '/Users/jbloggs/repos/Toolbox/README.md' to /tmp/Toolbox_2026-05-28_05-54_backup_readme.md
        VERBOSE: [Toolbox] Save output to new README.md file

            Directory: /Users/jbloggs/repos/Toolbox

            Mode               LastWriteTime    Length Name
            ----               -------------    ------ ----
            -rw-r--r--  2026-05-28   5:54 PM    4484 README.md

        VERBOSE: [END: New-PKGitReadmeFile] Script operation is complete

.EXAMPLE
    PS> New-PKGitReadmeFile -ModuleName LabUtilities -Author "Jane Blogs" -Force

        WARNING: Author name 'Jane Blogs' specified for README.md will conflict with 'jbloggs-test' specified in module
        WARNING: No native module description found; -Description not specified

            Directory: /Users/jbloggs/repos/LabUtilities

            Mode                 LastWriteTime         Length Name
            ----                 -------------         ------ ----
            -rw-r--r--  2026-05-28   6:01 PM           2046 README.md   

.EXAMPLE
    PS> New-PKGitReadmeFile -ModuleName Kittens -Description "Testing new module process" -Force -DisplayFileContent

        # Module kittens

        ## About
        |||
        |---|---|
        |**Name** |kittens|
        |**Author** |jbloggs|
        |**Type** |Script|
        |**Version** |01.00|
        |**Description**|Testing new module process|
        |**Date**|README.md file generated on Tuesday, May 28, 2026 6:04:00 PM|

        This module contains 2 PowerShell functions or commands

        All functions should have reasonably detailed comment-based help, accessible via Get-Help ... e.g.,
          * `Get-Help Do-Something`
          * `Get-Help Do-Something -Examples`
          * `Get-Help Do-Something -ShowWindow`

        ## Prerequisites

        Computers must:

          * be running PowerShell 5.1 or later

        ## Installation

        Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module kittens`

        ## Notes

        _All code should be presumed to be written by jbloggs unless otherwise specified (see the context help within each function for more information, including credits)._

        _Changelogs are generally found within individual functions, not per module._

        ## Commands

        |**Command**|**Version**|**Synopsis**|
        |---|---|---|
        |<span style="white-space: nowrap">**Get-Email**</span>|01.01|Returns the current user's Mail attribute from AD, if present|
        |<span style="white-space: nowrap">**Get-SQLSvc**</span>|01.00|Returns all SQL services using remote WMI query|


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
    [validatescript({If ((Test-Path $_) -and ($_ -match "\.psm*")) {$True}})]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleFile,

    [Parameter(
        HelpMessage = "Text to add after boilerplate; e.g., 'This module contains x PowerShell function(s) and tools' in the About section (defaults to description in module's .psd1 file, if found)"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("ModuleDescription")]
    [string]$Description,

    [Parameter(
        HelpMessage = "Help content to provide in markdown table for each function, Synopsis or Description (default is Synopsis; keep content short for readability)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Synopsis","Description")]
    [string]$LabelName = "Synopsis",

    [Parameter(
        HelpMessage = "Full name of author (by default, uses will use Author property from .psd1 file)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Author,

    [Parameter(
        HelpMessage = "Don't search for function version numbers"
    )]
    [Switch]$SkipVersionCheck,

    [Parameter(
        HelpMessage = "Force overwrite if README.md already exists, renaming/moving old file to user's temp directory"
    )]
    [Switch]$Force,

    [Parameter(
        HelpMessage = "If new README.md file is created, also display markdown content to console"
    )]
    [Switch]$DisplayFileContent
)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "06.01"

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $ScriptName = $MyInvocation.MyCommand.Name
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} | 
        Where-Object {Test-Path variable:$_}| Foreach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    $ComputerName = [System.Net.Dns]::GetHostName()

    #region Inner functions

    # Function to look through a function definition and grab the version
    Function _GetVersion(){
        Param([Parameter(ValueFromPipeline,Mandatory)]$Command)
        Begin{}
        Process{
            Try {
                # Extract version from Begin block; ignores build numbers (e.g., "01.00.0000" → "01.00", "06.00" → "06.00")
                $def = Get-Command $Command -all | Select-Object -ExpandProperty Definition
                $pattern = 'Begin\s*\{(.*?)\[version\]\$Version\s*=\s*"(\d+\.\d+)(?:\.\d+)*"'
                $match = [regex]::Match($def, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if ($match.Success) {
                    $VersionString = $match.Groups[2].Value
                    $Parts = $VersionString -split '\.'
                    "{0:D2}.{1:D2}" -f [int]$Parts[0], [int]$Parts[1]
                }
            }
            Catch {}
        }
    } #end _GetVersion

    # Function to get a module path
    Function _GetModulePath{
        [Cmdletbinding()]
        Param([Parameter(Position=0,ValueFromPipeline,Mandatory)]$Name)
        Begin{}
        Process{
            Try {
                $Msg = "Get module path"
                Write-Verbose "[$Name] $Msg"
                $File = Get-Module -ListAvailable $Name -Verbose:$False | Select-Object -ExpandProperty Path
                $File | Split-Path -Parent
            }
            Catch {}
        }
    } #end _GetModulePath

    #endregion Inner functions

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
    If (-not $SkipVersionCheck.IsPresent) {$Activity += " (look for versions within functions)"}
    $Msg = "[BEGIN: $Scriptname] $Activity" 
    Write-Verbose $Msg

}
Process {
    
    # Switch
    [switch]$Continue = $False

    # Check for module
    $Msg = "Getting or verifying module object" 
    Write-Verbose "[$ModuleName] $Msg"
    Write-Progress -Activity $Activity -CurrentOperation $Msg
    Switch($Source) {
        Module {
            Try {
                If (-not ($ModuleObj = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue -Verbose:$False)) {
                    If ($ModuleObj = Get-Module -Name $Modulename -ListAvailable -ErrorAction "Stop" -Verbose:$False | 
                        Import-Module -Force -PassThru -ErrorAction "Stop" -Verbose:$False) {
                            $ParentDirectory = $ModuleObj.ModuleBase
                            $Msg = "Found and imported module $($ModuleObj.Name), version $($ModuleObj.Version)"
                            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                            $Continue = $True   
                        }
                    Else {
                        $Msg = "Module '$ModuleName' not found in any PSModule directory on $Env:ComputerName"
                        Write-Warning "[$($ModuleObj.Name)] $Msg" 
                    }
                }
                Else {
                    $ParentDirectory = $ModuleObj.ModuleBase
                    $Msg = "Found module '$($ModuleObj.Name)' version $($ModuleObj.Version) in $ParentDirectory"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    $Continue = $True
                }
            }
            Catch {
                $Msg = "Failed to get or import module '$ModuleName'"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
            }
        }
        File {
            Try {
                If ($ModuleObj = Import-Module $ModuleFile -Force -ErrorAction "Stop" -Verbose:$False) {
                    $FullModulePath = $Module.Path
                    $ParentDirectory = (Get-Item $FullModulePath -ErrorAction "Stop" -Verbose:$False).DirectoryName
                    $Msg = "Found module $($ModuleObj.Name) version $($ModuleObj.Version), in '$($ModuleObj.Path | Split-Path -Parent)'"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    $Continue = $True
                }
                Else {
                    $Msg = "Failed to import module '$ModuleFile'"
                    Write-Warning "[$($ModuleObj.Name)] $Msg" 
                }
            }
            Catch {
                $Msg = "Failed to import module '$ModuleFile'"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
            }
        }
    } #end switch for parameterset

    # Check for existing file
    If ($Continue.IsPresent) {
        
        $Msg = "Looking for existing README.md file" 
        Write-Verbose "[$($ModuleObj.Name)] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg
    
        # Reset flag
        $Continue = $False

        # Check for existing file
        If ($ExistingFile = Get-ChildItem -Path $ParentDirectory -Filter 'readme.md') {
            
            If (-not $Force.IsPresent) {
                $Msg = "Existing '$($ExistingFile.Name)' file found; -Force not specified"
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
            }
            Else {
                $Msg = "Existing '$($ExistingFile.Name)' file found; -Force specified"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
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
            Write-Verbose ($Found | Out-String)

        } #end if file already exists
        Else {
            $Msg = "No existing README.md file found"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            $Continue = $True
        }
    } #end get content

    # Get the author, etc
    If ($Continue.IsPresent) {
        
        # reset flag
        $Continue = $False
        $Msg = "Getting general module information"
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 

        If ($ModuleObj.Author) {

            If ($CurrentParams.Author) {
                $Msg = "Overwrite module author: '$($ModuleObj.Author)'`n with '$($CurrentParams.Author)'" 
                Write-Warning "[$($ModuleObj.Name)] $Msg`?" 
                If ($PSCmdlet.ShouldProcess($ModuleObj.Name,$Msg)) {
                    $Continue = $True
                    $Msg = "Overwriting native module author name in readme.md"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                }
                Else {
                    $Msg = "Operation cancelled by user"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                }
            }
            Else {
                $Author = $ModuleObj.Author
                $Continue = $True
            }
        } # end if module has an author
        Else {
            If ($CurrentParams.Author) {
                $Msg = "No author name found in module; -Author specified"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                $Continue = $True
            }
            Else {
                $Msg = "No author name found in module; please re-run with -Author"
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
            }
        } # end if module has no author
    }

    # Get the description
    If ($Continue.IsPresent) {

        If ($ModuleObj.Description) {   
            If ($CurrentParams.Description) {
                $Continue = $False
                $Msg = "Overwrite module description: '$($ModuleObj.Description)'`n with '$($CurrentParams.ModuleDescription)'" 
                Write-Warning "[$($ModuleObj.Name)] $Msg`?" 
                If ($PSCmdlet.ShouldProcess($ModuleObj.Name,$Msg)) {
                    $Continue = $True
                    $Msg = "Overwriting native module description in readme.md"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                }
                Else {
                    $Msg = "Operation cancelled by user"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                }
            }
            Else {$ModuleDescription = $ModuleObj.Description}
        } # end if module has a description
        Else {
            If ($CurrentParams.Description) {
                $Msg = "No description found in module; using value from -Description parameter"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            }
            Else {
                $Msg = "No description found in  module; please run again with -Description"
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
                $Continue = $False
            }
        } #end if module has no description
    } # end get or set description

    # Check dependencies & modules
    If ($Continue.IsPresent) {
        $Continue = $False
        $FirstLine = $ModuleObj.Definition -split "`n" | Select-Object -First 1
        If ($FirstLine -like "#Requires*") {
            $PSVersionRequired = $($FirstLine -split " " | Select-Object -Last 1)
        }
        Else {
            If ($ModuleObj.PowerShellVersion) {
                $PSVersionRequired = $ModuleObj.PowerShellVersion.ToString()
            }
        }
        If ([array]$ReqModules = $ModuleObj.RequiredModules.Name) {
            $Continue = $True
            $Msg = "Found required modules list"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            $Continue = $True
        }
        Else {
            $Continue = $True
        }
    } #end check dependencies

    # Create content for new file
    If ($Continue.IsPresent) {

        $Msg = "Creating README.md content" 
        Write-Verbose "[$($ModuleObj.Name)] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg
    
        # Initialize variable to which we will add lines of strings
        $Readme = @()

        #region Module description
        $Commands = @()
        $Commands = $ModuleObj.ExportedFunctions.Values
        $CommandsCount = $($Commands.Count)
        $Msg = "Found $Commandscount functions in module" 
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 

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
            Foreach ($Command in ($Commands | Sort-Object -Property Name)) {

                Write-Verbose "[$($ModuleObj.Name)] * $($Command.Name)"
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command.Name -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command.Name -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            Write-Warning "[$($ModuleObj.Name)] $Msg"
                        }
                    }
                    If ($CommandHelp) {
                        $Readme += "|<span style=`"white-space: nowrap`">**$($Command.Name)**</span>|$($CommandHelp -replace("`n","<br/>"))|"
                    }
                }
                Catch {
                    $Msg = "Failed to get comment-based help for '$($Command.Name)'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    Write-Warning "[$($ModuleObj.Name)] $Msg"
                }
            } #end foreach function/command
        } # end if we won't look for versions within functions

        Else {
            # Commands
            $Readme += "$Spacer## Commands"
            $Readme += "$Spacer|**Command**|**Version**|**$LabelName**|"
            $Readme += "|---|---|---|"

            # Loop through all commands in alphabetical order
            Foreach ($Command in ($Commands | Sort-Object -Property Name)) {
                Write-Verbose "[$($ModuleObj.Name)] * $($Command.Name)"
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command.Name -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command.Name -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            Write-Warning "[$($ModuleObj.Name)] $Msg"
                        }
                    }
                    If ($CommandHelp) {
                        If (-not ($VerInfo = _GetVersion -Command $Command -ErrorAction SilentlyContinue)) {$VerInfo = "-"}
                        $Readme += "|<span style=`"white-space: nowrap`">**$($Command.Name)**</span>|$VerInfo|$($CommandHelp -replace("`n","<br/>"))|"
                    }
                }
                Catch {
                    $Msg = "Failed to get comment-based help for '$($Command.Name)'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    Write-Warning "[$($ModuleObj.Name)] $Msg" 
                }
            } #end foreach function/command
        }

        $Msg = "Successfully created README.md content for module"
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 
        $Continue = $True

        # Move existing file, if one exists
        If ($ExistingFile) {
            
            $Msg = "Renaming and moving existing README.md file"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            Write-Progress -Activity $Activity -CurrentOperation $Msg
    
            # Reset flag
            $Continue = $False        
            
            $NewName = "$($ModuleObj.Name)_$(Get-Date -f yyyy-MM-dd_hh-mm)_backup_readme.md"
            $NewPath = [System.IO.Path]::GetTempPath()
            $ConfirmMsg = "`n`n`tMove existing file:`n`t`t$($ExistingFile.FullName)`n`tto new file:`n`t`t$(Join-Path $NewPath $NewName)`n`n"

            If ($PScmdlet.ShouldProcess($ComputerName,$ConfirmMsg)) {
                Try {
                    $Newfile = $ExistingFile | Rename-Item -NewName $NewName -Force -Confirm:$False -PassThru -ErrorAction "Stop" -Verbose:$False |
                        Move-Item -Destination (Join-Path $NewPath $NewName) -Force -Passthru -Confirm:$False -ErrorAction "Stop" -Verbose:$False
                    $Msg = "Moved '$($ExistingFile.FullName)' to $($NewFile.FullName)"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    $Continue = $True
                }
                Catch {
                    $Msg = "Failed to rename/move file '$($ExistingFile.FullName)' to '$NewPath\$NewName'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    Write-Warning "[$($ModuleObj.Name)] $Msg" 
                }
            }
            Else {
                $Msg = "Operation cancelled by user"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            }
        } #end if an existing file needs to be moved

        # Output to file
        If ($Continue.IsPresent) {

            $Msg = "Saving output to new README.md file"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md" -ErrorAction "Stop" -Verbose:$False
            
            $ConfirmMsg = "`n`n`t$Msg`n`n"
            If ($PScmdlet.ShouldProcess($ReadmeFilePath,$ConfirmMsg)) {
                $Readme | Out-File -FilePath $ReadmeFilePath -Force -ErrorAction "Stop" -Verbose:$False
                If ($DisplayFileContent.IsPresent) {
                    Get-Content $ReadmeFilePath
                }
                Else {
                    Get-Item $ReadmeFilePath
                }
            }
            Else {
                $Msg = "Operation cancelled by user"
                If ($Force.IsPresent -and ($NewFile)) {
                    
                    $Msg = "; restoring original README.md file"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    $ConfirmMsg = "`n`n`t$Msg`n`n"
                    If ($PScmdlet.ShouldProcess($ExistingFile.Name,$ConfirmMsg)) {
                        Try {
                            $RestoreFile = $NewFile | Rename-Item -NewName $ExistingFile.Name -Force -Confirm:$False -PassThru -ErrorAction "Stop" -Verbose:$False |
                                Move-Item -Destination $ExistingFile.FullName -Force -Passthru -Confirm:$False -ErrorAction "Stop" -Verbose:$False
                            $Msg = "Moved '$($NewFile.FullName)' to $($RestoreFile.FullName)"
                            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                            $Continue = $True
                        }
                        Catch {
                            $Msg = "Failed to restore '$($NewFile.FullName)' to $($RestoreFile.FullName)"
                            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                            Write-Warning "[$($ModuleObj.Name)] $Msg" 
                        }
                    }
                    Else {
                        $Msg = "Operation cancelled by user"
                        Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    }
                }
                Else {
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                }
            } # end if cancel
        } # end if continue
    }
}
End {
    
    Write-Progress -Activity $Activity -Completed
    $Msg = "[END: $ScriptName] Script ran successfully"
    Write-Verbose $Msg
}
} #end New-PKGitReadmeFile
