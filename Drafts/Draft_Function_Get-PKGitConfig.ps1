#requires -version 4.0
Function Get-PKGitConfig {

<#
.SYNOPSIS
    Get git configuration settings

.DESCRIPTION
    Git stores configurations settings in a simple text file format. Fortunately, this file is structured and predictable. This command will process git configuration information into PowerShell friendly output.

.NOTES
    Name    : Function_Get-PKGitConfig.ps1 
    Created : 2018-08-13
    Author  : Paula Kingsley
    Version : 04.03.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2018-08-13 - Created script based on Jeffery Hicks' Get-GitConfig
        The command assumes you have git installed. Otherwise, why would you be using this?
    
.PARAMETER Scope
    Possible values are Global,Local or System

.PARAMETER Path
    Enter the path to a .gitconfig file. You can use shell paths like ~\.gitconfig

.EXAMPLE
PS C:\> Get-GitConfig
   
Scope  Category  Name         Setting
-----  --------  ----         -------
global filter    lfs          git-lfs clean -- %f
global filter    lfs          git-lfs smudge -- %f
global filter    lfs          true
global user      name         Art Deco
global user      email        artd@company.com
global gui       recentrepo   C:/Scripts/Gen2Tools
global gui       recentrepo   C:/Scripts/PSVirtualBox
global gui       recentrepo   C:/Scripts/FormatFunctions
global core      editor       powershell_ise.exe
global core      autocrlf     true
global core      excludesfile ~/.gitignore
global push      default      simple
global color     ui           true
global alias     logd         log --oneline --graph --decorate
global alias     last         log -1 HEAD
global alias     pushdev      !git checkout master && git merge dev && git push && git checkout dev
global alias     st           status
global alias     fp           !git fetch && git pull
global merge     tool         kdiff3
global mergetool kdiff3       'C:/Program Files/KDiff3/kdiff3.exe' $BASE $LOCAL $REMOTE -o $MERGED

Getting global configuration settings

.EXAMPLE
PS C:\> Get-GitConfig -scope system | where category -eq 'filter'

Scope  Category Name Setting
-----  -------- ---- -------
system filter   lfs  git-lfs clean -- %f
system filter   lfs  git-lfs smudge -- %f
system filter   lfs  git-lfs filter-process
system filter   lfs  true

Get system configuration and only git filters.

.EXAMPLE
PS C:\> Get-GitConfig -path ~\.gitconfig | format-table -groupby category -property Name,Setting

Get settings from a configuration file and present in a grouped, formatted table.

.INPUTS
    none
.OUTPUTS
    [pscustomobject]

.LINK
    git
#>

[CmdletBinding(DefaultParameterSetName = "Scope")]
[OutputType([PSCustomObject])]
Param (
    [Parameter(
        Position = 0, 
        ParameterSetName = "Scope"
    )]
    [ValidateSet("Global", "System", "Local")]
    [ValidateNotNullOrEmpty()]
    [string[]]$Scope = "Global",
    
    [Parameter(
        ParameterSetName = "File",
        HelpMessage  = "Path to git config file if not searching by scope, e.g. ~\.gitconfig"
    )]
    [Alias("config")]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath = $Pwd.path,

    #[Parameter(
    #    ParameterSetName = "File",
    #    HelpMessage  = "Search subfolders for files matching 'config'"
    #)]
    #[switch]$SearchSubfolders,

    [Parameter(
        HelpMessage = "Suppress non-verbose/non-error console output"
    )]
    [Switch]$Quiet
)
    
Begin {

    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

    # How did we get here
    $Source = $PSCmdlet.ParameterSetName
    $ScriptName = $MyInvocation.MyCommand.Name
    
    # Display our parameters
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$ScriptName)
    $CurrentParams.Add("ScriptVersion",$Version)
    Switch ($Source) {
        Scope {$CurrentParams.FilePath = $Null}
        File {$CurrentParams.Scope = $Null}
    }
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    $WarningPreference = "Continue"
    $CurrentLocation = $PWD.Path

    # Prerequisites
    If (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $Msg = "git.exe not found in path"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

    # Make sure we're in a git repo
    Try {
        $TestCmd = "git rev-parse --is-inside-work-tree 2>&1"
        $ScriptBlock = [scriptblock]::Create($TestCmd)

        If (-not ($Null = Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True) {
            $Msg = "$($PWD.Path) is not a git repository"
            $Host.UI.WriteErrorLine("ERROR: $Msg")
            Break
        }
    }
    Catch {
        $Msg = "Failed to confirm $($PWD.Path) is a git repository"
        If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }


    $Activity = "Get git configuration data"

    Switch ($Source) {
        File {
            
            $Activity += " from file"
        
            If ($Verify = Get-Item $FilePath -ErrorAction SilentlyContinue) {
                If ($Verify.PSIsContainer) {
                    $Msg = "Invalid path '$FilePath'; please specify a file name"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    Break
                }
                Else {
                    
                    # Make sure we're in a git repo
                    Try {
                        $TestCmd = "git rev-parse --is-inside-work-tree 2>&1"
                        $ScriptBlock = [scriptblock]::Create($TestCmd)

                        If (-not ($Null = Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True) {
                            $Msg = "$($PWD.Path) is not a git repository"
                            $Host.UI.WriteErrorLine("ERROR: $Msg")
                            Break
                        }
                        Else {
                            #Set-Location ($Verify | Split-Path -Parent)
                            [string]$ConfigFile = Convert-Path -Path $FilePath

                        }
                    }
                    Catch {
                        $Msg = "Failed to confirm $($PWD.Path) is a git repository"
                        If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}
                        $Host.UI.WriteErrorLine("ERROR: $Msg")
                        Break
                    }
                }
            }
            Else {
                $Msg = "Invalid file path '$FilePath'"
                $Host.UI.WriteErrorLine("ERROR: $Msg")
                Break
            }
        }
        Scope {
            $Activity += " by scope"
            Switch ($Scope) {
                Local {
                    # Make sure we're in a git repo
                    Try {
                        $TestCmd = "git rev-parse --is-inside-work-tree 2>&1"
                        $ScriptBlock = [scriptblock]::Create($TestCmd)

                        If (-not ($Null = Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction Stop -Verbose:$False) -eq $True) {
                            $Msg = "$($PWD.Path) is not a git repository"
                            $Host.UI.WriteErrorLine("ERROR: $Msg")
                            Break
                        }
                    }
                    Catch {
                        $Msg = "Failed to confirm $($PWD.Path) is a git repository"
                        If ($ErrorDetails = $_.Exception.Message) {$Msg += "`n$Msg"}
                        $Host.UI.WriteErrorLine("ERROR: $Msg")
                        Break
                    }
                }
                Default {}
            }
        }
    }

    <#
    if ($Source -eq "File") {

        $Activity += " from file"
        
        If ($Verify = Get-Item $FilePath -ErrorAction SilentlyContinue) {
            If ($Verify.PSIsContainer) {
                $Msg = "Invalid path '$FilePath'; please specify a file name"
                $Host.UI.WriteErrorLine("ERROR: $Msg")
                Break
            }
            Else {
                #Set-Location ($Verify | Split-Path -Parent)
                [string]$ConfigFile = Convert-Path -Path $FilePath
            }
        }
           
            Switch ($Verify.PSIsContainer) {
                $True {
                    If ($SearchSubfolders.IsPresent) {
                        $Msg = "[$Source] Perform recursive search for '.git\config' in $FilePath"
                        Write-Verbose $Msg
                        [String[]]$ConfigFiles = Get-Childitem -Path $FilePath -Filter ".git" -Recurse -Hidden -ErrorAction SilentlyContinue | 
                            Get-Childitem -Filter "config" -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
                    }
                    Else {
                        $Msg = "'$FilePath' is a directory, not a file - try re-running command with -SearchSubfolders"
                        $Host.UI.WriteErrorLine("ERROR: $Msg")
                        Break
                    }
                }
                $False {
                    [string[]]$ConfigFiles = Convert-Path -Path $FilePath
                }
            }

            
        }

        
        #If (($Verify = Get-Item $FilePath -ErrorAction SilentlyContinue) -and -not $Verify.PSIsContainer) {
        #    #convert path value to a complete file system path
        #    $FilePath = Convert-Path -Path $FilePath
        #}
        #Else {
        #    $Msg = "Invalid configuration file path '$FilePath'"
        #    $Host.UI.WriteErrorLine("ERROR: $Msg")
        #    Break
        #}
    ##}
    #Else {
        $Activity += " by scope"
    #}
    #>

    # Internal function
    function _process {
        [cmdletbinding()]
        Param(
            [scriptblock]$scriptblock,
            [string]$Scope,
            [string]$File
            
        )

        Write-Verbose "[$Scope] Invoking $($scriptblock.tostring())"
        #invoke the scriptblock and save the text output
        If ($Data = Invoke-Command -scriptblock $scriptblock -Verbose:$False -ErrorAction SilentlyContinue) {
                
            # Split each line on the break
            [array]$DataArr = $Data -split("`n")

            foreach ($Line in $DataArr) {
                    
                #split each line of the config on the = sign & add to hashtable
                $split = $line.split("=")

                #split the first element again to get the category and name
                $Sub = $split[0].split(".")
                $Output = [PSCustomObject]@{
                    Scope    = $scope
                    Category = $sub[0]
                    Name     = $sub[1]
                    Setting  = $split[1]
                }
                If ($File) {$Output | Add-Member -MemberType NoteProperty -Name "FilePath" -Value $File}
                Write-Output $Output
            } #foreach line
            
        }
        Else {
            $Msg = "No configuration data found in target file or scope"
            $Host.UI.WriteWarningLine($Msg)

            $Output = [PSCustomObject]@{
                Scope    = $scope
                Category = $Null
                Name     = $Null
                Setting  = $Null
            }
            If ($File) {$Output | Add-Member -MemberType NoteProperty -Name "FilePath" -Value $File}
            Write-Output $Output
        }
    } # end function _process

    # Console output
    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = "Action: $Activity"
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}
        
} #begin
    
Process {

    Switch ($Source) {
        File {
            Foreach ($Item in $ConfigFiles) {
                $Msg = "[$Source] Config file path '$Item'"
                Write-Verbose $Msg
                
                # Create scriptblock & run helper function
                $Get = [scriptblock]::Create("git config --file $Item --list")
                _process -scriptblock $get -scope "File" -File $Item -Verbose:$False
            }
        }
        Scope {
            
            Foreach ($Item in $Scope) {
                
                $Msg = "[$Scope] Getting $Item config"
                Write-Verbose $Msg

                #the git command is case sensitive so convert to lower
                $Item = $Item.tolower()

                #create a scriptblock to run git config
                $Get = [scriptblock]::Create("git config --$Item --list")
        
                #call the helper function
                _process -scriptblock $Get -Scope $Item -Verbose:$False

                #Try {
                #    $Cmd = "git rev-parse --is-inside-work-tree  2>&1"
                #    If (($Null = Invoke-Expression -Command $Cmd -ErrorAction Stop -Verbose:$False) -eq $True) {
                #        #create a scriptblock to run git config
                #        $Get = [scriptblock]::Create("git config --$Item --list")
       # 
       #                 #call the helper function
       #                 _process -scriptblock $Get -Scope $Item -Verbose:$False
       #             }
       #             Else {
       #                 $Msg = "[$Scope] Not a git repository"
       #                 $Host.UI.WriteWarningLine("$Msg")
       #             }
       #         }
       #         Catch {}
                    
            } #foreach scope
        }
    } #end switch

} #process
    
End {
   #Write-Verbose "Ending $ScriptName"
} #end

} #end Get-PKGitConfig


#
#Function Get-PKGitConfigFile {
    

#}