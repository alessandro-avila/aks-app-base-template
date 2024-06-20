## Azure Kubernetes Service (AKS) app base template

The template uses Bicep and the Azure Developer CLI (`azd`) to create the following infrastructure resources from the `infra` folder:
- Azure Kubernetes Service cluster
- Azure Container Registry
- Azure Managed Grafana
- Azure Monitor managed service for Prometheus

### Prerequisites
- Visual Studio Code AKS developer extension
- Azure Developer CLI

### Usage

- Fork this template into your own repo (or click **Use this template -> Create a new repository**)
- Initialize the template on your machine using `azd init -t <your fork's git repo>`
- Deploy the infrastructure using `azd provision`
- Add your source code to `src/app-placeholder/code`.
- Add your Kubernetes manifests to `src/app-placeholder/manifests`. You can use the Visual Studio Code AKS developer extension to generate the manifests.
- Add a GitHub Actions workflow to the `.github` folder. You can use the Visual Studio Code AKS developer extension to generate the workflow.
- Configure GitHub Actions authentication using `azd pipeline config`
- Add all files to your commit with `git add .`
- Commit and push your changes then watch the build pipeline `git commit -m "Changes" && git push`