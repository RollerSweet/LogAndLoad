import os

# LDAP Configurations
DOMAIN = "your.domain"
AD_SERVER = f"ldap://{DOMAIN}"
allowed_group = 'LogAndLoadGroup'

#vCenter Server
vCenter_IP = 'X.X.X.X'
vCenter_username = 'LogAndLoad'
vCenter_passwd = 'PASSWORD'

# Setting Variables
current_path = os.getcwd()
script_path = os.path.join(current_path, "Main_Script.ps1")
csv_dir = os.path.join(current_path, "csv")
uploads_dir = os.path.join(current_path, "uploads")
logs_dir = os.path.join(current_path, "logs")

# JWT
JWT_SECRET = "secret_token"
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 20