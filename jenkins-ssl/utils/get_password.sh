#!/bin/sh -e

CONTAINER=jenkins-ssl
docker exec $CONTAINER cat /var/jenkins_home/secrets/initialAdminPassword
