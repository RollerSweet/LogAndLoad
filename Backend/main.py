from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from os import getcwd
import subprocess
from pathlib import Path
import aiofiles


# setting classes
class VM(BaseModel):
    name: str


# setting variables
current_path = getcwd()
ps_filename = r'\PowerShellScript.ps1'
ps_script_path = current_path + ps_filename
powershell = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)


@app.post('/upload/csv')
async def upload_file(file: UploadFile = File(None), vm_name: str = Form(None)):
    if file is not None:
        file_path = Path('uploads') / file.filename
        async with aiofiles.open(file_path, 'wb') as out_file:
            content = await file.read()  # async read the file contents
            await out_file.write(content)  # async write the file contents to disk
        # Write here the part to run with csv file!
        return {'message': 'File uploaded successfully'}

    elif vm_name is not None:
        # Write here the part to run with vm name!
        return {'message': 'vm name passed successfully'}

    else:
        return {'message': 'No file or vm name provided'}
    # return {'message': 'File or vm name uploaded successfully'}


@app.post("/vmlogs/")
async def vmlogs(vm: VM):
    vm_name = vm.name
    script_path = r"C:\Users\Tamir-PC\Desktop\logandload\Backend\ps-test.ps1"
    # Setting up the powershell script with predefined parameters
    command = ["powershell.exe", "-Command", script_path, "-vmname", vm_name]
    # Use subprocess to run the script
    result = subprocess.run(command, capture_output=True, text=True)
    print(result.stdout)
