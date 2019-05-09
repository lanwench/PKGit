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
    Version : 01.00.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2019-04-09 - Created script

.PARAMETER Path
    Path to git repository (default is current directory)

.PARAMETER Scope
    git config scope to check: local, global, or all (default is all)

.PARAMETER Quiet
    Suppress non-verbose console output

.EXAMPLE
    PS C:\> Get-PKGitEmail -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                
        ---           -----                                
        Verbose       True                                 
        Path          C:\Users\jbloggs\mystuff
        Scope         All                                  
        Quiet         False                                
        PipelineInput False                                
        ScriptName    Get-PKGitEmail                       
        ScriptVersion 1.0.0                                



        VERBOSE: [WORKSTATION] Prerequisites
        VERBOSE: [WORKSTATION] Verify git.exe
        VERBOSE: [WORKSTATION] git.exe version 2.18.0.1 found in 'C:\Program Files\Git\cmd'
        
        BEGIN  : Get global and local git config user email addresses
        
        VERBOSE: [WORKSTATION] 'C:\Users\jbloggs\mystuff' contains a git repository


        ComputerName : WORKSTATION
        Scope        : Local
        Path         : C:\Users\jbloggs\mystuff
        Command      : git config --local --get user.email
        Email        : jbloggs@users.noreply.github.com
        Messages     : 

        ComputerName : WORKSTATION
        Scope        : Global
        Path         : n/a
        Command      : git config --global --get user.email
        Email        : joseph.bloggs@corpdomain.com
        Messages     : 

        END    : Get global and local git config user email addresses


.EXAMPLE
    PS C:\> Get-childitem -Path c:\users\jbloggs\repos | Get-PKGitEmail -Quiet | Format-Table -AutoSize

        WARNING: [WORKSTATION8] Pipeline input detected; scope will be reset to 'Local'
        WARNING: [WORKSTATION8] 'c:\users\jbloggs\repos\Modules' does not appear to contain a git repository

        ComputerName Scope Path                               Command                                  Email                             Messages                                                            
        ------------ ----- ----                               -------                                  -----                             --------                                                            
        WORKSTATION8 Local c:\users\jbloggs\repos\Modules     git rev-parse --is-inside-work-tree 2>&1 Error                             fatal: not a git repository (or any of the parent directories): .git
        WORKSTATION8 Local c:\users\jbloggs\repos\profiles    git config --local --get user.email      jbloggs@users.noreply.github.com                                                                     
        WORKSTATION8 Local c:\users\jbloggs\repos\chefprod    git config --local --get user.email      jbloggs@users.noreply.github.com 
        WORKSTATION8 Local c:\users\jbloggs\repos\tools       git config --local --get user.email      jbloggs@users.noreply.github.com                                                                     
        WORKSTATION8 Local c:\users\jbloggs\repos\kittens     git config --local --get user.email      hellokitty@users.noreply.github.com                                                                     
        WORKSTATION8 Local c:\users\jbloggs\repos\Sandbox     git config --local --get user.email      jbloggs@users.noreply.github.com                                                                               
    

