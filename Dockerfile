FROM ubuntu:16.04
MAINTAINER Simon Tse <simon.tse@lalamove.com>

RUN apt-get update && \
    apt-get -q -y install software-properties-common && \
    apt-get -q -y install python wget && \
    apt-get clean
ADD https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py /awslogs-agent-setup.py

COPY awslogs.conf.dummy /awslogs.conf.dummy
COPY entry.sh /entry.sh
RUN mkdir /conf.d # for adding config files here

RUN python /awslogs-agent-setup.py -n -r ap-southeast-1 -c /awslogs.conf.dummy

CMD ["/entry.sh"]
