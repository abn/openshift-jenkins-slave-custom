# OpenShift Jenkins Slave: Custom Builds

This repository provides the source required to generate a Jenkins slave pod image using any base images. The intention here is to provide a solution that works in environments where OpenShift image layering strategy requires the use of approved/custom/qualified base images. While other scenarios can benefit from this approach, that is the primary intended function.

#### Why does this even exist? Why not just use Red Hat provided images?
While the default images provided by Red Hat that comes with the platform or available via [registry.access.redhat.com](https://registry.access.redhat.com) are useful in majority scenarios, this does not work in the following scenarios.

1. As part of policy, business/technical requirements (certificate configuration etc.) a custom base image is required.
2. A language/framework runtime/s2i image already exists that needs to be converted to Jenkins slave.

The alternative approach is to perform the steps required to create the base image on top of the provided image. This, however, does not scale well and introduces maintenance overhead.

### Assumptions
1. The base image is Red Hat flavoured; ie. `rhel-atomic`, `rhel7`, `fedora`, `centos`.
2. The base image contains any language specific logic (this is not an asserted assumption).

### Defaults
By default, on building an image using the provided [Dockerfile](Dockerfile) will generate a CentOS Jenkins slave that is functionally equivalent "in theory", to an image produced using [openshift/jenkins/slave-base/Dockerfile](https://github.com/openshift/jenkins/blob/master/slave-base/Dockerfile).

To produce a RHEL Atomic Jenkins Slave (locally), the following command can be executed. Note that this is required for testing only, the base image can be changed using an OpenShift BuildConfig.
```sh
sed s='FROM .*'='FROM registry.access.redhat.com/rhel-atomic:latest'= Dockerfile \
  | docker build -t jenkins-slave-rhel-atomic -
```
### Pre-configured Hooks
The installation script allows for several hooks to be executed specific to the build and can be extended by using externalised configuration. More details coming soon.

### OpenShift
#### Using Provided OpenShift Template
##### Option 1: Make template available cluster wide
```sh
oc create -f https://raw.githubusercontent.com/abn/openshift-jenkins-slave-custom/master/openshift/template.yml
```

##### Option 2: Use the template via the CLI
```sh
oc process \
  -p BASE_IMAGE=rhel-atomic \
  -p BASE_IMAGE_NAMESPACE=openshift \
  -p JENKINS_SLAVE_BUILD=base \
  -p JENKINS_SLAVE_VERSION=7.4 \
  -p JENKINS_SLAVE_RELEASE=1 \
  -p 'EXTRA_PACKAGES="git make gcc"' \
  -f https://raw.githubusercontent.com/abn/openshift-jenkins-slave-custom/master/openshift/template.yml \
    | oc apply -f -
```
#### Example Build Configuration
The following build configuration will work on any OpenShift Container Platform cluster with valid host subscriptions and a pre-defined image stream.

```yaml
apiVersion: v1
kind: BuildConfig
metadata:
  name: jenkins-slave-rhel-atomic
  labels:
    build: base
    role: jenkins-slave
spec:
  triggers:
    - type: ConfigChange
  runPolicy: SerialLatestOnly
  source:
    type: Git
    git:
      uri: 'https://github.com/abn/openshift-jenkins-slave-custom.git'
      ref: master
  strategy:
    type: Docker
    dockerStrategy:
      from:
        kind: DockerImage
        name: registry.access.redhat.com/rhel-atomic:latest
      noCache: true
      buildArgs:
        - name: "BUILD"
          value: "rhel-atomic-base"
        - name: "VERSION"
          value: "7"
        - name: "RELEASE"
          value: "4"
  output:
    to:
      kind: ImageStreamTag
      name: 'jenkins-slave-rhel-atomic:latest'
```

### FAQs
#### Running behind proxies
As with any Jenkins slave image instances; proxies are expected to be configured so that the the following can be done.

1. Download `remoting.jar` from the master node. In kubernetes/openshift context, this would be <master-pod-ip>:80. This is done using `curl` from the [run-jnlp-client](https://github.com/openshift/jenkins/blob/master/slave-base/contrib/bin/run-jnlp-client#L58) script. If the container has any of the proxy environment variables set, make sure that they are configured so that the command succeeds. Watch out for 50x error htmls in the jar file.
2. Java runtime can communicate with the master pod-ip. The java command is forked from the [run-jnlp-client](https://github.com/openshift/jenkins/blob/master/slave-base/contrib/bin/run-jnlp-client#L134) script.
3. Optionally, if you want internet access from within the slave during pipeline executions etc.; ensure the configuration allows for that.

