# Services requirements

## 3.1) Local HTTP server Phase

> **Note:** For more info about the setup of the local HTTP server, you may check the [official documentation](https://docs.openshift.com/container-platform/4.10/installing/installing_bare_metal_ipi/ipi-install-installation-workflow.html#ipi-install-creating-an-rhcos-images-cache_ipi-install-installation-workflow) of Red Hat.

- _Description:_ This is an HTTP server running on the bastion node. It does not need SSL nor auth configured, just a plane and basic HTTP daemon serving on the baremetal network. This service is mainly used to serve the `RHCOS` requirements for the ZTP Hub cluster, as well as for the target Spoke clusters. It is also used to store other relevant objects like the [RT kernel](https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=3727) that will be used by the spoke clusters.

    - IPI Installer needs QEMU and Openstack images to deploy the ZTP Hub cluster.
    - `RHACM` needs the `RHCOS` Live ISO and the RootFS to deploy the target Spoke clusters.

- _Automation:_ A sample playbook to automate the installation and configuration of the local HTTP server using **HTTPD** on the Bastion node, can be found on the `automation/services-requirements-yml`[L7-L105](../automation/services-requirements.yml#L7-L105). As a validation, below is a pre-flight check that could be automated.

    - Check downloaded ISOs are available through the baremetal network.

## 3.2) Disconnected Registry Phase

> **Note:** For more info about the setup of a disconnected registry, you may check the [official documentation](https://docs.openshift.com/container-platform/4.10/installing/disconnected_install/installing-mirroring-installation-images.html) of Red Hat.

- _Description:_ This is a disconnected registry running on the bastion node. It will provide all the container images for the initial ZTP Hub cluster as well as for the target Spoke clusters. Hence, the registry not only needs to be reachable by all clusters (on default port 5000), but it also needs to contain the [OCP releases](https://quay.io/repository/openshift-release-dev/ocp-release?tab=tags), the [OLM Marketplace](https://docs.openshift.com/container-platform/4.10/operators/admin/olm-restricted-networks.html) and the required software you need to run in your cloud.

- _Automation:_ A sample playbook to automate the installation and configuration of the disconnected registry on the Bastion node, can be found on the `automation/services-requirements.yml`[L108-L215](../automation/services-requirements.yml#L108-L215). Here, the ansible block was separated into two subtasks, first to create a systemd to start and enable the disconnected registry [L113-L176](../automation/services-requirements.yml#L113-L176), and then mirroring the OCP release container images [L178-L215](../automation/services-requirements.yml#L178-L215).

## 3.3) Local Repository Phase

- _Description:_ This is a local repository running on the bastion node. It does not need SSL nor auth configured, just an HTTP service. This repository is used by the ZTP flow proposed by Red Hat to deploy the target Spoke clusters, not used during the initial ZTP Hub cluster deployment.

- _Automation:_ A sample playbook to automate the installation of the local repository using **Gogs** on the Bastion node, can be found on the `automation/services-requirements.yaml`[L218-L240](../automation/services-requirements.yml#L218-L240). Automation of this service requires further automation, given that the first time it should be configured via a browser.

  - Further, automate the configuration of the local repository or select another technology for that.

## 3.4) On-prem Artifactory Phase (optional)

Additionally, another optional component that is gaining more traction on Telco deployments is the use of an Artifactory as **"One Central Interface"** to store all artifacts needed during the registry, repository, and HTTP server phases above. This artifactory may be implemented using JFrog and serve directly the initial Hub cluster deployment processes.
