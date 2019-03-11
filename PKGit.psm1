# PKGit

Write-Verbose "Loading functions for PKGit module"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

<#
Try {
    Get-ChildItem "$ScriptPath\Scripts" | Select -Expand FullName | ForEach {
        $Function = Split-Path $_ -Leaf
        . $_
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}   
#>

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
Try {
    Get-ChildItem "$ScriptPath\Scripts" -filter "*.ps*" | Where-Object {$_.Name -like "function_*"}  |  Select -Expand FullName | ForEach {
        $Function = Split-Path $_ -Leaf
        . $_
    }

    If ($Null = Get-Command git.exe) {
        Set-Alias -Name git -Value $ScriptPath\Files\git_ise.cmd -Description "Fix stderr issue with git in the PS ISE" -Force -Scope Local -Confirm:$False -Verbose:$False
    }

} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}   

