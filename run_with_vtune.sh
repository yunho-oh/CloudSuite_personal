#!/bin/bash

#Configure the below part accoring to the Vtune install status
VTUNE_PATH=/opt/intel/vtune_profiler_2020.0.0.605129/bin64
VTUNE=vtune
VTUNE_OPTION=hotspots
SAMPLING_MODE=hw

#Configure the below part according to your system
#DATASET: name of the dataset container that you create with the following command
#docker create --name data_in_memory_analytics cloudsuite/movielens-dataset
DATASET=data_in_memory_analytics
#DATA: you can choose either ml-latest-small or ml-latest. ml-latest is larger.
DATA=ml-latest-small
#SERVER_CPUS is used for -cpu-mask in Vtune and assigning cores to the server container
SERVER_CPUS=0,2,4,6,8,10,12,14,16,18,20,22
#SOURCE_DIR is the path of folder that inlcudes System.map file
SOURCE_DIR=sym:p=/boot
DRIVER_MEMORY=64g
EXECUTOR_MEMORY=64g

sysctl -w kernel.kptr_restrict=0

rm -rf r00*

#If you already create the dataset, comment out the below command.
docker create --name $DATASET cloudsuite/movielens-dataset

sleep 10

if [ "${SAMPLING_MODE}" = "hw" ]; then
    STACK_SIZE=1024
else    
    STACK_SIZE=0
fi

echo $VTUNE_PATH/$VTUNE -collect $VTUNE_OPTION -knob sampling-mode=$SAMPLING_MODE  -knob sampling-interval=1 -knob enable-stack-collection=true -knob stack-size=$STACK_SIZE -analyze-system  --search-dir $SOURCE_DIR -cpu-mask=$SERVER_CPUS -finalization-mode=full -- docker run --cpuset-cpus=$SERVER_CPUS --rm --volumes-from $DATASET --cap-add=SYS_PTRACE cloudsuite/in-memory-analytics \
    /data/$DATA /data/myratings.csv \
    --driver-memory $DRIVER_MEMORY --executor-memory $EXECUTOR_MEMORY

$VTUNE_PATH/$VTUNE -collect $VTUNE_OPTION -knob sampling-mode=$SAMPLING_MODE  -knob sampling-interval=1 -knob enable-stack-collection=true -knob stack-size=$STACK_SIZE -analyze-system  --search-dir /boot -cpu-mask=$SERVER_CPUS -- docker run --cpuset-cpus=$SERVER_CPUS --rm --volumes-from $DATASET --cap-add=SYS_PTRACE cloudsuite/in-memory-analytics \
    /data/$DATA /data/myratings.csv \
    --driver-memory $DRIVER_MEMORY --executor-memory $EXECUTOR_MEMORY  