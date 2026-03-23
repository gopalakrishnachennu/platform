# Argo CD: “Resource not found in cluster” (LIVE MANIFEST) but Synced / Healthy

## What you see

- Summary / tree: **Synced**, **Healthy**
- **LIVE MANIFEST** tab: **Resource not found in cluster** for `Deployment`, `Service`, `ConfigMap` in `dev`

Resources often **do exist** (`kubectl get` works). The UI failed to **GET** them live.

---

## 1) Confirm objects exist (same cluster as Argo)

```bash
kubectl get deploy,svc,cm -n dev
kubectl get application platform-api-dev -n gitops -o yaml | grep -A5 'destination:'
```

If these are missing, fix the cluster first (not an Argo UI-only issue).

---

## 2) Check if `argocd-server` may read `dev` (RBAC)

Argo CD’s **server** uses the **`argocd-server`** ServiceAccount (often in **`gitops`** or **`argocd`**).

```bash
NS=gitops   # or: argocd

kubectl auth can-i get deployments -n dev --as=system:serviceaccount:${NS}:argocd-server
kubectl auth can-i get configmaps -n dev --as=system:serviceaccount:${NS}:argocd-server
kubectl auth can-i get services -n dev --as=system:serviceaccount:${NS}:argocd-server
```

- If **no** → bind the **view** ClusterRole (read-only) to the server SA:

```bash
kubectl create clusterrolebinding argocd-server-view \
  --clusterrole=view \
  --serviceaccount=${NS}:argocd-server \
  --dry-run=client -o yaml | kubectl apply -f -
```

(If a binding already exists with a different name, **describe** it first: `kubectl get clusterrolebinding | grep argocd`.)

- If **yes** → RBAC is likely fine; continue to §3.

---

## 3) Restart Argo CD (server + controller cache)

```bash
kubectl rollout restart deployment/argocd-server -n gitops
kubectl rollout restart deployment/argocd-application-controller -n gitops
kubectl rollout status deployment/argocd-server -n gitops
```

**Hard refresh** the Application in the UI (or use CLI):

```bash
argocd app get platform-api-dev --hard-refresh   # if you use argocd CLI
```

---

## 4) Upgrade Argo CD (older UIs had bugs)

**v2.3.x** is old; **v3.x** has many UI/API fixes. If you still see the error after §2–3, plan an upgrade.

---

## 5) Optional: network policy

If you use **NetworkPolicies** in `dev` or `gitops`, ensure the **kube-apiserver** can reach `argocd-server` (usually not blocked by NetworkPolicy for API access). Rare; worth checking only on **locked-down** clusters.

---

## Summary

| Cause | Fix |
|--------|-----|
| **SA cannot read** `dev` | **ClusterRoleBinding** `view` → `argocd-server` |
| **Stale cache / UI** | **Restart** `argocd-server` + **hard refresh** app |
| **Old Argo CD** | **Upgrade** |

---

If you paste **output** of `kubectl auth can-i ...` (the three lines) and the **namespace** where Argo CD is installed (`gitops` vs `argocd`), you can narrow the exact fix in one step.
