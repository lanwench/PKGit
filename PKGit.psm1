# PKGit

Write-Verbose "Loading functions for PKGit module"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

Try {
    Get-ChildItem "$ScriptPath\Scripts" -filter "*.ps*" | Where-Object {$_.Name -like "function_*"}  |  Select -Expand FullName | ForEach {
        $Function = Split-Path $_ -Leaf
        . $_
    }

    #If ($Host.Name -match "ISE") {
        #Try {
            #$GitAlias = "$ScriptPath\Files\git_ise.cmd"
            #If (($Null = Get-Command git.exe) -and ($Null = Get-Item -path $GitAlias -EA SilentlyContinue)) {
            #    Set-Alias -Name git -Value $GitAlias -Description "Fix bogus stderr with git in the PS ISE" -Force -Scope Local -Confirm:$False -Verbose:$False -EA SilentlyContinue
            #}
        #}
        #Catch {}
    #}

} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}   

