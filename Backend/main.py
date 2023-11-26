import os
import subprocess
import shutil
import uvicorn
from datetime import datetime, timedelta

import jwt
import aiofiles
from fastapi import FastAPI, File, UploadFile, Form, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials, HTTPBasicCredentials
from fastapi.staticfiles import StaticFiles
from Utilities.Addresses import current_path, script_path, csv_dir, uploads_dir, logs_dir
from Utilities.Addresses import JWT_SECRET, JWT_ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES, vCenter_IP, vCenter_username, \
    vCenter_passwd
from Utilities.Utility import check_folder_existence, check_session_existence, is_user_in_group

security = HTTPBearer()
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def create_access_token(username: str) -> str:
    # Get the expiry time
    expiry = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    # Create the token
    access_token = jwt.encode({"sub": username, "exp": expiry}, JWT_SECRET, algorithm=JWT_ALGORITHM)
    # Return the token
    return access_token


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        # Verify the token and get the payload
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        # Get the username from the payload and returns it
        username = payload.get("sub")
        return username
    except jwt.exceptions.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Access token expired")
    except (jwt.exceptions.InvalidTokenError, Exception):
        raise HTTPException(status_code=401, detail="Invalid access token")


@app.get("/protected")
def protected_route(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        username = payload.get("sub")
        return {"message": f"Hello, {username}!"}
    except jwt.exceptions.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Access token expired")
    except (jwt.exceptions.InvalidTokenError, Exception):
        raise HTTPException(status_code=401, detail="Invalid access token")


@app.get("/validate_token")
def protected_route(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        username = payload.get("sub")
        if username:
            return True
        else:
            return False
    except jwt.exceptions.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Access token expired")
    except (jwt.exceptions.InvalidTokenError, Exception):
        raise HTTPException(status_code=401, detail="Invalid access token")


@app.post("/api/login")
async def login(credentials: HTTPBasicCredentials):
    username = credentials.username
    password = credentials.password
    # Check if the user is in the specific OU
    valid_user = is_user_in_group(username, password)
    if not valid_user:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    access_token = create_access_token(username)  # If user is valid, create and return access token
    return {"access_token": access_token}


@app.post('/upload')
async def upload_file(file: UploadFile = File(None), vm_name: str = Form(None),
                      current_user: str = Depends(get_current_user)):
    check_folder_existence(csv_dir, uploads_dir, logs_dir)
    UID = check_session_existence(csv_dir, uploads_dir, logs_dir)
    if file is not None:
        file_path = os.path.join(csv_dir, f"{UID}.csv")
        async with aiofiles.open(file_path, 'wb') as out_file:
            content = await file.read()  # async read the file contents
            await out_file.write(content)  # async write the file contents to disk
        # PowerShell Start
        command = ["powershell.exe", "-Command", script_path, "-csv_path", file_path, "-zip_uid", UID, "-vCenter_IP",
                   vCenter_IP, "-username", vCenter_username, "-passwd", vCenter_passwd]
        subprocess.run(command, capture_output=True, text=True)
        # PowerShell End
        os.remove(file_path)  # Deletes CSV File
        shutil.rmtree(os.path.join(logs_dir, UID))  # Deletes the folder from logs folder
        return FileResponse(os.path.join(uploads_dir, f"{UID}.zip"))
    elif vm_name is not None:
        # PowerShell Start
        command = ["powershell.exe", "-Command", script_path, "-vmname", vm_name.strip(), "-zip_uid", UID, "-vCenter_IP",
                   vCenter_IP, "-username", vCenter_username, "-passwd", vCenter_passwd]
        subprocess.run(command, capture_output=True, text=True)
        # PowerShell End
        shutil.rmtree(os.path.join(logs_dir, UID))  # Deletes the folder from logs folder
        return FileResponse(os.path.join(uploads_dir, f"{UID}.zip"))
    else:
        return {'message': 'No file or vm name provided'}


@app.get("/login")
def renderReact(request: Request):
    return FileResponse("StaticFiles/build_v1/index.html")


@app.get("/vmlogs")
def renderReact(request: Request):
    return FileResponse("StaticFiles/build_v1/index.html")


app.mount("/", StaticFiles(directory="StaticFiles/build_v1", html=True), name="static")

if __name__ == "__main__":
    ssl_keyfile = os.path.join(current_path, "logandload.key")
    ssl_certfile = os.path.join(current_path, "logandload.crt")
    uvicorn.run("main:app", host="logandload", port=443, ssl_keyfile=ssl_keyfile, ssl_certfile=ssl_certfile, reload=True)
    # uvicorn.run("main:app", host="0.0.0.0", port=80, reload=True)  # If you want to use http instead of https

# Command for the terminal HTTPS
# uvicorn main:app --ssl-keyfile="C:\Users\p0868logandload\Desktop\LogAndLoad\Backend\logandload.key" --ssl-certfile="C:\Users\p0868logandload\Desktop\LogAndLoad\Backend\logandload.crt" --host 0.0.0.0 --port 443 --reload
