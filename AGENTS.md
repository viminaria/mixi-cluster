# mixi-cluster

Talos Linux + TrueCharts ClusterTool Kubernetes cluster. Flux CD GitOps. SOPS-encrypted secrets (age).

## Structure

```
clusters/main/              # single cluster
  clusterenv.yaml           # SOPS-encrypted env vars (node IPs, passwords, tokens)
  kubernetes/
    kustomization.yaml      # root: resources = apps/ core/ flux-entry.yaml flux-system/ kube-system/ models/ networking/ system/
    flux-entry.yaml         # Flux Kustomization entrypoint (sops decryption + variable substitution)
    apps/                   # each app: <name>/ks.yaml + <name>/app/helm-release.yaml + namespace.yaml
    system/                 # platform services (same pattern)
    models/                 # LLM model manifests (IsClusterIP, Ingress)
repositories/               # GitRepository + HelmRepository + OCIRepository definitions
```

Each app/system component has a `ks.yaml` (Flux Kustomization) and an `app/` directory with Helm release and namespace manifests.

## Secrets

- `clusterenv.yaml` is SOPS-encrypted with age. Edit with `sops --inplace clusters/main/clusterenv.yaml`
- `.sops.yaml` defines encryption rules: `values.yaml` files matching `clusters.*kubernetes.*values.yaml` and `.secret.yaml` files are auto-encrypted
- `age.agekey` is gitignored. Never commit it
- Secrets matching patterns like `password`, `secret`, `token`, `key` in Helm values are auto-encrypted by SOPS

## Adding an app

1. Create `clusters/main/kubernetes/apps/<name>/` directory
2. Add `ks.yaml` (Flux Kustomization pointing to `./app`)
3. Add `app/namespace.yaml`
4. Add `app/helm-release.yaml`
5. Add parent `kustomization.yaml` resource if not already auto-wired

## CLI tools

- `clustertool` — ClusterTool CLI (generated, gitignored, not in repo)
- `forgetool` — Flux CLI (generated, gitignored, not in repo)
- These are not source files; they are downloaded/managed externally

## Renovate

- Config: `.github/renovate.json5` extending TrueCharts templates
- System upgrade packages (kubectl, kubelet, installer) require manual approval — no automerge
- Pin updates auto-merge with `type/pin` label
- `custom.json5`: minio, postgresql, reloader updated "at any time"

## Dev container

- Image: `oci.trueforge.org/tccr/devcontainer:v4.0.1`
- Post-create: installs fisher plugins, krew + pv-mounter/cnpg/df-pv plugins
- Runs with `--privileged` for k8s access

## GitOps flow

1. Push changes to `main` branch
2. Flux webhook triggers reconciliation immediately on push — no wait needed
3. SOPS decryption and variable substitution applied via `postBuild.substituteFrom`
4. `substitution.flux.home.arpa/disabled=true` label skips substitution

## Style

- Flux Kustomization resources only (no raw Deployments/Services)
- Helm releases via Flux HelmRelease (TrueCharts charts)
- Each app owns its namespace
- Models (LLM serving) use separate IsClusterIP, Ingress, Model manifests

## Chart Values

TrueCharts Helm values reference (source of truth for available options):

```
https://github.com/trueforge-org/truecharts/blob/master/charts/{incubator|stable}/{chart}/values.yaml
```

- `incubator/` — experimental/newer charts
- `stable/` — mature/stable charts
- Replace `{chart}` with the actual chart directory name (usually differs from release name)
- Upstream `values.yaml` is the source of truth with all defaults. Only override keys in HelmRelease that actually differ from defaults — every value set in `helm-release.yaml` overrides upstream, so minimize values to reduce drift and simplify upgrades
