  #requires -Version 3
Function Get-PKGitRepos {
<#
.SYNOPSIS 
    Searches a directory for directories containing hidden .git files, with option for recurse / depth

.DESCRIPTION
    Searches a directory for directories containing hidden .git files, with option for recurse / depth
    Defaults to current directory
    Verfies current directory holds a git repo and displays push URL.
    Requires git, of course.

.NOTES
    Name    : Function_Get-PKGitRepos.ps1
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2019-06-26 - Created script

.EXAMPLE
    PS C:\Users\jbloggs\repos> Get-PKGitrepos -verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value                           
        ---              -----                           
        Verbose          True                            
        Path             C:\Users\jbloggs\repos
        NoRecurse        False                           
        Depth            0                               
        Quiet            False                           
        PipelineInput    False                           
        ParameterSetName Recurse                         
        ComputerName     LAPTOP                 
        ScriptName       Get-PKGitRepos                  
        ScriptVersion    1.0.0                           

        VERBOSE: [LAPTOP] Prerequisites
        VERBOSE: [LAPTOP] Verify git.exe
        VERBOSE: [LAPTOP] git.exe version 2.21.0.1 found in 'C:\Program Files\Git\cmd'

        BEGIN : Search for all directories with .git files, recursively

        [C:\Users\jbloggs\repos] Verify path
        [C:\Users\jbloggs\repos] 5 git repo directories found

        C:\Users\jbloggs\repos\CTGFileSearch
        C:\Users\jbloggs\repos\GNOpsLastPassImport
        C:\Users\jbloggs\repos\gnops_director
        C:\Users\jbloggs\repos\gnops_icinga2prod
        C:\Users\jbloggs\repos\Infrastructure\PowerShell

        END  : Search for all directories with .git files, recursively

.EXAMPLE
    PS C:\> Get-PKGitrepos -Path "$Home\cat videos" -NoRecurse

        BEGIN : Search for all hidden '.git' directories in path

        [C:\Users\jbloggs\cat videos] Verify path
        [C:\Users\jbloggs\cat videos] No results found; -Recurse not specified

        END  : Search for all hidden '.git' directories in path

.EXAMPLE
    PS C:\Temp> Get-PKGitRepos -Quiet

        C:\Temp\chefmodules

#>
[Cmdletbinding(DefaultParameterSetName = "Recurse")]
Param(
    [Parameter(
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Starting path for search (default is current directory)"
    )]
    [Alias("Name","FullName")]
    [ValidateNotNullOrEmpty()]
    $Path = (Get-Location).Path,

    [Parameter(
        ParameterSetName = "NoRecurse",
        HelpMessage = "Do not perform recursive search (default is rercursive without depth limit, unless -Depth is set)"
    )]
    [switch]$NoRecurse,
        
    [Parameter(
        ParameterSetName = "Recurse",
        HelpMessage = "Depth limit for recursive searches"
    )]
    [ValidateNotNullOrEmpty()]
    [int]$Depth,

    [Parameter(
        HelpMessage = "Hide all non-verbose/non-error console output"
    )]
    [Alias("SuppressConsoleOutput")]
    [Switch] $Quiet
)
Begin {

    # Version from comment block
    [version]$Version = "01.00.0000"

    # Preference
    $ErrorActionPreference = "Stop"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites

    #$Msg = "Prerequisites"
    #Write-Verbose "[$Env:ComputerName] $Msg"

    #$Msg = "Verify git.exe"
    #Write-Verbose "[$Env:ComputerName] $Msg"

    #If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
    #    $Msg = "git.exe not found in path"
    #    $Host.UI.WriteErrorLine("ERROR  : [$ComputerName] $Msg")
    #    Break
    #}
    #Else {
    #    $Msg = "git.exe version $($GitCmd.Version) found in '$(Split-Path $GitCmd.Source)'"
    #    Write-Verbose "[$Env:ComputerName] $Msg"
    #}

    #endregion Prerequisites

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

    #endregion Functions


    #region Splats
        
    # Splat for Write-Progress
    [string]$Activity = "Search for all hidden '.git' directories in path"
    If (-not $NoRecurse.IsPresent) {$Activity += ", recursively"}
    If ($Depth) {$Activity += " up to $Depth level(s)"}
    
    $Param_WP = @{}
    $Param_WP = @{
        Activity         = $Activity
        CurrentOperation = $Null
        Status           = "Working"
        PercentComplete  = $Null
    }

    # Splat for Test-Path
    $Param_Test = @{}
    $Param_Test = @{
        Path        = $Null
        ErrorAction = "SilentlyContinue"
        Verbose     = $False
    }

    # Splat for Get-Childitem
    [switch]$Recurse = (-not $NoRecurse.IsPresent)
    $Param_GCI = @{}
    $Param_GCI = @{
        Path        = $Null
        Hidden      = $True
        Filter      = ".git"
        Recurse     = $Recurse
        Force       = $True
        ErrorAction = "SilentlyContinue"
        Verbose     = $False
    }
    If ($CurrentParams.Depth) {
        $Param_GCI.Add("Depth",$Depth)
    }

    #endregion Splats

    # Start
    $Msg = "BEGIN : $Activity"
    $Msg | Write-MessageInfo -FGColor Yellow -Title

}
Process {
    
    $Total = ($Path -as [array]).Count
    $Current = 0

    Foreach ($P in $Path) {
        
        If ($P -is [system.io.filesysteminfo]) {$P = $P.FullName}
        
        $Param_WP.CurrentOperation = $P
        $Param_WP.PercentComplete = ($Current/$Total*100)
        Write-Progress @Param_WP

        $Msg = "Verify path"
        "[$P] $Msg" | Write-MessageInfo -FGColor White

        $Param_Test.Path = $P
        If ($Null = Test-Path @Param_Test) {
            
            Try {
                If ([array]$Repos = Get-ChildItem @Param_GCI) {
                    Switch ($Repos.Count) {
                        1       {$Msg = "$($Repos.Count) matching directory found`n"}
                        Default {$Msg = "$($Repos.Count) matching directories found`n"}
                    }
                    "[$P] $Msg" | Write-MessageInfo -FGColor Green
                    Write-Output ($Repos.FullName | Split-Path -Parent)
                }
                Else {
                    $Msg = "No results found"
                    If ($NoRecurse.IsPresent) {
                        $Msg += "; -Recurse not specified"
                    }
                    ElseIf ($Depth) {
                        $Msg += " in recursive search; try increasing -Depth from current setting of $Depth"
                    }
                    "[$P] $Msg" | Write-MessageInfo -FGColor Red
                }
            }
            Catch {
                $Msg = "Operation failed"
                If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                "[$P] $Msg" | Write-MessageError
            }
        }
        Else {
            $Msg = "Invalid path"
            "[$P] $Msg" | Write-MessageError
        }

    } #end foreach 
        
}
End {
    Write-Progress -Activity $Activity -Complete
    $Msg = "END  : $Activity"
    $Msg | Write-MessageInfo -FGColor Yellow -Title

}
} # end Get-PKGitRepos