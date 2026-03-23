# Installing Argo CD and Backstage on GKE (detailed)

This guide matches how this platform repo **expects** things to be wired: **Argo CD** managing `gitops/` and **Backstage** in **`idp`**. Adjust **project**, **cluster**, **zone**, and **region** to your environment.

---

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **GKE cluster** | e.g. `platform-lab` in `us-central1-a` |
| **gcloud** + **kubectl** | `gcloud container clusters get-credentials ...` |
| **Helm 3** | `helm version` |
| **GitHub** | For Backstage: token with repo access (PRs, catalog) |
| **Permissions** | Your GCP user or CI SA can create **LoadBalancer**, **GCS** (for Terraform state elsewhere), etc. |

```bash
gcloud config set project YOUR_PROJECT_ID

gcloud container clusters get-credentials YOUR_CLUSTER_NAME \
  --zone YOUR_ZONE \
  --project YOUR_PROJECT_ID

kubectl cluster-info
kubectl get nodes
```

---

# Part 1 — Argo CD

Argo CD is the **GitOps controller**: it reads manifests from Git and reconciles the cluster. It does **not** run Terraform.

## 1.1 Choose install style

| Method | Namespace default | Best when |
|--------|-------------------|-----------|
| **Official YAML** | `argocd` | Quick lab; you’ll apply `Application` CRs (can live in another namespace). |
| **Helm (`argo/argo-cd`)** | You choose (e.g. `gitops`) | You want **all** Argo components in **`gitops`** to match this repo’s examples. |

Your cluster had Argo CD **pods in `gitops`** — that usually means **Helm** or a **custom manifest** with namespace `gitops`, not the stock single-file install (which targets **`argocd`** unless edited).

---

## 1.2 Install Argo CD with **Helm** (recommended for namespace `gitops`)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace gitops

helm install argocd argo/argo-cd \
  --namespace gitops \
  --version CHART_VERSION \
  --set configs.params."application\\.controller\\.repo\\.server\\.timeout\\.seconds"=300
```

Notes:

- Pick **`CHART_VERSION`** from [argo-helm releases](https://github.com/argoproj/argo-helm/releases) (pin a version in production).
- Optional values file for **HA**, **Ingress**, **SSO**, **resource limits** — start minimal for a lab.

**Wait until ready:**

```bash
kubectl rollout status deployment/argocd-server -n gitops
kubectl get pods -n gitops
```

---

## 1.3 Alternative — **Official manifest** (namespace `argocd`)

If you use upstream install YAML, it creates namespace **`argocd`**:

```bash
kubectl create namespace argocd

kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl rollout status deployment/argocd-server -n argocd
```

To use namespace **`gitops`** instead, you must **not** use this file as-is; use **Helm**, **Kustomize** (namespace override), or **forked manifests**. Do not blindly duplicate resources.

---

## 1.4 First login (initial admin password)

```bash
# If using default install, secret name may be argocd-initial-admin-secret
kubectl -n gitops get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

If the secret does not exist, admin was already rotated — use your saved password or reset via [Argo CD docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/) (`argocd-secret`).

---

## 1.5 Expose the Argo CD UI

**Option A — LoadBalancer (simple on GKE)**

```bash
kubectl patch svc argocd-server -n gitops -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc -n gitops argocd-server -w
```

Open **`https://<EXTERNAL-IP>`** (port 443). Accept the cert warning for the default self-signed cert.

**Option B — Port-forward (local only)**

```bash
kubectl port-forward -n gitops svc/argocd-server 8080:443
# https://localhost:8080
```

**Option C — Ingress + TLS**  
Use your org’s pattern (GKE Ingress, Gateway API, IAP). Set **`argocd-cm`** `url:` to the public URL so links and OIDC work.

---

## 1.6 Register **this platform’s** Application

From a clone of **this** repo:

```bash
kubectl apply -f argocd/dev-app.yaml
```

Edit **`spec.source.repoURL`** in `argocd/dev-app.yaml` **before** apply so it matches **your** GitHub repo URL.

**Verify:**

```bash
kubectl get applications -n gitops
argocd app list   # if argocd CLI is logged in
```

Argo should sync **`gitops/overlays/dev`** into namespace **`dev`** (per `dev-app.yaml`).

---

## 1.7 GitHub Actions → cluster (optional but used in this repo)

Workflows call:

```bash
gcloud container clusters get-credentials ... 
kubectl apply -f argocd/dev-app.yaml
kubectl patch application platform-api-dev -n gitops ...
```

