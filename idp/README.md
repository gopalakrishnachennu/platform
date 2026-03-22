# Backstage

Helm values: `backstage-values-dev.yaml`.

**Required before install**

1. Non-empty **`app.baseUrl`**, **`backend.baseUrl`**, **`cors.origin`** — URL where Backstage is served.
2. **`catalog.locations`** — add at least one `url` entry whose `target` is the raw Git URL of `templates/all.yaml` in this repository.
3. **`integrations.github`** token — via env or Secret.
4. Rotate **`auth.keys`** / `dangerouslyDisableDefaultAuthPolicy` for production.
