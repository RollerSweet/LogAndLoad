# LogAndLoad

VM Log Downloader is a specialized tool designed to securely and conveniently download virtual machine (VM) log files from a vCenter server. This project addresses the need for a specific role in vCenter for downloading VM logs, by providing a dedicated and secure solution for this task.

## Key Features

- **Active Directory Authentication**: Users are authenticated through Active Directory, ensuring secure access.
- **Selective Log Downloads**: Download logs for specific VMs by entering VM names or by uploading a CSV file with multiple VM names.
- **Convenient Bulk Download**: Provides the ability to download logs for multiple VMs at once, delivered in a compressed zip file.
- **Enhanced Security**: The system uses a dedicated user account with specific permissions, ensuring that only authorized personnel can download, edit, or remove logs.

## Getting Started

### Prerequisites

- Access to a vCenter server with appropriate permissions.
- Active Directory credentials for authentication.
- PowerCLI installed on the system for vCenter communication.
- A domain user account created specifically for this project, with minimal permissions allowing browsing VMs, and downloading, editing, and removing log files.
- A group in the domain created for users who will access and sign in to the web application.
- Edit the `env` files with addresses to the domain, user, password, etc.
- Creation of a Certificate using Win64OpenSSL for secure communication.

### Installation

Clone the repository to your local machine to get started:

```bash
git clone https://github.com/RollerSweet/VMLogDownloader.git
cd VMLogDownloader
