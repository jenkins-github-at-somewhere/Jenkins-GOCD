#!/bin/bash

NOW=`date +%s`

##
# Write METADATA Information of the build to MetaFile
##
function writeData() {

  echo -e "Writing METADATA Information: \n"
  _file=${1}
  _link=${2}
  touch ${_file}
  if [[ -h ${_link} ]]; then unlink ${_link}; fi
  ln -s ${_file} ${_link}

  cat > ${_file} <<EOL
PUBLISH_GIT_BRANCH=${PUBLISH_GIT_BRANCH}
PUBLISH_GIT_COMMIT=${PUBLISH_GIT_COMMIT}
PUBLISH_JOB_NAME=${PUBLISH_JOB_NAME}
PUBLISH_JOB_ID=${PUBLISH_JOB_ID}
PUBLISH_ARTIFACT=${PUBLISH_ARTIFACT}
######################################
JENKINS_URL=${JENKINS_URL}
JENKINS_JOB_NAME=${JOB_NAME}
JENKINS_JOB_NUMBER=${BUILD_NUMBER}
######################################
EOL

  curl ${JENKINS_URL}job/${PUBLISH_BINARY_JOB_NAME}/${PUBLISH_BINARY_JOB_ID}/artifact/build.info --silent >> ${_file}
  cat ${_file}
}

##
# Git init. Create Root Folders.
##
function createRootFolders() {
  mkdir MasterBuilds
  mkdir ReleaseBuilds
  mkdir FeatureBuilds
}

##
# Prepare the appropriate MetaFile in location based on JobName
##
function prepareMetaFile(){

  if [[ ${PUBLISH_JOB_NAME} == *_Sanity ]];
  then
     _file=Sanity_${NOW}.properties
      writeData ${_file} lastSuccessfulSanity

   elif [[ ${PUBLISH_JOB_NAME} == *_Regression* ]];
   then
     _file=Regression_${NOW}.properties
      writeData ${_file} lastSuccessfulRegression

  elif [[ ${PUBLISH_JOB_NAME} == *_Performance* ]];
  then
     _file=Performance_${NOW}.properties
      writeData ${_file} lastSuccessfulPerformance
  else
     echo "Unknown Job!!"
  fi
}

##
# Commit MetaFile(s) to GIT
##
function commitToMaster() {

  cd ${WORKSPACE}
  git add .
  git commit -m "${JENKINS_URL}job/${PUBLISH_JOB_NAME}/${PUBLISH_JOB_ID} [${PUBLISH_GIT_BRANCH}::${PUBLISH_GIT_COMMIT}] Checkin by jenkins @ [${NOW}]";
  git push origin master
}

##
# Main Function goes here!!
##
function main() {

  cd ${WORKSPACE}
  git checkout master

  createRootFolders

  echo -e "\nPublishing Reports:"
  echo -e "\tBranch: ${PUBLISH_GIT_BRANCH}"
  echo -e "\tJob: ${PUBLISH_JOB_NAME}"
  echo -e "\tCommit: ${PUBLISH_GIT_COMMIT}\n"

  if [[ -h lastSuccessfulBuild ]]; then unlink lastSuccessfulBuild; fi
  if [[ ${PUBLISH_GIT_BRANCH} == Release_* ]] || [[ ${PUBLISH_GIT_BRANCH} == OPDK_* ]];
    then

    ln -s ReleaseBuilds lastSuccessfulBuild
    cd ${WORKSPACE}/ReleaseBuilds

    #Create Release Build Directory
    mkdir ${PUBLISH_GIT_BRANCH}

    if [[ -h lastSuccessfulBranch ]]; then unlink lastSuccessfulBranch; fi
    ln -s ${PUBLISH_GIT_BRANCH} lastSuccessfulBranch

    cd ${PUBLISH_GIT_BRANCH}
    prepareMetaFile

  elif [[ ${PUBLISH_GIT_BRANCH} == "master" ]];
  then

    ln -s MasterBuilds lastSuccessfulBuild
    cd ${WORKSPACE}/MasterBuilds

    prepareMetaFile

  else

    ln -s FeatureBuilds lastSuccessfulBuild
    #Create Feature Build Directory
    cd ${WORKSPACE}/FeatureBuilds

    mkdir ${PUBLISH_GIT_BRANCH}
    if [[ -h lastSuccessfulBranch ]]; then unlink lastSuccessfulBranch; fi
    ln -s ${PUBLISH_GIT_BRANCH} lastSuccessfulBranch

    cd ${PUBLISH_GIT_BRANCH}
    prepareMetaFile
  fi

  echo -e "\nPublishing MetaData to GIT:\n"
  commitToMaster
}

main

echo -e "\nEND\n"
