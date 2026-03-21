#!/usr/bin/env bash
set -euo pipefail

# Opens four Terminal tabs (macOS) and starts port-forwards.
osascript <<'EOF'
tell application "Terminal"
  activate
  do script "kubectl port-forward svc/backstage 7007:7007 -n idp"
  do script "kubectl port-forward svc/argocd-server 8080:443 -n gitops"
  do script "kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n monitoring"
  do script "kubectl port-forward svc/demo-app 18080:80 -n dev"
end tell
EOF

echo "Started all 4 port-forward commands in Terminal tabs."
