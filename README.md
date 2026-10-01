# AKS DevSecOps Platform - Implementation Package

End-to-end implementation blueprint for the Azure AKS DevSecOps reference
architecture, sized for a **personal pay-as-you-go subscription**
(`adminebooks` / `995377ec-18d5-43bb-98db-74ab68a2ef8f`) - small SKUs and
Spot node pools throughout.

## Start here

Open **`docs/index.html`** in a browser - it links all six documents:

| Doc | Covers |
|---|---|
| `docs/01-architecture-blueprint.html` | Stage-by-stage architecture, decisions, naming/versioning/release standards |
| `docs/02-installation-guide.html` | What to install, where, in which order + timelines |
| `docs/03-pipelines-and-promotion.html` | The 4 pipelines, security tooling, image promotion (non-prod → prod ACR) |
| `docs/04-deployment-strategies.html` | Rolling / Blue-Green / Canary / Helm / ArgoCD pros & cons |
| `docs/05-monitoring-security.html` | Prometheus, Grafana, LAW, Defender, Key Vault CSI, KQL, Day-2 ops |
| `docs/06-cost-optimization.html` | SKU choices, monthly estimate, spot strategy, budget guardrails |

## Deploy order

```powershell
scripts\00-prerequisites.ps1            # tools, az login, provider registration
# edit infra/bicep/params/platform.bicepparam  (globally-unique names!)
scripts\01-deploy-infrastructure.ps1    # platform RG + dev/prod AKS via Bicep
scripts\02-post-deployment-config.ps1   # kubeconfig, namespaces, Prometheus
# then follow scripts\03-azure-devops-setup.md (org, service conn, envs, policies)
```

## Layout

```
docs/            HTML documentation set (open index.html)
infra/bicep/     platform.bicep (shared) + main.bicep (per-env) + modules/ + params/
pipelines/       Azure DevOps YAML (pr / ci / promote / cd) + templates/
helm/sample-app/ Helm chart: values.yaml + values-staging + values-production
k8s/             namespaces (Pod Security) + default-deny NetworkPolicies
gitops/argocd/   ArgoCD installer + Application manifests (GitOps alternative)
scripts/         numbered PowerShell runbooks + Azure DevOps setup guide
src/             sample Flask app + Dockerfile + pytest tests
```

## Cost profile

- AKS Free tier control plane, 1× B2s system node, 0-3× B2s **Spot** user pool
- ACR Basic ×2, Key Vault Standard, LAW PAYG with 1 GB/day cap
- Estimated ~$45-130/month depending on optional components - see doc 06.
