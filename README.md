# 🚀 Welcome to the Airlock Microgateway Examples

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

**Airlock Microgateway** is a **Kubernetes-native WAAP** (Web Application and API Protection, formerly known as WAF) solution designed to secure microservices and web applications with robust, production-ready security features.

---

## 🔒 Why Airlock Microgateway?

In modern DevSecOps pipelines, security and therefore a WAAP solution must be agile, scalable, and seamlessly integrated into the CI/CD lifecycle.
Airlock Microgateway is the perfect fit for these requirements, as it is optimized for Kubernetes environments.

**Benefits**:

- **Free Basic Gateway API**: No license is required for basic Gateway API features. It can be used as a data plane for free.
- **Comprehensive WAAP**: Robust security through continuously improved deny rules to provide protection for [OWASP Top 10](https://owasp.org/www-project-top-ten/) attacks, API schema enforcement for OpenAPI and GraphQL, and insightful dashboards.
- **Identity Aware Proxy**: Enforces secure, modern authentication mechanisms with fine-grained access control for web applications and APIs.
- **Seamless Platform Integration**: Integrates effortlessly with Kubernetes-native tools and service meshes like kubectl, [ArgoCD](https://argo-cd.readthedocs.io), [FluxCD](https://fluxcd.io), [Helm](https://helm.sh), [Cilium](https://docs.cilium.io), and [Istio](https://istio.io).
- **Frictionless DevSecOps Process**: Streamlines technical and business process integration, enabling secure and agile development through Shift-Left and GitOps based controls.
- **Enables Hybrid Cloud Strategy**: Supports platform engineering across hybrid and multi-cloud environments, easing governance and aligning with Kubernetes-based infrastructure best practices.
- **Interoperability by Design**: Built on open standards like [Kuberentes Gateway API](https://gateway-api.sigs.k8s.io), [OIDC](https://openid.net), [JWT](https://jwt.io) and proven technologies such as [Elastic Common Schema](https://www.elastic.co/docs/reference/ecs), [Prometheus](https://prometheus.io), [Grafana](https://grafana.com), [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift), [Rancher](https://www.rancher.com) to ensures flexibility, avoid vendor lock-in, and supports migration across platforms.

For a list of all features, view the [comparison of the community and premium edition](https://docs.airlock.com/microgateway/latest/?topic=MGW-00000056).

---

## 📂 What’s in This Repository?

This repository includes hands-on examples to help you deploy and use Airlock Microgateway in real-world scenarios:

- [`README-k8s `](./README-k8s.md): Prepare the environment with tooling used by all examples (licensing is optional, only required for authentication and security functionalities).
- [`README-openshift`](./README-openshift.md): Based on Red Hat OpenShift
- [`README-webprotect`](./scenarios/README-webprotect.md): Secure your web application against threats ⚠️ **(Filtering license required)**.
- [`README-oidc`](./scenarios/README-oidc.md): Integrate upfront authentication and access control using OIDC ⚠️ **(Auth license required)**.
- [`README-trace`](./scenarios/README-trace.md): Track and visualize request flows to your microservices using OpenTelemetry distributed tracing.

## 🏁 Quick Start (K8s only)

1. Deploy the license (optional; only required for authentication and security functionalities):

```bash
kubectl create ns airlock-microgateway-system --dry-run=client -o yaml | kubectl apply -f -

kubectl -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | kubectl apply -f -
```

2. Apply the GatewayAPI CRDs:

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

3. Apply the remaining parts at once:

```bash
kubectl kustomize --enable-helm manifests | kubectl apply --server-side -f -
```

---

## ⚖️ License

Source code for the examples is provided under the [MIT License](./LICENSE). Commercial use requires compliance with licensing terms for Airlock Microgateway.

## Disclaimer

Airlock Microgateway is available as community and premium editions. A license is no longer needed for basic usage; it is only required for authentication and security functionalities. See [Community vs. Premium editions in detail](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html) to choose the right license type. Anyway, this example setup can be deployed with both editions of Airlock Microgateway.
