# GCS buckets (Terraform)

- Add **one directory per bucket**: `infra/gcp-storage/<stack-name>/main.tf` with `output "bucket_name"`.
- **Do not** edit `gitops/base/gcp-bucket-nodes.yaml` or bucket lists in `platform-runtime-config` by hand — **GitHub Actions** regenerates them from `terraform output` across **all** stacks on every run.
- After merge to `main`, the **Infra Terraform** workflow applies changed stacks, then **always** rebuilds the GitOps files (no hardcoded names), then **automatically** runs **kubectl** against GKE to **apply** the Argo `Application` and **hard-refresh** `platform-api-dev` — **no manual Argo step**.
- **Important:** Argo CD only ever sees **Git**. If you create a bucket **only** in the GCP Console (no Terraform in this repo), nothing can sync to Argo until it exists as code under `infra/gcp-storage/`.
