# 🛡️ Airlock Microgateway Web Protection Example

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This example demonstrates how to secure web applications in Kubernetes using Airlock Microgateway.

---

## 🖼 Architecture Overview

![Topology Diagram](media/topology-webprotect.svg)

**Key Components:**

- **Ingress Controller (Traefik)** for routing
- **Airlock Microgateway**:

   - Sidecar data plane mode for Nextcloud
   - Sidecarless data plane mode (Gateway API) for Juice Shop

- **Prometheus + Grafana** for metrics
- **Loki + Alloy** for logging

---

## 🌐 Application Access

| Application | URL |
|------------|-----|
| Nextcloud | [http://nextcloud-127-0-0-1.nip.io/](http://nextcloud-127-0-0-1.nip.io/) (Login: admin/changeme) |
| Juice Shop | [[http://juice-shop-127-0-0-1.nip.io:8080/](http://juice-shop-127-0-0-1.nip.io:8080/) |

---

## ⚙️ Setup

> [!WARNING]
> Be aware that this is an example and some security settings are disabled to make this demo as simple as possible (e.g. authentication enforcement, restrictive deny rule configuration and other security settings).

## 🧰 General Prerequisites

Before continuing, make sure your environment is prepared by following the instructions in the [General Setup](../general) or [General-OpenShift Setup](../general-openshift).  
This includes installing required tools, deploying observability components, certificate authorities, Redis, and the Airlock Microgateway itself.

## 🛠 Deploy the examples:

### Deploy Nextcloud

```bash {"cwd":"../"}
# Deploy Nextcloud
kubectl kustomize --enable-helm manifests/nextcloud | kubectl apply --server-side -f -

# Wait until Nextcloud is up and running
kubectl -n nextcloud rollout status deployment,statefulset
```

> [!NOTE]
> You can now access Nextcloud via http://nextcloud-127-0-0-1.nip.io/
>
> * Username: admin
> * Password: changeme

> [!IMPORTANT]
> The web application is not yet protected by Airlock Microgateway. Protection will be enabled later (see [Protect the web application](#protect-the-web-application)).

### Deploy Juice Shop

```bash {"cwd":"../"}
# Deploy Juice Shop
kubectl kustomize --enable-helm manifests/juice-shop | kubectl apply --server-side -f -

# Wait until Juice Shop is up and running
kubectl -n juice-shop rollout status deployment
```

## Protect the web application

### Protect Nextcloud (data plane mode 'sidecar')

> ⚠️ Warning
> Sidecar mode needs to be installed manually in OpenShift and is not part of the Example.

```bash {"cwd":"../"}
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

```bash {"cwd":"../"}
# Deploy the Airlock Microgateway configuration
kubectl kustomize --enable-helm manifests/juice-shop-microgateway-config | kubectl apply --server-side -f -

# The Ingress ressource can be deleted as it is no longer needed.
kubectl -n juice-shop delete ingress juice-shop
```

> [!NOTE]
> You can now access the protected Juice Shop via http://juice-shop-127-0-0-1.nip.io:8080/

## 🔁 Data plane mode 'Sidecar' vs. 'Sidecarless'

| Feature | Sidecar | Sidecarless |
|--------|---------|-------------|
| Resource Usage | Low | Even lower |
| License Impact | Higher | Lower |
| CNI Plugin | Required | Not required |
| Compatibility | Istio, Cilium | No dependencies |
| Updates | App restart | Gateway restart |
| Application Location | Inside Kubernetes | Inside/outside |
| North-South & East-West Traffic | Supported | Supported |

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
