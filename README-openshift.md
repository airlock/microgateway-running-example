# ⚙️ Airlock Microgateway General OpenShift Setup

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This guide provides the foundational setup required for running Airlock Microgateway examples within the Red Hat OpenShift environment. It includes all general steps like infrastructure setup, logging, monitoring, and installing the Microgateway (licensing is optional and only required for authentication and security functionalities).

---

## 🖼️ Architecture Overview

> ⚠️ This setup was validated with **Red Hat OpenShift Local 4.22.1**.

**Core Components:**

- **Airlock Microgateway** – Data plane security
- **Prometheus & Grafana** – Metrics and dashboards
- **Alloy** – Collection of Kubernetes logs and application OTLP data
- **LokiStack & Loki Operator** – Operator-managed log storage and querying
- **TempoMonolithic & Tempo Operator** – Operator-managed trace storage and querying
- **RustFS** – S3-compatible, single-node/single-storage object storage for Loki

---

### Airlock Microgateway Requirements

- Review and fulfill all [Airlock Microgateway prerequisites](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html)

### Helm Requirements

The `oc` client included with OpenShift 4.22 embeds Kustomize 5.7.1, which is not compatible with Helm 4 when rendering Helm charts. Install both Helm versions with the following command names:

- `helm` for Helm 4
- `helm3` for Helm 3

The commands below explicitly select `helm3` when rendering manifests with `oc kustomize`.

---

## 🛡️ Install License (Optional)

📝 A license is no longer needed for basic usage. It is only required if you want to use authentication and security functionalities. If needed, you must obtain a valid license before continuing:

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
oc kustomize --enable-helm --helm-command helm3 manifests/ca | oc apply --server-side -f -
```

## 🔐 Deploy Valkey (Session Store)

```bash
oc kustomize --enable-helm --helm-command helm3 manifests/valkey-sessionstore/overlays/openshift | oc apply --server-side -f -

# Wait until Valkey is up and running
oc -n valkey rollout status deployment
```

## 📊 Deploy Logging and Monitoring Stack

### Install the Red Hat operators

Install these operators from OperatorHub before applying the manifests:

- **Loki Operator**, provided by Red Hat
- **Tempo Operator**, provided by Red Hat

Wait until both operators are available and confirm that their CRDs exist:

```bash
oc get csv -A | grep -E 'loki|tempo'
oc get crd lokistacks.loki.grafana.com tempomonolithics.tempo.grafana.com
```

The OpenShift overlay uses the operators only on OpenShift. The Kubernetes overlay continues to deploy the community Loki and Tempo Helm charts.

### Storage layout

The example deploys RustFS as an S3-compatible **single node with one storage volume**:

- image: `docker.io/rustfs/rustfs:1.0.0-rc.2`
- one RustFS replica
- one `ReadWriteOnce` PVC mounted at `/data`
- one `loki` bucket, created by a bootstrap Job
- access key: `airlock`
- secret key: `Start123!`

The credentials are example credentials and must be changed for any shared or persistent environment. RustFS SNSD and LokiStack size `1x.demo` are intended for this local example, not a highly available production deployment.

The manifests use OpenShift Local's `crc-csi-hostpath-provisioner` storage class. For another cluster, change `storageClassName` in:

- `manifests/logging-and-reporting/overlays/openshift/loki/lokistack.yaml`
- `manifests/logging-and-reporting/overlays/openshift/rustfs/pvc.yaml`
- `manifests/logging-and-reporting/overlays/openshift/tempo/tempomonolithic.yaml`

### Grant Grafana access to OpenShift metrics

```bash
oc adm policy add-cluster-role-to-user cluster-monitoring-view \
  -z grafana \
  -n monitoring
```

Loki, Tempo, and Prometheus use the declarative `grafana-datasource-token` service-account token Secret.

### Apply the stack

```bash
oc kustomize --enable-helm --helm-command helm3 manifests/logging-and-reporting/overlays/openshift | oc apply --server-side -f -

# Wait for the application components
oc -n monitoring rollout status deployment/alloy
oc -n monitoring rollout status deployment/grafana
oc -n monitoring rollout status deployment/rustfs

# Wait for operator-managed resources
oc -n monitoring wait --for=condition=Ready lokistack/lokistack --timeout=10m
oc -n monitoring wait --for=condition=Ready tempomonolithic/tempo --timeout=10m

# The bucket bootstrap must finish successfully
oc -n monitoring wait --for=condition=complete job/rustfs-create-loki-bucket --timeout=5m
```

The deployment creates:

- a RustFS SNSD deployment and `loki` bucket;
- a Red Hat `LokiStack` using S3 path-style access to RustFS;
- a Red Hat `TempoMonolithic` with a 5 Gi persistent volume;
- OpenShift-authenticated Alloy writers for the Loki and Tempo `application` tenants;
- Grafana Loki, Tempo, and Prometheus data sources;
- OpenShift `restricted-v2` security contexts for Alloy and RustFS.

No privileged SCC assignment is required.

Tempo uses the generic tenant name `application`. The Tempo Operator also requires a stable, globally unique `tenantId`; the UUID in `tempomonolithic.yaml` is therefore intentionally opaque and fixed. Do not change it after storing traces, because Tempo uses it as the storage prefix.

### Verify the result

```bash
oc -n monitoring get lokistack lokistack
oc -n monitoring get tempomonolithic tempo
oc -n monitoring get pods,pvc

# LokiStack 1x.demo intentionally has one ingester, so the operator reports
# InsufficientIngesterReplicas as a resilience warning on this single-node setup.
oc -n monitoring get lokistack lokistack \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'

# RustFS bucket creation
oc -n monitoring logs job/rustfs-create-loki-bucket
```

In Grafana Explore, use OpenShift's canonical namespace label to restrict a query to the Airlock Microgateway logs:

```logql
{kubernetes_namespace_name="airlock-gateway"}
```

The Grafana service account receives read access to the complete Loki `application` tenant and read-only permission to list OpenShift projects. Tenant-wide read access is required because Grafana Logs Drilldown performs service and volume discovery before adding namespace filters. Restrict access to Grafana appropriately: anyone who can use this data source can query application logs from every namespace.

Alloy publishes both `service` and `service_name` labels. The latter is required by Grafana Logs Drilldown for its default service discovery query.

> [!NOTE]
> Grafana is available at http://grafana-127-0-0-1.nip.io/ in the default OpenShift Local setup. Generic data-source checks can report an error because the operator gateways do not expose every optional upstream endpoint. Explore, Logs Drilldown, and dashboard queries use the supported tenant API paths.

## 🚀 Install Airlock Microgateway via OperatorHub

> ⚠️ Warning
> Starting in OpenShift Container Platform 4.19, the Ingress Operator manages the lifecycle of any Gateway API custom resource definitions (CRDs). This means that you will be denied access to creating, updating, and deleting any CRDs within the API groups that are grouped under Gateway API.

### 🧩 Deploy GatewayAPI CRDs

If you have an OpenShift version <= 4.18 please install the GatewayAPI CRDs manually.

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.0/standard-install.yaml
```

### Airlock Microgateway configure the after it was installed via OperatorHub

```bash
oc kustomize --enable-helm --helm-command helm3 manifests/airlock-microgateway/overlays/openshift | oc apply -f -


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
