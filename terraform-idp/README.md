# Terraform IDP Module

This module creates:
- team namespace
- resource quota
- limit range
- service account
- namespace-scoped read RBAC

## Usage

```bash
cd terraform-idp
terraform init
terraform plan -var="team_namespace=team-a" -var="service_account_name=team-viewer"
terraform apply -var="team_namespace=team-a" -var="service_account_name=team-viewer"
```

## Validate

```bash
kubectl get ns team-a
kubectl get quota -n team-a
kubectl get limitrange -n team-a
kubectl auth can-i get pods --namespace production --as system:serviceaccount:team-a:team-viewer
```
