#!/bin/bash

while read line; do export $line; done <jenkins.properties;curl -o result.html ${JENKINS_URL}job/${PUBLISH_JOB_NAME}/${PUBLISH_JOB_ID}/artifact/${PUBLISH_ARTIFACT}
