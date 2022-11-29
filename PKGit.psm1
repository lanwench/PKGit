$ModuleName = "PKGit"
$Activity = "Importing module $ModuleName"

If (Test-Path $PSScriptRoot\Scripts -ErrorAction SilentlyContinue){
    Try {
        [object[]]$ScriptFiles = @( Get-ChildItem -Path $PSScriptRoot\Scripts\function_*.ps1 -ErrorAction SilentlyContinue )
        $Total = $ScriptFiles.Count
        $Current = 0
        Foreach($import in ($ScriptFiles | Sort-Object FullName)){
            $Current ++
            Try {
                Write-Progress -Activity "Importing module $ModuleName" -CurrentOperation $Import.Fullname -PercentComplete ($Current/$Total*100)
                . $import.fullname
            }
            Catch {
                Write-Error -Message "Failed to import function $($import.fullname): $_"
            }
        }
    }
    Catch {}
    Finally {
        Write-Progress -Activity $Activity -Completed
    }
}



