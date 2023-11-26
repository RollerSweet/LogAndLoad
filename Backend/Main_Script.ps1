Param(
    [Parameter(Mandatory=$false)]
    [string]$vmname,

    [Parameter(Mandatory=$false)]
    [string]$csv_path,
    
    [Parameter(Mandatory=$false)]
    [string]$csv_init,

    [Parameter(Mandatory=$false)]
    [string]$zip_uid,

    [Parameter(Mandatory=$true)]
    [string]$vCenter_IP,

    [Parameter(Mandatory=$true)]
    [string]$username,

    [Parameter(Mandatory=$true)]
    [string]$passwd
)
echo $passwd
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server $vCenter_IP -Protocol https -user $username -Password $passwd

# Setting variables
#$check_vm_error = 'the VM you specified doesnt exist in the enviroment, vm name:'
$logs_directory_name = '\logs\'
$work_dir = $PSScriptroot
$zip_destination_folder = 'uploads'

$folders_list = $zip_destination_folder, $logs_directory_name

$download_destination = "$work_dir$logs_directory_name$zip_uid\"  # this variable needs to exist prior to running the script

if (!(Test-Path $download_destination)){
     New-Item -ItemType Directory -Path $work_dir -Name $logs_directory_name
}

if (!($csv_init)){
    $csv_init = 'Name'
}

$ps_drive_name = 'ds1'
$ps_drive_path = $ps_drive_name + ':\'

cd $work_dir

########################################################################################################

<#
function test-viserver-connection($vi_address){
    if(!($global:DefaultVIServer)){
        
    }
}
#>


#verify_display_folder -

#clear_logs - 
#  archive_logs - 

# This function takes a single parameter $vm_2 which is the name of a virtual machine. 
# The function uses the Get-VM cmdlet to retrieve information about the VM, and then extracts the datastore name from the VMX file path. 
# The extracted datastore name is returned as the output of the function.
function datastore_verification($vm_2){
    $vm_3 = Get-VM $vm_2
    $vm_path = ($vm_3.ExtensionData.Layoutex.file | where-object {$_.name -like '*.vmx'}).name
    $dataname = ($vm_path.Substring(1)).split("]")[0]
    
    return $dataname
}

# This function takes two parameters, $vm_1 and $datastore_1. 
# $vm_1 is a virtual machine object, and $datastore_1 is an array of datastore names. The function extracts the folder name from the VMX file path and compares it to the datastore name(s). If the folder name matches exactly one of the datastore names, the function does nothing. 
# Otherwise, it returns an array with information about the folder name, the datastore name(s), and the VM name.
function verify_display_folder ([System.Array]$vm_1, [System.Array]$datastore_1){
    $vm_name_1 = $vm_1.name
    $vm_path = ($vm_1.ExtensionData.Layoutex.file | where-object {$_.name -like '*.vmx'}).name

    if($datastore_1.count -gt 1){
        $compare = ($vm_path.substring((($datastore_1 | Measure-object -Property Name -character).characters) +( $datastore_1.count * $datastore_1.count), ($vm_path.Length - ((($datastore_1 | Measure-object -Property Name -character).characters) + 3)- 4))).split("/")
    }
    else{
         $compare = ($vm_path.substring(($datastore_1.name).Length + 3, ($vm_path.length - (($datastore_1.name).Length + 3) - 4))).split("/")
    }

    # Contains the Display Name, Folder Name and vmx Name
    $compare = $compare + $vm_name_1
    
    
    if(($compare.tolower() | select -unique).count -ne 1){
        return $compare
    }
}

# This function compresses the contents of the $download_destination directory and creates a ZIP archive in the $PSScriptroot\$zip_destination_folder\$zip_uid directory. The contents of the $download_destination directory are compressed using the Compress-Archive cmdlet, 
# which takes two parameters: -Path specifies the source directory to compress, and -DestinationPath specifies the output path of the ZIP archive.

function clear_logs($folders_list_rm){
    Get-ChildItem -Path $folders_list_rm | Remove-Item -Recurse -Filter * -Confirm:$false
}

function archive_logs{
    $src = $download_destination
    $dst = ("$PSScriptroot\$zip_destination_folder\$zip_uid").toString()
    Compress-Archive -Path $src -DestinationPath $dst
}


