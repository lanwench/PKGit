##Description :


This module contains 7 cmdlets :  
**Get-PKGitModuleReadme**  
**Get-PKGitRemoteOrigin**  
**Invoke-PKGitCommit**  
**Invoke-PKGitPull**  
**Invoke-PKGitPush**  
**Test-PKGitInstall**  
**Test-PKGitRepo**  


##Get-PKGitModuleReadme :



Creates markdown-formatted output suitable for a Git readme.md by running Get-Help against a module, 
using either the Synopsis or Description label
Accepts pipeline input
Outputs a PSObject

###Parameters :


**ModuleName :**   


**LabelName :**   


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\>Get-PKGitModuleReadme -ModuleName gnopswindowschef -LabelName Synopsis -Verbose


# Creates markdown-formatted output suitable for a Git readme.md, for the GNOpsWindowsChef module, using the Synopsis label

    VERBOSE: PSBoundParameters: 

    Key           Value                
    ---           -----                
    ModuleName    gnopswindowschef     
    LabelName     Synopsis             
    Verbose       True                 
    ScriptName    Get-PKGitModuleReadme
    ScriptVersion 1.0.0                

    VERBOSE: Get module 'gnopswindowschef'
    VERBOSE: Found and module GNOpsWindowsChef, version 2.3.2
    VERBOSE: Get function commands from module 'GNOpsWindowsChef'
    VERBOSE: 8 functions/command(s) found

    VERBOSE: Get-GNOpsChefNode
    VERBOSE: Get-GNOpsWindowsChefClient
    VERBOSE: Install-GNOpsWindowsChefClient
    VERBOSE: Install-GNOpsWindowsChefDK
    VERBOSE: Invoke-GNOpsWindowsChefClient
    VERBOSE: Invoke-GNOpsWindowsChefClientDownload
    VERBOSE: New-GNOpsWindowsChefClientConfig
    VERBOSE: Remove-GNOpsWindowsChefClientService

    # Functions

    #### Get-GNOpsChefNode ####
    Show the configuration and status of a Chef node

    #### Get-GNOpsWindowsChefClient ####
    Looks for Chef-Client on a Windows server, using Invoke-Command as a job

    #### Install-GNOpsWindowsChefClient ####
    Installs chef-client on a remote machine from a local or downloaded MSI file
    using Invoke-Command and a remote job

    #### Install-GNOpsWindowsChefDK ####
    Downloads and installs the latest stable version of the ChefDK from the Omnitruck site

    #### Invoke-GNOpsWindowsChefClient ####
    Runs chef-client on a remote machine as a job using invoke-command

    #### Invoke-GNOpsWindowsChefClientDownload ####
    Downloads Chef-Client from a Gracenote or public Chef.io url

    #### New-GNOpsWindowsChefClientConfig ####
    Creates new files on a remote computer to register the node with the Gracenote Chef server the next time chef-client runs

    #### Remove-GNOpsWindowsChefClientService ####
    Looks for the chef-client service on a computer and prompts to remove it if found




-------------------------- EXAMPLE 2 --------------------------

PS C:\>"GNOpsWindowsChef" | Get-PKGitModuleReadme -LabelName Description


