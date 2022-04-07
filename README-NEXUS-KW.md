#!/bin/bash

# This script deploys nexus 3 and sets it up as a docker registry.
# Some parts of this script are taken from:
# https://raw.githubusercontent.com/redhat-gpte-devopsautomation/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh

PROJ=infra

#
# Add a Docker Registry Repo to Nexus3
# add_nexus3_docker_repo [repo-id] [repo-port] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_docker_repo() {
  local _REPO_ID=$1
  local _REPO_PORT=$2
  local _NEXUS_USER=$3
  local _NEXUS_PWD=$4
  local _NEXUS_URL=$5

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "repository.createDockerHosted('$_REPO_ID',$_REPO_PORT,null)"
}
EOM

  curl -v -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
  curl -v -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"
}


set -e

oc new-project $PROJ --display-name="Shared Nexus" || oc project ${PROJ}

oc new-app \
  --name='nexus' \
  --docker-image='docker.io/sonatype/nexus3:3.21.2' \
  --as-deployment-config

oc rollout pause dc/nexus

oc set resources \
  dc/nexus \
  --limits=cpu=2,memory=2Gi \
  --requests=cpu=500m,memory=1Gi

oc patch \
  dc/nexus \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/strategy/type","value":"Recreate"}]'

oc set volumes \
  dc/nexus \
  --add \
  --mount-path=/nexus-data \
  -t pvc \
  --name=nexus-volume-1 \
  --claim-size=10Gi \
  --overwrite

oc set probe \
  dc/nexus \
  --liveness \
  --readiness \
  --get-url=http://:8081/ \
  --initial-delay-seconds=30 \
  --period-seconds=30 \
  --failure-threshold=6

oc rollout resume dc/nexus

oc expose svc/nexus

URL="http://$(oc get route/nexus -o jsonpath='{.spec.host}')"
echo "nexus URL is ${URL}"

# wait till there is only 1 nexus pod (i.e. wait for the original pod to
# terminate)
echo -n "waiting for original pod to terminate..."
while [ $(oc get po -l deploymentconfig=nexus --no-headers | wc -l) -gt 1 ]; do
  echo -n "."
  sleep 1
done
echo "done"

echo -n "waiting for pod to be ready..."
RC=0
while [ $RC -ne 200 -a $RC -ne 302 -a $RC -ne 403 ]; do
  sleep 5
  RC=$(curl -k -sL -w "%{http_code}" ${URL} -o /dev/null)
  echo -n "."
done
echo "done"


export NEXUS_PASSWORD=$(oc rsh dc/nexus cat /nexus-data/admin.password)
echo "nexus admin password is ${NEXUS_PASSWORD}"

oc set deployment-hook \
  dc/nexus \
  --mid \
  --volumes=nexus-volume-1 \
  -- /bin/sh -c "echo nexus.scripts.allowCreation=true >./nexus-data/etc/nexus.properties"

oc wait dc/nexus --for condition=available
oc rollout latest dc/nexus

# wait till there is only 1 nexus pod (i.e. wait for the original pod to
# terminate)
echo -n "waiting for original pod to terminate..."
while [ $(oc get po -l deploymentconfig=nexus --no-headers | wc -l) -gt 1 ]; do
  echo -n "."
  sleep 1
done
echo "done"

echo -n "waiting for pod to be ready..."
RC=0
while [ $RC -ne 200 -a $RC -ne 302 -a $RC -ne 403 ]; do
  sleep 5
  RC=$(curl -k -sL -w "%{http_code}" ${URL} -o /dev/null)
  echo -n "."
done
echo "done"

set +e

# Configure nexus as a docker registry
add_nexus3_docker_repo docker 5000 admin $NEXUS_PASSWORD $URL



oc expose \
  dc/nexus \
  --port=5000 \
  --protocol="TCP" \
  --name=nexus-registry

oc create route edge nexus-registry --service nexus-registry

echo "nexus URL is ${URL}"
echo "nexus admin password is ${NEXUS_PASSWORD}"


