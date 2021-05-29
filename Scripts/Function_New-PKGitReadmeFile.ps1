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
    Version : 05.00.0001
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0      - 2017-02-10 - Adapted Mathieu Buisson's original module script (see link)
        v1.1.0      - 2017-02-10 - Changed formatting output/headers
        v2.0.0      - 2017-05-16 - Renamed from New-ToolboxReadmeFromHelp, added rename for old file found
        v2.1.0      - 2017-08-22 - Added LabelName parameter, to choose Synopsis or Description for function content
        v02.02.0000 - 2017-10-30 - Added 'Description', minor cosmetic changes
        v03.00.0000 - 2019-07-22 - General updates, help/examples
        v04.00.0000 - 2021-04-19 - Added parameter to include function version, if found (may not always work!)
        v04.01.0000 - 2021-04-26 - Changed function version check to opt-out, cosmetic changes
        v05.00.0000 - 2021-05-24 - Simplified, removed custom console output functions, removed Quiet, added switch to 
                                   output file content rather than defaulting to same
        v05.00.0001 - 2021-05-28 - Fixed accidental function rename!
         
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

.PARAMETER DisplayFileContent
    If new README.md file created, output content to console (default is to output new file object)

.EXAMPLE
    PS C:\> New-ToolboxReadmeFile -ModuleName Toolbox -Author "Joe Bloggs" -Force -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key                Value              
        ---                -----              
        ModuleName         Toolbox              
        Force              True               
        Verbose            True               
        ModuleFile                            
        ModuleDescription                     
        LabelName          Synopsis           
        Author             Joe Bloggs                   
        SkipVersionCheck   False              
        DisplayFileContent False              
        ParameterSetName   Module             
        PipelineInput      False              
        ScriptName         New-ToolboxReadmeFile
        ScriptVersion      5.0.0              



        VERBOSE: [BEGIN: New-ToolboxReadmeFile] Create new Github-flavored markdown README.md file for PowerShell module 'Toolbox' (attempt to look up function versions)
        VERBOSE: [Toolbox] Get or verify module object
        VERBOSE: [Toolbox] Found module 'Toolbox' version 1.18.0 in C:\Repos\Toolbox
        VERBOSE: [Toolbox] Look for existing README.md file
        VERBOSE: [Toolbox] Existing 'README.md' file found; -Force specified
        VERBOSE: 

        Name       : README.md
        Path       : C:\Repos\Toolbox\README.md
        LineCount  : 35
        SizeKB     : 04.38
        ReadOnly   : False
        CreateDate : 2021-04-22 5:31:39 PM
        LastWrite  : 2021-05-24 5:49:17 PM


        VERBOSE: [Toolbox] Get general module information
        VERBOSE: [Toolbox] Got module description
        VERBOSE: [Toolbox] Found author name 'Joe Bloggs' in module
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
        VERBOSE: [Toolbox] Moved 'C:\Repos\Toolbox\README.md' to C:\Users\jbloggs\AppData\Local\Temp\Toolbox_2021-05-24_05-54_backup_readme.md
        VERBOSE: [Toolbox] Save output to new README.md file

            Directory: C:\Repos\Toolbox

            Mode                 LastWriteTime         Length Name                                                                                                                                                                
            ----                 -------------         ------ ----                                                                                                                                                                
            -a----        2021-05-24   5:54 PM           4484 README.md                                                                                                                                                           
        
        VERBOSE: [END: New-ToolboxReadmeFile] Create new Github-flavored markdown README.md file for PowerShell module 'Toolbox' (attempt to look up function versions)

.EXAMPLE
    PS C:\> New-PKGitReadmeFile -ModuleName LabUtilities -Author "Rainbow Dash" -Force

        WARNING: Author name 'Rainbow Dash' specified for README.md will conflict with 'jbloggs-test' specified in module
        WARNING: No native module description found; -ModuleDescription not specified

            Directory: C:\Repos\Lab\LabUtilities


        Mode                 LastWriteTime         Length Name                                                                                                                                                                
        ----                 -------------         ------ ----                                                                                                                                                                
        -a----        2021-05-24   6:01 PM           2046 README.md   

