########ENV vars############
DOCKER_NETWORK=openhack2-net

SQL_SERVER=sql1

SQL_DBNAME=mydrivingDB

#SQL_USER=sa

SQL_PASSWORD=uJ3ie1No7

ACR_REGISTRY=registryylw2763

ACR_USER=

ACR_PASSWORD=""


###### 0. authenticate to ACR registry, check the name on the hacker portal ###
az acr login -n $ACR_REGISTRY
####### 1. Create docker network #########
docker network create $DOCKER_NETWORK
## list to confirm
docker network ls

###### 2. Run SQL server container ##########

docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=$SQL_PASSWORD" -p 1433:1433 --name $SQL_SERVER --network $DOCKER_NETWORK -d mcr.microsoft.com/mssql/server:2017-latest
#docker inspect container to confirm network/password etc.

##### 3. create DB without data #####
docker exec -it $SQL_SERVER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SQL_PASSWORD" -Q "CREATE DATABASE $SQL_DBNAME"
# confirm DB mydrivingDB is created
docker exec -it $SQL_SERVER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SQL_PASSWORD" -Q "SELECT Name from sys.Databases"

###### 4. load dataload from ACR registry to the DB: mydrivingDB 
docker run --network $DOCKER_NETWORK -e SQLFQDN=$SQL_SERVER -e SQLUSER=sa -e SQLPASS=$SQL_PASSWORD -e SQLDB=$SQL_DBNAME $ACR_REGISTRY.azurecr.io/dataload:1.0

###### 5. build poi image from src and dockerfile_3 ######
#dockerfile and src file are in different directory
#The docker build - builds Docker images from a Dockerfile and a “context”(src code). 
#A build’s context is the set of files located in the specified PATH (with the src code) or URL
#build from src dir - don't forget dot '.'
cd src/poi
docker build -f ../../dockerfiles/Dockerfile_3 -t "tripinsights/poi:1.0" .

###### 5. run poi container ########
#IMPORTANT: Set the ASPNETCORE_ENVIRONMENT environment variable in POI to Local. 
#This configures the application to skip the use of SSL encryption, allowing connection to the local sql server.
# Set config values via environment variables. 
docker run -d -p 8080:80 --name poi -e "SQL_PASSWORD=$SQL_PASSWORD" -e "SQL_SERVER=$SQL_SERVER" -e "ASPNETCORE_ENVIRONMENT=local"  --network $DOCKER_NETWORK tripinsights/poi:1.0

## test poi -it login to container poi
# at root#, echo $SQL_PASSWORD - the vaule get passed by environment vars from the cmd line above.
docker exec -it poi /bin/sh

###############################################
## docker compose up all other containers ###
## all the container up this way will be on different network than above. use 'docker inspect container' to check
## also, the sql connection is not correct. just to build the image
## also, there is no host port mapping for these images
cd .azdevops
docker compose up -d

#### my own try out #######
#push container image to my internal subscription
#this link: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal
# change login to my registry: rofaregistry (created in the portal) from openhack
az acr login --name rofaregistry
#pull image from mcr to my local
docker run -it --rm -p 1000:80 mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine
#tag image at local machine -- make sure tag to rofaregistry, otherwise push local images to my ACR will fail
docker tag mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine rofaregistry.azurecr.io/samples/nginx
#push to my registry
docker push rofaregistry.azurecr.io/samples/nginx
#push openhack images to my registry

#use docker compose to bring up all openhack containers
#run at path where docker-compose.yaml exist 
#detach mode use -d
docker compose up -d 

