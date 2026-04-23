# scripts/new-worktree.ps1
# Create an isolated git worktree for an Issue and install dependencies.
# Usage: .\scripts\new-worktree.ps1 -IssueNumber 42 [-BaseBranch main]

param(
    [Parameter(Mandatory=$true)]
    [int]$IssueNumber,
    [string]$BaseBranch = "main"
)

$ErrorActionPreference = "Stop"

$WorktreeName = "issue-$IssueNumber"
$WorktreePath = ".claude/worktrees/$WorktreeName"
$BranchName = "feature/issue-$IssueNumber"

if (-not (Test-Path ".git")) {
    Write-Error "Not in a git repository root."
    exit 1
}

if (Test-Path $WorktreePath) {
    Write-Error "Worktree $WorktreePath already exists."
    exit 1
}

Write-Host "Fetching latest $BaseBranch..."
git fetch origin $BaseBranch

Write-Host "Creating worktree $WorktreePath (branch $BranchName from origin/$BaseBranch)..."
git worktree add -b $BranchName $WorktreePath "origin/$BaseBranch"

Push-Location $WorktreePath
try {
    Write-Host "Installing dependencies with pnpm..."
    pnpm install
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Worktree ready."
Write-Host "  Path:   $WorktreePath"
Write-Host "  Branch: $BranchName"
Write-Host "  Issue:  #$IssueNumber"
Write-Host ""
Write-Host "Next:"
Write-Host "  cd $WorktreePath"
Write-Host "  claude -w $WorktreeName"
