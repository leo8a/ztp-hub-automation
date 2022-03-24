# Node requirements

To fulfil the node requirements for an initial ZTP Hub cluster, two phases with several steps are proposed below.

> **Note:** Given that most of the node requirements to deploy an OpenShift cluster can be found in the [Official Red Hat Documentation](https://docs.openshift.com/container-platform/4.9/installing/installing_bare_metal_ipi/ipi-install-prerequisites.html#node-requirements_ipi-install-prerequisites), we have focused this section on those requirements which are missing, or can be further automated for Telco deployments.

## 1.1) Hardware / Baseboard Management Controller (BMC) Phase

### 1.1.1) Check minimum hardware requirements

- _Description:_ **Applies to both the bastion and Hub cluster nodes.** Before starting any task or configuration, we should first check if the available hardware resources are sufficient to host the initial Hub cluster as well as the required services (e.g. disconnected registry, repository and HTTP server, among others).

- _Automation:_ This pre-check task is usually performed via manual inspections.

### 1.1.2) Install latest BIOS and driver versions

- _Description:_ **Applies to Hub cluster nodes only.** Before starting the initial Hub cluster deployment, we should first check if all baremetal nodes have the latest BIOS and driver versions installed. This would be needed to include not only the latest fixes for security, but also fixes for advanced networking features on NICs like Precision Time Protocol ([PTP](https://en.wikipedia.org/wiki/Precision_Time_Protocol)), etc. Furthermore, Ironic may also have better integration with the latest BIOS versions, as well as an improved redfish support.

- _Automation:_ Usually, this task is performed manually using the available GUI interface of the BMC in the baremetal nodes.

### 1.1.3) Clean up boot entries

- _Description:_ **Applies to Hub cluster nodes only.** Before starting the initial Hub cluster deployment, we should first check that boot entries in all baremetal nodes are clean of old or inaccessible entries. This is aiming to avoid installation problems due to Ironic selecting an old entry to boot the server up during installation.

- _Automation:_ This task is usually performed manually from the available BIOS interface in the baremetal nodes.

## 1.2) Operating System (OS) / Kernel Phase

### 1.2.1) Bastion node bootstrapping

- _Description:_ **The OS assumed on the Bastion node is RHEL 8.4.** In this step, we install the software required for the automation of the initial ZTP Hub cluster. For instance, `Libvirtd` is needed for the Bootstrap VM (which is triggered by the OCP IPI installer). OpenShift client (`oc`) and installer (`openshift-baremetal-install`) will be needed for installation and daily basis work with the different clusters. The rest of desirable software is necessary for debugging and the container image synchronization.

- _Automation:_ A sample playbook to automate the bootstrapping of the bastion node can be found on `automation/node-requirements.yml`[L15-L43](../automation/node-requirements.yml#L15-L43). As you can see, we have separated this ansible block into two tasks, one for the required software dependencies [L18-L31](../automation/node-requirements.yml#L18-L31), and another for the nice-to-have tools [L33-L43](../automation/node-requirements.yml#L33-L43).

### 1.2.2) Configure Kernel parameters

- _Description:_ **These kernel configurations are performed on the bastion node.** This to ensure the proper installation of the OpenShift clusters later on.

- _Automation:_ A sample playbook to automate the configuration of the required kernel flags on the bastion node can be found on `automation/node-requirements.yml`[L100-L137](https://github.com/leo8a/ztp-hub-automation/blob/main/automation/node-requirements.yml#L100-L137). It is worth to highlight that, below flags are going to most important for the deployment phases later on:

    - [net.ipv6.conf.all.accept_ra](../automation/node-requirements.yml#L103)

    - [net.ipv6.conf.all.forwarding](../automation/node-requirements.yml#L109)
