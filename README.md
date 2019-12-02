# ibm-sun-interns

Create Kuberenets cluster with Jenkins

## Requirements
* Use k8s cluster v1.14
* Use terrafrom v0.11.14 version
* Use kubectl v1.14.7 version
* Use helm v2.13.0 version or highter
* Configuration variables can be changed in files:
  ```shell
  variables.tf
  ```

## Get the API keys

ibmcloud iam api-key-create <YOURNAME>-terraform -d '<YOURNAME> terraform' --file ibmcloud_api_key.json

## Set up the variables file for Terraform to use

export TF_VAR_ibmcloud_api_key="YOUR_API"


## Terraform deploy

Running

For planning phase

```shell
terraform plan
```

For apply phase

_Use terraform apply, or if you prefer not to have to type ‘yes’ to confirm, use terraform apply -auto-approve_

```shell
terraform apply
```

For destroy

```shell
terraform destroy
```

## Accessing your cluster

```
ibmcloud ks cluster config --cluster ibm_cluster
```

set the path to the local Kubernetes configuration file as an environment variable

 ```
export KUBECONFIG=/Users/<user_name>/.bluemix/plugins/kubernetes-service/clusters/mycluster/kube-config-<org>-<space>-<cluster_name>.yml
 ```
