#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_cmd() {
  local msg="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$msg"
  else
    fail "$msg"
  fi
}

echo "Running platform health checks..."
echo

# 1) Basic cluster access
check_cmd "Kubernetes API reachable" kubectl cluster-info
check_cmd "At least one node is Ready" bash -c "kubectl get nodes --no-headers | awk '\$2==\"Ready\"{ok=1} END{exit !ok}'"

# 2) Required namespaces
for ns in idp gitops monitoring dev staging production; do
  check_cmd "Namespace exists: ${ns}" kubectl get namespace "${ns}"
done

# 3) Core workloads
check_cmd "Backstage deployment available" bash -c "kubectl get deploy -n idp backstage -o jsonpath='{.status.availableReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "ArgoCD server available" bash -c "kubectl get deploy -n gitops argocd-server -o jsonpath='{.status.availableReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "Grafana deployment available" bash -c "kubectl get deploy -n monitoring kube-prometheus-grafana -o jsonpath='{.status.availableReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "Prometheus statefulset ready" bash -c "kubectl get sts -n monitoring prometheus-kube-prometheus-kube-prome-prometheus -o jsonpath='{.status.readyReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "Loki statefulset ready" bash -c "kubectl get sts -n monitoring loki -o jsonpath='{.status.readyReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"

# 4) ArgoCD app sync/health
for app in demo-app-dev demo-app-staging demo-app-production; do
  check_cmd "ArgoCD app is Synced: ${app}" bash -c "[ \"\$(kubectl get app -n gitops ${app} -o jsonpath='{.status.sync.status}')\" = \"Synced\" ]"
  check_cmd "ArgoCD app is Healthy: ${app}" bash -c "[ \"\$(kubectl get app -n gitops ${app} -o jsonpath='{.status.health.status}')\" = \"Healthy\" ]"
done

# 5) Deployed app workloads
check_cmd "Dev app available" bash -c "kubectl get deploy -n dev demo-app -o jsonpath='{.status.availableReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "Staging app available" bash -c "kubectl get deploy -n staging demo-app -o jsonpath='{.status.availableReplicas}' | awk '\$1>=1{ok=1} END{exit !ok}'"
check_cmd "Production app available (2 replicas expected)" bash -c "kubectl get deploy -n production demo-app -o jsonpath='{.status.availableReplicas}' | awk '\$1>=2{ok=1} END{exit !ok}'"

# 6) Alert rules
check_cmd "Custom alert rule exists (platform-alerts)" kubectl get prometheusrule -n monitoring platform-alerts

echo
echo "Health check summary: PASS=${PASS_COUNT}, FAIL=${FAIL_COUNT}"

if [ "${FAIL_COUNT}" -gt 0 ]; then
  exit 1
fi

echo "Overall status: PASS"
