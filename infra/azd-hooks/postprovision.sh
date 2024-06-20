#!/bin/bash
echo "Retrieving cluster credentials"
az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${AZURE_AKS_CLUSTER_NAME}

#echo "Creating service principle for Azure Service Operator"
#ASO_SP_NAME=azure-service-operator-${AZURE_AKS_CLUSTER_NAME}
#AZURE_CLIENT_SECRET=$(az ad sp create-for-rbac -n ${ASO_SP_NAME}  --role contributor --scopes /subscriptions/${AZURE_SUBSCRIPTION_ID} --query password -o tsv)
#AZURE_CLIENT_ID=$(az ad sp list --display-name ${ASO_SP_NAME} --query "[].{id:appId}" -o tsv)

# Temporary until ASO is an AKS add-on/extension
echo "Installing Azure Service Operator"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml
helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
helm repo update
#helm upgrade --install --devel aso2 aso2/azure-service-operator \
#     --create-namespace \
#     --namespace=azureserviceoperator-system \
#     --set azureSubscriptionID=${AZURE_SUBSCRIPTION_ID} \
#     --set azureTenantID=${AZURE_TENANT_ID} \
#     --set azureClientID=${AZURE_CLIENT_ID} \
#     --set azureClientSecret=${AZURE_CLIENT_SECRET}
helm upgrade --install --devel aso2 aso2/azure-service-operator \
     --create-namespace \
     --namespace=azureserviceoperator-system \
     --set azureSubscriptionID=${AZURE_SUBSCRIPTION_ID} \
     --set azureTenantID=${AZURE_TENANT_ID} \
     --set azureClientID=${ASO_WORKLOADIDENTITY_CLIENT_ID} \
     --set useWorkloadIdentityAuth=true

# Temporary until KEDA add-on is updated to 2.10 which is needed for workload identity support in Prometheus scaler
echo "Installing KEDA"
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
     --namespace kube-system \
     --set podIdentity.azureWorkload.enabled=true

# Create role assignments for current user to be able to access the Grafana dashboard and Azure Monitor workspace
     CURRENT_UPN=$(az account show --query user.name -o tsv)
     CURRENT_OBJECT_ID=$(az ad user show --id ${CURRENT_UPN} --query id -o tsv)

     # Azure Monitor Data Reader role assignment for current user
     echo "Creating Azure Monitor Data Reader role assignment for current user"
     az role assignment create --assignee "${CURRENT_OBJECT_ID}" \
     --role "b0d8363b-8ddd-447d-831f-62ca05bff136" \
     --scope "${AZURE_MANAGED_PROMETHEUS_RESOURCE_ID}"

     # Grafana Admin role assignment for current user
     echo "Creating Grafana Admin role assignment for current user"
     az role assignment create --assignee "${CURRENT_OBJECT_ID}" \
     --role "22926164-76b3-42b3-bc55-97df8dab3e41" \
     --scope "${AZURE_MANAGED_GRAFANA_RESOURCE_ID}"

# Create a Grafana dashboard for requests per second if it doesn't exist
# This is a data plane operation, hence the need to do here as opposed to a Bicep template
DASHBOARD_UID=$(az grafana dashboard list -g ${AZURE_RESOURCE_GROUP} -n ${AZURE_MANAGED_GRAFANA_NAME} --query "[?title=='RPSDashboard'].uid" -o tsv)
if [[ -z "$DASHBOARD_UID" ]]; then
     echo "Dashboard doesn't exist, creating"
     az grafana dashboard create -g ${AZURE_RESOURCE_GROUP} -n ${AZURE_MANAGED_GRAFANA_NAME}  --title "RPSDashboard" --folder managed-prometheus --definition '{
     "dashboard": {
          "annotations": {

          },
          "panels": {

          }
     },
     "message": "Create a new test dashboard"
     }'
fi
