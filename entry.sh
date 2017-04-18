#!/bin/bash

shutdown_awslogs()
{
    echo "Stopping container..."
    kill $(pgrep -f /var/awslogs/bin/aws)
    exit 0
}
trap shutdown_awslogs INT TERM HUP

cat <<EOF > /awslogs.conf
[general]
# Path to the CloudWatch Logs agent's state file. The agent uses this file to maintain
# client side state across its executions.
state_file = /var/awslogs/state/agent-state

EOF

if [ "$AWSLOGS" != "" ]
then
    for file in /conf.d/*
    do
        cat "$file" >> /awslogs.conf
        echo "" >> /awslogs.conf
    done

    IFS=$','
    for config in $AWSLOGS
    do
        sectionName=$(echo -n "$config" | cut -d ':' -f 1)
        file=$(echo -n "$config" | cut -d ':' -f 2)
        logGroup=$(echo -n "$config" | cut -d ':' -f 3)
        logStream=$(echo -n "$config" | cut -d ':' -f 4)
        cat <<EOF >> /awslogs.conf
[$sectionName]
datetime_format = %Y-%m-%d %H:%M:%S
file = $file
buffer_duration = 5000
initial_position = start_of_file
log_group_name = $logGroup
log_stream_name = $logStream

EOF
    done
fi

region=$(wget --tries=2 --timeout=2 -qO- http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | sed 's/",.*$//' | sed 's/^.*"//')
if [ "$region" == "" ]
then
    region=ap-southeast-1
fi
if [ "$region" != "" ]
then
    mv -f /awslogs.conf /var/awslogs/etc/awslogs.conf
    sed -i "s/region =.*/region = $region/" /var/awslogs/etc/aws.conf

    echo "Start launcher..."
    /var/awslogs/bin/awslogs-agent-launcher.sh 
    echo "Run complete..."
else
    echo "ERR: This does not seem to be an EC2 instance..."
    exit 0
fi
