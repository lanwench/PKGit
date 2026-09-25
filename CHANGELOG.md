# PKGit Changelog

## 2026-09-25 · v02.01

**Consistency pass:** Added Stopwatch timing to all 13 functions (Begin block initialization, End block completion timing). Standardized loop variable naming across all functions: `$Item` for primary path iteration, `$GitRepos` for Test-PKGitRepo results, `$RepoPath` for secondary repo iteration. Updated all End blocks to use consistent timing format without activity description.

## 2026-09-17 · v02.00

**New:** Get-PKGitRepo — comprehensive repo analysis with owner info, privacy settings, branch tracking, commit counts, and detailed dates.

**Consistency pass:** Standardized .NOTES formatting, help text style, parameter declarations, and help-block indentation across all 13 functions. Added `Created` field to .NOTES blocks, fixed `Mandatory=$true` to bare `Mandatory`, stripped terminal periods from help text, and un-indented indented help blocks to flush-left.
