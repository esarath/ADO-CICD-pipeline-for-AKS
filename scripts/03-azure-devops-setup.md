# Azure DevOps Setup Guide

One-time configuration in Azure DevOps so the pipeline YAMLs work end to end.
Everything below is **manual in the portal** (or scriptable via `az devops` / REST).

## 1. Organization + Project

1. https://dev.azure.com -> **New organization** (free tier: 5 Basic users, 1 free
   Microsoft-hosted parallel job for private projects after the free-grant request,
   unlimited for public projects).
2. Create project `aks-devsecops-platform` (private).
3. Push this repo into **Repos**:

   ```powershell
   cd C:\Users\tiny-win\Desktop\DATA_STORE\JOBS\Hexaware
   git init; git add -A; git commit -m "platform baseline"
   git remote add origin https://dev.azure.com/<org>/aks-devsecops-platform/_git/platform
   git push -u origin main
   ```

## 2. ARM Service Connection (Workload Identity Federation - no secrets)

Project Settings -> Service connections -> **New** -> Azure Resource Manager ->
**Workload identity federation (automatic)** -> Subscription `adminebooks`
(995377ec-18d5-43bb-98db-74ab68a2ef8f) -> name it **`sc-azdo-aks-platform`** ->
Resource group: leave empty (scripts use explicit RGs) -> Grant access to all
pipelines (POC) -> Save.

Then grant the created service principal Azure RBAC:

```powershell
# ObjectId is shown on the service connection page (or via az ad sp list)
az role assignment create --assignee <SP_OBJECT_ID> `
  --role Contributor --scope /subscriptions/995377ec-18d5-43bb-98db-74ab68a2ef8f
# Narrower scopes for real prod: Contributor on the three RGs only +
# AcrPush/AcrPull on the ACRs instead of subscription Contributor.
```

## 3. Variable Group `platform-settings`

Pipelines -> Library -> **+ Variable group** -> name `platform-settings`:

| Variable | Value (example) |
|---|---|
| `acrNonProdName` | `acrhexaksnp001` |
| `acrProdName` | `acrhexakspr001` |
| `keyVaultName` | `kv-hexaks-001` |
| `aksDevRg` / `aksDevName` | `rg-hexaks-dev` / `aks-hexaks-dev` |
| `aksProdRg` / `aksProdName` | `rg-hexaks-prod` / `aks-hexaks-prod` |
| `sonarOrg` | your SonarCloud org (only if enabling Sonar) |

For secrets: toggle **Link secrets from an Azure key vault** on the group and
point at `kv-hexaks-001` (uses the ARM service connection).

## 4. Environments (approval gates)

Pipelines -> Environments -> **New environment**:

- `aks-staging` - no checks (auto-deploy).
- `aks-production` - open it -> Approvals and checks -> **Approvals** ->
  add yourself/team -> "Minimum 1 approver". This is the *manual
  intervention* step between staging and prod in the reference architecture.

## 5. Create the pipelines

Pipelines -> New pipeline -> Azure Repos Git -> repo -> **Existing YAML file**:

| Pipeline | YAML path |
|---|---|
| PR - Validate | `pipelines/azure-pipelines-pr.yml` |
| CI - Build & Push | `pipelines/azure-pipelines-ci.yml` |
| Promote - Image | `pipelines/azure-pipelines-promote.yml` |
| CD - Staging & Prod | `pipelines/azure-pipelines-cd.yml` |

## 6. Branch policy on `main` (wires the PR pipeline)

Project Settings -> Repositories -> repo -> Policies -> `main`:

- Minimum number of reviewers: 1 (+ "Allow requestors to approve" off for real teams)
- **Build validation**: add the PR pipeline, automatic trigger, required
- Reset votes on new pushes: on
- Optional: comment resolution required, limit merge types to squash

## 7. Agents (cost note)

- Microsoft-hosted `ubuntu-latest`: free for public projects; private projects
  need the free parallelism grant (request in portal) or a self-hosted agent.
- Self-hosted cheapest option: install the agent on your workstation
  (Settings -> Agent pools -> Default -> New agent) or a `Standard_B2s`
  **spot** VM (~$6/mo) in the platform RG.

## 8. SonarQube option

- Easiest: **SonarCloud** (free for public projects) -> service connection
  named `SonarCloud`, set pipeline variable `enableSonar=true`.
- Or self-host SonarQube Community as a container on the dev cluster's spot
  pool (free but uses cluster capacity).
