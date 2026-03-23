# Platform deep-dive (2–3 hour session)

Audience: engineers who will operate or extend this platform.  
Goal: understand **IDP → Git → Terraform → GitOps → GKE**, then map **every folder/workflow** to behavior.

---

## Suggested agenda (150 min ≈ 2.5 h)

| Time | Block | What you cover |
|------|--------|----------------|
| 0:00–0:15 | **Context** | Problem statement: one repo, GCP, self-service infra, visible delivery. |
| 0:15–0:45 | **Concepts A–I** | Terms below — slides or whiteboard. |
| 0:45–1:15 | **End-to-end story** | One path: Backstage template → PR → merge → Actions → GCP + Git commit → Argo. |
| 1:15–1:45 | **Code walkthrough** | Repo tree → `templates/` → `infra/` → workflows → `gitops/` → `argocd/`. |
| 1:45–2:15 | **Live or recorded demo** | Backstage, GitHub Actions, Argo CD UI, optional `kubectl`. |
| 2:15–2:30 | **Q&A + ops** | Secrets, branching, DR, hardening. |

Stretch to **3 h**: add **30 min** on **GCP** (IAM, state bucket, networking) and **30 min** on **hardening** (auth, no guest Backstage, rotate keys).

---

## Part 1 — Concepts we discuss (checklist)

Use this as your **slide list**. Under each: **one sentence** + **where it appears in this repo**.

### A. Internal Developer Platform (IDP)

**What:** A single place (portal) where developers **discover** and **run** approved workflows (templates), instead of opening tickets for infra.  
**Here:** **Backstage** in GKE (`idp` namespace), templates under `templates/`.

### B. Software template (Backstage)

**What:** A **wizard** (forms) that runs **actions** (e.g. render files, open a PR).  
**Here:** `templates/gcp-storage-bucket/`, `templates/gcp-vpc-network/`, registered via `templates/all.yaml`.

### C. Git as source of truth

**What:** **Desired state** (Terraform + Kubernetes YAML) lives in **Git**; humans merge changes via PR.  
**Here:** Whole repo; `main` is the deployment branch for automation.

### D. Infrastructure as Code (IaC)

**What:** **Terraform** declares cloud resources (buckets, VPC, …); apply creates/changes them.  
**Here:** Stacks under `infra/` after a template PR merges (e.g. `infra/gcp-storage/<name>/main.tf`).

### E. Terraform remote state

**What:** State file stored in **GCS** so CI and teams share state and avoid local-only applies.  
**Here:** Workflow `infra-terraform.yml` uses `TF_STATE_BUCKET` and per-directory prefixes.

### F. Continuous Integration (CI)

**What:** On each change, **build/test/plan** automatically (GitHub Actions).  
**Here:** PR → Terraform **plan**; push to `main` → **apply** (for `infra/`), **Cloud Build** for images (all `main` pushes for `ci-cloudbuild.yml`).

### G. GitOps

**What:** **Cluster** is reconciled to match **Git**; operators don’t `kubectl apply` ad hoc for routine changes.  
**Here:** **Argo CD** syncs `gitops/overlays/dev` to namespace `dev`.

### H. Continuous Delivery / deployment

**What:** After merge, **new images** and **manifests** roll out automatically within guardrails.  
**Here:** Image tag updated in `gitops/base/deployment.yaml` by CI; Argo syncs deployment.

### I. Separation: “data plane” vs “control plane” (simple)

**What:** **GCP APIs** create buckets/VPC (**Terraform**). **Kubernetes** runs apps and **ConfigMaps** that **describe** or **surface** that info (**Argo**). Argo does **not** call GCP for buckets.  
**Here:** Terraform in Actions; Argo only applies `gitops/`.

### J. Artifact Registry & image tags

**What:** Built **OCI images** are stored in **Artifact Registry**; **immutable tags** (e.g. git SHA) trace what runs.  
**Here:** `us-central1-docker.pkg.dev/.../platform-api:<sha>` in `gitops/base/deployment.yaml`.

### K. Pull request workflow

