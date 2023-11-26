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

## Usage

The VM Log Downloader is designed to be user-friendly and straightforward. Here's a step-by-step guide on how to use the application:

### 1. LogIn Page

When you start the application, you'll be greeted with the LogIn page. Enter your domain username and password to authenticate via Active Directory.

![LogIn Page](/Screenshots/LogAndLoadLogin.png)

### 2. Main Interface

After logging in, you'll see the main interface where you can enter VM names or upload a CSV file containing the names of the VMs whose logs you want to download.

![Main Interface](/Screenshots/LogAndLoadMain.png)

- **Single VM**: To download logs for a single VM, simply type the VM's name in the provided field.
- **Multiple VMs**: To download logs for multiple VMs, click on the 'Upload CSV' button and select a CSV file with the VM names.

### 3. Downloading Logs

Once you have input the VM names or uploaded the CSV file, press the 'Download' button to start the log download process. The logs will be compiled and downloaded in a zip file format.

![Downloading Logs](/Screenshots/LogAndLoadRar.png)

Wait for the download to complete. The time taken for the download depends on the number of logs and their sizes.

## Built With

Frontend built using React.js for a responsive UI.
Backend services developed in Python with FastAPI.
PowerCLI scripts for interacting with vCenter server.

### Installation

Clone the repository to your local machine to get started:

```bash
git clone https://github.com/RollerSweet/VMLogDownloader.git
cd VMLogDownloader
```
