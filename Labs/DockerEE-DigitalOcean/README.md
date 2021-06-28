Docker Enterprise on Digital Ocean
====

This repository serves files used along the articles:

* [Running Docker Enterprise 2.1 on DigitalOcean — Part 1](https://link.medium.com/0XPAOy21ZR)
* [Running Docker Enterprise 2.1 on DigitalOcean — Part 2](https://link.medium.com/yXqG11xt0R)
* [Running Docker Enterprise 2.1 on DigitalOcean — Part 3](https://link.medium.com/A7KisfnQ3R)

You'll find here terraform scripts and ansible playbooks that provision a whole Docker Enterprise cluster that:

* Uses native DigitalOcean block storage for kubernetes persistent volumes
* Uses native DigitalOcean load balancers for kubernetes ingress controllers
* Configures HTTPS termination for load balancers or ingress endpoints

# Quick steps

Steps described in the articles resumed here:

1. Own a domain or subdomain managed by/delegated to DigitalOcean (like "devops.mycompany.com")

2. Clone this repo

3. Run:

```sh
./setdomain.sh <YOUR-DOMAIN>
```

4. Edit "babyswarm.auto.tfvars" and provide token & key fingerprints

5. Terraform your cluster

```sh
terraform init
terraform apply
```

6. Test SSH connectivity to nodes

```sh
ansible -m ping all
```

7. Install Docker Enterprise Engine

```sh
ansible-playbook install-dockeree.yml
```

8. Test docker engines with ansible:

```sh
ansible -a "docker version" all
```

9. Create and backup certificates for UCP node

```sh
export DOCKER_HOST=ssh://root@do-manager.devops.mycompany.com
docker volume create ucp-controller-server-certs
# creates certs with certbot
docker run --rm -ti \
  -p 80:80 -p 443:443 \
  -v ucp-controller-server-certs:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  --email admin@example.com \
  -n --agree-tos \
  -d ucp.devops.mycompany.com
# copies certs to UCP "hotspot"
docker run --rm -v ucp-controller-server-certs:/dummy \
  -w /dummy/live/ucp.devops.mycompany.com \
  alpine sh -c "cp privkey.pem /dummy/key.pem && \
     cp fullchain.pem /dummy/ca.pem && \
     cp fullchain.pem /dummy/cert.pem"
```

...*OR*, if you already have the certificates:

```sh
export DOCKER_HOST=ssh://root@do-manager.devops.mycompany.com
docker volume create ucp-controller-server-certs
docker run --rm -d --name dummy \
  -v ucp-controller-server-certs:/etc/letsencrypt \
  alpine tail -f /dev/null
docker cp ./letsencrypt dummy:/etc/
docker stop dummy
```

10. Install UCP

```sh
ansible-playbook install-ucp.yml
```

UCP will be available at https://ucp.devops.mycompany.com

11. Install worker nodes

```sh
ansible-playbook install-swarm.yml
```

11. Change orchestrator for worker nodes

12. Create and download client bundle, run "env.sh" script, list nodes

```sh
. ./env.sh
docker node ls
```

13. Create and edit "digitalocean-secret.yml" from template, deploy secret

```sh
cp digitalocean-secret.yml.template digitalocean-secret.yml
<edit file>
kubectl apply -f digitalocean-secret.yml
```

14. Install Storage CSI, check config, create dummy PVC

```sh
kubectl apply -f https://raw.githubusercontent.com/digitalocean/csi-digitalocean/master/deploy/kubernetes/releases/csi-digitalocean-v0.2.0.yaml
kubectl get sc
kubectl apply -f https://raw.githubusercontent.com/digitalocean/csi-digitalocean/master/examples/kubernetes/deployment-single-volume/pvc.yaml
```

15. Install CCM

```sh
kubectl apply -f https://raw.githubusercontent.com/digitalocean/digitalocean-cloud-controller-manager/master/releases/v0.1.8.yml
```

16. Install Helm

```sh
helm init
kubectl create rolebinding default-view \
  --clusterrole=view \
  --serviceaccount=kube-system:default \
  --namespace=kube-system
kubectl create clusterrolebinding add-on-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:default
```

17. Create wildcard certificate for apps domain, upload it to DO

```sh
docker run --rm -ti \
  -v $(pwd)/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly --agree-tos \
  -d "*.apps.devops.mycompany.com" \
  --preferred-challenges=dns --manual \
  --email=admin@example.com
<create "_acme-challenge.apps" entry in DNS as requested>
<wait until certificate is created>
doctl compute certificate create \
  --private-key-path letsencrypt/live/apps.devops.mycompany.com/privkey.pem \
  --certificate-chain-path ./letsencrypt/live/apps.devops.mycompany.com/fullchain.pem \
  --leaf-certificate-path ./letsencrypt/live/apps.devops.mycompany.com/fullchain.pem \
  --name apps-devops
```

18. Get certificate ID, install Ingress Controller (HTTPS in DO LB only)

```sh
doctl compute certificate list [-t "YOUR-DO-TOKEN-HERE"]
<FIND YOUR-CERT-ID>
helm install stable/nginx-ingress \
  --name my-nginx \
  --set rbac.create=true \
  --namespace nginx-ingress \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-protocol"="http" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-algorithm"="round_robin" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-tls-ports"="443" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-certificate-id"="YOUR-CERT-ID-HERE" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-healthcheck-path"="/healthz" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-redirect-http-to-https"="true" \
  --set controller.service.targetPorts.https="http"
```

This creates a new load balancer in DO that points to Ingress Controller

19. Create "\*.apps.devops.mycompany.com" wildcard DNS entry, use the load balancer IP, test health endpoint

```sh
curl xxx.apps.devops.mycompany.com/healthz
```
