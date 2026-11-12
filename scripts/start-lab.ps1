# ==============================================================================
# start-lab.ps1 - Start the Docker Learning Lab EC2 instance (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          Starting Docker Learning Lab Instance             " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Read instance ID and region from Terraform output
$InstanceId = (terraform -chdir="$TerraformDir" output -raw instance_id 2>$null)
$AwsRegion = (terraform -chdir="$TerraformDir" output -raw aws_region 2>$null)
if (-not $AwsRegion) { $AwsRegion = "ap-south-1" }

if (-not $InstanceId) {
    Write-Error "Error: Could not retrieve instance_id from Terraform output. Make sure lab is created with .\scripts\create-lab.ps1"
    exit 1
}

Write-Host "Instance ID: $InstanceId"
Write-Host "AWS Region:  $AwsRegion"
Write-Host ""

# Check current state
$CurrentState = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].State.Name" --output text 2>$null)
Write-Host "Current instance state: $CurrentState"

if ($CurrentState -eq "running") {
    Write-Host "[+] Instance is already running." -ForegroundColor Green
} else {
    Write-Host ">> Requesting EC2 instance start..." -ForegroundColor Yellow
    aws ec2 start-instances --instance-ids $InstanceId --region $AwsRegion | Out-Null
    Write-Host "Waiting for instance to transition to 'running' state (this takes ~15-30s)..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $InstanceId --region $AwsRegion
    Write-Host "[+] Instance is now RUNNING!" -ForegroundColor Green
}

# Fetch live Public IP & Public DNS
$PublicIp = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
$PublicDns = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].PublicDnsName" --output text)
$KeyPath = (terraform -chdir="$TerraformDir" output -raw private_key_path 2>$null)

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  Lab Ready! Connection Details:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Public IP:     $PublicIp"
Write-Host "  Public DNS:    $PublicDns"
if ($KeyPath) {
    Write-Host "  SSH Key:       $KeyPath"
    Write-Host "  Connect via:   ssh -i $KeyPath ubuntu@$PublicIp"
    Write-Host "                 or run: .\scripts\ssh-lab.ps1" -ForegroundColor Cyan
}
Write-Host "============================================================" -ForegroundColor Green