.EXAMPLE
    PS C:\> New-PKGitReadmeFile -ModuleName Kittens -ModuleDescription "Testing new  module process" -Force -DisplayFileContent

        # Module kittens

        ## About
        |||
        |---|---|
        |**Name** |kittens|
        |**Author** |ksmith|
        |**Type** |Script|
        |**Version** |1.0.0|
        |**Description**|Testing new  module process|
        |**Date**|README.md file generated on Monday, May 24, 2021 6:04:00 PM|

        This module contains 2 PowerShell functions or commands

        All functions should have reasonably detailed comment-based help, accessible via Get-Help ... e.g., 
          * `Get-Help Do-Something`
          * `Get-Help Do-Something -Examples`
          * `Get-Help Do-Something -ShowWindow`

        ## Prerequisites

        Computers must:

          * be running PowerShell 4 or later

        ## Installation

        Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module kittens`

        ## Notes

        _All code should be presumed to be written by ksmith unless otherwise specified (see the context help within each function for more information, including credits)._

        _Changelogs are generally found within individual functions, not per module._

        ## Commands

        |**Command**|**Version**|**Synopsis**|
        |---|---|---|
        |**Get-Email**|01.01.0000|Returns the current user's Mail attribute from AD, if present|
        |**Get-SQLSvc**|01.00.0000|Returns all SQL services using remote WMI query|


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
        HelpMessage = "If new README.md file created, output content to console (default is to output new file object)"
    )]
    [Switch]$DisplayFileContent
)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "05.00.0001"

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

    #region Functions

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
    $Msg = "[BEGIN: $Scriptname] $Activity" 
    Write-Verbose $Msg

}
Process {
    
    # Switch
    [switch]$Continue = $False

    # Check for module
    $Msg = "Get or verify module object" 
    Write-Verbose "[$ModuleName] $Msg"
    Write-Progress -Activity $Activity -CurrentOperation $Msg
    Switch($Source) {
        Module {
            Try {
                If (-not ($ModuleObj = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue -Verbose:$False)) {
                    If ($ModuleObj = Get-Module -Name $Modulename -ListAvailable @StdParams | Import-Module -Force @StdParams) {
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
                If ($ModuleObj = Import-Module $ModuleFile -Force @StdParams) {
                    $FullModulePath = $Module.Path
                    $ParentDirectory = (Get-Item $FullModulePath @StdParams).DirectoryName
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
    }

    # Check for existing file
    If ($Continue.IsPresent) {
        
        $Msg = "Look for existing README.md file" 
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
    } #end if continue

    # Get the author, etc
    If ($Continue.IsPresent) {
        
        # reset flag
        $Continue = $False

        $Msg = "Get general module information"
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 

        If ($ModuleObj.Author) {
            If ($CurrentParams.Author) {
                $Msg = "Author name '$Author' specified for README.md will conflict with '$($ModuleObj.Author)' specified in module"
                Write-Warning $Msg
            }
            Else {
                $Author = $ModuleObj.author
                $Msg = "Found author name '$Author' in module"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            }
            $Continue = $True
        }
        Else {
            If ($CurrentParams.Author) {
                $Msg = "No author name specified in module; -Author specified as '$Author'"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                $Continue = $True
            }
            Else {
                $Msg = "No author name specified in module; please re-run with -Author"
                Write-Warning "[$($ModuleObj.Name)] $Msg" 
            }
        }

        # Get the description
        If ($ModuleObj.Description) {
            If (-not $ModuleDescription) {
                $Msg = "Got module description"
                Write-Verbose "[$($ModuleObj.Name)] $Msg" 
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
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 

        # Check module dependencies
        If ([array]$ReqModules = $ModuleObj.RequiredModules.Name) {
            If ($ReqModules.Count -gt 1) {$RequiredModules = $($ReqModules -join(", "))}
            Else {$RequiredModules = $ReqModules}
        }
        $Msg = "Found required modules list"
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 
    }
        
    # Create readme content
    If ($Continue.IsPresent) { 
        
        $Msg = "Create README.md content" 
        Write-Verbose "[$($ModuleObj.Name)] $Msg"
        Write-Progress -Activity $Activity -CurrentOperation $Msg
    
        # Initialize variable to which we will add lines of strings
        $Readme = @()

        #region Module description
        $Commands = @()
        $Commands = Get-Command -Module $ModuleObj @StdParams | Where-Object {$_.CommandType -ne "Alias"}
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
            Foreach ($Command in ($Commands| Sort)) {

                Write-Verbose "[$($ModuleObj.Name)] * $($Command.Name)"
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            Write-Warning "[$($ModuleObj.Name)] $Msg" 
                        }
                    }
                    If ($CommandHelp) {
                        $Readme += "|**$($Command.Name)**|$($CommandHelp -replace("`n","<br/>"))|"
                    }
                }
                Catch {
                    $Msg = "Failed to get comment-based help for '$($Command.Name)'"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    Write-Warning "[$($ModuleObj.Name)] $Msg" 
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

                Write-Verbose "[$($ModuleObj.Name)] * $($Command.Name)" 
                Try {
                    If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($CommandHelp = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Msg = "No '$LabelName' or '$Alt' help found for $($Command.Name)"
                            Write-Warning "[$($ModuleObj.Name)] $Msg" 
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
                    Write-Warning "[$($ModuleObj.Name)] $Msg" 
                }
            } #end foreach function/command
        }

        $Msg = "Successfully created README.md content for module"
        Write-Verbose "[$($ModuleObj.Name)] $Msg" 
        $Continue = $True

        # Move existing file, if one exists
        If ($ExistingFile) {
            
            $Msg = "Rename and move existing README.md file"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
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

            $Msg = "Save output to new README.md file"
            Write-Verbose "[$($ModuleObj.Name)] $Msg" 
            $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md" @StdParams
            
            $ConfirmMsg = "`n`n`t$Msg`n`n"
            If ($PScmdlet.ShouldProcess($ReadmeFilePath,$ConfirmMsg)) {
                $Host.UI.WriteLine()
                $Readme | Out-File -FilePath $ReadmeFilePath -Force @StdParams
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
                    
                    $Msg = "; restore original README.md file"
                    Write-Verbose "[$($ModuleObj.Name)] $Msg" 
                    $ConfirmMsg = "`n`n`t$Msg`n`n"
                    If ($PScmdlet.ShouldProcess($ExistingFile.Name,$ConfirmMsg)) {
                        
                         Try {
                            $RestoreFile = $NewFile | Rename-Item -NewName $ExistingFile.Name -Force -Confirm:$False -PassThru @StdParams |
                                Move-Item -Destination $ExistingFile.FullName -Force -Passthru -Confirm:$False @StdParams
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
    $Msg = "[END: $Scriptname] $Activity" 
    Write-Verbose $Msg
}
} #end New-PKGitReadmeFile
