# Airlock Microgateway running example

*Airlock Microgateway is a Kubernetes native WAAP (Web Application and API Protection) solution to protect microservices.*

<picture>
  <source media="(prefers-color-scheme: dark)"
          srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight_Negative.svg">
  <source media="(prefers-color-scheme: light)"
          srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg">
  <img alt="Microgateway" src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" align="right" width="250">
</picture>

Modern application security is embedded in the development workflow and follows DevSecOps paradigms. Airlock Microgateway is the perfect fit for these requirements. It is a lightweight WAAP solution (formerly known as WAF), optimized for Kubernetes environments. Airlock Microgateway protects your applications and microservices with the tried-and-tested Airlock security features against attacks, while also providing a high degree of scalability.

This repository contains a running example of Airlock Microgateway in Kubernetes. It shows how to protect a backend application with Airlock Microgateway. The source code is available under the [MIT license](/LICENSE).

## Overview
![Topology](/media/topology.svg)
<br>

**This topology diagram illustrates the deployment architecture of a Kubernetes cluster with focus on Secure access to web applications using the Airlock Microgateway.**
- Users access the cluster from devices (e.g., laptops or smartphones).
- Requests are routed through an **Ingress** managed by Traefik, which serves as the cluster's entry point.
- Traefik handles traffic forwarding based on routing rules.
- The Juice Shop will be Protected by the **Airlock Microgateway via GatewayAPI**.
- Nextcloud will be Protected by the **Airlock Microgateway via Sidecar**.
- Prometheus Collects metrics from the cluster, including all **Airlock Microgateway** instances.
- PromTail is used to forward logs from the Microgateway to Loki for analysis and storage.
- Grafana Visualizes metrics and logs collected from Prometheus and Loki.
<br>

**Links to access the applications**
- Grafana via http://grafana-127-0-0-1.nip.io/
- Prometheus via http://prometheus-127-0-0-1.nip.io/
- Nextcloud via http://nextcloud-127-0-0-1.nip.io/
  - Username: admin
  - Password: changeme
- Juice Shop via http://juice-shop-127-0-0-1.nip.io/

## Disclaimer
Airlock Microgateway is available as community and premium edition. See [Community vs. Premium editions in detail](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html) to choose the right license type. Anyway, this example setup can be deployed with Airlock Microgateway both editions.

> [!WARNING]
> Be aware that this is an example and some security settings are disabled to make this demo as simple as possible (e.g. authentication enforcement, restrictive deny rule configuration and other security settings).

## General prerequisites
* Install [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/).

