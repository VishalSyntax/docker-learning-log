# ==============================================================================
# destroy-lab.ps1 - Tear down all Docker Learning Lab infrastructure (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

Write-Host "============================================================" -ForegroundColor Red
Write-Host "      [!] DANGER ZONE: Destroy Docker Learning Lab          " -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host "This will permanently terminate the EC2 instance, delete the"
Write-Host "EBS volume, and remove all VPC networking components."
Write-Host ""
Write-Host "[!] ALL UNCOMMITTED DOCKER LAB DATA AND CONTAINERS WILL BE LOST!" -ForegroundColor Yellow
Write-Host "Make sure you have pushed all your code & notes to GitHub."
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""

$Confirmation = Read-Host "To confirm destruction, please type 'destroy'"

if ($Confirmation -cne "destroy") {
    Write-Host "Confirmation mismatched. Aborting destroy process." -ForegroundColor DarkYellow
    exit 0
}

Write-Host "`n>> Proceeding with Terraform destruction..." -ForegroundColor Yellow
Set-Location $TerraformDir
terraform destroy

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  [+] All Docker Learning Lab cloud resources destroyed." -ForegroundColor Green
Write-Host "  AWS billing for this lab is now completely stopped (`$0.00)." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
