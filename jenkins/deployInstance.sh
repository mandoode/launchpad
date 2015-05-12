#!/bin/bash

source /home/docker/.aws/eucarc

JSON_FILE="`pwd`/$1"

echo "Checking for JSON file..."
if [ -f "$JSON_FILE" ];
then
   echo "JSON  File $FILE exists."
else
   echo "JSON file $FILE does not exist.  Must have a JSON file named request-spot-instances.json to pass to —-cli-input-json in $GIT_RELATIVE_DIR/jenkins"
   exit -1
fi


#run the instance#
instance_id="$(aws --endpoint-url $EC2_URL ec2 run-instances --cli-input-json file://$JSON_FILE --query Instances[].InstanceId --output text --profile ziunet)"

if [ "$?" == "0" ];then
    if [ "$instance_id" == "None" ];then
	echo "run instance failed !!!"
	exit -1	
    else
        if [ -z "$instance_id" ];then
	    echo "run instance failed !!!"
	    exit -1	
        else
	    echo "instance $instance_id has been successfully created..."
        fi	
    fi
else
	echo "run-instances failed!!!"
	exit -1	
fi


#WAIT#
aws --endpoint-url $EC2_URL ec2 wait instance-running --instance-ids $instance_id --profile ziunet
if [ "$?" == "0" ];then
	echo "instance [$instance_id] has started"
else	
	echo "instance [$instance_id] failed to start !!!"
	exit -1	
fi

echo "exiting…"
