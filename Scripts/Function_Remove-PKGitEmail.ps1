#requires -Version 4
Function Remove-PKGitEmail {
<#
.SYNOPSIS
    Removes the git config user email address from global or local scope

.DESCRIPTION
    Removes the git config user email address from global or local scope
    Verifies that git is installed/available in the path, and that the directory contains a git repo (if scope is local)
    Accepts pipeline input (for local scope)
    Supports ShouldProcess
    Returns a PSObject

.NOTES
    Name    : Function_Remove-PKGitEmail.ps1
    Created : 2026-06-03
    Author  : Paula Kingsley
    Version : 01.00
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **

        v01.00 - 2026-06-03 - Created script

.PARAMETER Path
    Path to git repository (default is current directory)

.EXAMPLE
    PS C:\> Remove-PKGitEmail -Scope Global -Verbose

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Scope            Global
        Verbose          True
        PipelineInput    False
        ScriptName       Remove-PKGitEmail
        ScriptVersion    1.0

        VERBOSE: [BEGIN: Remove-PKGitEmail] Remove git global config user email address
        VERBOSE: Commands:
                TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
                GetEmail    : git config --global --get user.email
                RemoveEmail : git config --global --unset user.email

        VERBOSE: [Mapple.local] Getting current global git email address
        VERBOSE: [Mapple.local] Current email address is jbloggs@users.noreply.github.com

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Remove git global email address 'jbloggs@users.noreply.github.com'" on target "Mapple.local".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

        VERBOSE: [Mapple.local] Successfully removed email address

        Scope          : Global
        Target         : Mapple.local
        IsChanged      : True
        RemovedAddress : jbloggs@users.noreply.github.com
        Messages       : Successfully removed email address

        VERBOSE: [END: Remove-PKGitEmail] Operation completed successfully

.EXAMPLE
    PS /Users/paula/repos> Get-ChildItem -Directory | Remove-PKGitEmail -Scope Local -Verbose

        VERBOSE: PSBoundParameters:

        Key              Value
        ---              -----
        Scope            Local
        Verbose          True
        PipelineInput    True
        ScriptName       Remove-PKGitEmail
        ScriptVersion    1.0

        VERBOSE: [BEGIN: Remove-PKGitEmail] Remove git local config user email address
        VERBOSE: Commands:
                TestGitRepo : git rev-parse --is-inside-work-tree 2>&1
                GetEmail    : git config --local --get user.email
                RemoveEmail : git config --local --unset user.email

        VERBOSE: [/Users/paula/repos/PKGit] Verifying that path contains a git repository
        VERBOSE: [/Users/paula/repos/PKGit] Getting current local git email address
        VERBOSE: [/Users/paula/repos/PKGit] Current email address is lanwench@users.noreply.github.com

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Remove git local email address 'lanwench@users.noreply.github.com' in /Users/paula/repos/PKGit" on target "/Users/paula/repos/PKGit".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

        VERBOSE: [/Users/paula/repos/PKGit] Successfully removed email address

        Scope          : Local
        Target         : /Users/paula/repos/PKGit
        IsChanged      : True
        RemovedAddress : lanwench@users.noreply.github.com
        Messages       : Successfully removed email address

        VERBOSE: [END: Remove-PKGitEmail] Operation completed successfully

#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Mandatory = $True,
        HelpMessage = "Target scope for removal of git config email: Global, Local, or All"
    )]
    [ValidateSet("Global","Local","All")]
    [string]$Scope,

    [Parameter(
        Position = 1,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "One or more absolute paths to git repos (required for Local or All scope)"
    )]
    [Alias("Name","FullName")]
    $Path = $PWD

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00"

    # How did we get here
    $ScriptName = $MyInvocation.MyCommand.Name
    [switch]$PipelineInput = $MyInvocation.ExpectingInput

    # Display our parameters
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where-Object {$CurrentParams.keys -notContains $_} |
        Where-Object {Test-Path variable:$_}| ForEach-Object {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Throw "git not found in path! Please ensure git is installed and available in the system path before running this script."
    }

    #region Functions
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
    } # end _GetEmail

    # Function to remove the email address
    Function _RemoveEmail {
        [CmdletBinding()]
        Param([string]$ScopeLevel, [string]$Path)
        if ($ScopeLevel -eq "local" -and $Path) {
            $RemoveCmd = "git -C '$Path' config --$ScopeLevel --unset user.email"
        } else {
            $RemoveCmd = "git config --$ScopeLevel --unset user.email"
        }
        $ScriptBlock = [scriptblock]::Create($RemoveCmd)
        $Null = Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction SilentlyContinue
    } #end _RemoveEmail

    #endregion Functions

    #region Splats
    $Param_WP = @{
        Activity         = "Remove git email address"
        CurrentOperation = $Null
        Status           = "Working"
        PercentComplete  = $Null
    }
    #endregion Splats

    $Activity = "Remove $($Scope.ToLower()) git config email address"
    $Msg = "[BEGIN: $ScriptName] $Activity"
    Write-Verbose $Msg

    $Commands = [PSCustomObject]@{
        TestGitRepo = 'git rev-parse --is-inside-work-tree 2>&1'
        GetEmail    = 'git config --$($Scope.ToLower()) --get user.email'
        RemoveEmail = 'git config --$($Scope.ToLower()) --unset user.email'
    }
    Write-Verbose "Commands: `n`t$($Commands | Format-List | out-string )"
}

