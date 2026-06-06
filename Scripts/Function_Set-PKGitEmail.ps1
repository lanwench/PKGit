#requires -Version 4
Function Set-PKGitEmail {
<#
.SYNOPSIS
    Sets or changes the git config user email address in global or local scope

.DESCRIPTION
    Sets or changes the git config user email address in global or local scope.
    Verifies that git is installed/available in the path, and that the directory contains a git repo (if scope is local).
    If the email address is already set to the requested value, no change is made.
    Accepts pipeline input for the Path parameter (local scope only).
    Supports ShouldProcess.
    Returns a PSObject.

.NOTES
    Name    : Function_Set-PKGitEmail.ps1
    Created : 2018-08-13
    Author  : Paula Kingsley
    Version : 04.00
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **

        v01.00 - 2018-08-13 - Created script
        v01.01 - 2019-04-09 - Minor updates
        v02.00 - 2019-10-10 - Added pipeline input, overhauled, added inner functions, other updates
        v03.00 - 2021-05-24 - Simplified, removed custom console messages and Quiet parameter; fixed missing Activity variable
        v03.01 - 2024-06-01 - Updated help, simplified versions, added more verbose messages, other minor tweaks
        v04.00 - 2026-06-03 - Replaced -Global/-Local switches with mandatory -Scope parameter; cosmetic consistency pass

.PARAMETER Scope
    Target scope for git config email: Global or Local

.PARAMETER Path
    One or more absolute paths to git repos (required for Local scope; default is current directory)

.PARAMETER EmailAddress
    Email address to set

.EXAMPLE
    PS C:\> Set-PKGitEmail -Scope Global -EmailAddress jbloggs@domain.com -Verbose

        VERBOSE: PSBoundParameters:

        Key           Value
        ---           -----
        Scope         Global
        EmailAddress  jbloggs@domain.com
        Verbose       True
        Path
        PipelineInput False
        ScriptName    Set-PKGitEmail
        ScriptVersion 4.0

        VERBOSE: [BEGIN: Set-PKGitEmail] Set git global config user email address
        VERBOSE: Commands:

        TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
        GetEmail    : git config --global --get user.email
        SetEmail    : git config --global --add user.email <EmailAddress>

        VERBOSE: [Mapple.local] Getting current global git email address
        VERBOSE: [Mapple.local] Current email address is lanwench@users.noreply.github.com

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Replace git global email address 'lanwench@users.noreply.github.com' with 'jbloggs@domain.com'" on target "Mapple.local".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

        VERBOSE: [Mapple.local] Successfully configured email address

        Scope          : Global
        Target         : Mapple.local
        IsChanged      : True
        CurrentAddress : lanwench@users.noreply.github.com
        NewAddress     : jbloggs@domain.com
        Messages       : Successfully configured email address

        VERBOSE: [END: Set-PKGitEmail] Script ran successfully

.EXAMPLE
    PS C:\Repos\> Get-ChildItem -Depth 0 -Directory | Set-PKGitEmail -Scope Local -EmailAddress jbloggs@users.noreply.github.com -Verbose

        VERBOSE: PSBoundParameters:

        Key           Value
        ---           -----
        Scope         Local
        EmailAddress  jbloggs@users.noreply.github.com
        Verbose       True
        Path
        PipelineInput True
        ScriptName    Set-PKGitEmail
        ScriptVersion 4.0

        VERBOSE: [BEGIN: Set-PKGitEmail] Set git local config user email address
        VERBOSE: Commands:

        TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
        GetEmail    : git config --local --get user.email
        SetEmail    : git config --local --add user.email <EmailAddress>

        VERBOSE: [C:\Repos\ad-dns] Verifying that path is valid and contains a git repository
        VERBOSE: [C:\Repos\ad-dns] Getting current local git email address
        VERBOSE: [C:\Repos\ad-dns] Current email address is jbloggs@users.noreply.github.com
        VERBOSE: [C:\Repos\ad-dns] No change needed

        Scope          : Local
        Target         : C:\Repos\ad-dns
        IsChanged      : False
        CurrentAddress : jbloggs@users.noreply.github.com
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : No change needed

        VERBOSE: [C:\Repos\backups] Verifying that path is valid and contains a git repository
        VERBOSE: [C:\Repos\backups] Getting current local git email address
        VERBOSE: [C:\Repos\backups] No email address found

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Set git local email address to 'jbloggs@users.noreply.github.com' in C:\Repos\backups" on target "C:\Repos\backups".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

        VERBOSE: [C:\Repos\backups] Successfully configured email address

        Scope          : Local
        Target         : C:\Repos\backups
        IsChanged      : True
        CurrentAddress : (none)
        NewAddress     : jbloggs@users.noreply.github.com
        Messages       : Successfully configured email address

        VERBOSE: [END: Set-PKGitEmail] Script ran successfully

#>

[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(

    [Parameter(
        Mandatory = $True,
        HelpMessage = "Target scope for git config email: Global or Local"
    )]
    [ValidateSet("Global","Local")]
    [string]$Scope,

    [Parameter(
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "One or more absolute paths to git repos (required for Local scope)"
    )]
    [Alias("Name","FullName")]
    $Path,

    [Parameter(
        Mandatory = $True,
        Position = 1,
        HelpMessage = "Email address to set"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_ -as [mailaddress]})]
    [string]$EmailAddress

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "04.00"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput

    # Display our parameters
    $CurrentParams = $PSBoundParameters
    If (($Scope -eq "Local") -and (-not $PipelineInput.IsPresent) -and (-not $CurrentParams.Path)) {
        $CurrentParams.Path = $Path = $PWD
    }
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path variable:$_}| ForEach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    #region Prerequisites

    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path!"
    }

    #endregion Prerequisites

    #region Functions

    # Function to verify a path contains a git repo
    Function _TestRepo {
        [CmdletBinding()]
        Param([string]$Path = $PWD)
        $TestCmd = "git -C '$Path' rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($TestCmd)
        [bool]((Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True)
    } #end _TestRepo

    # Function to get the current email address
    Function _GetEmail {
        [CmdletBinding()]
        Param([string]$ScopeLevel, [string]$Path)
        if ($ScopeLevel -eq "local" -and $Path) {
            $GetEmailCmd = "git -C '$Path' config --$ScopeLevel --get user.email"
        } else {
            $GetEmailCmd = "git config --$ScopeLevel --get user.email"
        }
        $ScriptBlock = [scriptblock]::Create($GetEmailCmd)
        Invoke-Command -ScriptBlock $ScriptBlock
    } #end _GetEmail

    # Function to perform email change: compare, prompt, set, verify, return output
    Function _PerformEmailChange {
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
        param($Target, $CurrentEmail, $ConfirmMsg, [string]$Path)

        $Output = [PSCustomObject]@{
            Scope          = $Scope
            Target         = $Target
            IsChanged      = $False
            CurrentAddress = if ($CurrentEmail) { $CurrentEmail } else { "(none)" }
            NewAddress     = $EmailAddress
            Messages       = $Null
        }

        If ($CurrentEmail -eq $EmailAddress) {
            $Msg = "No change needed"
            Write-Verbose "[$Target] $Msg"
            $Output.Messages = $Msg
        }
        Else {
            $Msg = "Set email address"
            Write-Verbose "[$Target] $Msg"

            If ($PSCmdlet.ShouldProcess($Target, $ConfirmMsg)) {
                Try {
                    If ($Scope -eq "local" -and $Path) {
                        $SetEmailCmd = "git -C '$Path' config --$($Scope.ToLower()) --add user.email $EmailAddress"
                    } Else {
                        $SetEmailCmd = "git config --$($Scope.ToLower()) --add user.email $EmailAddress"
                    }
                    $ScriptBlock = [scriptblock]::Create($SetEmailCmd)
                    $Null = Invoke-Command -ScriptBlock $ScriptBlock
                    $VerifyEmail = _GetEmail -ScopeLevel $Scope.ToLower() -Path $Path

                    If ($VerifyEmail -eq $EmailAddress) {
                        $Msg = "Successfully configured email address"
                        Write-Verbose "[$Target] $Msg"
                        $Output.IsChanged = $True
                        $Output.Messages = $Msg
                    }
                    Else {
                        $Msg = "Failed to set email address"
                        Write-Warning "[$Target] $Msg"
                        $Output.Messages = $Msg
                    }
                }
                Catch {
                    $Msg = "Failed to set email address"
                    If ($ErrorDetails = $_.Exception.Message) { $Msg += " ($ErrorDetails)" }
                    Write-Warning "[$Target] $Msg"
                    $Output.Messages = $Msg
                }
            }
            Else {
                $Msg = "Operation cancelled by user"
                Write-Verbose "[$Target] $Msg"
                $Output.Messages = $Msg
            }
        }
        return $Output
    } #end _PerformEmailChange

    #endregion Functions

    #region Splats
    $Param_WP = @{
        Activity         = "Set git email address"
        CurrentOperation = $Null
        Status           = "Working"
        PercentComplete  = $Null
    }
    #endregion Splats

    $Activity = "Set git $($Scope.ToLower()) config user email address"

    $Commands = [PSCustomObject]@{
        TestGitRepo = "git rev-parse --is-inside-work-tree 2>&1"
        GetEmail    = "git config --$($Scope.ToLower()) --get user.email"
        SetEmail    = "git config --$($Scope.ToLower()) --add user.email <EmailAddress>"
    }

    $Msg = "[BEGIN: $ScriptName] $Activity"
    Write-Verbose $Msg
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"
}

