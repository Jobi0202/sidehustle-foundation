# scripts/cleanup-worktrees.ps1
# Remove worktrees whose branches have been merged into origin/main.
# Safe by default: prompts before removing anything. Pass -Force to skip prompts.

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "Fetching origin/main..."
git fetch origin main | Out-Null

$lines = git worktree list --porcelain
$worktrees = @()
$current = $null

foreach ($line in $lines) {
    if ($line -like "worktree *") {
        if ($current) { $worktrees += [PSCustomObject]$current }
        $current = @{ Path = $line.Substring(9).Trim(); Branch = $null }
    } elseif ($line -like "branch *") {
        $current.Branch = ($line.Substring(7).Trim() -replace "^refs/heads/", "")
    }
}
if ($current) { $worktrees += [PSCustomObject]$current }

$mergedRaw = git branch -r --merged "origin/main"
$mergedRefs = $mergedRaw | ForEach-Object { $_.Trim() }

foreach ($wt in $worktrees) {
    if (-not $wt.Path -or -not $wt.Branch) { continue }
    if ($wt.Path -notmatch "[\\/]\.claude[\\/]worktrees[\\/]") { continue }

    if ($mergedRefs -contains "origin/$($wt.Branch)") {
        if (-not $Force) {
            $reply = Read-Host "Remove merged worktree '$($wt.Path)' (branch $($wt.Branch))? [y/N]"
            if ($reply -ne "y") { Write-Host "Skipped."; continue }
        }
        Write-Host "Removing $($wt.Path)..."
        git worktree remove $wt.Path --force
        git branch -D $wt.Branch 2>$null
    } else {
        Write-Host "Keeping active worktree: $($wt.Path) (branch $($wt.Branch))"
    }
}

git worktree prune
Write-Host ""
Write-Host "Cleanup complete."
