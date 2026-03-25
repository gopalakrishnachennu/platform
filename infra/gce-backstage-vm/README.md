# Backstage on Compute Engine (Terraform)

This stack creates a Compute Engine VM and runs Backstage on port `7007` via Docker.

## Apply

Your repo CI is already wired to run Terraform for `infra/**` directories:

- PR: `terraform plan`
- Merge to `main`: `terraform apply`

## Outputs

- `backstage_url` — open this in your browser.

## Lock down access (recommended)

Change `source_ranges` from `0.0.0.0/0` to your IP:

```hcl
source_ranges = ["YOUR_PUBLIC_IP/32"]
```