# Creates markdown-formatted output suitable for a Git readme.md, for the GNOpsWindowsChef module, using the Description label

    # Functions
    #### Get-GNOpsChefNode ####

    Uses knife search Returns a PSObject with Name, Environment, FQDN, IP, RunList, Roles, Recipes,
    Platform, Tags properties

    #### Get-GNOpsWindowsChefClient ####
    Looks for Chef-Client on a Windows server, using Invoke-Command as a job
    Returns a PSObject
    Accepts pipeline input
    Accepts ShouldProcess

    #### Install-GNOpsWindowsChefClient ####
    Installs chef-client on a remote machine from a local or downloaded MSI file
    using Invoke-Command and a remote job
    Allows selection of local MSI on target or download (of various versions)
    Parameter -ForceInstall forces installation even if existing version is present
    Allows for standard or verbose logging from msiexec (stores log on target computer)
    Returns jobs

    #### Install-GNOpsWindowsChefDK ####
    Downloads and installs the latest stable version of the ChefDK from the Omnitruck site
    as a background job or interactively

    #### Invoke-GNOpsWindowsChefClient ####
    Runs chef-client on a remote machine as a job using invoke-command
    Returns a PSObject for the job invocation results, as well as the job state(s)
    Accepts pipeline input
    Uses implicit or explicit credentials

    #### Invoke-GNOpsWindowsChefClientDownload ####
    Downloads Chef-Client from a Gracenote or public Chef.io url 
    Runs remote jobs using Invoke-WebRequest or downlevel .NET 
    Defaults to v. 12.5.1, but allows current/latest version
    Saves output file in $Env:Windir\Temp\chefclient.msi on target computer
    by default, but you can change the path and filename.
    Optional -Force parameter overwrites file if already present
    Accepts pipeline input

    #### New-GNOpsWindowsChefClientConfig ####
    Creates new files on a remote computer to register the node with the Gracenote Chef server the next time chef-client runs
    Files include client.rb file and a validation key
    Renames previous folder if found and -ForceFolderCreation is specified, otherwise will not proceed if folder already exists
    Uses Invoke-Command and a remote scriptblock
    Supports ShouldProcess
    Accepts pipeline input
    Returns a psobject

    #### Remove-GNOpsWindowsChefClientService ####
    Looks for the chef-client service on a computer and prompts to remove it if found
    Accepts pipeline input
    Outputs array








##Get-PKGitRemoteOrigin :


Gets the remote origin for a git repo, using the current path.
Uses invoke-expression and "git remote show origin."
Requires git.

###Parameters :


**OutputType :**   
If not specified, it defaults to Full .


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\Users\lsimpson\Projects >Get-PKGitRemoteOrigin -Verbose


# Returns the full remote origin details for the current repo

    VERBOSE: PSBoundParameters: 

    Key          Value                
    ---          -----                
    Verbose      True                 
    OutputType   Full                 
    ComputerName WORKSTATION1     
    ScriptName   Get-PKGitRemoteOrigin
    Version      1.1.0                

    VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'

    Fetch URL                              : https://github.com/lsimpson/projects.git
    Push URL                               : https://github.com/lsimpson/projects.git
    HEAD branch                            : master
    Remote branch                          : master tracked
    Local branch configured for 'git pull' : master merges with remote master
    Local ref configured for 'git push'    : master pushes to master (local out of date)




-------------------------- EXAMPLE 2 --------------------------

PS C:\Users\lsimpson\Projects >Get-PKGitRemoteOrigin  -OutputType PullURLOnly -Verbose


# Returns the pull URL only for the current repo

        VERBOSE: PSBoundParameters: 
    
        Key          Value                
        ---          -----                
        OutputType   PullURLOnly          
        Verbose      True                 
        ComputerName WORKSTATION1      
        ScriptName   Get-PKGitRemoteOrigin
        Version      1.1.0                

        VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'
        https://github.com/lsimpson/projects.git




-------------------------- EXAMPLE 3 --------------------------

PS C:\Users\lsimpson\Projects >Get-PKGitRemoteOrigin -OutputType PushURLOnly -Verbose


# Returns the push URL only for the current repo

    VERBOSE: PSBoundParameters: 

    Key          Value                
    ---          -----                
    OutputType   PushURLOnly          
    Verbose      True                 
    ComputerName WORKSTATION1      
    ScriptName   Get-PKGitRemoteOrigin
    Version      1.1.0                

    VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\projects'

    https://github.com/lsimpson/projects.git




-------------------------- EXAMPLE 4 --------------------------

PS C:\Users\lsimpson\catvideos>Get-PKGitRemoteOrigin -Verbose


# Returns an error in a directory not managed by git

    VERBOSE: PSBoundParameters: 

    Key          Value                
    ---          -----                
    OutputType   Full          
    Verbose      True                 
    ComputerName WORKSTATION1      
    ScriptName   Get-PKGitRemoteOrigin
    Version      1.1.0                

    VERBOSE: Find Git remote origin for 'C:\Users\lsimpson\catvideos'
    
    fatal: Not a git repository (or any of the parent directories): .git








##Invoke-PKGitCommit :