> [!NOTE]
> This example is built for Rancher Desktop. Nevertheless, it should also work with any other Kubernetes distributions. Simply ensure the following:
> * Ensure the [Airlock Microgateway requirements](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html) are met.
> * [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) is installed.
> * [helm](https://helm.sh/docs/intro/install/) is installed.
> * [kustomize](https://kustomize.io) >= 5.2.1 is installed.
> * An Ingress Controller (e.g. Traefik, Ingress Nginx, ...) is deployed.

## Airlock Microgateway prerequisites

### Obtain and deploy the Airlock Microgateway license
1. Either request a community license free of charge or purchase a premium license.
   * Community license: [airlock.com/microgateway-community](https://airlock.com/en/microgateway-community)
   * Premium license: [airlock.com/microgateway-premium](https://airlock.com/en/microgateway-premium)
2. Check your mailbox and save the license file `microgateway-license.txt` locally (replace the existing file).
3. Deploy the Airlock Microgateway license
```bash
# Create the airlock-microgateway-system namespace
kubectl create ns airlock-microgateway-system --dry-run=client -o yaml | kubectl apply -f -

# Deploy the Airlock Microgateway license
kubectl -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | kubectl apply -f -
```

> [!NOTE]
> See [Community vs. Premium editions in detail](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html) to choose the right license type.

### Deploy the cert-manager
For an easy start in non-production environments, you may deploy the same [cert-manager](https://cert-manager.io/) we are using internally for testing.
```bash
# Deploy the cert-manager
kubectl kustomize --enable-helm manifests/cert-manager | kubectl apply --server-side -f -

# Wait until the cert-manager is up and running
kubectl -n cert-manager rollout status deployment
```

## Deploy the example

### Deploy the logging, monitoring and reporting  stack
```bash
# Deploy Promtail, Loki, Prometheus and Grafana
kubectl kustomize --enable-helm manifests/logging-and-reporting | kubectl apply --server-side -f -

# Wait until Promtail, Loki, Prometheus and Grafana are up and running
kubectl -n monitoring rollout status deployment,daemonset,statefulset
```

> [!NOTE]
> You can now access
> * Prometheus via http://prometheus-127-0-0-1.nip.io/
> * Grafana via http://grafana-127-0-0-1.nip.io/

### Deploy Airlock Microgateway
> [!TIP]
> Certain environments such as OpenShift or GKE require non-default configurations when installing the CNI plugin. In case that the CNI plugin does not start properly consult the [Troubleshooting Microgateway CNI article](https://docs.airlock.com/microgateway/latest/#data/1710781909882.html).

> [!NOTE]
> In case this example is not deployed in Rancher Desktop, most likely the `cniBinDir`and `cniNetDir`in the file `manifests/airlock-microgateway/microgateway-cni-values.yaml` must be adjusted.
> Example:
> ```
> config:
>   cniBinDir: "/usr/libexec/cni/"
>   cniNetDir: "/etc/cni/net.d"
> ```

```bash
# Deploy Airlock Microgateway including the CNI plugin
kubectl kustomize --enable-helm manifests/airlock-microgateway | kubectl apply --server-side -f -

# Wait until Airlock Microgateway is up and running
kubectl -n kube-system rollout status daemonset airlock-microgateway-microgateway-cni
kubectl -n airlock-microgateway-system rollout status deployment
```

### Deploy Nextcloud

```bash
# Deploy Nextcloud
kubectl kustomize --enable-helm manifests/nextcloud | kubectl apply --server-side -f -

# Wait until Nextcloud is up and running
kubectl -n nextcloud rollout status deployment,statefulset
```

> [!NOTE]
> You can now access Nextcloud via http://nextcloud-127-0-0-1.nip.io/
> * Username: admin
> * Password: changeme

> [!IMPORTANT]
> The web application is not yet protected by Airlock Microgateway. Protection will be enabled later (see [Protect the web application](#protect-the-web-application)).

### Deploy Juice Shop

```bash
# Deploy Juice Shop
kubectl kustomize --enable-helm manifests/juice-shop | kubectl apply --server-side -f -

# Wait until Juice Shop is up and running
kubectl -n juice-shop rollout status deployment
```

> [!NOTE]
> You can now access Juice Shop via http://juice-shop-127-0-0-1.nip.io/

> [!IMPORTANT]
> The web application is not yet protected by Airlock Microgateway. Protection will be enabled later (see [Protect the web application](#protect-the-web-application)).

## Protect the web application

### Protect Nextcloud (data plane mode 'sidecar')

```bash
# Deploy the Airlock Microgateway configuration
kubectl kustomize --enable-helm manifests/nextcloud-microgateway-config | kubectl apply --server-side -f -

# Label the Nextcloud deployment to be protected
kubectl -n nextcloud patch deployment nextcloud -p '{
   "spec":{ "template": {"metadata": {"labels": {
               "sidecar.microgateway.airlock.com/inject":"true"
            } } } } }'

# Wait until the Nextcloud is rolled out with Microgateway
kubectl -n nextcloud rollout status deployment
```

### Protect Juice Shop (data plane mode 'sidecarless')
```bash
# Deploy the Airlock Microgateway configuration
kubectl kustomize --enable-helm manifests/juice-shop-microgateway-config | kubectl apply --server-side -f -

# Adjust the Ingress to be routed through Airlock Microgateway
kubectl -n juice-shop patch ingress juice-shop -p '{
"spec": { "rules": [
    { "host": "juice-shop-127-0-0-1.nip.io",
      "http": {
        "paths": [
          {
            "path": "/",
            "pathType": "Prefix",
            "backend": {
              "service": {
                "name": "juice-shop-gateway",
                "port": {
                  "number": 8080
                } } } } ] } } ] } }'
```

### Sidecar vs sidecarless

|                         | Sidecar                         | Sidecareless (Kubernetes Gateway API)                     |
| :---------------------- | :----------------------------- | :----------------------------------------- |
| **Total resource consumption (CPU/Memory)** | Low                             | Even lower                                  |
| **3rd party solutions licensing number of containers** | Higher 3rd party license costs | Lower 3rd party license costs             |
| **Airlock Microgateway CNI plugin**        | Required                        | Not required                               |
| **Supported service mesh compatibility**   | Istio and Cilium                | No special compatibility requirements      |
| **Update Microgateway Engine**             | Rollover of the application Pod | Rollover of Microgateway (no impact on the application) |
| **Traffic filtering with Airlock Microgateway** | Automatically in-line (traffic is redirected first to Microgateway) | Filtering ensured with routing and NetworkPolicies in Kubernetes |
| **Protected web application**              | Runs inside of Kubernetes       | Runs inside or outside of Kubernetes       |
| **North-South traffic**                    | Yes, for the protected Pod      | Yes                                        |
| **East-West traffic**                      | Yes                             | Yes, by routing the traffic accordingly    |

## Additional Information

* [Microgateway manual](https://docs.airlock.com/microgateway/latest/)
  * [Getting Started](https://docs.airlock.com/microgateway/latest/#data/1660804708742.html)
  * [System Architecture](https://docs.airlock.com/microgateway/latest/#data/1660804709650.html)
  * [Installation](https://docs.airlock.com/microgateway/latest/#data/1660804708713.html)
  * [Troubleshooting](https://docs.airlock.com/microgateway/latest/#data/1659430054787.html)
  * [API Refernce](https://docs.airlock.com/microgateway/latest/api/index.html)
* [Release Repository](https://github.com/airlock/microgateway)
* [Airlock Microgateway labs](https://play.instruqt.com/airlock/invite/hyi9fy4b4jzc?icp_referrer=github.com)

## License
View the [detailed license terms](https://www.airlock.com/en/airlock-license) for the software contained in this image.
* Decompiling or reverse engineering is not permitted.
* Using any of the deny rules or parts of these filter patterns outside of the image is not permitted.

</details>
<br>

Airlock<sup>&#174;</sup> is a security innovation by [ergon](https://www.ergon.ch/en)

<!-- Airlock SAH Logo (different image for light/dark mode) -->
<a href="https://www.airlock.com/en/secure-access-hub/">
<picture>
    <source media="(prefers-color-scheme: dark)"
        srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo_Negative.png">
    <source media="(prefers-color-scheme: light)"
        srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo.png">
    <img alt="Airlock Secure Access Hub" src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo.png" width="150">
</picture>
</a>
