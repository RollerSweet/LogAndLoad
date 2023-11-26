Param(
    [Parameter(Mandatory=$false)]
    [string]$vmname,

    [Parameter(Mandatory=$false)]
    [string]$csv_path,

    [Parameter(Mandatory=$false)]
    [string]$csv_init = 'Name', # Default value if not provided

    [Parameter(Mandatory=$false)]
    [string]$zip_uid,

    [Parameter(Mandatory=$true)]
    [string]$vCenter_IP,

    [Parameter(Mandatory=$true)]
    [string]$username,

    [Parameter(Mandatory=$true)]
    [string]$passwd
)

# Configure PowerCLI to ignore invalid certificates and connect to vCenter
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server $vCenter_IP -Protocol https -User $username -Password $passwd

# Initialize variables
$logs_directory_name = '\logs\'
$work_dir = $PSScriptRoot
$zip_destination_folder = 'uploads'
$download_destination = Join-Path $work_dir "$logs_directory_name$zip_uid"

# Ensure the download destination directory exists
if (!(Test-Path $download_destination)){
    New-Item -ItemType Directory -Path $download_destination -Force
}

# Function to verify and return the datastore name of a VM
function Get-DatastoreName {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )
    
    $vm = Get-VM $VMName
    $vmxPath = ($vm.ExtensionData.Config.Files.VmPathName)
    $datastoreName = ($vmxPath -split '\[|\]')[1]
    return $datastoreName
}

# Function to download logs for a single VM
function Download-VMLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$VMName
    )

    $datastoreName = Get-DatastoreName -VMName $VMName
    $datastore = Get-Datastore -Name $datastoreName
    $vmFolder = ($VMName.Trim())

    # Construct paths
    $localFolderPath = Join-Path $download_destination $vmFolder

    # Ensure local folder for VM logs exists
    if (!(Test-Path $localFolderPath)){
        New-Item -ItemType Directory -Path $localFolderPath -Force
    }

    # Mount the datastore as a PSDrive
    New-PSDrive -Name "VMDatastore" -PSProvider VimDatastore -Root "\" -Location $datastore
    Push-Location -Path "VMDatastore:\"

    # Navigate to VM folder and download log files
    Set-Location -Path $vmFolder
    $logFiles = Get-ChildItem -Filter "*.log"
    foreach ($file in $logFiles) {
        $destinationPath = Join-Path $localFolderPath $file.Name
        Copy-DatastoreItem -Item $file -Destination $destinationPath
    }

    # Clean up PSDrive
    Pop-Location
    Remove-PSDrive -Name "VMDatastore" -Force
}

# Function to compress downloaded logs into a zip file
function Archive-Logs {
    Compress-Archive -Path $download_destination -DestinationPath "$PSScriptRoot\$zip_destination_folder\$zip_uid.zip" -Force
}

# Main Script Execution
if ($vmname) {
    Download-VMLog -VMName $vmname
} elseif ($csv_path) {
    $vmList = Import-Csv -Path $csv_path
    foreach ($vm in $vmList) {
        Download-VMLog -VMName $vm.$csv_init
    }
}

# Disconnect from vCenter server
Disconnect-VIServer -Server $vCenter_IP -Confirm:$false

# Archive the downloaded logs
Archive-Logs
