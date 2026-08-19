---
name: use-argo
description: Diagnose Argo CD application health, sync status, and deployment issues. Use when troubleshooting application deployments, checking sync status, viewing resource health, or identifying configuration drift.
argument-hint: '[application-name] [environment]'
allowed-tools: Bash
allowed-tools-patterns: which argocd|argocd version|argocd login|argocd app list|argocd app get|argocd app history|argocd app diff|argocd app resources|argocd app wait|grep|head|tail
---

# Argo CD Application Inspection

Use the dev and prod server addresses from the project's `CLAUDE.md`.

Always ask which environment (dev or prod) before running commands if not specified.

**Tokens expire daily.** On any auth error, re-authenticate automatically without asking the user:

```bash
argocd login <dev-server> --sso
```

## Common Commands

```bash
# Check an app
argocd app get <app-name> --server <dev-server> --grpc-web

# Find apps with issues
argocd app list --server <dev-server> --grpc-web | grep -E "(Unknown|Progressing|Degraded|Missing|OutOfSync)"

# View deployment history
argocd app history <app-name> --server <dev-server> --grpc-web

# Check resource-level status
argocd app resources <app-name> --server <dev-server> --grpc-web
```

When reporting issues, include the UI link: `https://<dev-or-prod-server>/applications/<app-name>`
