# GitOps Repository for Kubernetes Infrastructure

This repository implements GitOps principles using ArgoCD to manage and automate Kubernetes deployments. It follows the **App-of-Apps pattern**, providing a structured and scalable way to handle multiple applications and their configurations through version control.

---

## How it Works: GitOps with ArgoCD

GitOps is a paradigm for managing infrastructure and applications where Git is the single source of truth. ArgoCD, a declarative, GitOps continuous delivery tool for Kubernetes, automates the deployment and lifecycle management of applications.

1.  **Declarative Configuration**: All infrastructure and application configurations are defined as code (YAML manifests) and stored in this Git repository.
2.  **Version Control as Source of Truth**: Git provides versioning, history, and collaboration capabilities for all configurations.
3.  **Automated Synchronization**: ArgoCD continuously monitors the Git repository and the live state of applications in the Kubernetes cluster.
4.  **App-of-Apps Pattern**: This repository uses a hierarchical structure where a root ArgoCD `Application` or `ApplicationSet` manages other `Application` resources. These, in turn, can manage further applications or individual components.
    *   **Root Application (`/application.yaml`)**: Defines the top-level ArgoCD application(s) or ApplicationSet that bootstraps the cluster setup. It typically points to cluster-level applications.
    *   **Cluster Application (`/clusters/dev/application.yaml`)**: Manages applications and resources within a specific Kubernetes cluster. It often points to directories containing application definitions (e.g., `argo-apps`).
    *   **Application Definitions (`/clusters/dev/argo-apps/`)**: Each subdirectory here (e.g., `monitoring`, `playground`) contains ArgoCD `Application` manifests for specific sets of services or namespaces.
        *   These application manifests define the source Git repository, path to the Helm charts or raw YAMLs, target namespace, and sync policies.
    *   **Namespace and Resource Configurations (`/clusters/dev/namespaces/`)**: Contains the actual Kubernetes manifests (Deployments, Services, ConfigMaps, Helm charts, values files, etc.) organized by namespace and application.

---

## Automation and Version Controlling

*   **Automated Deployments**: When changes are pushed to the `main` branch (or any target revision configured in ArgoCD Applications), ArgoCD automatically detects these changes and applies them to the cluster, ensuring the live state matches the desired state defined in Git.
*   **Rollbacks**: If a deployment introduces issues, reverting is as simple as reverting the Git commit. ArgoCD will then automatically roll back the changes in the cluster.
*   **Consistency and Reproducibility**: Since Git is the source of truth, the state of the infrastructure is always auditable and reproducible.
*   **Self-Healing**: ArgoCD can be configured to automatically correct any drift from the desired state, ensuring that manual changes made directly to the cluster are reverted to match the Git configuration.
*   **Helm Integration**: Applications are often packaged as Helm charts. ArgoCD seamlessly integrates with Helm, allowing you to specify chart sources and `values.yaml` files directly from Git.

---

## Repository Structure Overview

``` 
├── application.yaml                 # Root ArgoCD Application/ApplicationSet (points to cluster definitions)
└── clusters/
    └── dev/                         # Configuration for a specific Kubernetes cluster
        ├── application.yaml         # Cluster-level ArgoCD Application (points to argo-apps)
        ├── argo-apps/               # Directory for ArgoCD Application manifests
        │   ├── monitoring/          # ArgoCD Applications for the 'monitoring' namespace (e.g., prometheus)
        │   │   ├── namespace.yaml
        │   │   └── kube-prom-stack.yaml
        │   └── playground/          # ArgoCD Applications for the 'playground' namespace
        │       ├── namespace.yaml
        │       └── test-app.yaml
        └── apps/              # Kubernetes manifests and Helm charts organized by namespace
            ├── monitoring/          # Resources for the 'monitoring' namespace
            │   └── kube-prom-stack/
            │       ├── chart/       # Helm chart for kube-prometheus-stack
            │       └── values.yaml  # Custom values for kube-prometheus-stack
            └── playground/
                └── test-app/
                    ├── Deployment.yaml
                    └── Service.yaml
```

---

## Key Benefits

*   **Increased Productivity**: Developers can manage applications and infrastructure using familiar Git workflows.
*   **Enhanced Stability**: Automated, version-controlled deployments reduce the risk of human error.
*   **Improved Security**: Clear audit trails and the ability to enforce policies through Git.
*   **Faster Mean Time to Recovery (MTTR)**: Easy rollbacks to previous known good states.
*   **Scalability**: The App-of-Apps pattern allows for managing complex deployments across multiple teams and environments effectively.

---

## Getting Started

1.  **Prerequisites**:
    *   A Kubernetes cluster.
    *   `kubectl` configured to interact with your cluster.
    *   ArgoCD installed in your cluster.
2.  **Bootstrap ArgoCD**:
    Apply the root `application.yaml` (or `ApplicationSet`) to your ArgoCD instance:
    ```bash
    kubectl apply -f application.yaml -n argocd
    ```
    This will instruct ArgoCD to start managing the applications defined in this repository.
3.  **Monitor Synchronization**:
    Use the ArgoCD UI or CLI (`argocd app list`) to monitor the synchronization status of your applications.

---

## Making Changes

1.  **Modify Configurations**: Make changes to the YAML manifests or Helm values files in the appropriate directory.
2.  **Commit and Push**: Commit your changes to a feature branch and create a Pull Request against the `main` branch (or your target branch).
3.  **Review and Merge**: After review, merge the Pull Request.
4.  **Automatic Sync**: ArgoCD will detect the changes in the Git repository and automatically update the applications in the Kubernetes cluster according to their sync policies.

This GitOps setup ensures that your Kubernetes environment is consistently and reliably managed through version-controlled configurations, automated by ArgoCD.

---

## Contribution Guidelines

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

