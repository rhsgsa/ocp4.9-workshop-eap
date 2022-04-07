#!/bin/bash

PROJ=nexus

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

export NEXUS_PASSWORD=$(oc rsh dc/nexus cat /nexus-data/admin.password)
echo "nexus admin password is ${NEXUS_PASSWORD}"

oc set deployment-hook \
  dc/nexus \
  --mid \
  --volumes=nexus-volume-1 \
  -- /bin/sh -c "echo nexus.scripts.allowCreation=true >./nexus-data/etc/nexus.properties"

oc wait dc/nexus --for condition=available
oc rollout latest dc/nexus

# Wait for nexus pod to be running. 

oc expose \
  dc/nexus \
  --port=5000 \
  --protocol="TCP" \
  --name=nexus-registry

oc create route edge nexus-registry --service nexus-registry

echo "nexus URL is ${URL}"
echo "nexus admin password is ${NEXUS_PASSWORD}"