**What:** **Review** before merge; optional **branch protection** and **required checks**.  
**Here:** Backstage opens PR; `infra-terraform.yml` plans on PR when `infra/**` changes.

### L. Observability (platform sense)

**What:** **You** know a step succeeded: **GitHub Actions** green, **Argo** Healthy/Synced, **GCP** console or `gcloud` for resources.  
**Here:** Not a separate metrics stack in this repo’s minimal layout — use **Actions**, **Argo UI**, **GCP**.

*(If you add Prometheus/Grafana later, that becomes “golden signals” for apps — separate topic.)*

---

## Part 2 — End-to-end flow (talk track)

1. Developer opens **Backstage** → **Create** → picks **GCS bucket** template.  
2. Fills **GitHub owner/repo**, **project**, **bucket name**, etc.  
3. Backstage **publishes a branch + PR** adding `infra/gcp-storage/.../main.tf`.  
4. **Review** PR → **Terraform plan** in Actions (on `infra/**`).  
5. **Merge** to `main`.  
6. **Actions** run `terraform apply` → **bucket exists in GCP**.  
7. Same workflow **reads outputs** and **updates** `gitops/base/platform-runtime-config.yaml`, `gcp-bucket-nodes.yaml`, optionally `argocd/dev-app.yaml` **info**.  
8. **Bot commits** those files if changed.  
9. **Argo CD** syncs `gitops/` → **ConfigMaps** in cluster update; **Application** UI shows bucket names in **Info**.  
10. **Separately**, on **every** `main` push, **Cloud Build** may build **`platform-api`** image and bump **Deployment** image → Argo rolls **pods** in `dev`.

---

## Part 3 — Code walkthrough (what each part does)

Walk the repo **top-down**. For each path: **purpose**, **key files**, **how it behaves**.

### Root

| Path | Purpose |
|------|--------|
| `README.md` | Entry point; links to architecture and IDP. |
| `Dockerfile` | Builds **tiny** image: Python serves `app/` on port **8080**. |
| `app/index.html` | Static content for the sample **platform-api** service. |

### `docs/`

| File | Purpose |
|------|--------|
| `ARCHITECTURE.md` | Provisioning flow IDP → GCP → Argo; operator setup. |
| `PLATFORM_TRAINING.md` | This training outline. |

### `templates/` (IDP)

| File / dir | Purpose |
|------------|--------|
| `all.yaml` | **Location** resource: list **raw Git URLs** to each `template.yaml` (Backstage catalog). |
| `gcp-storage-bucket/template.yaml` | Scaffolder: parameters, **publish** step → PR with Terraform under `infra/gcp-storage/`. |
| `gcp-storage-bucket/skeleton/main.tf` | **Template** Terraform copied/rendered into the PR. |
| `gcp-vpc-network/` | Same pattern for VPC/subnet/firewall. |
| `README.md` | How to register `targets` in `all.yaml`. |

**“How it works”:** Backstage reads `all.yaml` → loads **Templates** → user runs template → **git push** + **PR** with rendered `infra/...`.

### `infra/` (Terraform landing zone)

| Path | Purpose |
|------|--------|
| `gcp-storage/README.md` | Explains stacks live as `*/main.tf` with `output "bucket_name"`. |
| `.../main.tf` | **Created by Backstage PRs**, not shipped empty in minimal setup. |

**“How it works”:** After merge, **Actions** `init/plan/apply` per changed directory; **outputs** feed GitOps YAML generation in workflow.

### `.github/workflows/`

| Workflow | Trigger | What it does |
|----------|---------|----------------|
| `ci-cloudbuild.yml` | Push to `main` | **Cloud Build** image `platform-api:<sha>` → **patch** `gitops/base/deployment.yaml` → **commit** push. |
| `infra-terraform.yml` | PR/push `infra/**`, `workflow_dispatch` | **Plan** on PR; **apply** on `main`; **regenerate** `platform-runtime-config`, `gcp-bucket-nodes`, `argocd/dev-app.yaml` **info**; **commit**; **kubectl** refresh Argo **Application**. |
| `gitops-argoc-refresh.yml` | Push `gitops/**` or `argocd/**` | **kubectl apply** `argocd/dev-app.yaml` + **hard refresh** app. |