Ensure the **GCP service account** in **`GCP_CREDENTIALS`** can **`container.clusters.getCredentials`** and **`kubectl`** against the cluster (GKE RBAC: typically bind a **ClusterRole** for CI).

---

# Part 2 — Backstage

Backstage is the **IDP UI**: templates live in **`templates/`** in Git; the chart only runs the **app**.

## 2.1 Helm chart (matches a typical install)

Official chart:

```bash
helm repo add backstage https://backstage.github.io/charts
helm repo update

kubectl create namespace idp
```

Install or upgrade with **your** values (this repo ships an example):

```bash
cd /path/to/platform   # this repository

helm upgrade --install backstage backstage/backstage \
  --namespace idp \
  --version 2.6.3 \
  -f idp/backstage-values-dev.yaml
```

**OCI alternative** (same chart, pin version):

```bash
helm upgrade --install backstage oci://ghcr.io/backstage/charts/backstage \
  --namespace idp \
  --version 2.6.3 \
  -f idp/backstage-values-dev.yaml
```

Adjust **`--version`** to match the chart you want; **`2.6.3`** is what appeared in `helm list` on one cluster.

---

## 2.2 Required values (before install)

Edit **`idp/backstage-values-dev.yaml`** (or your override file):

| Setting | Why |
|---------|-----|
| **`app.baseUrl`**, **`backend.baseUrl`**, **`cors.origin`** | Must match how users open Backstage (e.g. `https://backstage.example.com` or `http://localhost:7007` with port-forward). |
| **`catalog.locations`** | Must include the **raw Git URL** of **`templates/all.yaml`** in your repo. |
| **`integrations.github`** | Token via Kubernetes **Secret** / env — chart-specific; see chart docs. |

Guest auth and `dangerouslyDisableDefaultAuthPolicy` in the sample file are **dev-only**.

---

## 2.3 GitHub token for Backstage

Create a token (classic or fine-grained) with scope to **read** the catalog repo and **create PRs** / **push** branches as your template actions require.

Mount according to chart conventions, e.g.:

```bash
kubectl -n idp create secret generic backstage-github-token \
  --from-literal=token=ghp_XXXXX
```

Reference that secret in Helm values per **`backstage/charts`** documentation (`extraEnv`, `envFrom`, etc.).

---

## 2.4 Expose Backstage

Default Service is often **ClusterIP**:

```bash
kubectl get svc -n idp backstage
```

**Port-forward:**

```bash
kubectl port-forward -n idp svc/backstage 7007:7007 --address 0.0.0.0
# http://localhost:7007  (or Cloud Shell Web Preview on 7007)
```

**LoadBalancer / Ingress** for team-wide access; then **update baseUrl** to match.

---

## 2.5 Verify Backstage

```bash
kubectl get pods -n idp -l app.kubernetes.io/name=backstage
helm list -n idp
helm get values backstage -n idp
```

In the UI: **Catalog** should list templates; **Create** should show **Software Templates** from `templates/all.yaml` **targets**.

---

# Part 3 — Order of operations (recommended)

1. **GKE** + `kubectl` working.  
2. **Argo CD** installed → UI reachable → **`kubectl apply -f argocd/dev-app.yaml`**.  
3. Confirm **`platform-api-dev`** is **Synced** / **Healthy** (after `gitops/` exists on `main`).  
4. **Backstage** installed with **catalog** pointing at **`templates/all.yaml`**.  
5. **GitHub Actions** secrets (**`GCP_CREDENTIALS`**) so Terraform + Cloud Build match your project.

---

# Part 4 — Troubleshooting

| Symptom | Check |
|---------|--------|
| Argo **Pending** LB | Wait; check `kubectl describe svc argocd-server -n gitops`; quotas. |
| **Invalid password** | Reset `argocd-secret` admin bcrypt hash; restart `argocd-server`. |
| Backstage **empty catalog** | `catalog.locations` URL must be **raw** YAML; repo **public** or token can read it. |
| Template **no PR** | GitHub token permissions; Backstage backend logs: `kubectl logs -n idp deploy/backstage`. |
| **OutOfSync** in Argo | Drift or bot not committed; **Refresh** app; fix Git. |

---

## References

- Argo CD: https://argo-cd.readthedocs.io/en/stable/getting_started/  
- Argo Helm: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd  
- Backstage Helm: https://github.com/backstage/charts  
- This repo: `docs/ARCHITECTURE.md`, `idp/README.md`, `argocd/README.md`