Process {

    [switch]$Continue = $False
    Switch ($Scope) {
        {$_ -in "Local","All"} {
            # Process each path and remove local email address
            $Total = $Path.Count
            $Current = 0

            Foreach ($P in $Path) {
                [switch]$Continue = $False

                # Validate directory exists and contains a git repository
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

                # Verify the directory contains a git repository
                If ($Continue.IsPresent) {
                    $Continue = $False

                    [object[]]$RepoCheck = Test-PKGitRepo -Path $P -Verbose:$False -ErrorAction Stop
                    If ($RepoCheck) {
                        $Continue = $True
                    }
                    Else {
                        $Msg = "Path doesn't appear to contain a git repository!"
                        Write-Warning "[$Target] $Msg"
                        Continue
                    }
                }

                # Get current email and remove if present
                If ($Continue.IsPresent) {
                    $Msg = "Getting current local git email address"
                    Write-Verbose "[$Target] $Msg"
                    $Param_WP.CurrentOperation = $Msg
                    Write-Progress @Param_WP

                    $CurrentEmail = _GetEmail -ScopeLevel "local" -Path $P

                    If ($CurrentEmail) {
                        $Msg = "Current email address is $CurrentEmail"
                        Write-Verbose "[$Target] $Msg"

                        $Param_WP.CurrentOperation = "Removing email address"
                        Write-Progress @Param_WP

                        $ConfirmMsg = "Remove git local email address '$CurrentEmail'"
                        If ($PSCmdlet.ShouldProcess($Target, $ConfirmMsg)) {
                            Try {
                                _RemoveEmail -ScopeLevel "local" -Path $P
                                $VerifyEmail = _GetEmail -ScopeLevel "local" -Path $P

                                If ([string]::IsNullOrEmpty($VerifyEmail)) {
                                    $Msg = "Successfully removed email address"
                                    Write-Verbose "[$Target] $Msg"
                                    $Output = [PSCustomObject]@{
                                        Scope          = "Local"
                                        Target         = $Target
                                        IsChanged      = $True
                                        RemovedAddress = $CurrentEmail
                                        Messages       = $Msg
                                    }
                                }
                                Else {
                                    $Msg = "Failed to remove email address"
                                    Write-Warning "[$Target] $Msg"
                                    $Output = [PSCustomObject]@{
                                        Scope          = "Local"
                                        Target         = $Target
                                        IsChanged      = $False
                                        RemovedAddress = $CurrentEmail
                                        Messages       = $Msg
                                    }
                                }
                            }
                            Catch {
                                $Msg = "Failed to remove email address"
                                If ($ErrorDetails = $_.Exception.Message) { $Msg += " ($ErrorDetails)" }
                                Write-Warning "[$Target] $Msg"
                                $Output = [PSCustomObject]@{
                                    Scope          = "Local"
                                    Target         = $Target
                                    IsChanged      = $False
                                    RemovedAddress = $CurrentEmail
                                    Messages       = $Msg
                                }
                            }
                        }
                        Else {
                            $Msg = "Operation cancelled by user"
                            Write-Verbose "[$Target] $Msg"
                        }
                    }
                    Else {
                        $Msg = "No email address set; nothing to remove"
                        Write-Verbose "[$Target] $Msg"
                        $Output = [PSCustomObject]@{
                            Scope          = "Local"
                            Target         = $Target
                            IsChanged      = $False
                            RemovedAddress = "(none)"
                            Messages       = $Msg
                        }
                        Write-Output $Output
                    }
                }
            } # end for each path
        } #end local/all local processing

        {$_ -in "Global","All"} {
            # Remove global git email address
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
                Write-Verbose "[$Target] $Msg"

                $Param_WP.CurrentOperation = "Remove email address"
                Write-Progress @Param_WP

                $ConfirmMsg = "Remove git global email address '$CurrentEmail'"
                If ($PSCmdlet.ShouldProcess($Target, $ConfirmMsg)) {
                    Try {
                        _RemoveEmail -ScopeLevel "global"
                        $VerifyEmail = _GetEmail -ScopeLevel "global"

                        If ([string]::IsNullOrEmpty($VerifyEmail)) {
                            $Msg = "Successfully removed email address"
                            Write-Verbose "[$Target] $Msg"
                            $Output = [PSCustomObject]@{
                                Scope          = "Global"
                                Target         = $Target
                                IsChanged      = $True
                                RemovedAddress = $CurrentEmail
                                Messages       = $Msg
                            }
                        }
                        Else {
                            $Msg = "Failed to remove email address"
                            Write-Warning "[$Target] $Msg"
                            $Output = [PSCustomObject]@{
                                Scope          = "Global"
                                Target         = $Target
                                IsChanged      = $False
                                RemovedAddress = $CurrentEmail
                                Messages       = $Msg
                            }
                        }
                    }
                    Catch {
                        $Msg = "Failed to remove email address"
                        If ($ErrorDetails = $_.Exception.Message) { $Msg += " ($ErrorDetails)" }
                        Write-Warning "[$Target] $Msg"
                        $Output = [PSCustomObject]@{
                            Scope          = "Global"
                            Target         = $Target
                            IsChanged      = $False
                            RemovedAddress = $CurrentEmail
                            Messages       = $Msg
                        }
                    }
                }
                Else {
                    $Msg = "Operation cancelled by user"
                    Write-Verbose "[$Target] $Msg"
                }
            }
            Else {
                $Msg = "No email address set; nothing to remove"
                Write-Verbose "[$Target] $Msg"
                $Output = [PSCustomObject]@{
                    Scope          = "Global"
                    Target         = $Target
                    IsChanged      = $False
                    RemovedAddress = "(none)"
                    Messages       = $Msg
                }
            }
            # Only output on success, failure, or no email — not on cancel
            If ($Null -ne $Output) {
                Write-Output $Output
            }
        } #end global/all global processing
    } #end switch
} #end process
End {
    Write-Progress -Activity * -Completed
    Write-Verbose "[END: $ScriptName] Script ran successfully"
}
} #end Remove-PKGitEmail
