import os
import random

import ldap3

from .Addresses import AD_SERVER, DOMAIN, allowed_group


def is_user_in_group(username: str, password: str):
    # Set up the LDAP server connection
    conn = ldap3.Connection(AD_SERVER, user=f'{username}@{DOMAIN}', password=password)
    conn.bind()

    # Search for the user in the LDAP directory
    search_filter = f"(sAMAccountName={username})"
    attrs = ["memberOf"]  # Attribute that holds the group membership information
    result = conn.search(search_base=f"dc={DOMAIN.split('.')[0]},dc={DOMAIN.split('.')[1]}", search_filter=search_filter, attributes=attrs)

    # Extract the user's groups from the search result
    if result and conn.entries:
        member_of_values = conn.entries[0]["memberOf"].values
        groups = [value.split(",")[0] for value in member_of_values]
        if f"CN={allowed_group}" in groups:
            return username
    else:
        return False


def check_folder_existence(csv_dir, uploads_dir, logs_dir):  # Function to check if csv and uploads directories exist
    if not os.path.exists(csv_dir):
        os.makedirs(csv_dir)
    if not os.path.exists(uploads_dir):
        os.makedirs(uploads_dir)
    if not os.path.exists(logs_dir):
        os.makedirs(logs_dir)


def check_session_existence(csv_dir, uploads_dir, logs_dir):  # This function creates UID for the seesions
    while True:
        UID = str(random.randint(1, 99999))  # Generate UID for the session
        csv_file_path = os.path.join(csv_dir, f'{UID}.csv')
        uploads_dir_path = os.path.join(uploads_dir, f'{UID}.zip')
        logs_dir_path = os.path.join(logs_dir, UID)
        if not os.path.exists(csv_file_path) and not os.path.exists(uploads_dir_path) and not os.path.exists(logs_dir_path):
            return UID
