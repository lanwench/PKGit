#requires -Version 4
Function Get-PKGitEmail {
<#
.SYNOPSIS
    Returns the git config email address on the local computer: global, local, or both

.DESCRIPTION
    Returns the git config email address on the local computer: global, local, or both
    Accepts pipeline input
    Returns a PSObject

.NOTES
    Name    : Function_Get-PKGitEmail.ps1 
    Created : 2019-04-09
    Author  : Paula Kingsley
    Version : 01.01.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2019-04-09 - Created script
        v01.01.0000 - 2021-05-24 - Simplified, removed -Quiet, fixed set-location

.PARAMETER Path
    Path to git repository (default is current directory)

.PARAMETER Scope
    git config scope to check: local, global, or all (default is all)

.EXAMPLE
    PS C:\Repos> $Z = (Get-Childitem -Directory -Recurse | Select -first 10 | Get-PKGitEmail -Scope All -Verbose) | Format-Table -Autosize

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

        ComputerName    Scope Path                                      Email                               Messages                                                            
        ------------    ----- ----                                      -----                               -------                                                            
        LAPTOP Local C:\Repos\Personal\34d08ae7d489b1e87d50c1614e6c                                         No local git email setting found; try Set-PKGitEmail                
        LAPTOP Local C:\Repos\Personal\blah                             joebloggs@megacorp.com                                                                            
        LAPTOP Local C:\Repos\Personal\blah2                            joebloggs@megacorp.com                                                                            
        LAPTOP Local C:\Repos\Personal\capas                                                                No local git email setting found; try Set-PKGitEmail                
        LAPTOP Local C:\Repos\Personal\gists                            Error                               fatal: not a git repository (or any of the parent directories): .git
        LAPTOP Local C:\Repos\Personal\Testing                          madamemax@users.noreply.github.com                                                                     
        LAPTOP Local C:\Repos\Personal\Sandbox                          madamemax@users.noreply.github.com                                                                     
        LAPTOP Local C:\Repos\Personal\ADTools                          madamemax@users.noreply.github.com                                                                     
        LAPTOP Local C:\Repos\Personal\ChefStuff                        madamemax@users.noreply.github.com                                                                     
       
.EXAMPLE
    PS C:\Repos\Corp\Profiles> Get-PKGitEmail

    ComputerName : WORKSTATION14
    Scope        : Local
    Path         : C:\Repos\Corp\Profiles
    Email        : 
    Messages     : No local git email setting found; try Set-PKGitEmail

    ComputerName : WORKSTATION14
    Scope        : Global
    Path         : -
    Email        : joe.bloggs@internal.megacorp.com
    Messages     : 


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
        HelpMessage = "git config scope to check: local, global, or all (default is all)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("All","Global","Local")]
    [string]$Scope = "All"
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.01.0000"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    
    # Display our parameters
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    If ($PipelineInput.IsPresent) {$CurrentParams.Path = $Null}
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences
    $ErrorActionPreference = "Stop"
    
    #region Prerequisites

    If (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

    #endregion Prerequisites

    #region Functions

    Function IsGitRepo($Path) {
        $CurrentLocation = Get-Location
        Set-Location $Path 
        $Cmd = "git rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (($Results = Invoke-Command -ScriptBlock $ScriptBlock) -ne $True) {
            $Msg = $Results
            [PSCustomObject]@{
                ComputerName = $Env:ComputerName
                Scope        = "Local"
                Path         = $Path
                #Command      = $Cmd
                Email        = "Error"
                Messages     = $Msg
            }
        }    
        Set-Location $CurrentLocation
    }

    Function GetGlobalEmail{
        $Cmd = "git config --global --get user.email"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (-not ($Results = Invoke-Command -ScriptBlock $ScriptBlock)) {
            $Msg = "No global git email setting found; try Set-PKGitEmail"
            #$Results = "Error"
        }
        Else {$Msg = $Null}

        [PSCustomObject]@{
            ComputerName = $Env:ComputerName
            Scope        = "Global"
            Path         = "-"
            #Command      = $Cmd
            Email        = $Results
            Messages     = $Msg
        }
    }

    Function GetLocalEmail($Path){
        $CurrentLocation = Get-Location
        Set-Location $Path 
        $Cmd = "git config --local --get user.email"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (-not ($Results = Invoke-Command -ScriptBlock $ScriptBlock)) {
            $Msg = "No local git email setting found; try Set-PKGitEmail"
            #$Results = "Error"
        }
        Else {$Msg = $Null}

        [PSCustomObject]@{
            ComputerName = $Env:ComputerName
            Scope        = "Local"
            Path         = $Path
            #Command      = $Cmd
            Email        = $Results
            Messages     = $Msg
        }
        Set-Location $CurrentLocation 
    }

    #endregion Functions
    
    #region Define actions
    
    If ($PipelineInput.IsPresent -and $CurrentParams.Scope -ne "Local") {
        $Msg = "Pipeline input detected; scope will be reset to 'Local'"
        Write-Warning "[$Env:ComputerName] $Msg"
        $Scope = "Local"
    }

    [switch]$GetLocal = $False
    [switch]$GetGlobal = $False
    Switch ($Scope) {
        All {
            [switch]$GetLocal = $True
            [switch]$GetGlobal = $True
            $Activity = "Get global and local git config user email addresses"
            $TargetStr = "on $Env:ComputerName"
        }
        Local  {
            [switch]$GetLocal = $True
            $Target = $PWD.Path
            $Activity = "Get $($Scope.ToLower()) git config user email address"
            $TargetStr = "in $Target"
        }
        Global {
            [switch]$GetGlobal = $True
            $Target = $Env:ComputerName
            $Activity = "Get $($Scope.ToLower()) git config user email address"
            $TargetStr = "on $Target"
        }
    }

    #endregion Define actions
    
    # This might get reset, so...
    $OriginalLocation = Get-Location

    $Commands = [PSCustomObject]@{
        TestGitRepo = "git rev-parse --is-inside-work-tree 2>&1"
        Local = "git config --local --get user.email"
        Global = "git config --global --get user.email"
    }
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"

    $Msg = "[BEGIN: $Scriptname] $Activity" 
    Write-Verbose $Msg


}
Process {
    
    # Set the flag
    [switch]$Continue = $False
    
    If ($Path -is [system.io.filesysteminfo]) {$Path = $Path.FullName}


    # Make sure we're in a git repo    
    If ($GetLocal.IsPresent) {
        
        Try {
            $Test = IsGitRepo -Path $Path -ErrorAction Stop
            If ($Test.Email -eq "Error") {
                $Msg = "'$Path' does not appear to contain a git repository"
                Write-Warning "[$Env:ComputerName] $Msg"
                $Test
            }
            Else {
                $Msg = "'$Path' contains a git repository"
                Write-Verbose "[$Env:ComputerName] $Msg"
                GetLocalEmail -Path $Path
            }
        }
        Catch {
            $Msg = "'$Path' does not appear to contain a git repository"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Write-Warning "[$Env:ComputerName] $Msg"
        }
    }
    
    If ($GetGlobal.IsPresent) {

        Try {
            GetGlobalEmail -ErrorAction Stop
        }
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Write-Error "[$Env:ComputerName] $Msg"
        }
    }

} #end process
End {
    
    # Reset location
    Set-Location $OriginalLocation

    $Msg = "[END: $Scriptname] $Activity" 
    Write-Verbose $Msg
}

} #end Get-PKGitEmail

