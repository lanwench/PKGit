#requires -Version 3
Function Invoke-PKGitCommit {
<#
.SYNOPSIS 
    Uses invoke-expression and "git commit" with optional parameters in the current directory

.DESCRIPTION
    Uses invoke-expression and "git commit" with optional parameters in the current directory,
    including add all tracked changes (git commit -a). 
    First verifies that directory contains a repo. 
    Forces mandatory message. 
    Optional parameter invokes Invoke-PKGitPush and runs git-push if the commit
    was successful and there are no untracked files.
    Supports ShouldProcess.
    Requires git, of course.

.NOTES
    Name    : Function_Invoke-PKGitCommit.ps1
    Author  : Paula Kingsley
    Version : 1.0.1
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-06-05 - Created script
        v1.0.1 - 2016-08-01 - Renamed with Function_ prefix
        

.EXAMPLE
    PS C:\MyRepo> Invoke-PKGitCommit -Message "Updated some things" -AddAllTrackedChanges -Verbose
    # Runs git commit -a -m "Updated some things" -v 

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

        [master 6e5810a] Testing invoke-pkgitcommit after adding -v
        1 file changed, 211 insertions(+)
        create mode 100644 Scripts/MyFile.PS1

.EXAMPLE
    PS C:\MyRepo> Invoke-PKGitCommit -Message "Updated some other things" -Quiet
    # Runs git commit -a -m "Updated some things" and returns a boolean 
    
        True        

.EXAMPLE
    PS C:\MyRepo> Invoke-PKGitCommit -Message "Testing some stuff" -AddAllTrackedChanges -InvokeGitPush -Verbose
    # Runs git commit -a -m "Testing some stuff" and runs Invoke-PKGitPush if no untracked files are present
        
        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                
        ---                  -----                                
        Message              Testing some stuff    
        AddAllTrackedChanges True                                 
        InvokeGitPush        True                                 
        Verbose              True                                 
        Quiet                False                                
        Confirm              False                                
        Path                 C:\MyRepo
        ComputerName         PKINGSLEY-04343                      
        ScriptName           Invoke-PKGitCommit                   
        ScriptVersion        1.0.0                                


        VERBOSE: Add all changes/stage all tracked files, and invoke 'git commit -m "Testing some stuff" -v' ?

        On branch master
        Your branch is ahead of 'origin/master' by 1 commit.
          (use "git push" to publish your local commits)
        nothing to commit, working directory clean

        VERBOSE: PSBoundParameters: 
	
        Key           Value                                
        ---           -----                                
        Verbose       True                                 
        Quiet         False                                
        Confirm       False                                
        Path          C:\MyRepo
        ComputerName  PKINGSLEY-04343                      
        ScriptName    Invoke-PKGitPush                     
        ScriptVersion 1.0.0                                


        Push URL: https://github.com/JoeBloggs/myrepo.git

        VERBOSE: Invoke 'git push -v' from the current repo 'C:\MyRepo' to remote origin 'https://github.com/JoeBloggs/myrepo.git'?
        VERBOSE: Redirecting output streams.
        To https://github.com/JoeBloggs/myrepo.git
           01d597b..6e5810a  master -> master

.EXAMPLE
    PS C:\MyRepo> Invoke-PKGitCommit -Message "I like coffee" -AddAllTrackedChanges -Verbose -InvokeGitPush
    # Runs git commit -a -m "I like coffee" and does not run Invoke-PKGitPush due to untracked files

        VERBOSE: PSBoundParameters: 
	
        Key                  Value                                          
        ---                  -----                                          
        Message              I like coffee
        AddAllTrackedChanges True                                           
        Verbose              True                                           
        InvokeGitPush        True                                           
        Quiet                False                                          
        Confirm              False                                          
        Path                 C:\MyRepo         
        ComputerName         PKINGSLEY-04343                                
        ScriptName           Invoke-PKGitCommit                             
        ScriptVersion        1.0.0                                          


        VERBOSE: Add all changes/stage all tracked files, and invoke 'git commit -m "I like coffee" -v"' ?

        On branch master
        Your branch is up-to-date with 'origin/master'.
        Untracked files:
	        Scripts/NewFile.ps1

        nothing added to commit but untracked files present

        WARNING: 'C:\MyRepo' contains untracked files; will not invoke git-push

.LINK
    https://github.com/lanwench/PKGit

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
    [version]$Version = "1.0.1"

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
            $Msg = "Operation cancelled by user"
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
