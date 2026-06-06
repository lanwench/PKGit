#requires -Version 4
Function Get-PKGitEmail {
<#
.SYNOPSIS
    Returns the git config email address on the local computer: global, local, system, or all

.DESCRIPTION
    Queries git configuration for user email addresses across Global, Local, and/or System scopes.
    Returns objects with email address, scope, target (computer name or repo path), and any relevant messages.

    Scope behavior:
    - Global: System-wide user email (~/.gitconfig), applies to all repos on computer
    - Local: Repository-specific email (.git/config), overrides global setting for that repo
    - System: Machine-wide email (/etc/gitconfig), rarely set except on shared servers
    - All: Returns global, local, and system settings (default)

    Accepts pipeline input for the Path parameter. When called with pipeline input, Global and System
    results are returned once upfront (if requested via -Scope All or -Scope Global/-System), then Local
    results are returned for each path in the pipeline.
    Returns PSCustomObject with ComputerName, Scope, Path, Email, and Messages properties.

.NOTES
    Name    : Function_Get-PKGitEmail.ps1 
    Created : 2019-04-09
    Author  : Paula Kingsley
    Version : 03.00
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00 - 2019-04-09 - Created script
        v01.01 - 2021-05-24 - Simplified, removed -Quiet, fixed set-location
        v02.00 - 2026-03-15 - Cleanup, made cross-platform compatible, added better error handling
        v03.00 - 2026-06-03 - Overhauled, simplified, made consistent with other functions in module

.PARAMETER Path
    Path to git repository (default is current directory)

.PARAMETER Scope
    git config scope to check: local, global, system, or all (default is all)

.EXAMPLE
    PS /Users/jbloggs/repos> Get-PKGitEmail -Verbose

        VERBOSE: PSBoundParameters: 

        Key           Value
        ---           -----
        Verbose       True
        Path          /Users/jbloggs/git/GitHub/PKGit
        Scope         All
        PipelineInput False
        ScriptName    Get-PKGitEmail
        ScriptVersion 2.1


        VERBOSE: [BEGIN: Get-PKGitEmail] Get global and local git config user email addresses on laptop2.local
        VERBOSE: Commands: 

        TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
        Local       : git config --local --get user.email
        Global      : git config --global --get user.email


        VERBOSE: [/Users/jbloggs/git/GitHub/PKGit] Verifying that path contains a git repository
        VERBOSE: [/Users/jbloggs/git/GitHub/PKGit] Getting local git email

        ComputerName : laptop2.local
        Scope        : Local
        Path         : /Users/jbloggs/git/GitHub/PKGit
        Email        : (none)
        Messages     : No local git email found

        VERBOSE: [/Users/jbloggs/git/GitHub/PKGit] Getting global git email
        ComputerName : laptop2.local
        Scope        : Global
        Path         : n/a
        Email        : jbloggs@users.noreply.github.com
        Messages     :

        VERBOSE: [END: Get-PKGitEmail] Operation completed successfully

.EXAMPLE
    PS C:\Repos> (Get-Childitem -Directory -Recurse | Select -first 10 | Get-PKGitEmail -Scope All -Verbose) | Format-Table -Autosize

        VERBOSE: PSBoundParameters: 
	
        Key           Value         
        ---           -----         
        Scope         All           
        Verbose       True          
        Path                        
        PipelineInput True          
        ScriptName    Get-PKGitEmail
        ScriptVersion 1.1.0         

        WARNING: [LAPTOP] Pipeline input detected; scope will be reset to 'Local'

        VERBOSE: Commands: 
            TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
            Local       : git config --local --get user.email
            Global      : git config --global --get user.email


        VERBOSE: [BEGIN: Get-PKGitEmail] Get local git config user email address
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\34d08ae7d489b1e87d50c1614e6cabbb' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\blah' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\blah2' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\capas' contains a git repository
        WARNING: [LAPTOP] 'C:\Repos\Personal\gists' does not appear to contain a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\Testing' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\Sandbox' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\ADTools' contains a git repository
        VERBOSE: [LAPTOP] 'C:\Repos\Personal\ChefStuff' contains a git repository
        VERBOSE: [END: Get-PKGitEmail] Get local git config user email address

        ComputerName    Scope Path                                    Email                                Messages
        ------------    ----- ----                                    -----                                -------
        LAPTOP          Local C:\Repos\Personal\34d08ae7d489b1e87d50c1614e6c                (none)                             No local git email found
        LAPTOP          Local C:\Repos\Personal\blah                           joebloggs@megacorp.com
        LAPTOP          Local C:\Repos\Personal\blah2                          joebloggs@megacorp.com
        LAPTOP          Local C:\Repos\Personal\capas                                                      (none)                             No local git email found
        LAPTOP          Local C:\Repos\Personal\gists                          Error                                fatal: not a git repository (or any of the parent directories): .git
        LAPTOP          Local C:\Repos\Personal\Testing                        madamemax@users.noreply.github.com
        LAPTOP          Local C:\Repos\Personal\Sandbox                        madamemax@users.noreply.github.com
        LAPTOP          Local C:\Repos\Personal\ADTools                        madamemax@users.noreply.github.com
        LAPTOP          Local C:\Repos\Personal\ChefStuff                      madamemax@users.noreply.github.com                                                                     

#>

[CmdletBinding()]
Param(
    
    [Parameter(
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Path to git repository (default is current directory)"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("FullName","Name")]
    $Path = $Pwd,

    [Parameter(
        HelpMessage = "Scope for git config check: local, global, system, or all (default is all)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("All","Global","Local","System")]
    [string]$Scope = "All"
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "03.00"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    
    # Display our parameters
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} | 
        Where-Object {Test-Path variable:$_}| ForEach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    If ($PipelineInput.IsPresent) {$CurrentParams.Path = $Null}
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    $ComputerName = [System.Net.Dns]::GetHostName()
    
    #region Prerequisites
    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $Msg = "Oops! Can't find git; please install git and/or make sure the command is in your system path!"
        Throw $Msg
    }
    #endregion Prerequisites

    #region Functions
    Function _IsGitRepo($Path) {
        $Cmd = "git -C '$Path' rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (($Results = Invoke-Command -ScriptBlock $ScriptBlock) -ne $True) {
            $Msg = $Results
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Scope        = "Local"
                Path         = $Path
                Email        = "Error"
                Messages     = $Msg
            }
        }
    } # end _IsGitRepo

    Function _GetEmail {
        param([switch]$Global, [switch]$System, [switch]$Local, [string]$Path)
        if ($Global.IsPresent) {
            $Cmd = "git config --global --get user.email"
            $ScriptBlock = [scriptblock]::Create($Cmd)
            $Results = Invoke-Command -ScriptBlock $ScriptBlock
            $Msg = if (-not $Results) { "No global git email found" } else { $Null }
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Scope        = "Global"
                Path         = "n/a"
                Email        = if ($Results) { $Results } else { "(none)" }
                Messages     = $Msg
            }
        }

        if ($System.IsPresent) {
            $Cmd = "git config --system --get user.email"
            $ScriptBlock = [scriptblock]::Create($Cmd)
            $Results = Invoke-Command -ScriptBlock $ScriptBlock
            $Msg = if (-not $Results) { "No system git email found" } else { $Null }
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Scope        = "System"
                Path         = "n/a"
                Email        = if ($Results) { $Results } else { "(none)" }
                Messages     = $Msg
            }
        }

        if ($Local.IsPresent) {
            $Cmd = "git -C '$Path' config --local --get user.email"
            $ScriptBlock = [scriptblock]::Create($Cmd)
            $Results = Invoke-Command -ScriptBlock $ScriptBlock
            $Msg = if (-not $Results) { "No local git email found" } else { $Null }
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Scope        = "Local"
                Path         = $Path
                Email        = if ($Results) { $Results } else { "(none)" }
                Messages     = $Msg
            }
        }
    } #end _GetEmail

    #endregion Functions
    
    #region Define actions

    [switch]$GetLocal = [switch]$GetGlobal = [switch]$GetSystem = $False
    Switch ($Scope) {
        All {
            [switch]$GetLocal = [switch]$GetGlobal = [switch]$GetSystem = $True
            $Activity = "Get global, local, and system git config user email addresses"
        }
        Local  {
            [switch]$GetLocal = $True
            $Activity = "Get $($Scope.ToLower()) git config user email address"
        }
        Global {
            [switch]$GetGlobal = $True
            $Activity = "Get $($Scope.ToLower()) git config user email address"
        }
        System {
            [switch]$GetSystem = $True
            $Activity = "Get $($Scope.ToLower()) git config user email address"
        }
    }

    #endregion Define actions

    # Pipeline input with Global scope only doesn't make sense
    If ($PipelineInput.IsPresent -and $Scope -eq "Global") {
        $Msg = "It's a waste of time to use pipeline input when Scope is not set to Local or All, as the global/system values will be the same regardless of path"
        Throw $Msg
    }

    # Fetch global and/or system email once if needed (even with pipeline input)
    $Output = $Null
    If ($GetGlobal.IsPresent -or $GetSystem.IsPresent) {
        Try {
            $Params = @{ ErrorAction = "Stop" }
            If ($GetGlobal.IsPresent) { $Params["Global"] = $True }
            If ($GetSystem.IsPresent) { $Params["System"] = $True }
            $Output = _GetEmail @Params
        }
        Catch {
            $Msg = "Failed to get email"
            If ($ErrorDetails = $_.Exception.Message) { $Msg += " ($ErrorDetails)" }
            Write-Error "[$ComputerName] $Msg"
        }
    }

    $Commands = [PSCustomObject]@{
        TestGitRepo = "git rev-parse --is-inside-work-tree 2>&1"
        Local = "git config --local --get user.email"
        Global = "git config --global --get user.email"
        System = "git config --system --get user.email"
    }

    $Msg = "[BEGIN: $Scriptname] $Activity $TargetStr"
    Write-Verbose $Msg
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

}
Process {

    # Output global and system email once (before local paths)
    If ($Null -ne $Output) {
        $Output
        $Output = $Null  # Clear so we don't output again in subsequent iterations in pipeline
    }   

    # Convert Path to string if it's a FileSystemInfo object (e.g. from Get-ChildItem)
    If ($Path -is [system.io.filesysteminfo]) { $Path = $Path.ToString() }

    # Make sure we're in a git repo
    If ($GetLocal.IsPresent) {
        $Msg = "Verifying that path contains a git repository"
        Write-Verbose "[$Path] $Msg"
        Try {
            $Test = _IsGitRepo -Path $Path -ErrorAction Stop
            If ($Test.Email -eq "Error") {
                $Msg = "Path doesn't appear to contain a git repository!"
                Write-Warning "[$Path] $Msg"
                $Test
            }
            Else {
                $Msg = "Getting local git email"
                Write-Verbose "[$Path] $Msg"
                $Params = @{ Local = $True; Path = $Path; ErrorAction = "Stop" }
                _GetEmail @Params
            }
        }
        Catch {
            $Msg = "Path doesn't appear to contain a git repository!"
            If ($ErrorDetails = $_.Exception.Message) { $Msg += " ($ErrorDetails)" }
            Write-Warning "[$Path] $Msg"
        }
    }

} #end process
End {

    $Msg = "[END: $Scriptname] Operation completed successfully"
    Write-Verbose $Msg
}

} #end Get-PKGitEmail

