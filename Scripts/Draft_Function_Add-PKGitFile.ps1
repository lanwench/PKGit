#requires -Version 3
<#
Function Add-PKGitFile {
<#
.SYNOPSIS 
    Invokes 'git add', or 'git add .'

.DESCRIPTION
    Uses invoke-expression and "git pull" with optional parameters,
    displaying the origin master URL.
    Requires git, of course.

.NOTES
    Name    : Add-PKGitFile.ps1
    Author  : Paula Kingsley
    Version : 1.0.0
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0 - 2016-08-01 - Created script
        

    To do: 

.EXAMPLE
 

.LINK
    https://github.com/lanwench/PKGit

#>

[CmdletBinding(
    DefaultParameterSetName = "All",
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        ParameterSetName = "All",
        HelpMessage = "Quiet"
    )]
    [Switch]$AllFiles,

    [Parameter(
        ParameterSetName = "File",
        HelpMessage = "Name of file (stage all listed files)"
    )]
    [Switch[]]$Filename,

    [Parameter(
        ParameterSetName = "Folder",
        HelpMessage = "Name of folder (stage all contents in folder)"
    )]
    [Switch]$Directory,

    [Parameter(
        HelpMessage = "Quiet"
    )]
    [Switch]$Quiet = $False


)
Process {    
    
    # Version from comment block
    [version]$Version = "1.0.0"

    # Preferences
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    $WarningPreference = "SilentlyContinue"
    
    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose     = $False
    }

    # How did we get here
    $Source = $PSCmdlet.ParameterSetName
    
    # Current path
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
    
    
    Switch ($Source) {
        All {
            $Cmd = "git add . 2>&1"
            Try {
                $FGColor = "Cyan"
                $Msg = "Add all files in '$CurrentPath' to staging"
                $Host.UI.WriteLine($FGColor,$BGColor,"$Msg`?")
                If ($PSCmdlet.ShouldProcess($Null,$Msg)) {
                    $Results = Invoke-Expression -Command $Cmd @StdParams
                    Write-Output $Results
                    Break
                }
                Else {
                    $FGColor = "Yellow"
                    $Msg = "Operation cancelled by user"
                    $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
                    Break
                }
            }
            Catch {
                $Msg = "General error"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            
            }

        
        }
        File {
            Try {# Turn the array into an arraylist
                $FileArr.Clear()
                $FileArr = New-Object System.Collections.ArrayList -ArgumentList(,$FileName) @StdParams
            }
            Catch {
                $Msg = "Can't convert filename to arraylist object"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            }
            Try {
                #Test validity
                Foreach ($File in ($FileArr | Where-Object {(-not ($Null = Test-Path $_ @StdParams))})) {
                    $Msg = "Can't find file '$File'; name will be removed"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    $FileArr.Remove($File)
                }

                $FileArr | ForEach-Object {
                
                
                
                
                }



            }
            Catch {}

            If ($FileArr.Count -eq 0) {
                $Msg = "No file(s) in list"   
                $Host.UI.WriteErrorLine("ERROR: $Msg")
                #Break
            }
        }
        Directory {
            
            Try {
                If (-not ($Null = Test-Path $Directory @StdParams)) {
                    $Msg = "Can't find directory '$File'; name will be removed"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
            }
            Catch {}
        }
    } # end switch
  
    



}
    
    <#
    # Show the origin
    Try {
        $Origin = Get-PKGitRemoteOrigin -OutputType PullURLOnly -Verbose:$False -ErrorAction Stop
        If ($Origin -notlike "ERROR:*") {
            $FGColor = "Cyan"
            If (-not $Quiet.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"Pull URL: $Origin")}
        }
        Else {
            $FGColor = "Yellow"
            $Msg = "Can't find remote origin"
            $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
            Break
        }
    }
    Catch {
        $FGColor = "Yellow"
        $Msg = "Can't check remote origin"
        $ErrorDetails = $_.Exception.Message
        $Host.UI.WriteLine($BGColor,$FGColor,"$Msg`n$ErrorDetails")
        Break
    }
    #>
    # If we found it, continue
    Try {

        # Command
        $AddCmd = "git add "

        # Parameters to modify command
        If ($CurrentParams.Quiet) {
            $Pull = $Pull +" -q"
        }
        If ($CurrentParams.Verbose) {
            $Pull = "git pull -v"
        }
        
        # Danger Will Robinson
        If ($CurrentParams.Rebase -ne "NoRebase") {
            Write-Warning "You chose '$($Rebase.tolower())' rebase. Be sure you know what you're doing."
            Write-Warning "HAHAHA We aren't actually goind to use this yet."
            #$Pull = $Pull + "-r $Rebase"
        }

        # Redirect output
        $Cmd = $Pull + " 2>&1"

        Write-Verbose "Invoke '$Pull' to the current repo '$CurrentPath' from remote origin '$Origin'?"

        If ($PSCmdlet.ShouldProcess($CurrentPath,"Invoke '$Pull' from remote origin '$Origin'")) {
            $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False -WarningAction SilentlyContinue
            $Results
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
} #end Add-PKGitFile



#

function Save-OpenFile {
    $Files = @()

    foreach ($Tab in $psISE.PowerShellTabs)
    {
        foreach ($File in ($Tab.Files | Where-Object { !$_.IsUntitled }))
        {
            $Files += $File.FullPath
        }
    }

    $Files | Out-File -FilePath $SavePath
}





