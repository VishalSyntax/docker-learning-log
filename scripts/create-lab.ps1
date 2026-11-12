# ==============================================================================
# create-lab.ps1 - Initialize and deploy the Docker Learning Lab infrastructure (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "      Initializing Docker Learning Lab Deployment           " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Terraform Directory: $TerraformDir"
Write-Host ""

# Check prerequisites
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "Error: 'terraform' CLI is not installed or not in PATH."
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "Error: 'aws' CLI is not installed or not in PATH."
    exit 1
}

Set-Location $TerraformDir

# Step 1: Terraform Init
Write-Host ">> Step 1/4: Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 2: Terraform Validate
Write-Host "`n>> Step 2/4: Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 3: Terraform Plan
Write-Host "`n>> Step 3/4: Creating execution plan..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Step 4: Confirmation & Apply
Write-Host "`n>> Step 4/4: Ready to apply infrastructure." -ForegroundColor Yellow
$Confirm = Read-Host "Proceed with deploying the infrastructure to AWS? [y/N]"
if ($Confirm -match "^[Yy]$") {
    Write-Host "Applying plan..." -ForegroundColor Green
    terraform apply tfplan
    if (Test-Path "tfplan") { Remove-Item "tfplan" }

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "  [+] Docker Learning Lab Infrastructure Created Successfully!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    terraform output
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Wait 1-2 minutes for user-data bootstrap script to complete installation."
    Write-Host "2. Connect to your instance with:  .\scripts\ssh-lab.ps1"
    Write-Host "3. Check status anytime with:     .\scripts\status.ps1"
    Write-Host "4. When done for the day:         .\scripts\stop-lab.ps1"
} else {
    Write-Host "Deployment cancelled by user. Removing temporary plan file." -ForegroundColor DarkYellow
    if (Test-Path "tfplan") { Remove-Item "tfplan" }
    exit 0
}