Uses invoke-expression and "git commit" with optional parameters in the current directory,
including add all tracked changes (git commit -a). 
First verifies that directory contains a repo. 
Forces mandatory message. 
Optional parameter invokes Invoke-PKGitPush and runs git-push if the commit
was successful and there are no untracked files.
Supports ShouldProcess.
Requires git, of course.

###Parameters :


**Message :**   


**AddAllTrackedChanges :**   
If not specified, it defaults to False .


**InvokeGitPush :**   
If not specified, it defaults to False .


**Quiet :**   
If not specified, it defaults to False .


**WhatIf :**   


**Confirm :**   


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\MyRepo>Invoke-PKGitCommit -Message "Updated some things" -AddAllTrackedChanges -Verbose


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




-------------------------- EXAMPLE 2 --------------------------

PS C:\MyRepo>Invoke-PKGitCommit -Message "Updated some other things" -Quiet


# Runs git commit -a -m "Updated some things" and returns a boolean 

    True




-------------------------- EXAMPLE 3 --------------------------

PS C:\MyRepo>Invoke-PKGitCommit -Message "Testing some stuff" -AddAllTrackedChanges -InvokeGitPush -Verbose


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




-------------------------- EXAMPLE 4 --------------------------

PS C:\MyRepo>Invoke-PKGitCommit -Message "I like coffee" -AddAllTrackedChanges -Verbose -InvokeGitPush


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








##Invoke-PKGitPull :


Uses invoke-expression and "git pull" with optional parameters,
displaying the origin master URL.
Requires git, of course.

###Parameters :


**Rebase :**   
If not specified, it defaults to NoRebase .


**Quiet :**   
If not specified, it defaults to False .


**WhatIf :**   


**Confirm :**   


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPull -Verbose


# Invokes git-pull in the current directory

    VERBOSE: PSBoundParameters: 

    Key           Value                                  
    ---           -----                                  
    Verbose       True                                   
    Quiet         False                                  
    Rebase        NoRebase                               
    Path          C:\Users\lsimpson\git\homework
    ComputerName  WORKSTATION1
    ScriptName    Invoke-PKGitPull                       
    ScriptVersion 1.0.1                                  

    Pull URL: https://github.com/lsimpson/homework.git

    VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?

    VERBOSE: Redirecting output streams.
    WARNING: Ignoring known Git command 'pull'. The process timeout will be disabled and may cause the ISE to hang.
    Updating 20bbf99..e7b5419
    Fast-forward
     .../Reports/kittens.csv   | 241 -------
     .../Essays/HeideggerAndKittens.docx | 757 ---------------------
     3 files changed, 998 deletions(-)
    From https://github.com/lsimpson/homework.git
       20bbf99..e7b5419  master     -> origin/master




-------------------------- EXAMPLE 2 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPull -Verbose


# Invokes git-pull in the current directory

    VERBOSE: PSBoundParameters: 

    Key           Value                                  
    ---           -----                                  
    Verbose       True                                   
    Quiet         False                                  
    Rebase        NoRebase                               
    Path          C:\Users\lsimpson\git\homework
    ComputerName  WORKSTATION1
    ScriptName    Invoke-PKGitPull                       
    ScriptVersion 1.0.1                                  

    Pull URL: https://github.com/lsimpson/homework.git

    VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?

    VERBOSE: Redirecting output streams.
    WARNING: Ignoring known Git command 'pull'. The process timeout will be disabled and may cause the ISE to hang.
    
    Already up-to-date.




-------------------------- EXAMPLE 3 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPull -Verbose


# Invokes git-pull in the current directory; cancels

    VERBOSE: PSBoundParameters: 

    Key           Value                                  
    ---           -----                                  
    Verbose       True                                   
    Quiet         False                                  
    Rebase        NoRebase                               
    Path          C:\Users\lsimpson\git\homework
    ComputerName  WORKSTATION1
    ScriptName    Invoke-PKGitPull                       
    ScriptVersion 1.0.1                                  

    Pull URL: https://github.com/lsimpson/homework.git

    VERBOSE: Invoke 'git pull -v' to the current repo 'C:\Users\lsimpson\git\homework' from remote origin 'https://github.com/lsimpson/Homework.git'?
    Operation cancelled








##Invoke-PKGitPush :


