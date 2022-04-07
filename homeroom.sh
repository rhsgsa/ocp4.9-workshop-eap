oc new-project homeroom-workshop

docker pull quay.io/openshifthomeroom/workshop-dashboard:5.0.1
  
## oc import-image quay.io/openshifthomeroom/workshop-dashboard:5.0.1

REGISTRY=default-route-openshift-image-registry.apps.cluster-1ec0.1ec0.sandbox1350.opentlc.com

docker login -u kubeadmin -p $(oc whoami -t) $REGISTRY

docker tag quay.io/openshifthomeroom/workshop-dashboard:5.0.1 $REGISTRY/homeroom-workshop/workshop-dashboard:5.0.1 

docker push $REGISTRY/homeroom-workshop/workshop-dashboard:5.0.1 

oc new-build  --name=openshift-workshop  --binary --image-stream=workshop-dashboard:5.0.1 \
-e MY_CUSTOM_VAR=abcd -e OCP_URI=".apps.cluster-2e68.2e68.sandbox1783.opentlc.com"

oc start-build openshift-workshop   --from-dir=.  --follow

oc new-app ./templates/hosted-workshop-production.json  -p SPAWNER_NAMESPACE=$(oc project --short)  -p CLUSTER_SUBDOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed -e 's/^[^.]*\.//')  -p WORKSHOP_IMAGE=openshift-workshop:latest

# Need to execute this before delete this project in order to re-create successfully

# oc delete oauthclient hosted-workshop-console


