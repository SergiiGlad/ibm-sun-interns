provider "ibm" {
  ibmcloud_api_key    = "${var.ibm_bmx_api_key}"
}


data "ibm_resource_group" "group" {
  name = "${var.group_name}"
}

resource "ibm_container_cluster" "cluster" {
  name              = "${var.cluster_name}"
  datacenter        = "${var.datacenter}"
  default_pool_size = 1
  machine_type      = "${var.machine_type}"
  hardware          = "${var.hardware}"
  resource_group_id = "${data.ibm_resource_group.group.id}"
}

data "ibm_container_cluster_config" "cluster_config" {
 cluster_name_id = "${ibm_container_cluster.cluster.name}"
 resource_group_id = "${data.ibm_resource_group.group.id}"
 depends_on = ["ibm_container_cluster.cluster"]
}

resource "null_resource" "kubectl_ver_checking" {
  provisioner "local-exec" {
    command = "bash kubectl_version.sh && bash helm_version.sh"
    on_failure = "fail"
  }
  depends_on = ["ibm_container_cluster.cluster"]
}

resource "null_resource" "configure_tiller" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<LOCAL_EXEC
      export KUBECONFIG="${data.ibm_container_cluster_config.cluster_config.config_file_path}"
      # To avoid Error: Could not get apiVersions from Kubernetes
      kubectl apply -f create-helm-service-account.yml
      helm init --service-account tiller --wait
      kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system
      while kubectl logs deploy/tiller-deploy -n kube-system; [ $? -gt 0 ]; do
         echo "Wait access to pod tiller"; done
      kubectl wait --for=condition=Available --timeout=300s apiservice v1beta1.metrics.k8s.io
    LOCAL_EXEC
   }
 depends_on = ["null_resource.kubectl_ver_checking"]

}

resource "null_resource" "install_cert-manager" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<LOCAL_EXEC
      export KUBECONFIG="${data.ibm_container_cluster_config.cluster_config.config_file_path}"
      # Install the CustomResourceDefinition resources separately
      kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml
      # Add the Jetstack Helm repository
      helm repo add jetstack https://charts.jetstack.io
      # Install the cert-manager Helm chart
      helm install --name cert-manager \
          --namespace cert-manager \
          --version v0.11.0 \
          --set ingressShim.defaultIssuerName=letsencrypt-prod \
          --set ingressShim.defaultIssuerKind=ClusterIssuer \
          jetstack/cert-manager
      # Wait after install
      kubectl rollout status -w deployment/cert-manager-webhook --namespace=cert-manager
      kubectl wait --for=condition=Available --timeout=300s APIService v1beta1.webhook.cert-manager.io
      # Configuring Cluster Issuer
      kubectl apply -f clusterissuer.yaml
    LOCAL_EXEC
   }
 depends_on = ["null_resource.configure_tiller"]
}

resource "null_resource" "configure_nginx_ingress" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<LOCAL_EXEC
      export KUBECONFIG="${data.ibm_container_cluster_config.cluster_config.config_file_path}"
      helm upgrade --install nginx-ingress  \
        --namespace=nginx-ingress \
        --set hostNetwork=true \
        --set controller.service.enabled=false \
        --set controller.kind=DaemonSet \
        --set controller.daemonset.useHostPort=true \
        --version v1.26.0 \
        stable/nginx-ingress
    LOCAL_EXEC
   }
   depends_on = ["null_resource.install_cert-manager"]
}

resource "null_resource" "configure_jenkins" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      external_node_ip=""
      site_name=""
      GREEN="\033[0;32m"
    }
    command = <<LOCAL_EXEC
      export KUBECONFIG="${data.ibm_container_cluster_config.cluster_config.config_file_path}"
      external_node_ip=$(kubectl get nodes \
              -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
      site_name=$(echo $external_node_ip | sed 's/\./-/g' | sed 's/^/jenkins-/' | sed 's/$/.nip.io/')
      kubectl apply -f pv_jenkins.yaml
      helm upgrade --install jenkins \
            --namespace=jenkins \
            --version v1.9.4 \
            --set master.ingress.enabled=true \
            --set-string master.ingress.hostName=$site_name \
            --set-string master.ingress.annotations."kubernetes\.io/tls-acme"=true \
            --set-string master.ingress.annotations."kubernetes\.io/ssl-redirect"=true \
            --set-string master.ingress.annotations."kubernetes\.io/ingress\.class"=nginx \
            --set-string master.ingress.tls[0].hosts[0]=$site_name \
            --set-string master.ingress.tls[0].secretName=acme-jenkins-tls \
            --set-string persistence.size=8Gi \
            stable/jenkins
      kubectl rollout status -w deployment/jenkins --namespace=jenkins
      echo "$GREEN ------------ NOTES --------------"
      echo "$GREEN You can open Jenkins via browser "
      echo "$GREEN https://$site_name"
    LOCAL_EXEC
   }
   depends_on = ["null_resource.configure_nginx_ingress"]
}
