# scripts/start-dev.ps1
# Start the dev server with a unique port derived from the current branch name.
# Port = 4000 + (SHA256(branch) first 4 bytes as uint32) % 200

$ErrorActionPreference = "Stop"

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if (-not $branch) {
    Write-Error "Not in a git repository."
    exit 1
}

$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($branch))
} finally {
    $sha256.Dispose()
}

$first4 = $hashBytes[0..3]
[Array]::Reverse($first4)
$intHash = [System.BitConverter]::ToUInt32($first4, 0)
$port = 4000 + ($intHash % 200)

Write-Host "Branch: $branch"
Write-Host "Port:   $port"
Write-Host ""
$env:PORT = "$port"
pnpm dev
