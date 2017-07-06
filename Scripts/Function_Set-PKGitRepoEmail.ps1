#requires -Version 2
Function Set-PKGitRepoEmail {
<#
.Synopsis
    Sets the configured email address for an individual git repo

.Description
    Sets the configured email address for an individual git repo

.NOTES 
    Name    : Function_Set-PKGitRepoEmail.ps1
    Version : 1.0.0
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0 - 2017-07-05 - Created script

.LINK
    https://help.github.com/articles/setting-your-email-in-git/
        
.EXAMPLE
 


#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Git directory / repo for email config (default is current directory)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({If (Test-Path $_) {$True}})]
    [string]$RepoPath = $Pwd,

    [Parameter(
        Mandatory = $True,
        HelpMessage = "Username (hellokitty) or full email address (hellokitty@users.noreply.github.com)"
    )]
    [string]$Email
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "1.0.0"

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    If ($Source -ne "Named") {$CurrentParams.Cluster = "All"}
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }
    
    # Normalize email
    If ($Email -notlike "*@users.noreply.github.com") {$Email = "$Email@users.noreply.github.com"}
    
    # Create strings for invoke-expression
    $GetCommand = "git config user.email 2>&1"
    $SetCommand = "git config user.email $Email 2>&1"
    $TestRepoCommand = "git rev-parse --is-inside-work-tree 2>&1"

    If (-not ($GitCmd = Get-Command -Name git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path on $Env:ComputerName"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

}
Process {

    Try {
        
        $BackupLocation = $Null
        $Location = Get-Location

        If ($Location.Path -ne $RepoPath) {
            $BackupLocation = $Location
            $Location = Set-Location $RepoPath -PassThru
            $Msg = "Location set to $($Location.Path)"
            Write-Verbose $Msg
        }
        
        $Msg = "Verify that '$($Location.Path)' contains a git repo"
        Write-Verbose $Msg

        $IsRepo = Invoke-Expression -Command $TestRepoCommand @StdParams
        
        Switch ($IsRepo) {
            Default {
                $Msg = "$($Location.Path) does not contain a git repo"
                $Host.UI.WriteErrorLine($Msg)
            }
            $True {
                $CurrentEmail = Invoke-Expression -Command $GetCommand @StdParams

                If ($CurrentEmail -ne $Email) {
                    $Msg = "Change Git repo email address from '$CurrentEmail' to '$Email'"
                    Write-Verbose $Msg

                    If ($PSCmdlet.ShouldProcess($Location.Path,$Msg)) {
                        $ChangeEmail = Invoke-Expression -Command $SetCommand @StdParams
                        $NewEmail = Invoke-Expression -Command $GetCommand @StdParams
                        $Msg = "New email for $($Location.Path) set to $NewMail"
                        Write-Verbose $Msg
                    }
                    Else {
                        $Msg = "Operation cancelled by user"
                        Write-Verbose $Msg
                    }
                }
                Else {
                    $Msg = "Email address for this repo is already set to $CurrentEmail"
                    Write-Verbose $Msg
                }

                If ($BackupLocation) {
                    $Null = Set-Location $BackupLocation @StdParams
                    $Msg = "Location changed back to $BackupLocation"
                    Write-Verbose $Msg
                }   
            }
        } #end switch
    }
    Catch {
        $Msg = "Operation failed"
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $Msg; $ErrorDetails")
    }
}
} #end function