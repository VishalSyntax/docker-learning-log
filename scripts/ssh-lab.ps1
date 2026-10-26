# ==============================================================================
# ssh-lab.ps1 - Connect to the Docker Learning Lab EC2 instance via SSH (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Resolve-Path (Join-Path $ScriptDir "..\terraform")

# Retrieve metadata from Terraform
$InstanceId = (terraform -chdir="$TerraformDir" output -raw instance_id 2>$null)
$AwsRegion = (terraform -chdir="$TerraformDir" output -raw aws_region 2>$null)
if (-not $AwsRegion) { $AwsRegion = "ap-south-1" }
$KeyPath = (terraform -chdir="$TerraformDir" output -raw private_key_path 2>$null)

if (-not $InstanceId) {
    Write-Error "Error: Could not find Terraform state or instance_id. Deploy first with .\scripts\create-lab.ps1"
    exit 1
}

# Verify instance running status
$State = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].State.Name" --output text 2>$null)

if ($State -ne "running") {
    Write-Host "[!] Instance $InstanceId is currently in '$State' state." -ForegroundColor Yellow
    $StartNow = Read-Host "Would you like to start it now? [y/N]"
    if ($StartNow -match "^[Yy]$") {
        & "$ScriptDir\start-lab.ps1"
    } else {
        Write-Host "Aborting SSH. Start the lab with: .\scripts\start-lab.ps1" -ForegroundColor Yellow
        exit 1
    }
}

# Query the live public IP from AWS
$PublicIp = (aws ec2 describe-instances --instance-ids $InstanceId --region $AwsRegion --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

if (-not $PublicIp -or $PublicIp -eq "None") {
    Write-Error "Error: No public IP address found for instance $InstanceId."
    exit 1
}

# Resolve full path to key file
if (-not (Test-Path $KeyPath)) {
    $ResolvedKeyPath = Join-Path $TerraformDir $KeyPath
    if (Test-Path $ResolvedKeyPath) {
        $KeyPath = $ResolvedKeyPath
    } else {
        Write-Error "Error: Private key file not found at: $KeyPath"
        exit 1
    }
}

# Ensure Windows ACLs on private key file don't cause SSH bad permissions error
try {
    icacls $KeyPath /inheritance:r | Out-Null
    icacls $KeyPath /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Connecting to Docker Lab: ubuntu@$PublicIp" -ForegroundColor Green
Write-Host "Key file: $KeyPath" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan

ssh -o StrictHostKeyChecking=accept-new -i $KeyPath "ubuntu@$PublicIp" $args
