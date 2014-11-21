#!/bin/bash

TYPE=${1:-"MasterBuilds"}
ARTIFACT_DIR=${2:-"artifacts"}

function resetArtifactDir() {
 rm -rf ${ARTIFACT_DIR}
 mkdir ${ARTIFACT_DIR}
}

function loadProperties() {
    source ${1}/${2}
}

function downloadArtifacts() {
  echo "Downloading Artifacts:"
  echo "wget -q \"${JENKINS_URL}job/${PUBLISH_JOB_NAME}/${PUBLISH_JOB_ID}/artifact/${PUBLISH_ARTIFACT}\" -O ${ARTIFACT_DIR}/${1}"
  wget -q "${JENKINS_URL}job/${PUBLISH_JOB_NAME}/${PUBLISH_JOB_ID}/artifact/${PUBLISH_ARTIFACT}" -O ${ARTIFACT_DIR}/${1}
}

function processArtifacts() {
  propertyDir=${1}
  if [[ -h "${propertyDir}/lastSuccessfulSanity" ]];
  then
    loadProperties ${propertyDir} lastSuccessfulSanity
    echo "JobName: ${PUBLISH_JOB_NAME}"
    echo "JobID: ${PUBLISH_JOB_ID}"
    echo "Artifact: ${PUBLISH_ARTIFACT}"
    downloadArtifacts sanity-report.html
  fi

  if [[ -h "${propertyDir}/lastSuccessfulRegression" ]];
  then
    loadProperties ${propertyDir} lastSuccessfulRegression
    echo "JobName: ${PUBLISH_JOB_NAME}"
    echo "JobID: ${PUBLISH_JOB_ID}"
    echo "Artifact: ${PUBLISH_ARTIFACT}"
    if [[ ${PUBLISH_JOB_NAME} == "4G_Regression" ]];
    then
      downloadArtifacts regression-report.zip
      unzip ${ARTIFACT_DIR}/regression-report.zip -d ${ARTIFACT_DIR}/
      mv ${ARTIFACT_DIR}/archive ${ARTIFACT_DIR}/regression-report
    else
      downloadArtifacts regression-report.html
    fi
  fi

  if [[ -h "${propertyDir}/lastSuccessfulPerformance" ]];
  then
    loadProperties ${propertyDir} lastSuccessfulPerformance
    echo "JobName: ${PUBLISH_JOB_NAME}"
    echo "JobID: ${PUBLISH_JOB_ID}"
    echo "Artifact: ${PUBLISH_ARTIFACT}"
    downloadArtifacts performance-reports.zip
    unzip ${ARTIFACT_DIR}/performance-reports.zip -d ${ARTIFACT_DIR}/
    mv ${ARTIFACT_DIR}/reports ${ARTIFACT_DIR}/performance-reports 
  fi
}


resetArtifactDir 

case "${TYPE}" in
  'MasterBuilds')
    echo "Collecting Master Build Artifacts"
    processArtifacts MasterBuilds
    ;;
  'ReleaseBuilds')
    echo "Collecting Release Build Artifacts"
    processArtifacts ReleaseBuilds/lastSuccessfulBranch
    ;;
  'FeatureBuilds')
    echo "Collecting Feature Build Artifacts"
    processArtifacts FeatureBuilds/lastSuccessfulBranch
    ;;
  *)
    echo "Usage:"
    echo "sh ./ArtifactCollector.sh ([MasterBuilds]|ReleaseBuilds|FeatureBuilds)"
    ;;
esac