Process {

    [switch]$Continue = $False

    Switch ($Scope) {
        Local {
            # Process each path and set local email address
            $Total = $Path.Count
            $Current = 0

            Foreach ($P in $Path) {
                [switch]$Continue = $False
                $Output = $Null

                $Msg = "Verifying that path is valid and contains a git repository"
                Write-Verbose "[$P] $Msg"

                $Current ++
                $Param_WP.PercentComplete = ($Current/$Total*100)
                $Param_WP.Status = $P
                $Param_WP.CurrentOperation = $Msg
                Write-Progress @Param_WP

                Try {
                    If ($Null = Test-Path -Path $P -PathType Container -ErrorAction Stop) {
                        $Target = $P
                    }
                    $Continue = $True
                }
                Catch {
                    $Msg = "Invalid directory path!"
                    Write-Warning "[$P] $Msg"
                    Continue
                }

                If ($Continue.IsPresent) {
                    $Continue = $False

                    If (_TestRepo -Path $P -ErrorAction Stop) {
                        $Continue = $True
                    }
                    Else {
                        $Msg = "Path doesn't appear to contain a git repository!"
                        Write-Warning "[$Target] $Msg"
                        Continue
                    }
                }

                If ($Continue.IsPresent) {
                    $Msg = "Getting current local git email address"
                    Write-Verbose "[$Target] $Msg"

                    $Param_WP.CurrentOperation = $Msg
                    Write-Progress @Param_WP

                    $CurrentEmail = _GetEmail -ScopeLevel "local" -Path $P
                    If ($CurrentEmail) {
                        $Msg = "Current email address is $CurrentEmail"
                        $ConfirmMsg = "Replace git local email address '$CurrentEmail' with '$EmailAddress' in $Target"
                    }
                    Else {
                        $Msg = "No email address found"
                        $ConfirmMsg = "Set git local email address to '$EmailAddress' in $Target"
                    }
                    Write-Verbose "[$Target] $Msg"

                    $Param_WP.CurrentOperation = "Set email address"
                    Write-Progress @Param_WP

                    $Output = _PerformEmailChange -Target $Target -CurrentEmail $CurrentEmail -ConfirmMsg $ConfirmMsg -Path $P -Confirm:$ConfirmPreference
                }

                If ($Null -ne $Output) {
                    Write-Output $Output
                }

            } # end foreach path
        } #end local

        Global {
            # Set global git email address for computer
            $Target = [System.Net.Dns]::GetHostName()
            $Param_WP.PercentComplete = 100
            $Param_WP.Status = $Target

            $Msg = "Getting current global git email address"
            Write-Verbose "[$Target] $Msg"
            $Param_WP.CurrentOperation = $Msg
            Write-Progress @Param_WP

            $CurrentEmail = _GetEmail -ScopeLevel "global"
            If ($CurrentEmail) {
                $Msg = "Current email address is $CurrentEmail"
                $ConfirmMsg = "Replace git global email address '$CurrentEmail' with '$EmailAddress'"
            }
            Else {
                $Msg = "No email address found"
                $ConfirmMsg = "Set git global email address to '$EmailAddress'"
            }
            Write-Verbose "[$Target] $Msg"

            $Param_WP.CurrentOperation = "Set email address"
            Write-Progress @Param_WP

            $Output = _PerformEmailChange -Target $Target -CurrentEmail $CurrentEmail -ConfirmMsg $ConfirmMsg -Confirm:$ConfirmPreference
            Write-Output $Output

        } #end global
    } #end switch

} #end process

End {

    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] Script ran successfully"
}

} #end Set-PKGitEmail
