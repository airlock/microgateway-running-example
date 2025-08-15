# ⚙️ Airlock Microgateway General Setup

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This guide provides the foundational setup required for running Airlock Microgateway examples within a Kubernetes environment such as Rancher Desktop. It includes all general steps like licensing, infrastructure setup, logging, monitoring, and installing the Microgateway.

---

## 🖼️ Architecture Overview

**Core Components:**
- **Ingress Controller (e.g. Traefik)** – Routing and traffic management
- **Airlock Microgateway** – Data plane security
- **Prometheus & Grafana** – Metrics and dashboards
- **Loki & Alloy** – Log aggregation and analysis

---

## 🧰 Prerequisites

> ⚠️ This setup is optimized for **Rancher Desktop** with `containerd`. You can adapt it to other Kubernetes distributions.

### Required Tools
Make sure the following tools are installed:
- [`kubectl`](https://kubernetes.io/docs/reference/kubectl/overview/)
- [`helm`](https://helm.sh/docs/intro/install/)
- [`kustomize`](https://kustomize.io) (version ≥ 5.2.1)
- A running **Kubernetes cluster** with an **Ingress Controller** (e.g. Traefik, Ingress NGINX)

### Airlock Microgateway Requirements
- Review and fulfill all [Airlock Microgateway prerequisites](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html)

---

## 🛡️ Install License

 📝 You must obtain a valid license before continuing:
 - **Community License**: [airlock.com/microgateway-community](https://airlock.com/en/microgateway-community)
 - **Premium License**: [airlock.com/microgateway-premium](https://airlock.com/en/microgateway-premium)
 - 📘 [Community vs. Premium Comparison](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html)

### Deploy the License
```bash
kubectl create ns airlock-microgateway-system --dry-run=client -o yaml | kubectl apply -f -

kubectl -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | kubectl apply -f -
```

## 📜 Deploy Cert-Manager
For an easy start in non-production environments, you may deploy the same [cert-manager](https://cert-manager.io/) we are using internally for testing.
```bash
kubectl kustomize --enable-helm general/manifests/cert-manager | kubectl apply --server-side -f -

# Wait until the cert-manager is up and running
kubectl -n cert-manager rollout status deployment
```

## 📜 Deploy Certificate Authority (CA)
```bash
kubectl kustomize --enable-helm general/manifests/ca | kubectl apply --server-side -f -
```

## 🗄️ Deploy Redis (Session Store)
```bash
kubectl kustomize --enable-helm general/manifests/redis-sessionstore | kubectl apply --server-side -f -

# Wait until the Redis is up and running
kubectl -n redis rollout status deployment
```

## 📊 Deploy Logging and Monitoring Stack
```bash
kubectl kustomize --enable-helm general/manifests/logging-and-reporting | kubectl apply --server-side -f -

# Wait until Alloy, Loki, Prometheus and Grafana are up and running
kubectl -n monitoring rollout status deployment,daemonset,statefulset
```

> [!NOTE]
> You can now access
> * Prometheus via http://prometheus-127-0-0-1.nip.io/
> * Grafana via http://grafana-127-0-0-1.nip.io/

## 🧩 Deploy GatewayAPI CRDs
In order to be able to use GatewayAPI you have to deploy the CRDs in advance.
```bash
# Please install experimental for backendTLS support e.g. OIDC example
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml --server-side

# Standard version with no experimental features. OIDC example will not work with it or needs to be manually adjusted.
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml --server-side
```

## 🚀 Deploy Airlock Microgateway
> [!TIP]
> Certain environments such as OpenShift or GKE require non-default configurations when installing the CNI plugin. In case that the CNI plugin does not start properly consult [Troubleshooting Microgateway CNI](https://docs.airlock.com/microgateway/latest/#data/1710781909882.html).

> [!NOTE]
> In case this example is not deployed in Rancher Desktop, most likely the `cniBinDir`and `cniNetDir`in the file `general/manifests/airlock-microgateway/microgateway-cni-values.yaml` must be adjusted.
> Example:
> ```
> config:
>   cniBinDir: "/usr/libexec/cni/"
>   cniNetDir: "/etc/cni/net.d"
> ```

```bash
# Deploy Airlock Microgateway including the CNI plugin
kubectl kustomize --enable-helm general/manifests/airlock-microgateway | kubectl apply -f -

# Wait until Airlock Microgateway is up and running
kubectl -n kube-system rollout status daemonset airlock-microgateway-microgateway-cni
kubectl -n airlock-microgateway-system rollout status deployment
```

---

## 📚 Resources

* [Microgateway manual](https://docs.airlock.com/microgateway/latest/)
  * [Getting Started](https://docs.airlock.com/microgateway/latest/#data/1660804708742.html)
  * [System Architecture](https://docs.airlock.com/microgateway/latest/#data/1660804709650.html)
  * [Installation](https://docs.airlock.com/microgateway/latest/#data/1660804708713.html)
  * [Troubleshooting](https://docs.airlock.com/microgateway/latest/#data/1659430054787.html)
  * [API Reference](https://docs.airlock.com/microgateway/latest/index/api/crds/index.html)
* [Release Repository](https://github.com/airlock/microgateway)
* [Airlock Microgateway labs](https://airlock.instruqt.com/pages/airlock-microgateway-labs)

## ⚖️ License
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
