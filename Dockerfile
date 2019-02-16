FROM redhat-openjdk-18/openjdk18-openshift
MAINTAINER RBS

ENV MULE_VERSION 4.1.4
ENV MULE_HOME=/opt/mule

###############################################################################
## Base container configurations

# set no proxy
#ENV 	no_proxy 

# Install base pre-requisites
USER    root
RUN     curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 --output /usr/bin/jq
RUN     curl -L https://github.com/mikefarah/yq/releases/download/2.1.1/yq_linux_amd64 --output /usr/bin/yq
RUN	chmod +x /usr/bin/jq && chmod +x /usr/bin/yq 

##############################################################################
## Install Nexus repo downloader
WORKDIR /opt/scripts
ADD     files/nexusRepoDownloader.sh /opt/scripts

###############################################################################
## Install Mule EE Runtime
WORKDIR /opt
ADD     files/mule-ee-distribution-standalone-${MULE_VERSION}.tar.gz /opt
RUN     ln -sf mule-enterprise-standalone-${MULE_VERSION} mule

## Copy license file
ADD     files/mule-ee-license.lic /opt/mule/conf

## Copy the mule start/stop script
ADD     files/startMule.sh /opt/mule/bin/

## Patch mule-agent t0 2.1.8
ADD     files/patch/agent-setup-2.1.8-amc-final.jar /opt/mule/tools/
ADD     files/patch/amc_debug /opt/mule/bin/
ADD     files/patch/amc_setup /opt/mule/bin/

## Install license
WORKDIR /opt/mule/conf
RUN     /opt/mule/bin/mule -installLicense /opt/mule/conf/mule-ee-license.lic
RUN     rm -f /opt/mule/conf/mule-ee-license.lic

###############################################################################
## Setup user for build execution and application runtime
ADD files/uid_entrypoint /tmp
RUN chmod 755 /tmp/uid_entrypoint

RUN chmod -R u+x /opt && \
    chgrp -R 0 /opt && \
    chmod -R g=u /opt /etc/passwd

### Containers should NOT run as root as a good practice
USER 10001

### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
ENTRYPOINT [ "/tmp/uid_entrypoint" ]

###############################################################################
## Expose the necessary port ranges as required by the apps to be deployed

## HTTP Service Port
EXPOSE 	8081

WORKDIR  /opt/mule/bin
CMD      ["/opt/mule/bin/startMule.sh"]
