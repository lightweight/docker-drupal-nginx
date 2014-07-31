#!/bin/bash
#
# get a root command prompt on the last created 
# Docker container 

Container_ID=`sudo docker ps -q`
echo "Container ID = $Container_ID"
Process_ID=`sudo docker inspect --format {{.State.Pid}} $Container_ID`
echo "Process ID = $Process_ID"
# connect to container via nsenter
sudo nsenter --target $Process_ID --mount --uts --ipc --net --pid
