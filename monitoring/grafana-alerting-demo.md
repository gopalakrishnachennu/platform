# Grafana / PagerDuty–style alerting (demo)

Your stack is **kube-prometheus-stack** → **Prometheus** + **Alertmanager** + **Grafana**. Alerts from `monitoring/prometheus-rules.yaml` go to **Alertmanager** first; Grafana can also send its own notifications via **Contact points** (PagerDuty, webhook, Slack, etc.).

## Option A — Fastest for a live demo (Grafana UI, no cluster YAML)

1. Port-forward Grafana (if not already):
   ```bash
   kubectl port-forward svc/kube-prometheus-grafana -n monitoring 3000:80
   ```
2. Open **http://localhost:3000** — login as `admin` (password from `kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d`).
3. Go to **Alerting** (bell) → **Contact points** → **Add contact point**.
4. Choose one:
   - **PagerDuty**: paste an **Events API v2** integration key from PagerDuty (free trial works).
   - **Webhook**: paste a URL from [webhook.site](https://webhook.site) — open that page in another tab to see the JSON payload when you test.
   - **Slack**: Incoming Webhook URL from Slack.
5. Click **Test** on the contact point — you should see a test notification (PagerDuty incident, webhook body, or Slack message).

This path is **only configuration in Grafana** — good for “PagerDuty-style” demos without editing Helm.

## Option B — Route real Prometheus alerts to PagerDuty (Alertmanager)

1. In PagerDuty: **Services** → **Service** → **Integrations** → add **Events API v2** → copy **Integration Key**.
2. Do **not** commit the key. Add it via Helm override or `kubectl edit secret` for Alertmanager — see [Alertmanager config](https://prometheus.io/docs/alerting/latest/configuration/).
3. For kube-prometheus-stack, typical pattern is `helm upgrade` with `alertmanager.config.receivers` containing `pagerduty_configs` + `routing_key`, or use **AlertmanagerConfig** CRD in `monitoring` namespace.

We keep the default **null** receiver in `kube-prometheus-values.yaml` so nothing external is called until you opt in.

## Option C — See alerts in Grafana without email/PagerDuty

1. **Alerting** → **Alert rules** — explore rules from Prometheus / Alertmanager datasource.
2. **Explore** → datasource **Alertmanager** (if listed) to see active / silenced alerts.

## Optional: fire a noisy test alert (remove after demo)

Apply a always-firing demo rule, verify routing, then delete it:

```bash
kubectl apply -f monitoring/prometheus-rules-demo.yaml
# After demo:
kubectl delete -f monitoring/prometheus-rules-demo.yaml
```

## Files in this repo

| File | Purpose |
|------|--------|
| `monitoring/prometheus-rules.yaml` | Real SLO-style alerts (error rate, latency, restarts, memory). |
| `monitoring/prometheus-rules-demo.yaml` | Optional always-firing alert for routing tests (not applied by default). |
| `monitoring/kube-prometheus-values.yaml` | Helm overrides (unified alerting on, Alertmanager routes). |
