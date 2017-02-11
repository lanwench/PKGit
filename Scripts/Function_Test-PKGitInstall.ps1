#requires -Version 3
Function Test-PKGitInstall {
<#
.SYNOPSIS    
    Looks for git.exe on the local computer

.DESCRIPTION
    Looks for git.exe on the local computer. Accepts full path to executable
    or drive/directory path and searches recursively until it finds the first match.
    Uses invoke-expression and "git rev-parse --is-inside-work-tree"
    Optional -BooleanOutput returns true/false instead of path.

.Notes
    Name    : Function_Test-PKGitInstall.ps1
    Author  : Paula Kingsley
    Version : 3.0.0
    History :
        
        ** PLEASE KEEP $VERSION UPDATED IN PROCESS BLOCK **
        
        v1.0.0 - 2016-05-29 - Created script
        v1.0.1 - 2-16-05-29 - Moved to individual file from main psm1 file; 
                              made path mandatory, added help
        v1.0.2 - 2016-05-29 - Changed true output for directory input 
                              to include full path to file
        v2.0.0 - 2016-06-06 - Renamed from Test-PKGitInstall, added alias,
                              added requires statement for parent module,
                              link to github repo
        v2.0.1 - 2016-08-01 - Renamed with Function_ prefix
        v3.0.0 - 2017-02-10 - Total overhaul and simplification

.EXAMPLE
    PS C:\> Test-PKGitInstall -Verbose
    # Searches all folders in the system %PATH% for git.exe

        VERBOSE: PSBoundParameters: 
	
        Key              Value                
        ---              -----                
        Verbose          True                 
        SearchFolders    False                
        DefaultFolders   False                
        FilePath                              
        BooleanOutput    False                
        ComputerName     PKINGSLEY-04343      
        ParameterSetName __DefaultParameterSet
        ScriptName       Test-PKGitInstall    
        ScriptVersion    3.0.0                

        VERBOSE: Found git.exe on PKINGSLEY-04343

        Name        : git.exe
        Path        : C:\Program Files\Git\cmd\git.exe
        Version     : 2.10.0.1
        Language    : English (United States)
        CommandType : Application
        FileDate    : 2017-01-18 23:45:52                              


.EXAMPLE
    PS C:\> Test-PKGitInstall -BooleanOutput
    # Searches all folders in the system %PATH% for git.exe, returning a boolean

        $True

.EXAMPLE
    C:\> Test-PKGitInstall -Verbose
    # Searches all folders in the system %PATH% for git.exe
    
        VERBOSE: PSBoundParameters: 
	
        Key              Value                
        ---              -----                
        Verbose          True                 
        SearchFolders    False                
        DefaultFolders   False                
        FilePath                              
        BooleanOutput    False                
        ComputerName     PKINGSLEY-04343      
        ParameterSetName __DefaultParameterSet
        ScriptName       Test-PKGitInstall    
        ScriptVersion    3.0.0             

        ERROR: Can't find git.exe on SERVER-666; please check your path

.EXAMPLE
    PS C:\> Test-PKGitInstall -SearchFolders -FilePath c:\users -Verbose
    # Searches a specific path for git.exe 


        VERBOSE: PSBoundParameters: 
	
        Key              Value            
        ---              -----            
        SearchFolders    True             
        FilePath         c:\users         
        DefaultFolders   False            
        BooleanOutput    False            
        ComputerName     WORKSTATION1  
        ParameterSetName Search           
        ScriptName       Test-PKGitInstall
        ScriptVersion    3.0.0            

        VERBOSE: Look for git.exe in c:\users on WORKSTATION1
        VERBOSE: C:\users

        VERBOSE: 3 matching file(s) found

        Name        : git.exe
        Path        : C:\users\jbloggs\AppData\Local\GitHub\PortableGit_25d850739bc178b2eb13c3e2a9faafea2f9143c0\cmd\git.exe
        Version     : 2.10.0.1
        Language    : English (United States)
        CommandType : Application
        FileDate    : 2016-04-11 09:18:03

        Name        : git.exe
        Path        : C:\users\jbloggs\AppData\Local\GitHub\PortableGit_25d850739bc178b2eb13c3e2a9faafea2f9143c0\mingw32\bin\git.exe
        Version     : 2.10.0.1
        Language    : English (United States)
        CommandType : Application
        FileDate    : 2016-04-11 09:18:03

        Name        : git.exe
        Path        : C:\users\gpalliser\Dropbox\Portable\git.exe
        Version     : 2.11.0.3
        Language    : English (United States)
        CommandType : Application
        FileDate    : 2017-01-22 14:01:48

.LINK
    https://github.com/lanwench/PKGit

#>

[cmdletbinding(DefaultParameterSetName = "__DefaultParameterSet")]
Param(
    [Parameter(
        ParameterSetName = "Search",
        Mandatory = $False,
        HelpMessage = "Search all folders, not just path statements"
    )]
    [switch]$SearchFolders,
    
    [Parameter(
        ParameterSetName = "Search",
        Mandatory = $False,
        HelpMessage = "Include default/standard folder paths only"
    )]
    [switch]$DefaultFolders,

        [Parameter(
        ParameterSetName = "Search",
        Mandatory = $False,
        HelpMessage = "Specific paths to search"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [string]$FilePath,
        
    [Parameter(
        Mandatory = $False,
        HelpMessage = "Return boolean output only"
    )]
    [switch]$BooleanOutput
)
Begin{

    # Version from comment block
    [version]$Version = "3.0.0"

    # Preference
    $ErrorActionPreference = "Stop"

    # Colors
    $BGColor = $Host.UI.RawUI.BackgroundColor
    
    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ComputerName",$Env:ComputerName)
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

}
Process {
    
    If ($SearchFolders.IsPresent) {
        
        If ($DefaultFoldersOnly.IsPresent) {
            $Include = "Users","Program Files","Program Files (x86)","Windows"
            $Msg = "Look for git.exe in directories $($Include -join(", ")) on $Env:ComputerName"
            Write-Verbose $Msg
        }
        ElseIf ($FilePath) {
            $Msg = "Look for git.exe in $FilePath on $Env:ComputerName"
            Write-Verbose $Msg
        }
        
        Try {
            $Results = @()
            If ($DefaultFoldersOnly.IsPresent) {[array]$TopLevelFolders = Get-ChildItem -Path "$($env:SystemDrive)\" -Directory @StdParams | Where-Object {$_.Name -in $Include} }
            Elseif ($FilePath) {[array]$TopLevelFolders = Get-Item -Path $FilePath @StdParams}
            Else {[array]$TopLevelFolders = Get-ChildItem -Path "$($env:SystemDrive)\" -Directory @StdParams}
            
            $Total = $TopLevelFolders.Count
            $Current = 0
            $CurrentOp = "Searching"
            Foreach ($Folder in $TopLevelFolders) {
                $Current++ 
                [int]$percentComplete = ($Current/$Total* 100)
                Write-Verbose $Folder.FullName
                Write-Progress -Activity $($Folder.FullName) -CurrentOperation $CurrentOp -percentcomplete $percentComplete -Status "$percentComplete%" #("$percentComplete% - $($Folder.FullName)")
                If ($ItemFound = $Folder | Get-ChildItem -File -Filter git.exe -Recurse -Force -ErrorAction SilentlyContinue) {
                    
                    Foreach ($Item in $ItemFound) {
                        
                        $FileDetails = Get-Command -Name $Item.Name -CommandType Application -ErrorAction SilentlyContinue

                        [array]$Results += New-Object PSObject -Property ([ordered]@{
                            Name        = $Item.Name
                            Path        = $Item.FullName
                            Version     = $FileDetails.Version
                            Language    = $FileDetails.FileVersionInfo.Language
                            CommandType = $FileDetails.CommandType
                            FileDate    = $Item.CreationTime
                        })
                    }
                }
            } # end for each subfolder from top-level

            If ($Results.Count -gt 0) {
                $Host.UI.WriteLine()
                If ($BooleanOutput.IsPresent) {$True}
                Else {
                    $Msg = "$($Results.Count) matching file(s) found"
                    Write-Verbose $Msg
                    Write-Output $Results
                }
            }
            Else {
                $Host.UI.WriteLine()
                If ($BooleanOutput.IsPresent) {$False}
                Else {
                    $Msg = "No matching file(s) found"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                }    
            }
        }
        Catch {Throw $_.Exception.Message}
    
    } # end if searching computer

    Else {

        $Msg = "Look for git.exe in any directory in system path on $Env:ComputerName"
        Try {
            If (-not ($Found = Get-Command -Name git.exe -EA SilentlyContinue -Verbose:$False)) {
                If ($BooleanOutput.IsPresent) {$False}
                Else {
                    $Msg = "Can't find git.exe on $Env:COMPUTERNAME; please check your path"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                }
            }
            Else {
                If ($BooleanOutput.IsPresent) {$True}
                Else {
                    $Msg = "Found git.exe on $Env:ComputerName"
                    Write-Verbose $Msg
                
                    $Item = Get-Item $Found.Path @StdParams

                    New-Object PSObject -Property ([ordered]@{
                        Name        = $Found.Name
                        Path        = $Found.Path
                        Version     = $Found.Version
                        Language    = $Found.FileVersionInfo.Language
                        CommandType = $Found.CommandType
                        FileDate    = $Item.CreationTime
                    })
                }        
            }
        }
        Catch {
            If ($BooleanOutput.IsPresent) {$False}
            Else {
                $Msg = "Can't check for git.exe on $Env:ComputerName"
                $ErrorDetails = $_.Exception.Message
            }    
        }
    }    
}
} #end Test-PKGitInstall

