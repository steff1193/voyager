#!/bin/bash

LOCAL_CHECKOUT_ROOT="$1"
VERSION="$2"
REPOSITORY="$3"

COMPANY_NAME="DesignWare.DK"
SOLR_GRPID="dk.designware.voyager"
SOLR_NAME="voyager"
BIG_SOLR_NAME="Voyager"
LUCENE_GRPID="dk.designware.vucene"
LUCENE_NAME="vucene"
BIG_LUCENE_NAME="Vucene"

echo ${VERSION} | grep 'SNAPSHOT$'
if [ $? -eq 0 ];then
  echo "SNAPSHOT release detected"
  SNAPSHOT=true
else
  echo "non-SNAPSHOT release detected"
  SNAPSHOT=false
fi

cd $LOCAL_CHECKOUT_ROOT;
rm -r maven-build
ant -Dversion=$VERSION -Dcompany_name=$COMPANY_NAME -Dsolr_groupId=$SOLR_GRPID -Dsolr_name=$SOLR_NAME -Dbig_solr_name=$BIG_SOLR_NAME -Dlucene_groupId=$LUCENE_GRPID -Dlucene_name=$LUCENE_NAME -Dbig_lucene_name=$BIG_LUCENE_NAME get-maven-poms
cd maven-build

echo pom.xmls created
read

# Using Maven to deploy artifacts to artifactory
if [ $SNAPSHOT == false ]; then
  LOCAL_REPOSITORY_PATH=~/.m2
  echo "In order to do a real (non-snapshot) release of Solr you need to manually manipulate the pom-file of the parent artifact before you do"
  echo "the deploy. The name of parent artifact should be listed here below:"
  grep -A 10 "<parent>" pom.xml | grep -B 10 "</parent>"
  echo "Find the artifact in your local maven repository (probably ${LOCAL_REPOSITORY_PATH}) and change the values under project | distributionManagement | repository"
  echo "in the pom-file of the artifact (e.g. ${LOCAL_REPOSITORY_PATH}/repository/org/apache/apache/13/apache-13.pom). Change into the following:"
  echo "<distributionManagement>"
  echo "  <repository>"
  echo "     <id>artifactory.tlt.local</id>"
  echo "     <name>artifactory.tlt.local-releases</name>"
  echo "     <url>${REPOSITORY}</url>"
  echo " </repository>"
  echo "</distributionManagement>"
  echo "Especially make sure to change <url> property to ${REPOSITORY}!" 
  echo "Press any key to confirm og press CTRL-C to skip this deploy"
  read
fi

mvn -N -Pbootstrap -DskipTests install

mvn -DskipTests -DdistMgmtSnapshotsUrl=${REPOSITORY} clean deploy

#CURRENT_DIR=$(pwd)

#cd ${CURRENT_DIR}/solr/solrj
#mvn -DskipTests -DdistMgmtSnapshotsUrl=${REPOSITORY} deploy
#cd ${CURRENT_DIR}/solr/core
#mvn -DskipTests -DdistMgmtSnapshotsUrl=${REPOSITORY} deploy
#cd ${CURRENT_DIR}/solr/solr-webapp
#mvn -DskipTests -DdistMgmtSnapshotsUrl=${REPOSITORY} deploy

#cd ${CURRENT_DIR}

if [ $SNAPSHOT == false ]; then
  echo "Now please revert the changes in the pom-file of the parent artifact"
  echo "Press any key to confirm"
  read
fi
