param (
    [string]$Message = "Update Terraform infrastructure and GitHub Actions workflows"
)

$ErrorActionPreference = "Stop"

# Automatically resolve the top-level Git repository root
$gitRoot = (git rev-parse --show-toplevel 2>$null).Trim()
if ($gitRoot) {
    Set-Location $gitRoot
}

$labPath = "Week1/Lab2"

# Get current branch name
$branch = (git branch --show-current).Trim()

if (-not $branch) {
    Write-Host "Error: Not a git repository or no branch found." -ForegroundColor Red
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Yellow
Write-Host " LEVEL 1: PRE-PUSH TERRAFORM CHECKS" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

Write-Host "[1/3] Checking Code Formatting..." -ForegroundColor Cyan
terraform fmt -check -recursive $labPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Auto-formatting files with terraform fmt..." -ForegroundColor Yellow
    terraform fmt -recursive $labPath
}

Write-Host "[2/3] Validating Dev Environment..." -ForegroundColor Cyan
Push-Location "$labPath/environments/dev"
terraform init -backend=false | Out-Null
terraform validate
Pop-Location

Write-Host "[3/3] Validating Prod Environment..." -ForegroundColor Cyan
Push-Location "$labPath/environments/prod"
terraform init -backend=false | Out-Null
terraform validate
Pop-Location

Write-Host "=== All Level 1 Checks Passed Successfully! ===" -ForegroundColor Green

Write-Host "`n=========================================" -ForegroundColor Yellow
Write-Host " LEVEL 2: GIT STAGING & REVIEW" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow
Write-Host "Branch: $branch"
Write-Host "Commit Message: `"$Message`""
Write-Host "`nModified / New Files:" -ForegroundColor Cyan
git status -s

Write-Host "`n-----------------------------------------" -ForegroundColor Magenta
$approval = Read-Host "APPROVAL REQUIRED: Do you approve and want to COMMIT & PUSH to '$branch'? (y/N)"
Write-Host "-----------------------------------------" -ForegroundColor Magenta

if ($approval -eq "y" -or $approval -eq "Y") {
    Write-Host "=== Staging changes ===" -ForegroundColor Cyan
    git add .

    Write-Host "=== Committing changes ===" -ForegroundColor Cyan
    git commit -m "$Message"

    Write-Host "=== Pushing to remote branch '$branch' ===" -ForegroundColor Green
    git push origin $branch

    Write-Host "`n🎉 Successfully committed and pushed to GitHub!" -ForegroundColor Green
} else {
    Write-Host "Git push CANCELLED by user." -ForegroundColor Red
}
