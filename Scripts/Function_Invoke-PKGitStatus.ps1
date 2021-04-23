#requires -Version 3
Function Invoke-PKGitStatus {
<#
.SYNOPSIS 
    Uses invoke-expression and "git status" with optional parameters in a folder hierarchy

.DESCRIPTION
    Uses invoke-expression and "git status" with optional parameters in a folder hierarchy
    Verifies git.exe is present
    Searches for hidden .git folder
    Returns a string

.NOTES
    Name    : Function_Invoke-PKGitStatus.ps1
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v01.00.0000 - 2021-04-19 - Created script
        
.LINK
    https://github.com/jbloggs/PKGit

.EXAMPLE
    PS C:\> 

.EXAMPLE
    PS C:\> Invoke-PKGitStatus -Path c:\temp -Recurse

        Invoke-PKGitPull : Git.exe not found on 'LABVDI21'; please install from https://git-scm.com/download/win
        At line:1 char:1
        + Invoke-PKGitPull -Path c:\temp -Recurse
        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
            + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Invoke-PKGitPull

#>
[CmdletBinding()]
Param(
    [Parameter(
        HelpMessage = "Folder or path",
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True
    )]
    [Alias("FullName")]
    $Path = $PWD,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Recurse through subfolders to find git repos in a hierarchy"
    )]
    [Switch] $Recurse

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

    # How did we get here?
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = $PSBoundParameters
    $ScriptName = $MyInvocation.MyCommand.Name
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path Variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "Git.exe not found on '$Env:ComputerName'; please install from https://git-scm.com/download/win"
        Write-Error $Msg
        Break
    }

    If ($Recurse.IsPresent) {
        $Activity = "Recursively search directories for git repos and invoke a 'git status' in folder if a git repo is found"
    }
    Else {
        $Activity = "Invoke a 'git status' in folder if a git repo is found"
    }

    $StartingLocation = Get-Location

}
Process {    
    
    Foreach ($P in $Path) {
        
        Try {
            $Folder = $Null
            If (($P -is [string]) -or ($P -is [System.Management.Automation.PathInfo])) {
                $Msg = "Get folder object"
                Write-Verbose "[$P] $Msg"
                Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $P
                $Folder = Get-Item -Path $P -Verbose:$False 
            }
            Elseif ($P -is [System.IO.FileSystemInfo]) {
                $Folder = $P
            }
            Else {
                $Msg = "Unknown object type; please use a valid path string or directory object"
                Throw $Msg
            }
        
            If ($Folder) {
                Switch ($Recurse) {
                    $True {$Msg = "Perform recursive search for git repos"}
                    $False {$Msg = "Search current folder for git repos"}
                }
                Write-Verbose "[$P] $Msg"
                Write-Progress -Activity $Activity -CurrentOperation $Msg -Status $P
                $Repo = $Folder | Get-Childitem -Recurse:$Recurse -Filter .git -Directory -Attributes H -ErrorAction Stop

                If ($Repo) {
                    $Msg = "$(($Repo -as [array]).Count) git repo(s) found"
                    Write-Verbose "[$P] $Msg"

                    Foreach ($R in $Repo) {
                        
                        $RepoLocation = $R.FullName | Split-Path -Parent
                        Set-Location $RepoLocation
                        $Status = Invoke-Expression -Command "git status 2>&1"

                        [pscustomObject]@{
                            Location = $RepoLocation
                            Summary  = ($Status | Select-String "your branch is").ToString()
                            Status   = $Status
                        } 

                        Set-Location $StartingLocation
                    }
                }
                Else {
                    $Msg = "No git repo(s) found"
                    Write-Warning "[$P] $Msg"
                }
            } # end if folder
        }
        Catch {
            $Msg = "Operation failed"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            Throw $Msg
        }    
    }
}
End {
    Write-Progress -Activity * -Completed
}
} #end Invoke-PKGitStatus


$Null = New-Alias -Name "Get-PKGitStatus" -Value Invoke-PKGitStatus -Force -Confirm:$False
