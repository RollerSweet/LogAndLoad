import os
from pyVmomi import vim
from pyVim.connect import SmartConnectNoSSL, Disconnect

# Setting variables
vCenter_IP = '1.1.1.200'
username = 'administrator@vsphere.local'
passwd = 'Ultra123!'
check_vm_error = 'the VM you specified doesnt exist in the environment, vm name:'
logs_directory_name = '/logs/'
work_dir = os.path.dirname(os.path.abspath(__file__))
zipfile_name = 'zipped.zip'

download_destination = os.path.join(work_dir, logs_directory_name)
print(download_destination)
if not os.path.exists(download_destination):
    os.makedirs(download_destination)

print(os.sys.argv[1])
vmname = os.sys.argv[1]
print(vmname)

# Connecting to vCenter
si = SmartConnectNoSSL(host=vCenter_IP, user=username, pwd=passwd)
content = si.RetrieveContent()


# Function to test connection to vCenter
def test_viserver_connection(vi_address):
    if not content:
        print("Could not connect to vCenter")
    else:
        print("Connected to vCenter")


# Function to verify display folder
def verify_display_folder(vm_1, datastore_1):
    vm_name_1 = vm_1.name
    vm_path = vm_1.config.files.vmPathName
    if len(datastore_1) > 1:
        compare = vm_path.split('][')[-1].split('/')[1:]
    else:
        compare = vm_path.split('/')[1:]
    if len(set([x.lower() for x in compare])) != 1:
        return compare


# Function to download log file
def simple_download_log(vm_i):
    vm_to_log = vm_i
    full_vm_data = content.searchIndex.FindByInventoryPath(vm_to_log)
    if not full_vm_data:
        print(check_vm_error + vm_to_log)
        return
    datastore = full_vm_data.datastore[0]
    print(datastore)
    if not os.path.exists(os.path.join(download_destination, vm_to_log)):
        os.makedirs(os.path.join(download_destination, vm_to_log))
    log_path = os.path.join(download_destination, vm_to_log)
    vmfolder = full_vm_data.parentVApp.name if isinstance(full_vm_data.parentVApp,
                                                          vim.Folder) else full_vm_data.parentVApp.config.name
    dwnl_file = [f.name for f in datastore.browser.Search(datastore.vmPathName + vmfolder + '/', '.log')]
    if not dwnl_file:
        print("No log file found for VM: " + vm_to_log)
        return
    datastore.download(dwnl_file[0], os.path.join(log_path, dwnl_file[0]))
    file_name_diff_vms = ''


# 1.
if vmname:
    simple_download_log(vmname)

# 2.
if csv_path:
    with open(csv_path, 'r') as file:
        lines = file.readlines()
        if 'Name' not in lines[0]:
            raise Exception('invalid csv file, first column should start with Name')
        for line in lines[1:]:
            vm = line.split(',')[0]
            simple_download_log(vm.strip())

print(os.path.join(work_dir, zipfile_name))
os.system(f'zip -r {os.path.join(work_dir, zipfile_name)} {download_destination}')

# Disconnecting from vCenter
Disconnect(si)
