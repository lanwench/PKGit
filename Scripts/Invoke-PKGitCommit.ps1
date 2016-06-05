#requires -Module PKGit
Function Invoke-PKGitCommit {
<#
.SYNOPSIS 
    Invokes git commit

.DESCRIPTION
    Uses invoke-expression and "git commit" with optional parameters
    Requires git, of course.

.NOTES
    Name    : Invoke-PKGitCommit.ps1
    Author  : Paula Kingsley
    Version : 1.0.0
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-05-29 - Created script
        

.EXAMPLE
    PS C:\> Invoke-PKGitCommit -Message "Updated some things" -AddAllTrackedChanges -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                          
        ---                  -----                                          
        Message              Updated some things
        AddAllTrackedChanges True                                           
        InvokeGitPush        False                                          
        Verbose              True                                           
        Quiet                False                                          
        Confirm              False                                          
        Path                 C:\MyRepo          
        ComputerName         PKINGSLEY-04343                                
        ScriptName           Invoke-PKGitCommit                             
        ScriptVersion        1.0.0                                          

        VERBOSE: Add all changes/stage all tracked files, and invoke 'git commit -m "Updated some things -v"' ?

        On branch master
        Your branch is up-to-date with 'origin/master'.
        Untracked files:
	        Scripts/NewFile.ps1

        nothing added to commit but untracked files present

.EXAMPLE
    PS C:\> Invoke-PKGitCommit -Message "Updated some other things" -Quiet
        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                          
        ---                  -----                                          
        Message              Updated some things
        AddAllTrackedChanges True                                           
        InvokeGitPush        False                                          
        Verbose              True                                           
        Quiet                False                                          
        Confirm              False                                          
        Path                 C:\MyRepo          
        ComputerName         PKINGSLEY-04343                                
        ScriptName           Invoke-PKGitCommit                             
        ScriptVersion        1.0.0                                          

        VERBOSE: Invoke 'git commit -m "Updated some other things"' ?

        On branch master
        Your branch is up-to-date with 'origin/master'.
        Untracked files:
	        Scripts/NewFile.ps1

        nothing added to commit but untracked files present        



#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Mandatory = $True,
        HelpMessage = "Commit message"
    )]
    [String]$Message,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Add all tracked changes during commmit (git commit -a)"
    )]
    [Switch] $AddAllTrackedChanges = $False,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Add Invoke-PKGitPush after commit"
    )]
    [Switch] $InvokeGitPush = $False,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Quiet"
    )]
    [Switch]$Quiet = $False

)
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.0"

    # Preference
    $ErrorActionPreference = "Stop"

    # Where we are
    $CurrentPath = (Get-Location).Path

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("Path",$CurrentPath)
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Colors
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Make sure this is actually a repo
    If (($Null = Test-PKGitRepo -ErrorAction Stop -Verbose:$False) -ne $True) {
        $Msg = "Folder '$CurrentPath' not managed by git"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }
    
    # If it is,
    Try {

        If ($Quiet.IsPresent) {
            $IsQuiet = $True
            
        }
        Else {$IsQuiet = $False}
        If ($CurrentParams.Verbose) {
            $IsVerbose = $True
            $v = " -v"
        }
        Else {$IsVerbose = $False;$v = $Null}

        # Command
        $Commit = "git commit -m ""$Message$V"""
        $CommitConfirm = "Invoke '$Commit'"

        
        If ($AddAllTrackedChanges.IsPresent) {
            $CommitConfirm = ("Add all changes/stage all tracked files, and " + $CommitConfirm.replace("Invoke","invoke") )
            $Commit = "git commit -a -m ""$Message$V """
        }

        # Redirect output
        $Cmd = $Commit + " 2>&1"

        Write-Verbose "$CommitConfirm ?`n"
        
        # Prompt and go
        If ($PSCmdlet.ShouldProcess($CurrentPath,$CommitConfirm)) {
            $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False -WarningAction SilentlyContinue
            If (-not $Quiet.IsPresent) {Write-Output $Results}
            Else {$True}
            
            If ($InvokeGitPush.IsPresent) {
                If ($Results -notlike "*untracked files present*") {
                    Try {
                        Invoke-PKGitPush -Verbose:$IsVerbose -Quiet:$IsQuiet
                    }
                    Catch {
                        If (-not $Quiet.IsPresent) {
                            $Msg = "Can't run Invoke-PKGitPush"
                            $ErrorDetails = $_.Exception.Message
                            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                        }
                        Else {$False}
                    }
                }
                Else {
                    If (-not $Quiet.IsPresent) {
                        $FGColor = "Yellow"
                        $Msg = "`nWARNING: '$CurrentPath' contains untracked files; will not invoke git-push"
                        $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                    }
                }
            }

        }
        Else {
            $FGColor = "Yellow"
            $Msg = "Operation canceled"
            $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
        }
    }
    Catch {
        $Msg = "General error"
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
    }
}
} #end Invoke-PKGitCommit
