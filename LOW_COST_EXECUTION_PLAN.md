# Platform Engineering Low-Cost Execution Plan (No Docker)

This plan is optimized for lowest possible cost while still completing:

1. Internal Developer Platform (Backstage + Terraform guardrails)
2. GitOps Multi-Environment Pipeline (GitHub Actions + ArgoCD)
3. Observability Stack (Prometheus + Grafana + Loki + Alerting)

## Cost Strategy (Important)

- Use one zonal GKE cluster.
- Use Spot nodes.
- Start with a single node.
- Use port-forward for Backstage, ArgoCD, and Grafana (no Load Balancer cost).
- Keep retention low for logs and metrics.
- Scale up to 2 nodes only if pods cannot schedule.

## Default Values Used

- GCP project ID: `chennu-platform`
- Cluster: `platform-lab`
- Zone: `us-central1-a`
- Region: `us-central1`
- Node pool: Spot enabled
- Namespaces: `idp`, `gitops`, `monitoring`, `dev`, `staging`, `production`

## Phase 0: Preflight (Local Machine)

You already have:
- Helm
- Terraform

You still need:
- gcloud CLI
- kubectl

Install quickly on macOS:

```bash
brew install --cask google-cloud-sdk
brew install kubectl
```

Then initialize:

```bash
gcloud init
gcloud auth application-default login
```

## Phase 1: GCP Bootstrap

Enable APIs:

```bash
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project chennu-platform
```

Create cluster (ultra-cheap start):

```bash
gcloud container clusters create platform-lab \
  --project chennu-platform \
  --zone us-central1-a \
  --num-nodes 1 \
  --machine-type e2-standard-2 \
  --spot
```

Connect kubectl:

```bash
gcloud container clusters get-credentials platform-lab \
  --zone us-central1-a \
  --project chennu-platform

kubectl get nodes
```

Create namespaces:

```bash
kubectl create namespace idp
kubectl create namespace gitops
kubectl create namespace monitoring
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production
```

## Phase 2: Project 1 (IDP)

Install Backstage:

```bash
helm repo add backstage https://backstage.github.io/charts
helm repo update
helm install backstage backstage/backstage -n idp
kubectl get pods -n idp
```

Access Backstage:

```bash
kubectl port-forward svc/backstage 7007:7007 -n idp
```

Then open `http://localhost:7007`.

Terraform deliverable for each team namespace:
- Namespace
- ResourceQuota
- LimitRange
- ServiceAccount
- RoleBinding (namespace-scoped view)

Validation:

```bash
kubectl get ns
kubectl get resourcequota -n <team-namespace>
kubectl get limitrange -n <team-namespace>
kubectl auth can-i get pods --namespace production \
  --as system:serviceaccount:<team-namespace>:<service-account-name>
```

Expected final command output: `no`.

## Phase 3: Project 2 (GitOps, No Docker)

Approach:
- Build/push images with Cloud Build (no local Docker engine).
- ArgoCD watches GitOps repo for deploys.

Install ArgoCD:

```bash
kubectl create namespace gitops || true
kubectl apply -n gitops -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n gitops
```

Access ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n gitops 8080:443
```

GitHub Actions flow:
- Trigger on push to app repo.
- Run tests.
- Build and push image via `gcloud builds submit`.
- Update GitOps manifests image tag.
- ArgoCD syncs:
  - `dev` auto sync
  - `staging` PR gated
  - `production` manual approval

## Phase 4: Project 3 (Observability)

Install kube-prometheus-stack:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install kube-prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

Install Loki stack:

```bash
helm install loki grafana/loki-stack -n monitoring \
  --set promtail.enabled=true
```

Access Grafana:

```bash
kubectl port-forward svc/kube-prometheus-grafana -n monitoring 3000:80
```

Then open `http://localhost:3000`.

Create dashboard:
- Traffic
- Error rate
- p99 latency
- CPU saturation
- Namespace variable filter

## Phase 5: End-to-End Validation

1. Backstage loads.
2. Terraform provisions team namespace + quotas + RBAC.
3. Commit app change.
4. GitHub Actions builds via Cloud Build and updates GitOps manifests.
5. ArgoCD deploys to `dev`.
6. Grafana shows metrics/logs for `dev`.
7. Promote to `staging`.
8. Manual promote to `production`.
9. Test alert firing.
10. Rollback by git revert + ArgoCD sync.

## If Single Node Is Not Enough

Scale to two nodes:

```bash
gcloud container clusters resize platform-lab \
  --project chennu-platform \
  --zone us-central1-a \
  --num-nodes 2
```

## Daily Cost Control

- Shut down cluster when not using it (largest savings).
- Avoid cloud load balancers initially.
- Keep one node except during testing spikes.
- Use budget alerts at 50/90/100%.
