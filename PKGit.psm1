# PKGit

Write-Verbose "Loading functions for PKGit module"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

Try {
    Get-ChildItem "$ScriptPath\Scripts" -filter "*.ps*" | Where-Object {$_.Name -match "^function_"}  |  Select -Expand FullName | ForEach {
        $Function = Split-Path $_ -Leaf
        . $_
    }

} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}   

