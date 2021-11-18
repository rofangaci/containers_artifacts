#https://docs.microsoft.com/en-us/learn/modules/aks-workshop/02-deploy-aks

########ENV vars############
RESOURCE_GROUP=Openhack-2021

REGION_NAME=southcentralus

VNET_NAME=aks-vnet

SUBNET_NAME=ask-subnet

AKS_CLUSTER_NAME=aksworkshop-$RANDOM

VERSION=1.21.2

AKS_NAMESPACE=openhack2021

#### create vnet ####
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefixes 10.240.0.0/16

## retrieve subnet ID
SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --query id -o tsv)

#get latest non-preview k8s version - 1.21.2, set as ENV
VERSION=$(az aks get-versions \
    --location $REGION_NAME \
    --query 'orchestrators[?!isPreview] | [-1].orchestratorVersion' \
    --output tsv)

