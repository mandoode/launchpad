#!/bin/bash

#JSON_FILE="`pwd`/request-spot-instances-dryrun.json"
JSON_FILE="`pwd`/request-spot-instances.json"

echo "Checking for JSON file..."
if [ -f "$JSON_FILE" ];
then
   echo "JSON  File $FILE exists."
else
   echo "JSON file $FILE does not exist.  Must have a JSON file named request-spot-instances.json to pass to —-cli-input-json in $GIT_RELATIVE_DIR/jenkins"
   exit -1
fi


echo "Using spot price: $SPOT_PRICE"

#Request the instance#
request_id="$(aws ec2 request-spot-instances --spot-price $SPOT_PRICE --cli-input-json file://$JSON_FILE --query SpotInstanceRequests[].SpotInstanceRequestId --output text --profile r2ad)"

echo "request_id=[$request_id]"

if [ “$?” == “0” ];then
    if [ “$request_id” == “None” ];then
	echo “spot request submission [$request_id] failed !!!”
	exit -1	
    else
        if [ -z “$request_id” ];then
	    echo “spot request submission [$request_id] failed !!!”
	    exit -1	
        else
	    echo “spot request [$request_id] has been successfully submitted...”
        fi	
    fi
else
	echo “spot request submission [$request_id] failed !!!”
	exit -1	
fi


#WAIT#
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids $request_id --profile r2ad

if [ “$?” == “0” ];then
	echo “spot request [$request_id] has been fulfilled”
else
	echo “spot request [$request_id] failed !!!”
        echo “Could not determine the state of the SPOT request.  An instance may be created and start and you may be spending money !!!”
	exit -1	
fi


#get the instance_id#
instance_id="$(aws ec2 describe-instances --filter "Name=spot-instance-request-id,Values=$request_id" --query "Reservations[].Instances[].InstanceId" --output text --profile r2ad)"

if ! [ “$?” == “0” ];then
	echo “Could not determine the instance_id of request_id $request_id.  Instance may be running and spending money !!!”
	exit -1	
fi


#WAIT#
aws ec2 wait instance-running --instance-ids $instance_id --profile r2ad
if [ “$?” == “0” ];then
	echo “spot instance [$instance_id] has started”
else	
	echo “spot instance [$instance_id] failed to start !!!”
	exit -1	
fi

echo “exiting…”
