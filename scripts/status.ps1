# ==============================================================================
# status.ps1 - Check current state and metadata of the Docker Learning Lab EC2 (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          Docker Learning Lab Status Overview               " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Read instance ID and region from Terraform output
$InstanceId = (terraform -chdir="$TerraformDir" output -raw instance_id 2>$null)
$AwsRegion = (terraform -chdir="$TerraformDir" output -raw aws_region 2>$null)
if (-not $AwsRegion) { $AwsRegion = "ap-south-1" }

if (-not $InstanceId) {
    Write-Error "Error: Could not retrieve instance_id from Terraform output. The lab might not be deployed yet."
    exit 1
}

# Fetch instance details via AWS CLI
$JsonRaw = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0]" --output json 2>$null)

if (-not $JsonRaw) {
    Write-Error "Error: Could not fetch details for instance $InstanceId from AWS."
    exit 1
}

$InstanceData = $JsonRaw | ConvertFrom-Json
$State = $InstanceData.State.Name
$InstanceType = $InstanceData.InstanceType
$PublicIp = if ($InstanceData.PublicIpAddress) { $InstanceData.PublicIpAddress } else { "N/A (Stopped)" }
$PrivateIp = $InstanceData.PrivateIpAddress
$LaunchTime = $InstanceData.LaunchTime

Write-Host "Instance ID:    $InstanceId"
Write-Host "AWS Region:     $AwsRegion"
Write-Host "Instance Type:  $InstanceType"
Write-Host "Private IP:     $PrivateIp"
Write-Host "Public IP:      $PublicIp"
Write-Host "Launch Time:    $LaunchTime"
Write-Host ""

if ($State -eq "running") {
    Write-Host "[+] Status: RUNNING" -ForegroundColor Green
    Write-Host "   Compute is ACTIVE. Docker environment is ready."
    Write-Host "   Connect anytime: .\scripts\ssh-lab.ps1" -ForegroundColor Cyan
    Write-Host "   Stop when done:  .\scripts\stop-lab.ps1" -ForegroundColor Yellow
} elseif ($State -eq "stopped") {
    Write-Host "[-] Status: STOPPED" -ForegroundColor Red
    Write-Host "   Compute is PAUSED (`$0.00/hr). EBS volume preserved."
    Write-Host "   To start lab:    .\scripts\start-lab.ps1" -ForegroundColor Yellow
} elseif ($State -eq "stopping") {
    Write-Host "[*] Status: STOPPING" -ForegroundColor Yellow
    Write-Host "   Instance is shutting down cleanly..."
} elseif ($State -eq "pending") {
    Write-Host "[*] Status: PENDING" -ForegroundColor Yellow
    Write-Host "   Instance is booting up..."
} else {
    Write-Host "[?] Status: $State"
}
Write-Host "============================================================" -ForegroundColor Cyan
