# ==============================================================================
# stop-lab.ps1 - Stop the Docker Learning Lab EC2 instance (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          Stopping Docker Learning Lab Instance             " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Read instance ID and region from Terraform output
$InstanceId = (terraform -chdir="$TerraformDir" output -raw instance_id 2>$null)
$AwsRegion = (terraform -chdir="$TerraformDir" output -raw aws_region 2>$null)
if (-not $AwsRegion) { $AwsRegion = "ap-south-1" }

if (-not $InstanceId) {
    Write-Error "Error: Could not retrieve instance_id from Terraform output."
    exit 1
}

Write-Host "Instance ID: $InstanceId"
Write-Host "AWS Region:  $AwsRegion"
Write-Host ""

# Check current state
$CurrentState = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].State.Name" --output text 2>$null)
Write-Host "Current instance state: $CurrentState"

if ($CurrentState -eq "stopped") {
    Write-Host "[+] Instance is already stopped. Compute billing is paused." -ForegroundColor Green
    exit 0
}

Write-Host ">> Requesting EC2 instance stop..." -ForegroundColor Yellow
aws ec2 stop-instances --instance-ids $InstanceId --region $AwsRegion | Out-Null

Write-Host "Waiting for instance to transition to 'stopped' state (this takes ~30-60s)..." -ForegroundColor Yellow
aws ec2 wait instance-stopped --instance-ids $InstanceId --region $AwsRegion

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  [+] Instance is now STOPPED!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Cost-Saving Summary:" -ForegroundColor Cyan
Write-Host "- EC2 Compute (vCPU & RAM):  `$0.00 / hour (PAUSED)"
Write-Host "- Public IPv4 Address:        `$0.00 / hour (RELEASED)"
Write-Host "- EBS Root Volume (20GB gp3): ~`$0.05 / day (Keeps your containers & files safe)"
Write-Host ""
Write-Host "To resume your learning session tomorrow, simply run: .\scripts\start-lab.ps1" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