function simple_download_log($vm_i){
    $vm_to_log = $vm_i
    $full_vm_data = Get-VM -Name $vm_to_log
    $datastore = Get-Datastore -Relatedobject $vm_to_log
    $file_name_diff_vm = ''
    
    if ($datastore.count -gt 1){
        $valid_datastore = datastore_verification($vm_to_log)
        $valid_datastore_full = Get-Datastore -Name $valid_datastore

        $file_name_diff_vm = (verify_display_folder $full_vm_data $valid_datastore_full)
        if ($file_name_diff_vm){
            if (!(Get-Item -Path ($download_destination + $file_name_diff_vm[0]))){
                New-Item -ItemType Directory -Path $download_destination -name $file_name_diff_vm[0]
                New-Item -Itemtype File -Path ($download_destination + $file_name_diff_vm[0]) -Name $vm_to_log   
            }
            $vmfolder = $file_name_diff_vm[0]
            $log_path = $download_destination + $file_name_diff_vm[0]
    
            New-PSDrive -Location $valid_datastore_full -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
            Set-Location $ps_drive_path
            $vmfolder = (get-childitem | where-object { $_.name -eq $file_name_diff_vm[0] }).name
            Set-Location $vmfolder
            $dwnl_file = (Get-childItem | where-object { $_.name -like '*.log' }).name
            Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
            Set-Location $PSScriptRoot
            Get-PSDrive $ps_drive_name | Remove-PSDrive -Force
            $file_name_diff_vm = ''
        }
    
        else{
            if (!(Get-Item -Path ($download_destination + $vm_to_log))){
                New-Item -ItemType Directory -Path $download_destination -name $vm_to_log
            }
            $log_path = $download_destination + $vm_to_log
            New-PSDrive -Location $valid_datastore_full -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
            Set-Location $ps_drive_path
            $vmfolder = (get-childitem | where-object { $_.name -eq $vm_to_log }).name
            Set-Location $vmfolder
            $dwnl_file = (Get-childItem | where-object { $_.name -like '*.log' }).name
            Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
            Set-Location $PSScriptRoot
            Get-PSDrive $ps_drive_name | Remove-PsDrive -Force
            $file_name_diff_vm = ''
        }
    }

    else{
        $file_name_diff_vm = (verify_display_folder $full_vm_data $datastore)
        if ($file_name_diff_vm){
            if (!(Get-Item -Path ($download_destination + $file_name_diff_vm[0]))){
                New-Item -ItemType Directory -Path $download_destination -name $file_name_diff_vm[0]
                New-Item -Itemtype File -Path ($download_destination + $file_name_diff_vm[0]) -Name $vm_to_log   
            }

            $vmfolder = $file_name_diff_vm[0]
            $log_path = $download_destination + $file_name_diff_vm[0]
    
            New-PSDrive -Location $datastore -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
            Set-Location $ps_drive_path
            $vmfolder = (get-childitem | where-object { $_.name -eq $file_name_diff_vm[0] }).name
            Set-Location $vmfolder
            $dwnl_file = (Get-childItem | where-object { $_.name -like '*.log' }).name
            Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
            Set-Location $PSScriptRoot
            Get-PSDrive $ps_drive_name | Remove-PSDrive -Force
            $file_name_diff_vm = ''
        }
    
        else{
            if (!(Get-Item -Path ($download_destination + $vm_to_log))){
                New-Item -ItemType Directory -Path $download_destination -name $vm_to_log
            }
            $log_path = $download_destination + $vm_to_log
            New-PSDrive -Location $datastore -Name $ps_drive_name -PSProvider VimDatastore -Root "\"
            Set-Location $ps_drive_path
            $vmfolder = (get-childitem | where-object { $_.name -eq $vm_to_log }).name
            Set-Location $vmfolder
            $dwnl_file = (Get-childItem | where-object { $_.name -like '*.log' }).name
            Copy-DatastoreItem -Item $dwnl_file -Destination $log_path
            Set-Location $PSScriptRoot
            Get-PSDrive $ps_drive_name | Remove-PsDrive -Force
            $file_name_diff_vm = ''
        }
    }
}
########################################################################################################

# 1. checking if a VM name is specified, then downloading it from the vcenter server
if($vmname){
    simple_download_log($vmname)
}

# 2.
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

# 3.
Disconnect-VIServer -Server $vCenter_IP -Confirm:$false

# 4.
archive_logs

# 5.
#clear_logs($download_destination)
