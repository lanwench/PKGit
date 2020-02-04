#requires -Version 4
Function Set-PKGitEmail {
<#
.SYNOPSIS
    Sets or changes a git global or local repo email address

.DESCRIPTION
    Sets or changes a git global or local repo email address
    Verifies that git is installed/available in the path, and that the directory contains a git repo (if scope is local)
    Accepts pipeline input (for local scope)
    Supports ShouldProcess
    Returns a PSObject

.NOTES
    Name    : Function_Set-PKGitEmail.ps1 
    Created : 2018-08-13
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2018-08-13 - Created script
        v01.01.0000 - 2019-04-09 - Minor updates
        v02.00.0000 - 2019-10-10 - Added pipeline input, overhauled, added inner functions, other updates

.EXAMPLE
    PS C:\> Set-PKGitEmail -Global -EmailAddress joe.bloggs@domain.local -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value                     
        ---              -----                     
        Global           True                      
        EmailAddress     joe.bloggs@domain.local
        Verbose          True                      
        Local            False                     
        Path                                       
        Quiet            False                     
        ParameterSetName Global                    
        PipelineInput    False                     
        ScriptName       Set-PKGitEmail            
        ScriptVersion    2.0.0                     

        BEGIN: Set git global config user email address

        [LAPTOP] Get current email address
        [LAPTOP] No email address found
        [LAPTOP] Set email address
        [LAPTOP] Successfully configured email address


        Scope          : Global
        Target         : LAPTOP
        IsChanged      : True
        CurrentAddress : -
        NewAddress     : joe.bloggs@domain.local
        Messages       : Successfully configured email address


        END  : Set git global config user email address

.EXAMPLE
    PS C:\> Set-PKGitEmail -Global -EmailAddress jbloggs@corp.net -Quiet

        Scope          : Global
        Target         : LAPTOP
        IsChanged      : False
        CurrentAddress : joe.bloggs@domain.local
        NewAddress     : jbloggs@corp.net
        Messages       : Operation cancelled by user


.EXAMPLE
    PS C:\Repos\> Get-ChildItem -Depth 0 -Directory | Set-backupsEmail -EmailAddress jbloggs@users.noreply.github.com -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value                            
        ---              -----                            
        EmailAddress     jbloggs@users.noreply.github.com
        Verbose          True                             
        Global           False                            
        Local            True                            
        Path                                              
        Quiet            False                            
        ParameterSetName Local                            
        PipelineInput    True                             
        ScriptName       Set-PKGitEmail                   
        ScriptVersion    2.0.0                            

        BEGIN: Set git local config user email address

        [ad-dns] Get directory object
        [C:\Repos\ad-dns] Verify git repo
        [C:\Repos\ad-dns] Get current email address
        [C:\Repos\ad-dns] Current email address is jbloggs@users.noreply.github.com
        [C:\Repos\ad-dns] No change needed

        Scope          : Local
        Target         : ad-dns
        IsChanged      : False
        CurrentAddress : jbloggs@users.noreply.github.com
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : No change needed

        [backups] Get directory object
        [C:\Repos\backups] Verify git repo
        [C:\Repos\backups] Get current email address
        [C:\Repos\backups] No email address found
        [C:\Repos\backups] Set email address
        [C:\Repos\backups] Successfully configured email address

        Scope          : Local
        Target         : backups
        IsChanged      : True
        CurrentAddress : -
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : Successfully configured email address

        [chef] Get directory object
        [C:\Repos\chef] Verify git repo
        [C:\Repos\chef] Get current email address
        [C:\Repos\chef] Current email address is testymctesterson@domain.local
        [C:\Repos\chef] Set email address
        [C:\Repos\chef] Successfully configured email address

        Scope          : Local
        Target         : chef
        IsChanged      : True
        CurrentAddress : testymctesterson@domain.local
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : Successfully configured email address

        [psmodules] Get directory object
        [C:\Repos\psmodules] Verify git repo
        [C:\Repos\psmodules] Get current email address
        [C:\Repos\psmodules] No email address found
        [C:\Repos\psmodules] Set email address
        [C:\Repos\psmodules] Successfully configured email address

        Scope          : Local
        Target         : psmodules
        IsChanged      : True
        CurrentAddress : -
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : Successfully configured email address

        [infra tools] Get directory object
        [C:\Repos\infra tools] Verify git repo
        [C:\Repos\infra tools] Get current email address
        [C:\Repos\infra tools] No email address found
        [C:\Repos\infra tools] Set email address
        [C:\Repos\infra tools] Successfully configured email address

        Scope          : Local
        Target         : infra tools
        IsChanged      : True
        CurrentAddress : -
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : Successfully configured email address

        END  : Set git local config user email address

#>

[CmdletBinding(
    DefaultParameterSetName = "Local",
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(

    [Parameter(
        ParameterSetName = "Global",
        HelpMessage = "Set git email address globally on computer"
    )]
    [switch]$Global,

    [Parameter(
        ParameterSetName = "Local",
        HelpMessage = "Set git email address at local repo level"
    )]
    [switch]$Local,

    [Parameter(
        ParameterSetName = "Local",
        Position = 1,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "One or more absolute paths to git repos"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","FullName")]
    $Path,

    [Parameter(
        Mandatory = $True,
        Position = 2,
        HelpMessage="Email address for reporting"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_ -as [mailaddress]})]
    [string]$EmailAddress,

    [Parameter(
        HelpMessage = "Suppress non-verbose console output"
    )]
    [Switch]$Quiet
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = $MyInvocation.ExpectingInput

    $Scope = $Source
    
    # Display our parameters
    $CurrentParams = $PSBoundParameters
    If (($Source -eq "Local") -and (-not $PipelineInput.IsPresent) -and (-not $CurrentParams.Path)) {
        $CurrentParams.Path = $Path = $PWD
    }
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
    $WarningPreference = "Continue"

    #region Prerequisites

    If (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

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

    # Function to write an error message (as a string with no stacktrace info)
    Function Write-MessageError {
        [CmdletBinding()]
        Param([Parameter(ValueFromPipeline)]$Message)
        If (-not $Quiet.IsPresent) {$Host.UI.WriteErrorLine("$Message")}
        Else {Write-Verbose "$Message"}
    }

    # Function to see if we're in a git repo
    Function Test-Repo{
        [CmdletBinding()]
        Param($Path = $PWD)
        $TestCmd = $Null                
        $TestCmd = "git rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($TestCmd)
        $Location = Get-Location
        If (-not ($Location -eq $Path)) {
            Set-Location $Path
        }
        [bool]((Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True)
        If (-not ($Location -eq $Path)) {
            Set-Location $Location
        }
    } #end Test-Repo

    # Function to get the current mail address
    Function Get-Email {
        [Cmdletbinding()]
        Param()
        $GetEmailCmd = $Null                
        $GetEmailCmd = "git config --$($Scope.ToLower()) --get user.email"
        $ScriptBlock = [scriptblock]::Create($GetEmailCmd)
        Invoke-Command -ScriptBlock $ScriptBlock
    } # end Get-Email

    # Function to set the email address & return a boolean
    Function Set-Email {
        [Cmdletbinding()]
        Param()
        $SetEmailCmd = $Null                
        $SetEmailCmd = "git config --$($Scope.ToLower()) user.email $EmailAddress"
        $ScriptBlock = [scriptblock]::Create($SetEmailCmd)
        $Set = Invoke-Command -ScriptBlock $ScriptBlock
        [bool]((Get-Email) -eq $EmailAddress)
    } # end Get-Email


    #endregion Functions

    #region Splats

        $Param_WP = @{}
        $Param_WP = @{
            Activity         = $Activity
            CurrentOperation = $Null
            Status           = "Working"
            PercentComplete  = $Null
        }

    #endregion Splats

    #region Output object

    $OutputTemplate = [pscustomobject]@{
        Scope          = $Scope
        Target         = "Error"
        IsChanged      = $False
        CurrentAddress = "Error"
        NewAddress     = $EmailAddress
        Messages       = "Error"
    }
    Switch ($Scope) {
        Local  {$OutputTemplate.Target = $Path}
        Global {$OutputTemplate.Target = $Env:ComputerName}
    }
    
    #endregion Output object

    $Activity = "Set git $($Scope.ToLower()) config user email address"
    "BEGIN: $Activity" | Write-MessageInfo -FGColor Yellow -Title

    
}
Process {
    
    # Set the flag
    [switch]$Continue = $False


    Switch ($Scope) {
    
        Local {

            $CurrentLocation = Get-Location
            $Total = $Path.Count
            $Current = 0

            Foreach ($P in $Path) {
            
                $Output = $OutputTemplate.PSObject.Copy()
                $Output.Target = $P
                [switch]$Continue = $False

                $Msg = "Get directory object"
                "[$P] $Msg" | Write-MessageInfo -FGColor White

                $Current ++
                $Param_WP.PercentComplete = ($Current/$Total*100)
                $Param_WP.Status = $P
                $Param_WP.CurrentOperation = $Msg
                Write-Progress @Param_WP

                Try {
                    $Target = (Get-Item -Path $P -ErrorAction Stop | Where-Object {$_.PSIsContainer} -ErrorAction Stop).FullName
                    $Continue = $True
                    Set-Location $Target
                }
                Catch {
                    $Msg = "Failed to find path"
                    "[$P] $Msg" | Write-MessageError
                    $Output.IsChanged = $False
                    $Output.Messages = $Msg
                }
                
                If ($Continue.IsPresent) {
                    
                    # Reset flag
                    $Continue = $False
                    
                    $Msg = "Verify git repo"
                    "[$Target] $Msg" | Write-MessageInfo -FGColor White

                    $Param_WP.CurrentOperation = $Msg
                    Write-Progress @Param_WP

                    If ($IsRepo = Test-Repo -ErrorAction Stop) {
                        $TargetStr = "in $Target"
                        $Continue = $True
                    }
                    Else {
                        $Msg = "Failed to find git repo"
                        "[$Target] $Msg" | Write-MessageError
                        $Output.IsChanged = $False
                        $Output.Messages = $Msg
                    }
                }
                
                If ($Continue.IsPresent) {
                    
                    # Reset flag
                    $Continue = $False

                    $Msg = "Get current email address"
                    "[$Target] $Msg" | Write-MessageInfo -FGColor White

                    $Param_WP.CurrentOperation = $Msg
                    Write-Progress @Param_WP

                    If ($CurrentEmail = Get-Email) {
                        $Output.CurrentAddress = $CurrentEmail
                        $Msg = "Current email address is $CurrentEmail"
                        "[$Target] $Msg" | Write-MessageInfo -FGColor White
                        If ($CurrentEmail -eq $EmailAddress) {    
                            $Msg = "No change needed"
                            "[$Target] $Msg" | Write-MessageInfo -FGColor Cyan
                            $Output.Ischanged = $False
                            $Output.Messages = $Msg
                        }
                        Else {
                            $Continue = $True
                            $ConfirmMsg = "`n`n`tReplace git $($Scope.ToLower()) email address '$CurrentEmail' with '$EmailAddress'`n`t$TargetStr`n`n"
                        }
                    }
                    Else {
                        $Msg = "No email address found"
                        "[$Target] $Msg" | Write-MessageInfo -FGColor Cyan
                        $Output.CurrentAddress = "-"
                        $Continue = $True
                        $ConfirmMsg = "`n`n`tSet git $($Scope.ToLower()) email address to '$EmailAddress'`n`t$TargetStr`n`n"
                    }
                }

                If ($Continue.IsPresent) {
                    
                    $Msg = "Set email address"
                    "[$Target] $Msg" | Write-MessageInfo -FGColor White

                    $Param_WP.CurrentOperation = $Msg
                    Write-Progress @Param_WP

                    If ($PSCmdlet.ShouldProcess($ConfirmMsg,$P)) {
                        
                        Try {
                            If (Set-Email) {
                                $Msg = "Successfully configured email address"
                                "[$Target] $Msg" | Write-MessageInfo -FGColor Green
                                $Output.IsChanged = $True
                                $Output.Messages = $Msg
                            }
                            Else {
                                $Msg = "Failed to set email address"
                                "[$Target] $Msg" | Write-MessageError
                                $Output.IsChanged = $False
                                $Output.Messages = $Msg
                            }
                        }
                        Catch {
                            $Msg = "Failed to set email address"
                            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                            "[$Target] $Msg" | Write-MessageError
                            $Output.IsChanged = $False
                            $Output.Messages = $Msg
                        } 
                    }
                    Else {
                        $Msg = "Operation cancelled by user"
                        "[$Target] $Msg" | Write-MessageError
                        $Output.IsChanged = $False
                        $Output.Messages = $Msg                        
                    }
                }
                
                Write-Output $Output    
            
            } # end for each path
            
            Set-Location $CurrentLocation
        } #end local

        Global {
            
            $Target = $Env:ComputerName

            $Output = $OutputTemplate.PSObject.Copy()
            $Output.Target = $Target
            [switch]$Continue = $True

            $Current ++
            $Param_WP.PercentComplete = 100
            $Param_WP.Status = $Target
               
            If ($Continue.IsPresent) {
                    
                # Reset flag
                $Continue = $False

                $Msg = "Get current email address"
                "[$Target] $Msg" | Write-MessageInfo -FGColor White

                $Param_WP.CurrentOperation = $Msg
                Write-Progress @Param_WP

                If ($CurrentEmail = Get-Email) {
                    $Output.CurrentAddress = $CurrentEmail
                    $Msg = "Current email address is $CurrentEmail"
                    "[$Target] $Msg" | Write-MessageInfo -FGColor White
                    
                    If ($CurrentEmail -eq $EmailAddress) {
                        $Msg = "No change needed"
                        "[$Target] $Msg" | Write-MessageInfo -FGColor Cyan
                        $Output.Ischanged = $False
                        $Output.Messages = $Msg
                    }
                    Else {
                        $Continue = $True
                        $ConfirmMsg = "`n`n`tReplace git $($Scope.ToLower()) email address '$CurrentEmail' with '$EmailAddress'`n`n"
                    }
                }
                Else {
                    $Output.CurrentAddress = "-"
                    $Msg = "No email address found"
                    "[$Target] $Msg" | Write-MessageInfo -FGColor White
                    $Continue = $True
                    $ConfirmMsg = "`n`n`tSet git $($Scope.ToLower()) email address to '$EmailAddress'`n`n"
                }
            }

            If ($Continue.IsPresent) {
                    
                $Msg = "Set email address"
                "[$Target] $Msg" | Write-MessageInfo -FGColor White

                $Param_WP.CurrentOperation = $Msg
                Write-Progress @Param_WP

                If ($PSCmdlet.ShouldProcess($ConfirmMsg,$Env:ComputerName)) {
                        
                    Try {
                        If (Set-Email) {
                            $Msg = "Successfully configured email address"
                            "[$Target] $Msg" | Write-MessageInfo -FGColor Green
                            $Output.IsChanged = $True
                            $Output.Messages = $Msg
                        }
                        Else {
                            $Msg = "Failed to set email address"
                            "[$Target] $Msg" | Write-MessageError
                            $Output.IsChanged = $False
                            $Output.Messages = $Msg
                        }
                    }
                    Catch {
                        $Msg = "Failed to set email address"
                        If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                        "[$Target] $Msg" | Write-MessageError
                        $Output.IsChanged = $False
                        $Output.Messages = $Msg
                    } 
                }
                Else {
                    $Msg = "Operation cancelled by user"
                    "[$Target] $Msg" | Write-MessageError
                    $Output.IsChanged = $False
                    $Output.Messages = $Msg                        
                }
            }
                
            Write-Output $Output   
        
        } #end global
   
    } #end switch

} #end process
End {
    
    Write-Progress -Activity $Activity -Completed
    "END  : $Activity" | Write-MessageInfo -FGColor Yellow -Title

}
} #end Set-backupsEmail