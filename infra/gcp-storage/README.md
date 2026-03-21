# GCS buckets (Terraform)

- Add **one directory per bucket**: `infra/gcp-storage/<stack-name>/main.tf` with `output "bucket_name"`.
- **Do not** edit `gitops/base/gcp-bucket-nodes.yaml` or bucket lists in `platform-runtime-config` by hand — **GitHub Actions** regenerates them from `terraform output` across **all** stacks on every run.
- After merge to `main`, the **Infra Terraform** workflow applies changed stacks, then **always** rebuilds the GitOps files (no hardcoded names).
- To refresh GitOps from existing state **without** a new `.tf` change: **Actions → Infra Terraform → Run workflow**.
