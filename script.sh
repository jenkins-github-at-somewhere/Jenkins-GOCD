#!/bin/bash

while read line; do export $line; done <jenkins.properties;curl -o downloadedFile ${JENKINS_URL}job/${JENKINS_JOB_NAME}/${JENKINS_JOB_NUMBER}/artifact/${JENKINS_ARTIFACT}
