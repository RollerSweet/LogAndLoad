Param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [string]$vmname,

    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [string]$csv_path
)

$vCenter_IP = '1.1.1.200'
$username = 'administrator@vsphere.local'
$passwd = 'Ultra123!'
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server $vCenter_IP -Protocol https -user $username -Password $passwd

# Setting variables
$check_vm_error = 'the VM you specified doesnt exist in the enviroment, vm name:'
$logs_directory_name = '\logs\'
$work_dir = $PSScriptroot
$zipfile_name = 'zipped.zip'

$download_destination = $work_dir + $logs_directory_name # this variable needs to exist prior to running the script
echo $download_destination
if (!(Test-Path $download_destination)){
     New-Item -ItemType Directory -Path $work_dir -Name $logs_directory_name
}

$ps_drive_name = 'ds1'
$ps_drive_path = $ps_drive_name + ':\'

if(! ($csv_init)){
    $csv_init = 'Name'
}

cd $work_dir

########################################################################################################

function test-viserver-connection($vi_address){
    if(!($global:DefaultVIServer)){

    }
}

function verify_display_folder ([System.Array]$vm_1, [System.Array]$datastore_1){
    $vm_name_1 = $vm_1.name
    $vm_path = ($vm_1.ExtensionData.Layoutex.file | where-object {$_.name -like '*.vmx'}).name
    if($datastore_1.count -gt 1){
        $compare = ($vm_path.substring((($datastore_1 | Measure-object -Property Name -character).characters) +( $datastore_1.count * $datastore_1.count), ($vm_path.Length - ((($datastore_1 | Measure-object -Property Name -character).characters) + 3)- 4))).split("/")
    }
    else{
        $compare = ($vm_path.substring(($datastore_1.name).Length + 3, ($vm_path.length - (($datastore_1.name).Length + 3) - 4))).split("/")
    }

    if(($compare.tolower() | select -unique).count -ne 1){
        return($compare)
    }
}


function simple_download_log($vm_i){
    $vm_to_log = $vm_i
    $full_vm_data = Get-VM -Name $vm_to_log
    #check_vm_existence ($vmname)
    $datastore = Get-Datastore -Relatedobject $vm_to_log
    echo $datastore
    if(!(Get-Item -Path ($download_destination + $vm_to_log))){
        New-Item -ItemType Directory -Path $download_destination -name $vm_to_log
    }
    $log_path = $download_destination + $vm_to_log
    New-PSDrive -Location $datastore -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
    Set-Location $ps_drive_path
    $vmfolder = (get-childitem | where-object {$_.name -eq $vm_to_log}).name
    Set-Location $vmfolder
    $dwnl_file = (Get-childItem | where-object {$_.name -like '*.log'}).name
    Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
    Set-Location $PSScriptRoot
    Get-PSDrive $ps_drive_name | Remove-PsDrive -Force
    $file_name_diff_vms = ''
}


########################################################################################################

# 1.
if($vmname){
    simple_download_log($vmname)
}

#2.
if($csv_path){
    $vms = Import-Csv -Path $csv_path
    $propery_name = ($vms | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty $csv_init)
    if($propery_name -ne $csv_init){
        throw('invalid csv file, first collumn should start with ' + $csv_init)
    }

    foreach($vm in $vms){
        simple_download_log($vm.$csv_init)
    }
}

echo ($PSScriptroot + $zipfile_name)
Compress-Archive -Path $download_destination -DestinationPath ($PSScriptroot + '\' + $zipfile_name)


# 3.
Disconnect-VIServer -Server $vCenter_IP -Confirm:$false
#>