Uses invoke-expression and "git push" with optional parameters.
Verfies current directory holds a git repo and displays push URL.
Requires git, of course.

###Parameters :


**Quiet :**   
If not specified, it defaults to False .


**WhatIf :**   


**Confirm :**   


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPush -Verbose


VERBOSE: PSBoundParameters: 

    Key           Value                                  
    ---           -----                                  
    Verbose       True                                   
    Quiet         False                                  
    Path          C:\Users\lsimpson\git\homework
    ComputerName  WORKSTATION1     
    ScriptName    Invoke-PKGitPush                       
    ScriptVersion 1.0.0                                  

    Push URL: https://github.com/lsimpson/homework.git
    VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
    VERBOSE: Redirecting output streams.
    WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.
    To https://github.com/lsimpson/homework.git
       39760e5..20bbf99  master -> master




-------------------------- EXAMPLE 2 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPush -Verbose


# Invokes git-push in the current directory

    VERBOSE: PSBoundParameters: 

    Key           Value                                  
    ---           -----                                  
    Verbose       True                                   
    Quiet         False                                  
    Path          C:\Users\lsimpson\git\homework
    ComputerName  WORKSTATION1     
    ScriptName    Invoke-PKGitPush                       
    ScriptVersion 1.0.0                                  

    Push URL: https://github.com/lsimpson/homework.git

    VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
    VERBOSE: Redirecting output streams.
    WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.
    
    Already up-to-date.




-------------------------- EXAMPLE 3 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPush -Quiet


# Invokes git-push in the current directory, with -quiet
 
    WARNING: Ignoring known Git command 'push'. The process timeout will be disabled and may cause the ISE to hang.




-------------------------- EXAMPLE 4 --------------------------

PS C:\Users\lsimpson\git\homework>Invoke-PKGitPush


# Invokes git-push in the current directory and cancels when prompted to confirm

    Push URL: https://github.com/lsimpson/homework.git
    VERBOSE: Invoke 'git push -v' from the current repo 'C:\Users\lsimpson\git\homework' to remote origin 'https://github.com/lsimpson/homework.git' ?
    Operation cancelled








##Test-PKGitInstall :


Looks for git.exe on the local computer. Accepts full path to executable
or drive/directory path and searches recursively until it finds the first match.
Uses invoke-expression and "git rev-parse --is-inside-work-tree"
Optional -BooleanOutput returns true/false instead of path.

###Parameters :


**SearchFolders :**   
If not specified, it defaults to False .


**DefaultFolders :**   
If not specified, it defaults to False .


**FilePath :**   


**BooleanOutput :**   
If not specified, it defaults to False .


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\>Test-PKGitInstall -Verbose


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




-------------------------- EXAMPLE 2 --------------------------

PS C:\>Test-PKGitInstall -BooleanOutput


# Searches all folders in the system %PATH% for git.exe, returning a boolean

    $True




-------------------------- EXAMPLE 3 --------------------------

C:\>Test-PKGitInstall -Verbose


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




-------------------------- EXAMPLE 4 --------------------------

PS C:\>Test-PKGitInstall -SearchFolders -FilePath c:\users -Verbose


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








##Test-PKGitRepo :


Uses invoke-expression and "git rev-parse --is-inside-work-tree"
to verify that the current directory is managed by Git.
Returns a boolean.
Requires git, of course.

###Parameters :


###Examples :


-------------------------- EXAMPLE 1 --------------------------

PS C:\Users\lsimpson\projects>Test-PKGitRepo -Verbose


VERBOSE: PSBoundParameters: 

    Key          Value          
    ---          -----          
    Verbose      True           
    ComputerName PKINGSLEY-06398
    ScriptName   Test-PKGitRepo 

    VERBOSE: Check whether 'C:\Users\lsimpson\projects' contains a Git repo
    True




-------------------------- EXAMPLE 2 --------------------------

PS C:\Users\bsimpson\catvideos>Test-PKGitRepo -Verbose


VERBOSE: PSBoundParameters: 

    Key          Value          
    ---          -----          
    Verbose      True           
    ComputerName WORKSTATION14
    ScriptName   Test-PKGitRepo 

    VERBOSE: Check whether 'C:\Users\bsimpson\catvideos' contains a Git repo
    False