.EXAMPLE
    PS C:\> Get-PKGitEmail -Path c:\users\jbloggs\catvideos

        BEGIN  : Get global and local git config user email addresses

        WARNING: [LAPTOP] 'c:\users\jbloggs\catvideos' does not appear to contain a git repository


        ComputerName : LAPTOP
        Scope        : Local
        Path         : c:\users\jbloggs\catvideos
        Command      : git rev-parse --is-inside-work-tree 2>&1
        Email        : Error
        Messages     : fatal: not a git repository (or any of the parent directories): .git

        ComputerName : LAPTOP
        Scope        : Global
        Path         : n/a
        Command      : git config --global --get user.email
        Email        : joe.bloggs@corp.net
        Messages     : 

        END    : Get global and local git config user email addresses

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
    [string]$Scope = "All",

    [Parameter(
        HelpMessage = "Suppress non-verbose console output"
    )]
    [Switch]$Quiet
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    #[switch]$PipelineInput = ((-not $PSBoundParameters.Path) -and (-not $Path))
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

    $Msg = "Prerequisites"
    Write-Verbose "[$Env:ComputerName] $Msg"

    $Msg = "Verify git.exe"
    Write-Verbose "[$Env:ComputerName] $Msg"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorLine("ERROR  : [$ComputerName] $Msg")
        Break
    }
    Else {
        $Msg = "git.exe version $($GitCmd.Version) found in '$(Split-Path $GitCmd.Source)'"
        Write-Verbose "[$Env:ComputerName] $Msg"
    }

    #endregion Prerequisites

    # Make sure we're not repeating ourselves
    If ($PipelineInput.IsPresent -and $CurrentParams.Scope -ne "Local") {
        $Msg = "Pipeline input detected; scope will be reset to 'Local'"
        Write-Warning "[$Env:ComputerName] $Msg"
        $Scope = "Local"
    }

    #region Functions

    Function IsGitRepo($Path) {
        $CurrentLocation = Get-Location
        Set-Location $Path 
        $Cmd = "git rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (($Results = Invoke-Command -ScriptBlock $ScriptBlock) -ne $True) {
            $Msg = $Results
            New-Object PSObject -Property ([ordered]@{
                ComputerName = $Env:ComputerName
                Scope        = "Local"
                Path         = $Path
                Command      = $Cmd
                Email        = "Error"
                Messages     = $Msg
            }) 
        }    
        Set-Location $CurrentLocation
    }

    Function GetGlobalEmail{
        $Cmd = "git config --global --get user.email"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (-not ($Results = Invoke-Command -ScriptBlock $ScriptBlock)) {
            $Msg = "No global git email setting found; try Set-PKGitEmail"
            $Results = "Error"
        }
        Else {$Msg = $Null}

        New-Object PSObject -Property ([ordered]@{
            ComputerName = $Env:ComputerName
            Scope        = "Global"
            Path         = "n/a"
            Command      = $Cmd
            Email        = $Results
            Messages     = $Msg
        }) 
    }

    Function GetLocalEmail($Path){
        $CurrentLocation = Get-Location
        Set-Location $Path 
        $Cmd = "git config --local --get user.email"
        $ScriptBlock = [scriptblock]::Create($Cmd)
        If (-not ($Results = Invoke-Command -ScriptBlock $ScriptBlock)) {
            $Msg = "No local git email setting found; try Set-PKGitEmail"
            $Results = "Error"
        }
        Else {$Msg = $Null}

        New-Object PSObject -Property ([ordered]@{
            ComputerName = $Env:ComputerName
            Scope        = "Local"
            Path         = $Path
            Command      = $Cmd
            Email        = $Results
            Messages     = $Msg
        })
        Set-Location $CurrentLocation 
    }

    #endregion Functions
    
    #region Define actions

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

    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = "BEGIN  : $Activity"
    $FGColor = "Yellow"
    If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}
    
}
Process {
    
    <#
    Foreach ($P in $Path) {
    # Set the flag
    [switch]$Continue = $False

    # Make sure we're in a git repo
    Try {
        $Test = IsGitRepo -Path $P
        If (($Test.Email -eq "Error") -and ($GetLocal.IsPresent)) {
            $Msg = "'$Path' does not appear to contain a git repository"
            Write-Warning "[$Env:ComputerName] $Msg"
            $Test.Scope = "Local"
            $Test
            #$GetLocal = $False
        }
        Else {
            $Msg = "'$P' contains a git repository"
            Write-Verbose "[$Env:ComputerName] $Msg"
        }
        If ($GetGlobal.IsPresent) {GetGlobalEmail}        
        If ($GetLocal.IsPresent)  {GetLocalEmail -Path $P}    
    }
    Catch {
        $Msg = "'$P' does not appear to contain a git repository"
        If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
        If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("[$Env:ComputerName] $Msg")}
        Else {Write-Warning "[$Env:ComputerName] $Msg"}
    }

    }

    #>

    

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
            If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("[$Env:ComputerName] $Msg")}
            Else {Write-Warning "[$Env:ComputerName] $Msg"}
        }        
            
            
    }
    
    If ($GetGlobal.IsPresent) {
        Try {
            GetGlobalEmail -ErrorAction Stop
        }
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("[$Env:ComputerName] $Msg")}
            Else {Write-Warning "[$Env:ComputerName] $Msg"}
        }
    }

} #end process
End {
    
    # Reset location
    Set-Location $OriginalLocation

    $Msg = "END    : $Activity"
    $FGColor = "Yellow"
    If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}
}

} #end Get-PKGitEmail

