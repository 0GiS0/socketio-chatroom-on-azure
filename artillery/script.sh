### Using ACI ###
#Create a storage account to upload reports
RESOURCE_GROUP="artillery-with-socketio"
LOCATION="northeurope"
STORAGE_NAME="artilleryreports" 

#Log in Azure
az login

#Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

#Create a storage account
az storage account create --name $STORAGE_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS
#Enable static website
az storage blob service-properties update --account-name $STORAGE_NAME --static-website --404-document 404.html --index-document index.html
#Get the connection string
CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_NAME --resource-group $RESOURCE_GROUP | jq .connectionString)

SHARE_NAME="load-tests"

#Get Azure storage access key
STORAGE_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_NAME --query '[0].value' -o tsv)

#Create a File Share
az storage share create --account-name $STORAGE_NAME --name $SHARE_NAME

#Upload test to the file share (se puede montar un repositorio git)
az storage file upload --account-name $STORAGE_NAME --share-name $SHARE_NAME --source simple-socketio-load-test.yaml

#Upload docker image to Docker Hub
IMAGE_NAME=0gis0/socketiotest
DOCKER_BUILDKIT=1 docker build -t $IMAGE_NAME .
docker push $IMAGE_NAME

#Create Azure Container Instances
CONTAINER_NAME="artillery-with-socketio"

az container create --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME \
    --image $IMAGE_NAME \
    --cpu 3 --memory 7 \
    --dns-name-label artillery-on-azure \
    --ports 80 \
    --restart-policy Never \
    --azure-file-volume-account-name $STORAGE_NAME \
    --azure-file-volume-share-name $SHARE_NAME \
    --azure-file-volume-account-key $STORAGE_KEY \
    --azure-file-volume-mount-path /tests \
    --environment-variables AZURE_STORAGE_CONNECTION_STRING=$CONNECTION_STRING

#See the logs
az container attach --name $CONTAINER_NAME --resource-group $RESOURCE_GROUP

#Delete ACI
az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME -y

#Delete container group & storage account
az group delete --name $RESOURCE_GROUP -y

https://STORAGE_ACCOUNT_NAME.z16.web.core.windows.net/artillery-report-10_19_06_01_2021.html

DEBUG=http,http:response artillery run simple-socketio-load-test.yaml -o report.json 
#Check it on https://reportviewer.artillery.io/