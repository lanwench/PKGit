#Requires -Version 3
Function Set-PKGitModuleReadmeContent {
<#
.Synopsis
    Creates markdown-formatted output suitable for a Git readme.md by running Get-Help against a module, 
    using either the Synopsis or Description label

.Description
    Creates markdown-formatted output suitable for a Git readme.md by running Get-Help against a module, 
    using either the Synopsis or Description label
    Accepts pipeline input
    Outputs a PSObject

.NOTES 
    Name    : Function_Set-PKGitModuleReadmeContent.ps1
    Version : 02.00.0000
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0      - 2017-02-10 - Created script
        v02.00.0000 - 2017-11-30 - Renamed from Set-PKGitModuleReadmeContent
        
.EXAMPLE
    PS C:\> Set-PKGitModuleReadmeContent -ModuleName gnopswindowschef -LabelName Synopsis -Verbose
    # Creates markdown-formatted output suitable for a Git readme.md, for the GNOpsWindowsChef module, using the Synopsis label

        VERBOSE: PSBoundParameters: 
	
        Key           Value                
        ---           -----                
        ModuleName    gnopswindowschef     
        LabelName     Synopsis             
        Verbose       True                 
        ScriptName    Set-PKGitModuleReadmeContent
        ScriptVersion 1.0.0                

        VERBOSE: Get module 'gnopswindowschef'
        VERBOSE: Found and module GNOpsWindowsChef, version 2.3.2
        VERBOSE: Get function commands from module 'GNOpsWindowsChef'
        VERBOSE: 8 functions/command(s) found

        VERBOSE: Get-GNOpsChefNode
        VERBOSE: Get-GNOpsWindowsChefClient
        VERBOSE: Install-GNOpsWindowsChefClient
        VERBOSE: Install-GNOpsWindowsChefDK
        VERBOSE: Invoke-GNOpsWindowsChefClient
        VERBOSE: Invoke-GNOpsWindowsChefClientDownload
        VERBOSE: New-GNOpsWindowsChefClientConfig
        VERBOSE: Remove-GNOpsWindowsChefClientService

        # Functions

        #### Get-GNOpsChefNode ####
        Show the configuration and status of a Chef node

        #### Get-GNOpsWindowsChefClient ####
        Looks for Chef-Client on a Windows server, using Invoke-Command as a job

        #### Install-GNOpsWindowsChefClient ####
        Installs chef-client on a remote machine from a local or downloaded MSI file
        using Invoke-Command and a remote job

        #### Install-GNOpsWindowsChefDK ####
        Downloads and installs the latest stable version of the ChefDK from the Omnitruck site

        #### Invoke-GNOpsWindowsChefClient ####
        Runs chef-client on a remote machine as a job using invoke-command

        #### Invoke-GNOpsWindowsChefClientDownload ####
        Downloads Chef-Client from a Gracenote or public Chef.io url

        #### New-GNOpsWindowsChefClientConfig ####
        Creates new files on a remote computer to register the node with the Gracenote Chef server the next time chef-client runs

        #### Remove-GNOpsWindowsChefClientService ####
        Looks for the chef-client service on a computer and prompts to remove it if found

.EXAMPLE
    PS C:\> "GNOpsWindowsChef" | Set-PKGitModuleReadmeContent -LabelName Description
    # Creates markdown-formatted output suitable for a Git readme.md, for the GNOpsWindowsChef module, using the Description label

        # Functions
        #### Get-GNOpsChefNode ####

        Uses knife search Returns a PSObject with Name, Environment, FQDN, IP, RunList, Roles, Recipes,
        Platform, Tags properties

        #### Get-GNOpsWindowsChefClient ####
        Looks for Chef-Client on a Windows server, using Invoke-Command as a job
        Returns a PSObject
        Accepts pipeline input
        Accepts ShouldProcess
        
        #### Install-GNOpsWindowsChefClient ####
        Installs chef-client on a remote machine from a local or downloaded MSI file
        using Invoke-Command and a remote job
        Allows selection of local MSI on target or download (of various versions)
        Parameter -ForceInstall forces installation even if existing version is present
        Allows for standard or verbose logging from msiexec (stores log on target computer)
        Returns jobs

        #### Install-GNOpsWindowsChefDK ####
        Downloads and installs the latest stable version of the ChefDK from the Omnitruck site
        as a background job or interactively

        #### Invoke-GNOpsWindowsChefClient ####
        Runs chef-client on a remote machine as a job using invoke-command
        Returns a PSObject for the job invocation results, as well as the job state(s)
        Accepts pipeline input
        Uses implicit or explicit credentials

        #### Invoke-GNOpsWindowsChefClientDownload ####
        Downloads Chef-Client from a Gracenote or public Chef.io url 
        Runs remote jobs using Invoke-WebRequest or downlevel .NET 
        Defaults to v. 12.5.1, but allows current/latest version
        Saves output file in $Env:Windir\Temp\chefclient.msi on target computer
        by default, but you can change the path and filename.
        Optional -Force parameter overwrites file if already present
        Accepts pipeline input

        #### New-GNOpsWindowsChefClientConfig ####
        Creates new files on a remote computer to register the node with the Gracenote Chef server the next time chef-client runs
        Files include client.rb file and a validation key
        Renames previous folder if found and -ForceFolderCreation is specified, otherwise will not proceed if folder already exists
        Uses Invoke-Command and a remote scriptblock
        Supports ShouldProcess
        Accepts pipeline input
        Returns a psobject

        #### Remove-GNOpsWindowsChefClientService ####
        Looks for the chef-client service on a computer and prompts to remove it if found
        Accepts pipeline input
        Outputs array


#>
[cmdletbinding()]
Param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Name of module"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Label to use (Synopsis or Description)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Synopsis","Description")]
    [string]$LabelName = "Synopsis"
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
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

    $Results= @()

    # Console output
    $Activity = "Get new content for readme.md from module $Module"
    $BGColor = $Host.UI.RawUI.BackgroundColor
    $Msg = "Action: $Activity"
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}
}
Process {

    # Tidy up name
    $ModuleName = $ModuleName.Trim()

    # Verify/get module
    $Msg = "Get module '$ModuleName'"
    Write-Verbose $Msg
    Try {
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
        Else {$Msg = "Found module $($Module), version $($Module.Version)"}
        Write-Verbose $Msg

        # Get commands
        $Msg = "Get function commands from module '$($Module.Name)'"
        Write-Verbose $Msg

        Try{
            [array]$Commands = (Get-Command -Module $Module -CommandType Function @StdParams | Sort Name)
            $Msg = "$($Commands.Count) functions/command(s) found"
            Write-Verbose $Msg

            $Host.UI.WriteLine()
            Foreach ($Command in ($Commands| Sort)) {

                Write-Verbose $Command.Name
                Try {
                    If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$LabelName)) {
                        If (-not ($Output = (Get-Help -Name $Command -ErrorAction SilentlyContinue -Verbose:$False).$Alt)) {
                            $Host.UI.WriteErrorLine("No '$LabelName' help found for $($Cmd.Name)")
                        }
                    }
                    If ($Output) {
                        $Results += "$Spacer#### $($Command.Name) ####"
                        $Results += $Output
                    }
                }
                Catch {}
            } #end foreach function/command

            If ($Results) {
                $Host.UI.WriteLine()
                Write-Output "# Functions"
                Write-Output $Results
            }
        }
        Catch {
            $Msg = "Can't get functions/commands"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
        }
    }
    Catch {
        $Msg = "Can't find module"
        $ErrorDetails = $_.Exception.Message
        $Host.Ui.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
    }

}

} #end Set-PKGitModuleReadmeContent
