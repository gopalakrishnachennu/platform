# Code comment structure (this repository)

Use this pattern so files stay consistent and easy to scan.

## Block header (YAML, Dockerfile, Terraform)

```text
# =============================================================================
# <FILE or COMPONENT NAME>
# -----------------------------------------------------------------------------
# Purpose:    One line — what this file or block does.
# Owner:      Which pipeline or team maintains it (optional).
# Related:    Paths or workflows (optional).
# =============================================================================
```

## Inline sections (Kubernetes / long YAML)

```text
# -----------------------------------------------------------------------------
# <Subsection> — short label
# -----------------------------------------------------------------------------
```

## HTML

```html
<!-- =============================================================================
     FILE: name
     Purpose: ...
     ============================================================================= -->
```

## GitHub Actions

- Top of file: full **WORKFLOW** block (Purpose, Triggers, Secrets used).
- Before each **job**: job name + one-line purpose.
- Before complex **steps**: brief `#` line.

## Do not

- Duplicate obvious field names (“replicas: 1  # replicas”).
- Put secrets or passwords in comments.