**“How it works”:** **GCP_CREDENTIALS** secret; **env** vars must match your **project**, **cluster**, **zone**, **state bucket**.

### `gitops/` (desired cluster state)

| Path | Purpose |
|------|--------|
| `base/deployment.yaml` | **Deployment** `platform-api`: **image** (tag from CI), **envFrom** ConfigMap `platform-runtime-config`, port **8080**. |
| `base/service.yaml` | **Service** `platform-api`: port **80** → target **8080** (in-cluster HTTP). |
| `base/platform-runtime-config.yaml` | **ConfigMap** — **generated** by CI from Terraform outputs (bucket/VPC fields). |
| `base/gcp-bucket-nodes.yaml` | **ConfigMap(s)** — **generated** so Argo tree shows **per-bucket** metadata. |
| `base/kustomization.yaml` | Lists **resources** for **kustomize**. |
| `overlays/dev/kustomization.yaml` | **Namespace** `dev`, patches replicas, points at **base**. |

**“How it works”:** Argo applies **kustomize build** of `overlays/dev` → objects in **`dev`** namespace.

### `argocd/`

| File | Purpose |
|------|--------|
| `dev-app.yaml` | **Application** CR: **repoURL**, **path** `gitops/overlays/dev`, **destination** namespace `dev`, **automated** sync + prune. |
| `README.md` | Set **repoURL** to your fork/clone. |

**“How it works”:** Argo **controller** watches this **Application**; **sync** = apply manifests from Git.

### `idp/`

| File | Purpose |
|------|--------|
| `backstage-values-dev.yaml` | **Helm values** for Backstage (URLs, catalog, GitHub token ref). |
| `README.md` | Required **baseUrl**, **catalog locations**, token. |

**“How it works”:** **Helm install/upgrade** `backstage` in namespace **`idp`** with `-f backstage-values-dev.yaml` (your cluster used chart **backstage 2.6.3**).

---

## Part 4 — “Metrics” / signals (how you know it’s working)

Use this table in the **final** segment — **not** Prometheus metrics unless you add them; these are **platform health signals**.

| Layer | What to show | Good signal | Bad signal |
|-------|----------------|-------------|------------|
| **Git** | Latest `main` | PR merged; bot commits for image/gitops | Failed merge; branch protection blocking bot |
| **Actions** | Workflow runs | Green **CI Cloud Build**, green **Infra Terraform** | Red steps; auth to GCP failed |
| **GCP** | Cloud Storage / APIs | Bucket exists; Terraform state in bucket | 403, API not enabled, quota |
| **Artifact Registry** | Image | Tag = **git SHA** | Build failed |
| **GKE** | `kubectl get pods -n dev` | `platform-api` **Running** **1/1** | CrashLoop, ImagePullBackOff |
| **Argo CD** | Application view | **Synced**, **Healthy** | OutOfSync, Degraded, Permission denied |
| **Backstage** | Create flow | Template completes; PR link | 401/500; GitHub token missing |

---

## Part 5 — Closing (what you say in the last 5 minutes)

- **Single repo** holds **templates**, **infra**, **gitops**, and **workflows** — roles are **separated by path and automation**.  
- **Backstage** = **human entry**; **Terraform** = **GCP reality**; **Argo** = **Kubernetes reality** from **gitops/**.  
- **Operate** via **Actions logs**, **Argo UI**, **GCP console**, **`kubectl`** — not by SSH to nodes.  
- **Next steps** for production: **lock down** Backstage auth, **rotate** secrets, **Ingress + TLS** for UIs, **narrow** firewall rules.

---

## Appendix — Commands cheat sheet (demo)

```bash
# Cluster
gcloud container clusters get-credentials platform-lab --zone us-central1-a --project chennu-platform

# App
kubectl get pods,svc -n dev -l app=platform-api

# Argo
kubectl get applications -n gitops

# Backstage (Helm)
helm list -n idp
helm get values backstage -n idp
```

---

*Generated for repo `platform` — adjust project/cluster/zone names in slides to match your environment.*
