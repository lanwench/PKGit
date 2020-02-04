#requires -Version 3
Function Test-PKGitRepo {
<#
.SYNOPSIS 
    Verifies that the current directory is managed by git

.DESCRIPTION
    Verifies that the current directory is managed by git
    Uses invoke-expression and "git rev-parse --is-inside-work-tree"
    Returns a boolean
    Requires git, of course!

.NOTES
    Name    : Function_Test-PKGitRepo.ps1
    Created : 2016-05-29
    Author  : Paula Kingsley
    Version : 02.00.0000
    History :
    
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **

        v1.0.0      - 2016-05-29 - Created script
        v1.0.1      - 2016-05-29 - Moved into separate file,
                                   updated verbose output
        v1.0.2      - 2016-06-06 - Added requires statement for parent
                                   module, link to github repo  
        v1.0.3      - 2016-08-01 - Renamed with Function_ prefix
        v02.00.0000 - 2019-07-22 - General updates/standardization                             

.LINK
    https://github.com/lanwench/PKGit

.EXAMPLE
    PS C:\> Test-PKGitRepo -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key              Value             
        ---              -----             
        Verbose          True              
        Path             C:\Temp           
        Quiet            False             
        PipelineInput    False             
        ScriptName       Test-PKGitRepo    
        ScriptVersion    2.0.0             

        VERBOSE: [Prerequisites] Verify git.exe
        VERBOSE: [Prerequisites] git.exe version 2.22.0.1 found in 'C:\Program Files\git\cmd'

        BEGIN: Test directory for git repo (git rev-parse --is-inside-work-tree)

        [C:\Temp] git.exe version 2.22.0.1 found in 'C:\Program Files\Git\cmd'
        [C:\Temp] Path is valid
        [C:\Temp] Test for git repo
        [C:\Temp] Path does not contain a git repo

        END  : Test directory for git repo (git rev-parse --is-inside-work-tree)

        ComputerName Path    IsGitRepo ErrorMessage                    
        ------------ ----    --------- ------------                    
        TABBY        C:\Temp     False Path does not contain a git repo


.EXAMPLE
    PS C:\Users\lsimpson\projects> GCI -Directory -recurse | Test-PKGitRepo -Quiet | Format-Table -AutoSize 

        ComputerName Path                                                        IsGitRepo   ErrorMessage                    
        ------------ ----                                                        ---------   ------------                    
        TABBY        C:\Users\lsimpson\projects                                      False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\others                               False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\Personal                             False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\Profiles                              True                                   
        TABBY        C:\Users\lsimpson\projects\Work                                  True                                   
        TABBY        C:\Users\lsimpson\projects\Work\.vscode                          True                                   
        TABBY        C:\Users\lsimpson\projects\Work\IBTest                           True                                   
        TABBY        C:\Users\lsimpson\projects\Work\ADTools\Scripts                  True                                   
        TABBY        C:\Users\lsimpson\projects\others\PhatGit                        True                                   
        TABBY        C:\Users\lsimpson\projects\others\posh-git                      False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\others\PhatGit\en-US                  True                                   
        TABBY        C:\Users\lsimpson\projects\others\posh-git\0.7.3                False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\others\posh-git\0.7.3\en-US          False   Path does not contain a git repo
        TABBY        C:\Users\lsimpson\projects\Personal\PKChef                       True                                   
        TABBY        C:\Users\lsimpson\projects\Personal\PKGit                        True                                   
        


#>
[CmdletBinding()]
Param(
    [Parameter(
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "One or more paths"
    )]
    [Alias("Name","FullName")]
    [ValidateNotNullOrEmpty()]
    #$Path = $PWD,
    $Path = (Get-Location).Path,

    [Parameter(
        HelpMessage = "Hide all non-verbose console output"
    )]
    [Alias("SuppressConsoleOutput")]
    [Switch] $Quiet
)
Begin {
    
    # Version from comment block
    [version]$Version = "02.00.0000"

    # Show our settings
    [switch]$PipelineInput = $MyInvocation.ExpectingInput
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    # General-purpose splat
    $StdParams = @{}
    $StdParams = @{
        Verbose     = $False
        ErrorAction = "Stop"
    }

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

    # Function to write an error as a string (no stacktrace)
    Function Write-MessageError {
        [CmdletBinding()]
        Param([Parameter(ValueFromPipeline)]$Message)
        $Host.UI.WriteErrorLine("$Message")
    }

    # Function to test for repo (beyond looking for hidden .git folders)
    Function IsGitRepo{
        $Cmd = "git rev-parse --is-inside-work-tree  2>&1"
        $Results = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False
        If ($Results -eq $True) {$True}
        Else {$False}
    }

    #endregion Functions

    #region Prerequisites

    $Msg = "Verify git.exe"
    Write-Verbose "[Prerequisites] $Msg"

    If (-not ($GitCmd = Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorMessage("[Prerequisites] $Msg")
        Break
    }
    Else {
        $Msg = "git.exe version $($GitCmd.Version) found in '$(Split-Path $GitCmd.Source)'"
        Write-Verbose "[Prerequisites] $Msg" 
    }

    #endregion Prerequisites

    # So we can get back to the original location
    $StartLocation = Get-Location 

    $Activity = "Test directory for git repo (git rev-parse --is-inside-work-tree)"
    "BEGIN: $Activity" | Write-Messageinfo -FGcolor Yellow -Title

}
Process {    
    
    $Total = ($Path -as [array]).Count
    $Current = 0

    Foreach ($P in $Path) {
    
        $Current ++
        
        $Output = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Path         = $P
            IsGitRepo    = "Error"
            ErrorMessage = "Error"
        }

        Try {
            $P = [System.IO.DirectoryInfo]$P
            "[$($P.FullName)] $Msg" | Write-Messageinfo -FGColor White
            Write-Progress -Activity $Activity -Status $P.FullName -CurrentOperation $Msg -PercentComplete ($Current/$Total*100)

            If ($Null = Test-Path -Path $P.FullName -PathType Container -ErrorAction SilentlyContinue) {
                
                $Output.Path = $P.FullName
                $Msg = "Path is valid"
                "[$($P.FullName)] $Msg" | Write-Messageinfo -FGColor Green
            
                $Location = Set-Location $P.FullName -PassThru @StdParams

                $Msg = "Test for git repo"
                "[$($Location.Path)] $Msg" | Write-Messageinfo -FGColor White
                Write-Progress -Activity $Activity -Status $P.FullName -CurrentOperation $Msg -PercentComplete ($Current/$Total*100)
                
                Try {
                
                    $Test = IsGitRepo -ErrorAction SilentlyContinue
                
                    If ($Test) {
                        $Msg = "Path contains a git repo"
                        "[$($P.FullName)] $Msg" | Write-Messageinfo -FGColor Green
                        $Output.IsGitRepo = $True
                        $Output.ErrorMessage = $Null
                    }
                    Else {
                        $Msg = "Path does not contain a git repo"
                        "[$($P.FullName)] $Msg" | Write-MessageError
                        $Output.IsGitRepo = $False
                        $Output.ErrorMessage= $Msg
                    }
                }
                Catch {
                    $Msg = "Operation failed"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
                    "[$($($P.FullName))] $Msg" | Write-MessageError
                    $Output.ErrorMessage= $Msg
                }
            }
            Else {
                $Msg = "Invalid path"
                "[$P] $Msg" | Write-MessageError
                $Output.IsGitRepo = $False
                $Output.ErrorMessage= $Msg
            }   
        }
        Catch {
            $Msg = "Invalid path"
            If ($ErrorDetails = $_.Exception.Message) {$Msg += " ($ErrorDetails)"}
            "[$P] $Msg" | Write-MessageError
            $Output.IsGitRepo = $False
            $Output.ErrorMessage= $Msg
        }
        
        $Null = Set-Location $StartLocation
        Write-Output $Output

    } # End foreach

}
End{

    $Null = Set-Location $StartLocation
    Write-Progress -Activity $Activity -Completed
    "END  : $Activity" | Write-Messageinfo -FGcolor Yellow -Title
    
}
} #end Test-PKGitRepo
