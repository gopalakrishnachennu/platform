# GCS buckets (Terraform)

- One directory per stack: `infra/gcp-storage/<name>/` with `output "bucket_name"`.
- CI on `main` regenerates GitOps; **do not** hand-edit bucket ConfigMaps.
