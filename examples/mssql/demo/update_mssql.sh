#!/bin/bash
  
sudo docker cp update.sql mssql-2017-latest-$(hostname):update.sql
sudo docker exec -it mssql-2017-latest-$(hostname) /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "Redis@123" -d RedisConnect -i update.sql
echo ""