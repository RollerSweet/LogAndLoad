param(
    [parameter(parametersetname ='one')]
    [string]$vm_name,

    [parameter()]
    [string]$csv_path,

    [parameter()]
    [string]$csv_init,

    [parameter()]
    [string]$vCenterIP
)


# Setting variables
$check_vm_error = 'the VM you specified doesnt exist in the enviroment, vm name:'
$logs_directory_name = 'logs\'
$work_dir = $PSScriptroot

$download_destination = $work_dir + $logs_directory_name # this variable needs to exist prior to running the script
if (!(Test-Path $download_destination)){
     New-Item -ItemType Directory -Path $work_dir -Name $logs_directory_name
}

$ps_drive_name = 'ds'
$ps_drive_path = $ps_drive_name + ':\'

#setting default values
if(! ($csv_init)){
    $csv_init = 'Name'
}

if(!(vm_name)){
    vm_name = $args[0]
}

if(! ($vcenter_IP)){
    $vCenter_IP = '1.1.1.200'
}

Connect-VIServer -Server $vCenter_IP -Protocol https -user "administrator@vsphere.local" -Password "Ultra123!"
cd $work_dir
function check_vm_existence ($vm_list_or_name){
    $all_vms = Get-VM *
    foreach ($vm in $vm_list_or_name){
        if(-not ($all_vms | where-object {$_.name -eq $vm})){
            echo ($check_vm_error + $vm)
        }
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
    echo  $vm_to_log
    $full_vm_data = Get-VM -Name $vm_to_log
    #check_vm_existence ($vmname)
    $datastore = Get-Datastore -Relatedobject $vm_to_log

    $file_name_diff_vm = (verify_display_folder $full_vm_data $datastore)
    if($file_name_diff_vm){
        if(!(Get-Item -Path ($download_destination + $file_name_diff_vm[0]))){
            New-Item -ItemType Directory -Path $download_destination -name $file_name_diff_vm[0]
            New-Item -Itemtype File -Path ($download_destination + $file_name_diff_vm[0]) -Name $vm_to_log
        }
        $vmfolder = $file_name_diff_vm[0]
        $log_path = $download_destination + $file_name_diff_vm[0]

        New-PSDrive -Location $datastore -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
        Set-Location $ps_drive_path
        $vmfolder = (get-childitem | where-object {$_.name -eq $file_name_diff_vm[0]}).name
        Set-Location $vmfolder
        $dwnl_file = (Get-childItem | where-object {$_.name -like '*.log'}).name
        Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
        Set-Location $PSScriptRoot
        Get-PSDrive $ps_drive_name | Remove-PSDrive -Force
        $file_name_diff_vms = ''
    }

    else{

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
}

#|>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>main code

#1
if($vm_name){
    simple_download_log($vm_name)
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

#3.
Disconnect-VIServer -Server $vCenterIP -Confirm:$false