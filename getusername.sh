oc new-app --name=redis --template=redis-persistent -p MEMORY_LIMIT=1Gi  -p DATABASE_SERVICE_NAME=redis -p REDIS_PASSWORD=redis -p VOLUME_CAPACITY=1Gi -p REDIS_VERSION=5

export USERCOUNT=3
export WORKSHOP=“Openshift\ Developer\ Workshop”
export ACCESSTOKEN=openshift2021
export ADMINPASSWORD=workshop2021
export MODULE=“https://hosted-workshop-homeroom-workshop.apps.cluster-5af7.5af7.sandbox615.opentlc.com\;Access\ Lab”
export OCPCONSOLE=“https://console-openshift-console.apps.cluster-5af7.5af7.sandbox615.opentlc.com\;OpenShift\ Console”

oc new-app quay.io/openshiftlabs/username-distribution -n workshop --name=get-a-username  -e LAB_REDIS_HOST=redis  -e LAB_REDIS_PASS=redis -e LAB_TITLE=“$WORKSHOP” -e LAB_DURATION_HOURS=8h -e LAB_USER_COUNT=$USERCOUNT -e LAB_USER_ACCESS_TOKEN=“$ACCESSTOKEN”  -e LAB_USER_PASS=openshift -e LAB_USER_PREFIX=user -e LAB_USER_PAD_ZERO=false -e LAB_ADMIN_PASS=“$ADMINPASSWORD” -e LAB_MODULE_URLS=“$MODULE“ -e LAB_EXTRA_URLS=“$OCPCONSOLE”

# Need to update the environment parameter in deployment


