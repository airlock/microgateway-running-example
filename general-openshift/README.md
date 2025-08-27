# ⚙️ Airlock Microgateway General OpenShift Setup

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This guide provides the foundational setup required for running Airlock Microgateway examples within the Red Hat OpenShift environment. It includes all general steps like licensing, infrastructure setup, logging, monitoring, and installing the Microgateway.

---

## 🖼️ Architecture Overview
> ⚠️ This setup is created based on **Red Hat OpenShift Local 4.19**

**Core Components:**
- **Airlock Microgateway** – Data plane security
- **Prometheus & Grafana** – Metrics and dashboards
- **Loki & Alloy** – Log aggregation and analysis
- **LokiStack & Red Hat Cluster Logging** - Log aggregation and analysis ***Red Hat Supported**

---

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
oc create ns airlock-microgateway-system --dry-run=client -o yaml | oc apply -f -

oc -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | oc apply -f -
```

## 🗃️ Deploy Cert-Manager Operator for Red Hat OpenShift via OperatorHub
Keep the recommended namespace **cert-manager-operator** during install.

## 🗄️📜 Deploy Certificate Authority (CA)
```bash
oc kustomize --enable-helm general-openshift/manifests/ca | oc apply --server-side -f -
```

## 🔐 Deploy Redis (Session Store)
```bash
oc kustomize --enable-helm general-openshift/manifests/redis-sessionstore | oc apply --server-side -f -

# Wait until the Redis is up and running
oc -n redis rollout status deployment
```

## 📊 Deploy Logging and Monitoring Stack

```bash
oc kustomize --enable-helm general-openshift/manifests/logging-and-reporting | oc apply --server-side -f -

# Wait until Grafana is up and running
oc -n monitoring rollout status deployment
```

### Create the binding and tokens to access Promethues via Thanos
```bash
oc adm policy add-cluster-role-to-user cluster-monitoring-view \
  -z grafana \
  -n monitoring
```

### Replace the example token with your own Token  in the Grafana values.yaml and reapply Grafana
```bash
oc create token grafana -n monitoring --duration=87600h > grafana-token.txt #valid for 10 years

cat grafana-token.txt 

oc kustomize --enable-helm general-openshift/manifests/logging-and-reporting/grafana | oc apply --server-side -f -
```

> [!NOTE]
> You can now access
> * Grafana via http://grafana-127-0-0-1.nip.io/

### Install Loki communiti edition via Operator Hub (from opdev)

Apply RBAC to grant Loki access:
```bash
kubectl kustomize --enable-helm general-openshift/manifests/logging-and-reporting/loki-community | kubectl apply --server-side -f -
```

Open Loki via installed Operator and apply the following config.

<details>
<summary>Loki Community config</summary>

```yaml
apiVersion: charts.example.com/v1alpha1
kind: Loki
metadata:
  name: loki-sample
  namespace: monitoring
  annotations:
    helm.sdk.operatorframework.io/install-disable-crds: 'true'
spec:
  global:
    clusterDomain: cluster.local
    dnsService: dns-default
    dnsNamespace: openshift-dns

  rbac:
    sccEnabled: true

  loki:
    auth_enabled: false
    commonConfig:
      replication_factor: 1
    storage:
      type: filesystem

  singleBinary:
    replicas: 1

  monitoring:
    dashboards:
      enabled: false
    servicemonitor:
      enabled: true
    lokiCanary:
      enabled: false
    rules:
      enabled: false
      alerting: false
    selfMonitoring:
      enabled: false
      grafanaAgent:
        installOperator: false

  test:
    enabled: false
```

</details>

### Install Alloy
```bash
kubectl kustomize --enable-helm general-openshift/manifests/logging-and-reporting/alloy/ | kubectl apply --server-side -f -

oc adm policy add-scc-to-user privileged -z alloy -n monitoring
```


## 🚀 Install Airlock Microgateway via OperatorHub

> ⚠️ Warning
> Starting in OpenShift Container Platform 4.19, the Ingress Operator manages the lifecycle of any Gateway API custom resource definitions (CRDs). This means that you will be denied access to creating, updating, and deleting any CRDs within the API groups that are grouped under Gateway API.

### 🧩 Deploy GatewayAPI CRDs

If you have an OpenShift version <= 4.18 please install the GatewayAPI CRDs manually.

```bash
# Please install experimental for backendTLS support needed for the OIDC example.
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml

# Standard version with no experimental features. OIDC example will not work with it or needs to be manually adjusted.
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```

### Airlock Microgateway configure the after it was installed via OperatorHub
```bash
oc kustomize --enable-helm general-openshift/manifests/airlock-microgateway | oc apply -f -


Activate the Podmonitor, by editing the subscription of the Airlock operator:
spec:
  config:
    env:
      - name: GATEWAY_API_POD_MONITOR_CREATE
        value: "true"
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
