# Argo CD Setup for Kubernetes Project

Welcome to the **Argo CD Setup** repository! This guide will walk you through generating Argo CD manifests from a centralized configuration, verifying them, and applying the resources in the correct order.

---

## 🚀 What This Setup Does

- Reads your **config.json** containing roles, accounts, and SSH key path
- Generates four key manifests inside an `out/` directory:
  - `project.yaml` (AppProject resource)
  - `github-repo.yaml` (Repository resource)
  - `account.yaml` (RBAC ConfigMaps for users and groups)
  - `application.yaml` (root application which helps to create all other applications)
- Applies these manifests in sequence to your Kubernetes cluster using `kubectl`
- Resetting passwords for all users defined in the configuration to a **default password** for easy initial access.
- It is strongly recommended to reset these passwords immediately after setup for security purposes.


---

## 📁 Folder Structure
```
.
├── README.md                   # Documentation on how to use this setup
├── config.json                 # Main configuration file with roles, accounts, SSH key path
├── generate.sh                 # Script to generate Kubernetes manifests into `./out/`
├── setup.sh                    # Script to apply generated manifests to the cluster
├── reset-password.sh           # Script to reset all user passwords based on config.json triggered by `setup.sh`
├── out/                        # Directory where generated manifest YAML files are saved
│   ├── project.yaml            # ArgoCD AppProject manifest
│   ├── repo.yaml               # Git repository manifest for ArgoCD
│   ├── account.yaml            # RBAC ConfigMaps for user and group permissions
│   └── application.yaml        # Root Application manifest to bootstrap other apps
└── snapshots/                  # Sample templates to verify and compare generated files
    ├── project.yaml            # Sample AppProject template
    ├── repo.yaml               # Sample Git repository template
    ├── account.yaml            # Sample RBAC ConfigMaps template
    └── application.yaml        # Sample Application manifest template
```

---

## ⚙️ Prerequisites

- Kubernetes cluster with `kubectl` configured
- `Helm` installed (for Argo CD installation)
- Access to `GitHub SSH key` referenced in `config.json`
- `jq` command-line tool installed

---

## 🛠️ Setup Steps

### 0. Make Scripts Executable
Before running any of the `.sh` scripts for the first time, ensure they’re marked as executable:
```bash
chmod +x generate.sh setup.sh reset-password.sh
```
This step is required so that you can run scripts without permission errors.



### 1. Configure your `config.json`

Make sure your `config.json` contains the correct roles, accounts, and the path to your SSH private key:
The structure and formatting of this file are **very important** — any deviation may cause the generation or setup scripts to fail.

```json
{
  "sshPath": "/home/username/.ssh/argo_key",
  "roles": [ ... ],
  "accounts": [ ... ]
}
```
**Always validate your `config.json` before running the scripts!**

### 2. Generate manifests

Run the `generate.sh` script to produce YAML manifests from your configuration:

```
./generate.sh
```
This will create the files in the out/ directory:
    - project.yaml
    - application.yaml
    - repo.yaml
    - account.yaml

### 3. Verify generated files

you have a sanpshots/ folder with existing files, compare them to the generated ones to ensure consistency. 

### 4. Execute setup script

Run the `setup.sh` script to automate the deployment process. 

```
./setup.sh
```


This script will:
- ✅ Verify that all expected manifest files (`project.yaml`, `repo.yaml`, `account.yaml`, and `application.yaml`) exist inside the `out/` directory  
- 🚀 Install Argo CD via Helm if it’s not already installed  
- 📂 Apply the `project.yaml` manifest to create the Argo CD project  
- 🔗 Apply the `repo.yaml` manifest to configure the Git repository access  
- 👥 Apply the `account.yaml` manifest to set up user and group RBAC  
- 🗂️ Apply the `application.yaml` manifest which deploys the root Argo CD Application and bootstraps other applications
- 🔐 Automatically reset passwords for all users defined in the configuration to the default password for easy initial access (recommended to change passwords after setup)

with a smooth, step-by-step setup with clear feedback at each stage.  

---

### 🧩 What happens now?
- Argo CD will be installed and ready to manage your Kubernetes apps.
- Your project and repository access roles will be configured as per your config.
- Users specified will have access roles assigned.
- The root Argo CD Application will be created from application.yaml

---

### ❓ Troubleshooting

- If you encounter issues running `argocd` during password resets or other commands, it may be missing or not executable. To fix this:
    - for mac just download `brew install argocd`
    - Download the official ArgoCD CLI binary create an alias so it can be accessed directly as `argocd`
    
  ```bash
  VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
  curl -sSL -o argocd.sh https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
  chmod +x argocd.sh
  ```
- Make sure you have kubectl, helm, and jq installed and accessible in your PATH.
- Ensure your Kubernetes context is set to the correct cluster.
- Confirm SSH key file path in config.json is correct and accessible.
- Check network connectivity to your Kubernetes cluster.
- Check the Argo CD namespace logs for errors if something fails.

---

### 🙌 Contributions

If you are contributing to this repository, please follow these steps to ensure smooth validation of YAML and JSON files:

1. **Install pre-commit**

Make sure you have [pre-commit](https://pre-commit.com/) installed on your system. You can install it via:

```bash
brew install pre-commit
```

2. **Install npm dependencies**

Run the following command in the project root to install required npm packages, including `yaml-lint` and `ajv`, which are used for YAML and JSON validations respectively:

```bash
npm install 
```
3. **Install pre-commit hooks**

Activate the pre-commit hooks by running:

```bash
pre-commit install
```

The pre-commit hooks are now configured to automatically validate your YAML and JSON files before each commit. This helps keep the codebase clean and consistent.


