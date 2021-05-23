#!/bin/bash

# Please build the oracle container image prior to running this setup script. See here, https://github.com/oracle/docker-images
# https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md
# ./buildContainerImage.sh -i -e -v 12.2.0.1
# OR
# Use a pre-built image


version="$1"
db_port=1521
db_pwd=Redis123
[[ -z "$version" ]] && { echo "Error: Missing docker version tag e.g. 12.2.0.1-ee, 19.3.0-ee"; exit 1; }

container_name="oracle-$version-$(hostname)"
# delete the existing container if it exist
sudo docker kill $container_name;sudo docker rm $container_name;

# create volume and setup necessary permissions
sudo rm -rf $(pwd)/oradata
sudo mkdir -p $(pwd)/oradata/recovery_area
sudo chgrp -R 54321 $(pwd)/oradata
sudo chown -R 54321 $(pwd)/oradata

echo "Creating $container_name docker container."
sudo docker run --name $container_name \
	-p $db_port:1521 \
	-p 5500:5500 \
	-e ORACLE_PWD=$db_pwd \
	-v $(pwd)/oradata:/opt/oracle/oradata \
        -d virag/oracle-$version
#	oracle/database:$version

#sudo docker wait $container_name

while ! nc -vz $(sudo docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name) $db_port < /dev/null
do
  echo "$(date) - still trying"
  sleep 2
done
echo "$(date) - connected successfully"

attempt=0
while [ $attempt -le 200 ]; do
    attempt=$(( $attempt + 1 ))
    echo "$(date) - Waiting for oracle database to be up (attempt: $attempt)..."
    result=$(docker logs $container_name)
    if grep -q 'DATABASE IS READY TO USE!' <<< $result ; then
      echo "$(date) - $container_name is up!"
      break
    fi
    sleep 5
done

echo "Setting up LogMiner and loading sample HR schema on $container_name.."
sudo docker cp setup_logminer.sh $container_name:/tmp/setup_logminer.sh
sudo docker exec -it $container_name bash -c "/tmp/setup_logminer.sh"
