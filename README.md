Project related to this workshop 
* https://github.com/likhia/eap73-ocp-helloworld.git
* https://github.com/likhia/eap73-ocp-db.git

SET UP
======

### MySQL DB
* Create `common` project 
* Install MySQL (NOT EMPHERAL)
* Set the administrator id as `admin`, password as `openshift`, root password as `openshift` and database name as `sampledb`.   Set host name as `MySQL`.
* Open Pod and go to Terminal.  Type `mysql -u admin -p` and key in password as 'openshift`.  
* Type `use sampledb`.
* Execute the script below.
 
```
Create table member (
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT, 
name varchar(25),
email varchar(255), 
phone_number varchar(12));
```
* Type `exit`.  Type `mysql -u root`
* Execute the script below. 

```
GRANT XA_RECOVER_ADMIN ON *.* TO ‘admin’@‘%’;
FLUSH PRIVILEGES;
```

### Edit default resouorce

* oc edit template/project-request -n openshift-config
* Change vCPU to default to '1' for app and max to '5' for codeready

### Create Project

* Login as userX and create project with name as eap-userX. 
* Login as opentlc-mgr and add cluster-admin role for eap-userX. 

### Note 

If user has problem to create / open workspace due to resource constraint,  

* Login as Opentlc-mgr
* Open userX-codeready
* Edit the default limitrange.  Change vCPU from `4` to `6`.

Cache Maven dependencies in Nexus
==================================
* Follow README-NEXUS.md to install nexus in your Openshift cluster.

* Please follow the steps below
    (a) Create a new repository using maven (proxy) to 
        (i) jboss-enterprise-maven-repository : https://maven.repository.redhat.com/ga/
        (ii) jboss-public-repository-group : https://repository.jboss.org/nexus/content/groups/public/
    (b) Edit maven-public and add the above-created repository to this maven-public.

* Create a "configuration" folder under your project directory.   Copy settings-NEXUS.xml as settings.xml under "configuration" folder.   REPLACE the nexus URL based on your environment.

* Must sure the properties below is added in your pom.xml
```
<properties>
    <java.version>11</java.version>
    <enforcer.skip>true</enforcer.skip>
</properties>
```

(5) Must sure the plug in is added in your pom.xml
```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.8.0</version>
    <configuration>
       <source>11</source>  <!-- same as <java.version> -->
       <target>11</target>    <!-- same as <java.version> -->
    </configuration>
</plugin>
```

* Compile and build project is `mvn clean package --settings ./configuration/settings.xml`

* Execute below to create the application container image.  REPLACE the nexus URL based on your environment.
```
oc new-build --name=eap-helloworld  --binary --image-stream=jboss-eap73-openjdk11-openshift:7.3 \
        -e MAVEN_MIRROR_URL='http://nexus-nexus.apps.cluster-cf1a.cf1a.sandbox824.opentlc.com/repository/maven-public/'

```
```
oc start-build eap-helloworld  --from-dir=.  --follow
```

INSTALL HOMEROOM
=================
* login as opentlc-mgr.

* oc new-project homeroom-workshop
  
* oc import-image quay.io/openshifthomeroom/workshop-dashboard:5.0.1  (NOT WORKING)

* REGISTRY=default-route-openshift-image-registry.apps.cluster-457b.457b.sandbox68.opentlc.com

* docker login -u kubeadmin -p $(oc whoami -t) $REGISTRY

* docker tag quay.io/openshifthomeroom/workshop-dashboard:5.0.1 $REGISTRY/homeroom-workshop/workshop-dashboard:5.0.1 

* docker push $REGISTRY/homeroom-workshop/workshop-dashboard:5.0.1 

* Navigate to ocp4.8-workshop-eap/lab-workshop-content

* oc new-build  --name=openshift-workshop  --binary --image-stream=workshop-dashboard:5.0.1 -e MY_CUSTOM_VAR=abcd

* oc start-build openshift-workshop   --from-dir=.  --follow

* Navigate to ocp4.9-workshop-eap

* oc new-app ./templates/hosted-workshop-production.json  -p SPAWNER_NAMESPACE=$(oc project --short)  -p CLUSTER_SUBDOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed -e 's/^[^.]*\.//')  -p WORKSHOP_IMAGE=openshift-workshop:latest -p SPAWNER_IMAGE=docker.io/likhia/workshop-sprawner:4.9

### Need to execute this before delete this project in order to re-create successfully

* oc delete oauthclient hosted-workshop-console


INSTALL GET A USERNAME
=======================
* oc new-app --name=redis --template=redis-persistent -p MEMORY_LIMIT=1Gi  -p DATABASE_SERVICE_NAME=redis -p REDIS_PASSWORD=redis -p VOLUME_CAPACITY=1Gi -p REDIS_VERSION=5
  
* set the following variables: 
export USERCOUNT=5
export WORKSHOP=“Openshift\ and\ EAP\ Developer\ Workshop”
export ACCESSTOKEN=openshift
export ADMINPASSWORD=eapworkshop
export MODULE=https://hosted-workshop-homeroom-workshop.apps.cluster-457b.457b.sandbox68.opentlc.com\;Access\ Lab
export OCPCONSOLE=https://console-openshift-console.apps.cluster-pgwmr.pgwmr.sandbox320.opentlc.com\;OpenShift\ Console

* oc new-app quay.io/openshiftlabs/username-distribution -n homeroom-workshop --name=get-a-username  -e LAB_REDIS_HOST=redis  -e LAB_REDIS_PASS=redis -e LAB_TITLE=$WORKSHOP -e LAB_DURATION_HOURS=8h -e LAB_USER_COUNT=$USERCOUNT -e LAB_USER_ACCESS_TOKEN=$ACCESSTOKEN  -e LAB_USER_PASS=openshift -e LAB_USER_PREFIX=user -e LAB_USER_PAD_ZERO=false -e LAB_ADMIN_PASS=$ADMINPASSWORD -e LAB_MODULE_URLS=$MODULE -e LAB_EXTRA_URLS=$OCPCONSOLE

* oc expose service/get-a-username


