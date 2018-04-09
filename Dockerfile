FROM centos:latest

ARG BUILD=base
ARG VERSION=1
ARG RELEASE=1
ARG NAMESPACE=openshift
ARG PACKAGE_INSTALL_EXTRA_ARGS

LABEL com.redhat.component="jenkins-slave-${BUILD}" \
      name="${NAMESPACE}/jenkins-slave-${BUILD}" \
      version="${VERSION}" \
      architecture="x86_64" \
      release="${RELEASE}" \
      io.k8s.display-name="Jenkins Slave (${BUILD})" \
      io.k8s.description="This is a jenkins slave image. Supports a build environment for ${LANGAUGE} ${VERSION}" \
      io.openshift.tags="openshift,jenkins,slave,${BUILD}"

ENV HOME=/home/jenkins \
  JENKINS_SLAVE_BUILD=${BUILD} \
  JENKINS_SLAVE_VERSION=${VERSION} \
  JENKINS_SLAVE_RELEASE=${RELEASE} \
  PACKAGE_INSTALL_EXTRA_ARGS="${PACKAGE_INSTALL_EXTRA_ARGS}"

USER root

ADD assets/bin/* /usr/local/bin/
ADD https://github.com/openshift/jenkins/blob/master/slave-base/contrib/bin/run-jnlp-client /usr/local/bin/run-jnlp-client
RUN chmod +x /usr/local/bin/run-jnlp-client

# install and initialise the jenkins-slave components
RUN /usr/local/bin/install-jenkins-slave

USER 1001

ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
